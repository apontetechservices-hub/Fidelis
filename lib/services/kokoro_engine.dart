import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'tts_text.dart';

export 'tts_text.dart' show KokoroVoice;

/// One synthesized sentence: raw PCM samples + sample rate.
class KokoroAudio {
  final Float32List samples;
  final int sampleRate;
  const KokoroAudio(this.samples, this.sampleRate);
}

/// On-device Kokoro TTS engine (sherpa-onnx 1.13.8, Kokoro v1.0 INT8).
///
/// Voices are per-slot profiles ([KokoroVoice]): the Bible speaks the
/// owner's voice-grid configuration — EN am_michael blended 70/30 with
/// am_echo (both sids render, PCM-mixed) at speed 0.81 / ES em_alex solo —
/// the rosary's runtime slot speaks EN af_aoede / ES af_aoede blended
/// 70/30 with ef_dora under Spanish phonemization, and readings plus the
/// rosary's timing-only synthesis keep the standard voices (EN bm_george
/// sid 26 / ES em_alex sid 29, speed 0.9). Kokoro has no Latin voice —
/// 'la' callers must use the flutter_tts path.
///
/// Model files ship as Flutter assets under assets/kokoro/ (~155 MB) and are
/// copied once to the app support directory, because onnxruntime needs real
/// file paths. Synthesis runs on a long-lived worker isolate: model loading
/// and generate() are heavy synchronous FFI calls that must never block the
/// UI. Kokoro's phonemization language is an engine-level setting, so the
/// worker recreates the engine when the requested language changes.
class KokoroEngine {
  KokoroEngine._();

  static const _assetRoot = 'assets/kokoro';

  /// Bump when the bundled model files change to force a re-copy on devices.
  static const _stamp = 'kokoro-int8-v1.0-2026-10-26';

  /// Sticky: any hard failure disables Kokoro for the rest of the session and
  /// callers fall back to flutter_tts (audio must never break).
  static bool _failed = false;
  static Future<bool>? _prepFuture;
  static String? _modelDirPath;

  static Isolate? _isolate;
  static ReceivePort? _responses;
  static ReceivePort? _exitPort;
  static SendPort? _toWorker;
  static Completer<void>? _hello;
  static int _nextId = 0;
  static final Map<int, Completer<Map<Object?, Object?>>> _pending = {};
  static String? _loadedLang;

  /// Copies the bundled model files to the app support directory if needed.
  /// Cheap no-op after the first run (marker check only). Safe to call at
  /// startup to keep the first listen tap fast.
  static Future<bool> prepareAssets() async {
    if (_failed) return false;
    try {
      _prepFuture ??= _prepare();
      return _prepFuture!;
    } catch (_) {
      _failed = true;
      return false;
    }
  }

  /// Ensures the worker can synthesize [lang] ('en' | 'es').
  /// Returns false on any failure (caller must fall back to flutter_tts).
  static Future<bool> ensureReady(String lang) async {
    if (_failed || (lang != 'en' && lang != 'es')) return false;
    try {
      if (!await prepareAssets()) {
        _failed = true;
        return false;
      }
      if (_isolate == null && !await _spawnWorker()) {
        _failed = true;
        return false;
      }
      if (_loadedLang == lang) return true;
      final ack = await _request('init', {'lang': lang},
          timeout: const Duration(seconds: 90));
      if (ack == null || ack['ok'] != true) {
        _failed = true;
        _killWorker();
        return false;
      }
      _loadedLang = lang;
      return true;
    } catch (_) {
      _failed = true;
      _killWorker();
      return false;
    }
  }

  /// Synthesizes [text] with [voice]'s sid/speed for [lang]; when the
  /// slot carries a blend partner for [lang], the text is rendered by BOTH
  /// sids under the same engine phonemization and the renders are PCM-mixed
  /// at the slot's ratio (the mixed length is the schedule's timing
  /// source). Returns null on failure (caller falls back to flutter_tts —
  /// audio must never break).
  static Future<KokoroAudio?> synthesize(
    String text,
    String lang, {
    KokoroVoice voice = KokoroVoice.standard,
  }) async {
    if (_failed || (lang != 'en' && lang != 'es')) return null;
    if (!await ensureReady(lang)) return null;
    final ack = await _request('gen', {
      'text': text,
      'sid': voice.sidFor(lang),
      'speed': voice.speed,
      'blendSid': voice.blendSidFor(lang),
      'blendRatio': voice.blendRatio,
    }, timeout: const Duration(minutes: 3));
    if (ack == null || ack['ok'] != true) return null;
    final samples = ack['samples'];
    final rate = ack['rate'];
    if (samples is! Float32List || rate is! int) return null;
    return KokoroAudio(samples, rate);
  }

  /// Releases the worker isolate and native engine (e.g. on hard failure).
  static void shutdown() {
    _failed = true;
    _killWorker();
  }

  // ---- internals ----

  static void _failAll(String error) {
    _failed = true;
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.complete(<Object?, Object?>{'ok': false, 'error': error});
      }
    }
    _pending.clear();
    _isolate = null;
    _toWorker = null;
    _responses?.close();
    _exitPort?.close();
    _responses = null;
    _exitPort = null;
    _loadedLang = null;
  }

  static void _killWorker() {
    _isolate?.kill(priority: Isolate.immediate);
    _failAll('worker killed');
  }

  static Future<bool> _spawnWorker() async {
    final dir = _modelDirPath;
    if (dir == null) return false;
    final mainPort = ReceivePort();
    final exit = ReceivePort();
    try {
      final isolate = await Isolate.spawn(
        _workerMain,
        _WorkerSetup(mainPort.sendPort, dir),
        onExit: exit.sendPort,
      );
      _isolate = isolate;
      _exitPort = exit;
      _responses = mainPort;
      _hello = Completer<void>();
      exit.listen((_) => _failAll('worker exited'));
      mainPort.listen((msg) {
        final m = msg as Map;
        if (m['type'] == 'hello') {
          _toWorker = m['port'] as SendPort;
          if (_hello != null && !_hello!.isCompleted) _hello!.complete();
          return;
        }
        final id = m['id'] as int;
        final pending = _pending.remove(id);
        if (pending != null && !pending.isCompleted) pending.complete(m);
      });
      // The worker answers with its inbox port once bindings are up.
      await _hello!.future.timeout(const Duration(seconds: 30));
      _hello = null;
      return true;
    } catch (_) {
      mainPort.close();
      exit.close();
      _isolate = null;
      _toWorker = null;
      _responses = null;
      _exitPort = null;
      return false;
    }
  }

  /// Sends a command to the worker and awaits its ack by id. Returns null on
  /// timeout/transport failure.
  static Future<Map<Object?, Object?>?> _request(
    String cmd,
    Map<String, Object?> args, {
    required Duration timeout,
  }) async {
    final worker = _toWorker;
    if (worker == null) return null;
    final id = _nextId++;
    final done = Completer<Map<Object?, Object?>>();
    _pending[id] = done;
    worker.send({'cmd': cmd, 'id': id, ...args});
    try {
      return await done.future.timeout(timeout, onTimeout: () {
        _pending.remove(id);
        // A hung generation means the worker is unusable; fail sticky so all
        // future speech falls back to flutter_tts immediately.
        _killWorker();
        return <Object?, Object?>{'ok': false, 'error': 'timeout'};
      });
    } catch (_) {
      _pending.remove(id);
      return null;
    }
  }

  static Future<bool> _prepare() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dirPath = '${support.path}/kokoro';
      _modelDirPath = dirPath;
      final marker = File('$dirPath/.ready');
      if (marker.existsSync() && marker.readAsStringSync() == _stamp) {
        return true;
      }
      // Copy in a background isolate: loading the 114 MB model asset spikes
      // memory and must not jank the UI. rootBundle there needs the binary
      // messenger token of this isolate.
      final token = RootIsolateToken.instance;
      if (token == null) return false;
      return await Isolate.run(() async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        final assets = manifest
            .listAssets()
            .where((a) => a.startsWith('$_assetRoot/'))
            .toList()
          ..sort();
        if (assets.isEmpty) return false;
        for (final asset in assets) {
          final rel = asset.substring(_assetRoot.length);
          final file = File('$dirPath$rel');
          await file.parent.create(recursive: true);
          final bytes = await rootBundle.load(asset);
          await file.writeAsBytes(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
            flush: true,
          );
        }
        // The model ships as split parts (GitHub's 100 MB file limit);
        // reassemble and drop the parts to halve the on-device footprint.
        final modelFile = File('$dirPath/model.int8.onnx');
        if (await modelFile.exists()) await modelFile.delete();
        final parts = Directory(dirPath)
            .listSync()
            .whereType<File>()
            .where((f) => f.uri.pathSegments.last
                .startsWith('model.int8.onnx.part-'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        if (parts.isEmpty) return false;
        final sink = modelFile.openWrite(mode: FileMode.write);
        for (final part in parts) {
          await sink.addStream(part.openRead());
        }
        await sink.flush();
        await sink.close();
        for (final part in parts) {
          try {
            await part.delete();
          } catch (_) {}
        }
        // Written last: its presence means the copy is complete, so a crash
        // mid-copy simply re-copies on the next launch.
        await File('$dirPath/.ready').writeAsString(_stamp, flush: true);
        return true;
      });
    } catch (_) {
      return false;
    }
  }
}

class _WorkerSetup {
  final SendPort toMain;
  final String modelDir;
  const _WorkerSetup(this.toMain, this.modelDir);
}

/// Long-lived synthesis worker. Owns the OfflineTts instance; processes one
/// command at a time (a long generate() naturally delays later messages).
/// Any uncaught error kills the isolate, which the parent treats as a hard
/// failure and falls back to flutter_tts.
void _workerMain(_WorkerSetup setup) {
  // FFI binding state is per-isolate — must be initialized here too.
  sherpa.initBindings();
  final inbox = ReceivePort();
  setup.toMain.send({'type': 'hello', 'port': inbox.sendPort});
  sherpa.OfflineTts? tts;
  inbox.listen((msg) {
    final m = msg as Map;
    final id = m['id'] as int;
    switch (m['cmd'] as String) {
      case 'init':
        try {
          tts?.free();
          tts = null;
          final dir = setup.modelDir;
          final lang = m['lang'] as String;
          // Phonemization fix (2026-11-05): sherpa-onnx passes `lang` straight
          // to espeak-ng as the voice name. 'en' = British RP (non-rhotic),
          // which made every English voice drop the R ("Lord" -> "lawd").
          // 'en-us' = American (rhotic). Spanish ('es') unchanged.
          tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
            model: sherpa.OfflineTtsModelConfig(
              kokoro: sherpa.OfflineTtsKokoroModelConfig(
                model: '$dir/model.int8.onnx',
                voices: '$dir/voices.bin',
                tokens: '$dir/tokens.txt',
                dataDir: '$dir/espeak-ng-data',
                lang: lang == 'en' ? 'en-us' : lang,
              ),
              numThreads: 2,
              debug: false,
              provider: 'cpu',
            ),
          ));
          setup.toMain.send({
            'type': 'ack',
            'id': id,
            'ok': true,
            'rate': tts!.sampleRate,
          });
        } catch (e) {
          tts = null;
          setup.toMain.send({
            'type': 'ack',
            'id': id,
            'ok': false,
            'error': e.toString(),
          });
        }
      case 'gen':
        try {
          final text = m['text'] as String;
          final sid = m['sid'] as int;
          final speed = (m['speed'] as num).toDouble();
          final blendSid = m['blendSid'] as int?;
          final blendRatio = (m['blendRatio'] as num?)?.toDouble() ?? 1.0;
          final audio = tts!.generate(text: text, sid: sid, speed: speed);
          var samples = audio.samples;
          // Synthesis-level voice blend: render the same text with the
          // partner sid under the same engine phonemization, then PCM-mix
          // at the slot's ratio. The mixed buffer's length (the longer
          // render) is the audio the schedule times against.
          if (blendSid != null &&
              blendSid != sid &&
              blendRatio > 0.0 &&
              blendRatio < 1.0) {
            final partner =
                tts!.generate(text: text, sid: blendSid, speed: speed);
            if (partner.samples.isNotEmpty &&
                partner.sampleRate == audio.sampleRate) {
              samples = mixKokoroBlend(
                Float32List.fromList(audio.samples),
                Float32List.fromList(partner.samples),
                blendRatio,
              );
            }
          }
          setup.toMain.send({
            'type': 'ack',
            'id': id,
            'ok': true,
            'samples': samples,
            'rate': audio.sampleRate,
          });
        } catch (e) {
          setup.toMain.send({
            'type': 'ack',
            'id': id,
            'ok': false,
            'error': e.toString(),
          });
        }
    }
  });
}

/// Encodes mono float PCM samples as a 16-bit WAV byte buffer.
Uint8List encodeWav16(Float32List samples, int sampleRate) {
  final dataLen = samples.length * 2;
  final pcm = ByteData(dataLen);
  for (var i = 0; i < samples.length; i++) {
    var v = samples[i];
    if (v > 1.0) v = 1.0;
    if (v < -1.0) v = -1.0;
    pcm.setInt16(i * 2, (v * 32767).round(), Endian.little);
  }
  final header = ByteData(44);
  void str(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  header.setUint32(4, 36 + dataLen, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // fmt chunk size
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little); // block align
  header.setUint16(34, 16, Endian.little); // bits per sample
  str(36, 'data');
  header.setUint32(40, dataLen, Endian.little);
  final out = Uint8List(44 + dataLen);
  out.setAll(0, header.buffer.asUint8List());
  out.setAll(44, pcm.buffer.asUint8List());
  return out;
}