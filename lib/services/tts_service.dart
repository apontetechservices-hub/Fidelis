import 'dart:async';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'kokoro_engine.dart';

/// On-device text-to-speech for prayer audio (free feature).
///
/// Two engines:
///  - Kokoro (sherpa-onnx, bundled on-device): EN bm_george / ES em_alex at
///    speed 0.9, synthesized SENTENCE-BY-SENTENCE so playback starts after the
///    first sentence and later sentences are generated while the current one
///    plays. stop() interrupts cleanly between sentences. Used for 'en'/'es'.
///  - flutter_tts (system engine): Latin ('la' — Italian voice approximates
///    ecclesiastical pronunciation) and the fallback whenever Kokoro is
///    unavailable or fails, so audio NEVER breaks. The mature male-voice
///    selection below is kept intact for that path.
///
/// A mature male voice is preferred on the flutter_tts path: known male Google
/// TTS voice codenames are applied per locale when the device actually exposes
/// them, and the pitch is lowered slightly so the active voice reads as
/// mature. When no male voice is available the engine default is kept —
/// selection never throws and never blocks speech.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _player = AudioPlayer();
  static bool _ready = false;

  /// Incremented by every new playback request and by stop(); an in-flight
  /// Kokoro pipeline aborts as soon as its epoch no longer matches.
  static int _epoch = 0;
  static Completer<void>? _playDone;
  static Directory? _sentenceDir;

  /// Known MALE Google TTS voice names per locale, in preference order.
  /// A candidate is only applied when it appears in the device's voice
  /// list; unmatched codenames are silently skipped so devices without
  /// them keep the engine default voice.
  static const Map<String, List<String>> _maleVoices = {
    'en-US': [
      'en-us-x-iom-local',
      'en-us-x-tpd-local',
      'en-us-x-afd-local',
      'en-us-x-afg-local',
    ],
    'es-ES': [
      'es-es-x-leb-local',
      'es-es-x-leb-network',
    ],
    'it-IT': [
      'it-it-x-lel-local',
      'it-it-x-ccd-local',
    ],
  };

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      // Slightly deeper pitch reads as mature regardless of which voice
      // is active (Android accepts 0.5-2.0).
      try {
        await _tts.setPitch(0.85);
      } catch (_) {}
      _ready = true;
    } catch (_) {}
  }

  /// Copies the bundled Kokoro model files to disk in the background (first
  /// launch only; later launches are a cheap marker check). Fire-and-forget
  /// warmup for app startup — synthesis itself stays lazy.
  static Future<void> warmAssets() async {
    try {
      await KokoroEngine.prepareAssets();
    } catch (_) {}
  }

  /// Returns the first available male voice for [language], or null to
  /// keep the engine default. Falls back to any device voice whose name
  /// carries an explicit gender marker (e.g. '#male_1' on some engines).
  static Future<String?> _maleVoiceFor(String language) async {
    try {
      final dynamic voices = await _tts.getVoices;
      if (voices is! List) return null;
      final names = <String>[];
      for (final v in voices) {
        if (v is Map && v['locale'] == language && v['name'] is String) {
          names.add(v['name'] as String);
        }
      }
      if (names.isEmpty) return null;
      for (final candidate in _maleVoices[language] ?? const <String>[]) {
        if (names.contains(candidate)) return candidate;
      }
      for (final name in names) {
        if (name.toLowerCase().contains('#male')) return name;
      }
    } catch (_) {}
    return null;
  }

  /// lang: 'en' | 'la' | 'es' — maps to a TTS voice.
  /// Latin uses the Italian voice (ecclesiastical pronunciation).
  static Future<void> speakPrayer(String text, {String? lang}) async {
    if (!_ready) await init();
    if (text.isEmpty) return;
    final myEpoch = ++_epoch;
    _finishPlayDone();
    final kokoroLang = (lang == 'en' || lang == 'es') ? lang : null;
    if (kokoroLang != null) {
      if (await _speakWithKokoro(text, kokoroLang, myEpoch)) return;
    }
    await _speakWithFlutterTts(text, _localeFor(lang));
  }

  /// Plays a bundled audio file (rosary pre-rendered OGG). Completes when
  /// playback finishes or stop() is called; never throws.
  static Future<void> playAssetFile(String assetPath) async {
    if (!_ready) await init();
    final myEpoch = ++_epoch;
    _finishPlayDone();
    try {
      await _playSource(AudioSource.asset(assetPath), myEpoch);
    } catch (_) {}
  }

  static Future<void> stop() async {
    _epoch++;
    _finishPlayDone();
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static String _localeFor(String? lang) => switch (lang) {
        'la' => 'it-IT',
        'es' => 'es-ES',
        _ => 'en-US',
      };

  // ---- Kokoro pipeline (en/es) ----

  /// Returns true when the text was delivered (fully by Kokoro, or partially
  /// with the remainder handed to flutter_tts after a mid-pipeline failure).
  /// Returns false only when Kokoro could not start at all, so the caller
  /// falls back to flutter_tts for the whole text.
  static Future<bool> _speakWithKokoro(
    String text,
    String lang,
    int myEpoch,
  ) async {
    try {
      if (!await KokoroEngine.ensureReady(lang)) return false;
      if (myEpoch != _epoch) return true; // stopped while the engine warmed up
      final sentences = _splitSentences(text);
      if (sentences.isEmpty) return false;

      // Synthesize sentence 1 first so playback starts fast; later sentences
      // are generated while the current one plays.
      var prefetch = KokoroEngine.synthesize(sentences[0], lang);
      for (var i = 0; i < sentences.length; i++) {
        final audio = await prefetch;
        if (myEpoch != _epoch) return true; // stop() while generating
        if (audio == null || audio.samples.isEmpty) {
          // Kokoro failed mid-pipeline: hand the remainder to flutter_tts so
          // the audio continues without a content gap.
          final rest = sentences.skip(i).join(' ');
          if (rest.isNotEmpty) await _speakWithFlutterTts(rest, _localeFor(lang));
          return true;
        }
        prefetch = i + 1 < sentences.length
            ? KokoroEngine.synthesize(sentences[i + 1], lang)
            : Future<KokoroAudio?>.value(null);
        await _playPcm(audio, myEpoch);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Writes one sentence as a WAV file in the cache dir and plays it.
  static Future<void> _playPcm(KokoroAudio audio, int myEpoch) async {
    final file = await _sentenceWavFile();
    await file.writeAsBytes(
      encodeWav16(audio.samples, audio.sampleRate),
      flush: true,
    );
    try {
      await _playSource(AudioSource.file(file.path), myEpoch);
    } finally {
      // Safe even while the player still holds it open (POSIX unlink).
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static Future<File> _sentenceWavFile() async {
    final dir = _sentenceDir ??=
        Directory('${(await getTemporaryDirectory()).path}/kokoro_sentences');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File(
        '${dir.path}/s_${DateTime.now().microsecondsSinceEpoch}.wav');
  }

  /// Splits text into speakable sentences: sentence-ending punctuation and
  /// paragraph/line breaks are boundaries; very short fragments (V., R., St.)
  /// merge into what follows so markers are not spoken alone; overly long
  /// sentences are split at clause punctuation to bound per-sentence latency.
  static List<String> _splitSentences(String text) {
    final raw = text
        .split(RegExp(r'(?<=[.!?…])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    // Merge tiny fragments (liturgical markers, abbreviations) forward.
    final merged = <String>[];
    for (final part in raw) {
      if (merged.isNotEmpty && merged.last.length <= 3) {
        merged[merged.length - 1] = '${merged.last} $part';
      } else {
        merged.add(part);
      }
    }
    // Bound per-sentence synthesis latency on slow devices.
    const maxLen = 280;
    final bounded = <String>[];
    for (final sentence in merged) {
      var rest = sentence;
      while (rest.length > maxLen) {
        var cut = -1;
        for (final pat in const [', ', '; ', ',']) {
          final idx = rest.lastIndexOf(pat, maxLen);
          if (idx > 40) {
            cut = idx + pat.length;
            break;
          }
        }
        if (cut <= 0) {
          cut = rest.lastIndexOf(' ', maxLen);
          if (cut <= 0) cut = maxLen;
        }
        bounded.add(rest.substring(0, cut).trim());
        rest = rest.substring(cut).trim();
      }
      if (rest.isNotEmpty) bounded.add(rest);
    }
    return bounded;
  }

  // ---- playback plumbing (shared by Kokoro WAVs and bundled files) ----

  static Future<void> _playSource(AudioSource source, int myEpoch) async {
    _finishPlayDone();
    final done = Completer<void>();
    _playDone = done;
    await _player.setAudioSource(source);
    if (myEpoch != _epoch) {
      _finishPlayDone();
      return;
    }
    await _player.play();
    late final StreamSubscription<PlayerState> sub;
    sub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) _finishPlayDone();
    });
    try {
      await done.future;
    } finally {
      sub.cancel();
      if (identical(_playDone, done)) _playDone = null;
    }
  }

  static void _finishPlayDone() {
    final done = _playDone;
    _playDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  // ---- flutter_tts path (Latin + fallback) — kept intact ----

  static Future<void> _speakWithFlutterTts(String text, String language) async {
    try {
      await _tts.stop();
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(0.42);
      // setLanguage resets the voice on Android, so the male voice is
      // applied after it; on failure the default voice simply remains.
      final male = await _maleVoiceFor(language);
      if (male != null) {
        try {
          await _tts.setVoice({'name': male, 'locale': language});
        } catch (_) {}
      }
      await _tts.speak(text);
    } catch (_) {}
  }
}