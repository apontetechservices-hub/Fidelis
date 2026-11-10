import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'tts_text.dart';

export 'tts_text.dart' show KokoroVoice;

/// One synthesized sentence: raw PCM samples + sample rate, plus the
/// slot-blend execution record (the owner's proof that the directed blend
/// actually rendered: blended=true and the mixed length is the LONGER of
/// the two renders).
class KokoroAudio {
  final Float32List samples;
  final int sampleRate;

  /// True when the slot's blend partner rendered and the PCM mix executed.
  final bool blended;

  /// The primary render's sample count (the solo extent).
  final int primarySamples;

  /// The blend partner render's sample count; null without a blend.
  final int? partnerSamples;

  const KokoroAudio(this.samples, this.sampleRate,
      {this.blended = false, this.primarySamples = 0, this.partnerSamples});
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
  /// 2026-11-10: bumped with the asset-preparation fix so every device wipes
  /// whatever partial state earlier builds left and re-copies cleanly.
  static const _stamp = 'kokoro-int8-v1.0-2026-11-10';

  /// Sticky: any hard failure disables Kokoro for the rest of the session and
  /// callers fall back to flutter_tts (audio must never break).
  static bool _failed = false;
  static Future<bool>? _prepFuture;
  static String? _modelDirPath;

  /// The last failure text (why Kokoro is unavailable this session) — the
  /// diagnostic build surfaces it on screen next to every fallback, so the
  /// ROOT CAUSE is visible, not just the fact of the fallback.
  static String? lastError;

  /// Sink for engine failures (the diagnostic build's on-screen banner).
  /// Null in logging-only setups; main.dart wires it to the AudioDiagnostics
  /// service.
  static void Function(String error)? failureSink;

  static void _recordFailure(String error) {
    lastError = error;
    failureSink?.call(error);
  }

  /// Test hook: force the sticky failure state (the fallback-surfacing
  /// tests drive the flutter_tts fallback without the native engine).
  @visibleForTesting
  static void forceFailedForTest(String error) {
    _failed = true;
    _recordFailure(error);
  }

  /// Test hook: clear all session state (sticky failure, cached prep,
  /// model dir, last error, test seams) so a test can drive preparation
  /// from scratch.
  @visibleForTesting
  static void resetForTest() {
    _failed = false;
    _prepFuture = null;
    _modelDirPath = null;
    _loadedLang = null;
    lastError = null;
    debugPrepDirOverride = null;
    debugAssetLoaderOverride = null;
  }

  /// Test seam: overrides the model directory (production: the app support
  /// directory). Tests point this at an empty temp dir to drive the REAL
  /// preparation path — the same bundle lookups the device performs.
  @visibleForTesting
  static String? debugPrepDirOverride;

  /// Test seam: overrides the asset-byte loader (production: rootBundle.load,
  /// which throws on an asset that is not in the bundle). Tests inject load
  /// failures to prove the recorded error names the exact asset and step.
  @visibleForTesting
  static Future<ByteData> Function(String key)? debugAssetLoaderOverride;

  /// The preparation stamp, for tests that assert the .ready marker.
  @visibleForTesting
  static String get debugStamp => _stamp;

  static Isolate? _isolate;
  static ReceivePort? _responses;
  static ReceivePort? _exitPort;
  static SendPort? _toWorker;
  static Completer<void>? _hello;
  static int _nextId = 0;
  static final Map<int, Completer<Map<Object?, Object?>>> _pending = {};
  static String? _loadedLang;

  /// Copies the bundled model files to the app support directory if needed.
  /// Cheap no-op after a complete preparation (marker + the files the engine
  /// init reads). Safe to call at startup to keep the first listen tap fast.
  static Future<bool> prepareAssets() async {
    if (_failed) return false;
    try {
      _prepFuture ??= _prepare();
      return _prepFuture!;
    } catch (e) {
      _failed = true;
      _recordFailure('asset preparation failed: $e');
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
      if (ack == null) {
        _failed = true;
        _recordFailure('engine init timed out (worker unreachable)');
        _killWorker();
        return false;
      }
      if (ack['ok'] != true) {
        _failed = true;
        _recordFailure('engine init failed: ${ack['error']}');
        _killWorker();
        return false;
      }
      _loadedLang = lang;
      return true;
    } catch (e) {
      _failed = true;
      _recordFailure('engine startup failed: $e');
      _killWorker();
      return false;
    }
  }

  /// Synthesizes [text] with [voice]'s slot config for [lang]: the slot's
  /// sid/speed, and when the slot carries a blend partner for [lang], the
  /// text is rendered by BOTH sids under the same engine phonemization and
  /// the renders are PCM-mixed at the slot's ratio (the mixed length is the
  /// schedule's timing source). The render itself runs in the worker
  /// through the shared [synthesizeSlotSentence] — the one slot-synthesis
  /// path the word-timing verifier also drives. Returns null on failure
  /// (caller falls back to flutter_tts — audio must never break).
  static Future<KokoroAudio?> synthesize(
    String text,
    String lang, {
    KokoroVoice voice = KokoroVoice.standard,
  }) async {
    if (_failed || (lang != 'en' && lang != 'es')) return null;
    if (!await ensureReady(lang)) return null;
    final ack = await _request('gen', {
      'text': text,
      'lang': lang,
      'voice': voice,
    }, timeout: const Duration(minutes: 3));
    if (ack == null) {
      _recordFailure('synthesis request failed (worker unreachable)');
      return null;
    }
    if (ack['ok'] != true) {
      _recordFailure('synthesis failed: ${ack['error']}');
      return null;
    }
    final samples = ack['samples'];
    final rate = ack['rate'];
    if (samples is! Float32List || rate is! int) {
      _recordFailure('synthesis returned no usable samples');
      return null;
    }
    return KokoroAudio(
      samples,
      rate,
      blended: ack['blended'] == true,
      primarySamples: (ack['primarySamples'] as int?) ?? 0,
      partnerSamples: ack['partnerSamples'] as int?,
    );
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
    if (dir == null) {
      _recordFailure('worker spawn failed: model directory not prepared');
      return false;
    }
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
      exit.listen((_) {
        _recordFailure('worker isolate exited unexpectedly');
        _failAll('worker exited');
      });
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
    } catch (e) {
      _recordFailure('worker spawn failed: $e');
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

  /// Files the worker's engine init reads. The fast path re-verifies them so
  /// a lost or partially-cleared directory is re-copied, not trusted.
  static const _criticalFiles = [
    'model.int8.onnx',
    'voices.bin',
    'tokens.txt',
    'espeak-ng-data/phontab',
  ];

  /// True when [dirPath] already holds a complete preparation for [_stamp]:
  /// the marker matches AND every file the engine init reads exists. Anything
  /// else — no marker, an older stamp, a missing file — falls through to a
  /// clean re-copy, because installs over previous builds arrive with
  /// whatever partial or stale state earlier attempts left behind.
  static bool _prepComplete(String dirPath) {
    try {
      final marker = File('$dirPath/.ready');
      if (!marker.existsSync() || marker.readAsStringSync() != _stamp) {
        return false;
      }
      for (final name in _criticalFiles) {
        if (!File('$dirPath/$name').existsSync()) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _prepare() async {
    try {
      final dirPath = debugPrepDirOverride ??
          '${(await getApplicationSupportDirectory()).path}/kokoro';
      _modelDirPath = dirPath;
      if (_prepComplete(dirPath)) return true;
      await _copyAssets(dirPath);
      return true;
    } catch (e) {
      _recordFailure('asset copy failed: $e');
      return false;
    }
  }

  /// Copies every bundled kokoro asset to [dirPath], always from a CLEAN
  /// state: previous content (partial copies from a crashed attempt, stale
  /// files from older builds) is wiped first so a re-copy can never mix old
  /// and new files.
  ///
  /// Runs on the ROOT isolate. The old implementation copied inside
  /// Isolate.run — but rootBundle is unusable on background isolates:
  /// PlatformAssetBundle.load reaches for ServicesBinding.instance, which no
  /// background isolate has (statics are per-isolate, and
  /// BackgroundIsolateBinaryMessenger.ensureInitialized registers the
  /// isolate with the engine without initializing any binding). In release
  /// builds the framework's descriptive assert is stripped and the bare
  /// null-check fires — "Null check operator used on a null value" — which
  /// is exactly what every on-device preparation hit before any file was
  /// copied. Every step here is async and the copy is one-time
  /// (marker-gated), so the UI stays responsive; the only UI-thread cost is
  /// receiving each asset's bytes, the largest being the three ~40 MB model
  /// parts.
  ///
  /// Every failure names the SPECIFIC asset and step (the audio diagnostics
  /// screen shows it verbatim) — never a bare "asset copy failed".
  static Future<void> _copyAssets(String dirPath) async {
    // 1. Wipe whatever a previous attempt left behind.
    try {
      final type = FileSystemEntity.typeSync(dirPath);
      if (type == FileSystemEntityType.directory) {
        await Directory(dirPath).delete(recursive: true);
      } else if (type != FileSystemEntityType.notFound) {
        await File(dirPath).delete(); // a file where the directory belongs
      }
      await Directory(dirPath).create(recursive: true);
    } catch (e) {
      throw _PrepException('clear the stale model directory $dirPath: $e');
    }
    // 2. Enumerate the bundled assets from the manifest — the same bundle
    //    lookup the device exercises (an undeclared subdirectory never
    //    appears here: the October non-recursive-declaration failure class).
    List<String> assets;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      assets = manifest
          .listAssets()
          .where((a) => a.startsWith('$_assetRoot/'))
          .toList()
        ..sort();
    } catch (e) {
      throw _PrepException('read the asset manifest (AssetManifest.bin): $e');
    }
    if (assets.isEmpty) {
      throw _PrepException('no assets under $_assetRoot/ in the bundle '
          'manifest (pubspec.yaml does not declare them)');
    }
    // 3. Copy each asset; any failure names the asset and the step.
    for (final asset in assets) {
      final rel = asset.substring(_assetRoot.length);
      final file = File('$dirPath$rel');
      try {
        await file.parent.create(recursive: true);
      } catch (e) {
        throw _PrepException('create the directory for $asset: $e');
      }
      final ByteData bytes;
      try {
        bytes = await _loadAsset(asset);
      } catch (e) {
        throw _PrepException('$asset is not in the asset bundle: $e');
      }
      try {
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
      } catch (e) {
        throw _PrepException('write $asset to ${file.path}: $e');
      }
    }
    // 4. The model ships as split parts (GitHub's 100 MB file limit);
    //    reassemble and drop the parts to halve the on-device footprint.
    final modelFile = File('$dirPath/model.int8.onnx');
    try {
      if (await modelFile.exists()) await modelFile.delete();
    } catch (e) {
      throw _PrepException('remove a stale model.int8.onnx: $e');
    }
    final parts = Directory(dirPath)
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.uri.pathSegments.last.startsWith('model.int8.onnx.part-'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (parts.isEmpty) {
      throw _PrepException('model.int8.onnx.part-* missing after asset copy '
          '(the model parts are not declared in pubspec.yaml?)');
    }
    try {
      final sink = modelFile.openWrite(mode: FileMode.write);
      for (final part in parts) {
        await sink.addStream(part.openRead());
      }
      await sink.flush();
      await sink.close();
    } catch (e) {
      throw _PrepException(
          'reassemble model.int8.onnx from ${parts.length} parts: $e');
    }
    for (final part in parts) {
      try {
        await part.delete();
      } catch (_) {}
    }
    // 5. Verify the files the engine init reads before declaring readiness.
    for (final name in _criticalFiles) {
      if (!File('$dirPath/$name').existsSync()) {
        throw _PrepException('$name missing after asset copy (not declared '
            'in pubspec.yaml?)');
      }
    }
    // 6. Written last: its presence means the copy is complete, so a crash
    //    mid-copy simply re-copies (from a clean wipe) on the next launch.
    try {
      await File('$dirPath/.ready').writeAsString(_stamp, flush: true);
    } catch (e) {
      throw _PrepException('write the .ready marker: $e');
    }
  }

  /// Loads one asset's bytes (production: rootBundle; tests may inject).
  static Future<ByteData> _loadAsset(String key) {
    final loader = debugAssetLoaderOverride;
    if (loader != null) return loader(key);
    return rootBundle.load(key);
  }

  /// The engine's on-device state for the diagnostics screen: whether the
  /// model assets are prepared (the .ready marker), the model directory,
  /// the bundled voices.bin speaker count (the model metadata the sid
  /// roll-call lists), whether the engine failed this session, and the
  /// last failure text. Reads the copied files when present, else the
  /// bundled asset — the same model metadata either way.
  static Future<KokoroEngineStatus> diagnosticStatus() async {
    final dir = _modelDirPath;
    var prepared = false;
    var sidCount = 0;
    String? readError;
    if (dir != null) {
      try {
        final marker = File('$dir/.ready');
        prepared = marker.existsSync() &&
            marker.readAsStringSync() == _stamp;
        final voices = File('$dir/voices.bin');
        if (voices.existsSync()) {
          sidCount = kokoroSidCount(voices.lengthSync());
        }
      } catch (e) {
        readError = 'model files unreadable: $e';
      }
    }
    if (sidCount == 0) {
      // Not copied yet (or the copy is incomplete): read the bundled
      // asset — the same model metadata.
      try {
        final bytes = await rootBundle.load('$_assetRoot/voices.bin');
        sidCount = kokoroSidCount(bytes.lengthInBytes);
      } catch (e) {
        readError ??= 'voices.bin unavailable: $e';
      }
    }
    return KokoroEngineStatus(
      assetsPrepared: prepared,
      modelDir: dir,
      sidCount: sidCount,
      failedThisSession: _failed,
      lastError: lastError ?? readError,
    );
  }

  /// The bundled model's speaker count from the voices.bin size: each
  /// voice is a 510×256 float32 style tensor — the model metadata the sid
  /// roll-call lists (the same source the relabeled audition used).
  static int kokoroSidCount(int voicesBinBytes) =>
      voicesBinBytes ~/ (510 * 256 * 4);
}

/// A preparation failure carrying its exact asset/step context — the text
/// the audio diagnostics screen shows (never a bare "asset copy failed").
class _PrepException implements Exception {
  final String message;
  const _PrepException(this.message);
  @override
  String toString() => message;
}

/// The Kokoro engine's on-device state (see [KokoroEngine.diagnosticStatus]).
class KokoroEngineStatus {
  /// The model files are copied and the .ready marker matches the stamp.
  final bool assetsPrepared;

  /// The app-support directory holding the copied model (null before the
  /// first prepare attempt).
  final String? modelDir;

  /// Speakers in the bundled voices.bin (the model metadata).
  final int sidCount;

  /// The sticky session failure state (Kokoro is disabled until restart).
  final bool failedThisSession;

  /// The last failure text, when any failure was recorded.
  final String? lastError;

  const KokoroEngineStatus({
    required this.assetsPrepared,
    required this.modelDir,
    required this.sidCount,
    required this.failedThisSession,
    required this.lastError,
  });
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
          final voice = m['voice'] as KokoroVoice;
          final lang = m['lang'] as String;
          // The ONE slot-synthesis path (tts_text.dart): the primary render
          // plus the blend partner render PCM-mixed at the slot's ratio.
          // The word-timing verifier drives this same function; the blend
          // record is the owner's proof that the directed blend rendered.
          final (samples, rate, blended, primarySamples, partnerSamples) =
              synthesizeSlotSentenceDetailed(
            (t, sid, speed) {
              final audio = tts!.generate(text: t, sid: sid, speed: speed);
              return (audio.samples, audio.sampleRate);
            },
            text,
            voice,
            lang,
          );
          setup.toMain.send({
            'type': 'ack',
            'id': id,
            'ok': true,
            'samples': samples,
            'rate': rate,
            'blended': blended,
            'primarySamples': primarySamples,
            'partnerSamples': partnerSamples,
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