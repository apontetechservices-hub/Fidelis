import 'package:flutter_tts/flutter_tts.dart';
import '../config/app_strings.dart';

/// On-device text-to-speech for prayer audio (free feature).
/// Latin is read through an Italian voice, which approximates
/// ecclesiastical pronunciation well.
///
/// A mature male voice is preferred: known male Google TTS voice
/// codenames are applied per locale when the device actually exposes
/// them, and the pitch is lowered slightly so the active voice reads
/// as mature. When no male voice is available the engine default is
/// kept — selection never throws and never blocks speech.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

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
    try {
      await _tts.stop();
      final language = switch (lang) {
        'la' => 'it-IT',
        'es' => 'es-ES',
        _ => 'en-US',
      };
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

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}