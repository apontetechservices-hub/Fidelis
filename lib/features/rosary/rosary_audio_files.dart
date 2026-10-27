import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'mystery_data.dart';
import 'rosary_controller.dart';

/// Maps rosary steps to the pre-rendered audio bundled under
/// assets/rosary_audio/ (Stage 1 pipeline output: 31 step files × en/es).
///
/// The manifest lists every available (language, step_key) file. Steps without
/// a file for the language — and Dead-variant steps personalized with the
/// deceased's name, whose generic files use plural wording — fall back to
/// runtime TTS at the call site. Audio must never go silent.
class RosaryAudioFiles {
  RosaryAudioFiles._();

  static const _manifestAsset =
      'assets/rosary_audio/rosary_audio_manifest.json';
  static Map<String, dynamic>? _manifest;
  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(_manifestAsset);
      final decoded = jsonDecode(raw);
      _manifest = decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      // Missing/corrupt manifest: every step falls back to runtime TTS.
      _manifest = const {};
    }
  }

  /// Bundled asset path for (stepKey, lang), or null when no pre-rendered
  /// file exists for that combination.
  static Future<String?> assetFor(String stepKey, String lang) async {
    await ensureLoaded();
    final langMap = _manifest?[lang];
    if (langMap is! Map) return null;
    final entry = langMap[stepKey];
    if (entry is! Map) return null;
    final file = entry['file'];
    if (file is! String || file.isEmpty) return null;
    return 'assets/rosary_audio/$file';
  }

  /// Manifest key for a rosary step, or null when the step has no
  /// pre-renderable generic text.
  ///
  /// The shared prayers reuse one file per prayer across all their step
  /// occurrences (3 intro + 50 decade Hail Marys share hail_mary.ogg, the
  /// opening and final Sign of the Cross share sign_of_the_cross.ogg, etc.).
  /// Mystery announcements key on MysteryData.id (e.g. 'joyful_1').
  static String? keyForStep(RosaryStep step, {required String mysteryType}) {
    switch (step.type) {
      case RosaryStepType.signOfTheCross:
      case RosaryStepType.creed:
      case RosaryStepType.ourFather:
      case RosaryStepType.hailMary:
      case RosaryStepType.gloryBe:
      case RosaryStepType.fatimaPrayer:
      case RosaryStepType.hailHolyQueen:
      case RosaryStepType.litany:
      case RosaryStepType.deProfundis:
      case RosaryStepType.eternalRest:
      case RosaryStepType.deadRosaryClosing:
        return step.prayerKey;
      case RosaryStepType.mysteryAnnouncement:
        try {
          return MysteryData.getMysteries(mysteryType)[step.mysteryIndex!].id;
        } catch (_) {
          return null;
        }
      case RosaryStepType.concludingPrayer:
      case RosaryStepType.mysteryMeditation:
        return null;
    }
  }
}