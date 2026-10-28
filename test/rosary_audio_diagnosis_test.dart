// DIAGNOSIS TESTS (no fixes) — rosary audio defects reported on build 1.4.65.
//
// Reproduces the SHIPPED bundle state inside the test environment: the
// pubspec declares `assets/rosary_audio/` as a directory, and Flutter asset
// directory declarations are NON-RECURSIVE — only files directly in the
// directory are bundled. The manifest (a direct file) ships; the en/ and
// es/ subdirectory .ogg files do NOT. The test asset bundle is built with
// the same flutter_tools rules, so the tests below run against exactly the
// state the device sees: manifest loadable, every .ogg missing.
//
// Problems under diagnosis:
//   P2: audio stops after the first couple of prayers.
//   P1: highlighted words lag behind the audio.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/config/app_strings.dart';
import 'package:fidelis/features/rosary/rosary_audio_files.dart';
import 'package:fidelis/features/rosary/rosary_controller.dart';
import 'package:fidelis/features/rosary/rosary_prayer_screen.dart';
import 'package:fidelis/services/audio_controller.dart';

/// Device-faithful engine for the shipped-bundle state:
///  - playAsset: the real TtsService.playAssetFile catches just_audio's
///    PlayerException for a missing bundled asset and returns NORMALLY
///    (instantly, no audio). We mirror that: record + complete immediately.
///  - speakText: records; the runtime path would speak here.
///  - sentenceDurations: the device's Kokoro cannot synthesize (the APK
///    bundles no espeak-ng-data, so phonemization data is missing), and
///    synthesizeSentenceDurations returns null on any Kokoro failure —
///    mirror that with null (no per-sentence timeline can ever resolve).
class DeviceFaithfulEngine implements AudioEngine {
  final List<String> log = [];
  final List<String?> speakLangs = [];

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    log.add('speak[$lang]:${text.length}ch:${text.substring(0, text.length > 40 ? 40 : text.length)}');
    speakLangs.add(lang);
    onSentenceStart?.call(0);
  }

  @override
  Future<void> playAsset(String asset) async {
    log.add('asset:$asset');
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  bool get isPaused => false;

  @override
  (Duration, Duration?)? get progress => null;

  @override
  Future<List<Duration>?> sentenceDurations(String text, String lang,
      {bool Function()? shouldAbort}) async {
    log.add('sentenceDurations[$lang]:${text.length}ch');
    return null; // device: Kokoro unavailable (no espeak-ng-data in APK)
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RosaryAudioFiles.resetForTest();
    await AppStrings.setLanguage('en');
  });

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
  });

  testWidgets('DIAG P2-A: shipped bundle state — manifest loads, ogg missing',
      (tester) async {
    await tester.runAsync(() async {
      // The manifest IS bundled (a file directly inside the declared dir).
      final raw = await rootBundle
          .loadString('assets/rosary_audio/rosary_audio_manifest.json');
      expect(raw, contains('hail_mary'),
          reason: 'the manifest ships in the APK');

      // The .ogg files are NOT bundled: they live in en/ and es/
      // SUBDIRECTORIES of the declared directory, and Flutter asset
      // directory declarations are non-recursive. This is exactly the
      // device state (verified in fidelis-latest.apk: 0 .ogg entries).
      var oggLoaded = false;
      try {
        await rootBundle.load('assets/rosary_audio/en/hail_mary.ogg');
        oggLoaded = true;
      } catch (_) {}
      expect(oggLoaded, isFalse,
          reason: 'subdirectory .ogg files are not in the bundle — '
              'same as the shipped APK');
      var esLoaded = false;
      try {
        await rootBundle.load('assets/rosary_audio/es/hail_mary.ogg');
        esLoaded = true;
      } catch (_) {}
      expect(esLoaded, isFalse);
    });
  });

  testWidgets('DIAG P2-B: full rosary run — every keyed step is a silent '
      'asset failure; the runtime-TTS fallback NEVER fires', (tester) async {
    await tester.runAsync(() => RosaryAudioFiles.ensureLoaded());
    final engine = DeviceFaithfulEngine();
    AudioController.instance.engineForTest = engine;

    await tester.pumpWidget(const MaterialApp(
      home: RosaryPrayerScreen(mysteryType: 'joyful', language: 'en'),
    ));
    await tester.pumpAndSettle();

    final steps = RosaryController.buildRosarySteps(
      mysteryTypes: const ['joyful', 'joyful', 'joyful', 'joyful', 'joyful'],
      includeLuminous: false,
      isForDead: false,
    );

    // Walk the whole rosary: play the first step, then Next through every
    // step (listening mode auto-plays each new step). The litany step
    // consumes Next presses for its invocations (61+) before advancing,
    // so keep tapping until the engine sees the next asset attempt.
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    int engineCalls() => engine.log.length;
    for (var i = 1; i < steps.length; i++) {
      final before = engineCalls();
      for (var tap = 0; tap < 70 && engineCalls() == before; tap++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    // Let the last step's async asset-resolution chain reach the engine.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final assetAttempts = engine.log.where((e) => e.startsWith('asset:')).length;
    final speakAttempts = engine.log.where((e) => e.startsWith('speak')).length;
    // ignore: avoid_print
    print('DIAG P2-B totals: assetAttempts=$assetAttempts '
        'speakAttempts=$speakAttempts of ${steps.length} steps');

    // THE FINDING: every step attempts the (missing) asset; the runtime
    // path is never reached — no step speaks. The rosary is silent for its
    // whole run, and the "runtime-TTS fallback" cannot cover asset chunks.
    expect(assetAttempts, steps.length,
        reason: 'every keyed step resolves a manifest path and attempts '
            'the missing asset');
    expect(speakAttempts, 0,
        reason: 'AudioController.start has NO runtime-TTS fallback for '
            'asset chunks (audio_controller.dart asset branch) — a failed '
            'playAsset completes the chunk in silence');
  });

  testWidgets('DIAG P2-C: when the manifest lookup yields nothing, every '
      'step reaches runtime TTS — including announcements and the litany',
      (tester) async {
    // Simulate the "no manifest entry" branch through the SAME code path a
    // manifest-load failure takes: language 'la' has no manifest section,
    // so assetFor returns null for EVERY step and each one becomes a text
    // chunk spoken by the runtime path. (A device manifest-load failure
    // lands in the identical branch — assetFor null → text chunk.)
    // Warm the manifest first: a load started inside the test's FakeAsync
    // zone never completes (its microtask lands on the zone's own queue).
    await tester.runAsync(() => RosaryAudioFiles.ensureLoaded());
    final engine = DeviceFaithfulEngine();
    AudioController.instance.engineForTest = engine;

    await tester.pumpWidget(const MaterialApp(
      home: RosaryPrayerScreen(mysteryType: 'joyful', language: 'la'),
    ));
    await tester.pumpAndSettle();

    final steps = RosaryController.buildRosarySteps(
      mysteryTypes: const ['joyful', 'joyful', 'joyful', 'joyful', 'joyful'],
      includeLuminous: false,
      isForDead: false,
    );

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    int engineCalls() => engine.log.length;
    for (var i = 1; i < steps.length; i++) {
      final before = engineCalls();
      for (var tap = 0; tap < 70 && engineCalls() == before; tap++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // ignore: avoid_print
    print('DIAG P2-C engine log (no-manifest-entry simulation, first 12):');
    for (final e in engine.log.take(12)) {
      // ignore: avoid_print
      print('  $e');
    }

    // Every step speaks through the runtime path — the announcement and
    // litany texts ARE composed (_fallbackSpeechText), so candidate (c)
    // "the runtime path lacks announcement/litany text" is ruled out.
    expect(engine.log.where((e) => e.startsWith('speak')).length, steps.length,
        reason: 'with no manifest, every step becomes a text chunk and the '
            'runtime path speaks it — announcements and litany included');
  });

  testWidgets('DIAG P1-A: a failed asset chunk publishes NO word range — '
      'the highlight cannot track audio that never plays', (tester) async {
    await tester.runAsync(() => RosaryAudioFiles.ensureLoaded());
    final engine = DeviceFaithfulEngine();
    AudioController.instance.engineForTest = engine;

    await tester.pumpWidget(const MaterialApp(
      home: RosaryPrayerScreen(mysteryType: 'joyful', language: 'en'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 250));

    // The word tick runs every 200ms while "playing"; with the asset failed
    // the player has no source (position 0, duration null) and no timeline
    // can resolve (sentenceDurations returns null on device) — no word
    // range is ever published.
    // ignore: avoid_print
    print('DIAG P1-A wordRange after failed-asset step: '
        '${AudioController.instance.wordRangeListenable.value}');
    expect(AudioController.instance.wordRangeListenable.value, isNull,
        reason: 'no timing source exists for a failed asset chunk: the '
            'timeline needs sentenceDurations (null on device) and the '
            'coarse fallback needs a non-null total duration');
  });
}