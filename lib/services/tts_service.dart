import 'package:flutter_tts/flutter_tts.dart';
import '../config/app_strings.dart';

/// On-device text-to-speech for prayer audio (free feature).
/// Latin is read through an Italian voice, which approximates
/// ecclesiastical pronunciation well.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (_) {}
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
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}