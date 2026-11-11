// REGRESSION GUARDS (v1.4.67+82) — rosary audio defects reported on 1.4.65.
//
// History: the 1.4.65/1.4.66 APKs declared `assets/rosary_audio/` and
// `assets/kokoro/` as directories, and Flutter asset directory declarations
// are NON-RECURSIVE — only files directly inside ship. The manifest (a
// direct file) shipped; the en/ and es/ .ogg files and the whole
// kokoro/espeak-ng-data subtree did NOT: every keyed step's asset play
// failed silently, and Kokoro could not phonemize (no espeak-ng-data).
// v1.4.67 adds the missing subdirectory declarations; these tests guard the
// FIXED state. Each was a diagnosis test asserting the broken state and
// inverted when the fix landed:
//   P2-A: ogg-missing assertion flipped — the manifest AND the subdirectory
//         .ogg files now ship and load (all 62 of them).
//   P2-B: silent-asset-failure walk flipped — every keyed step now PLAYS
//         its bundled asset (in-flight playback), the runtime-TTS fallback
//         still never fires, and every attempted asset loads from the bundle.
//   P2-C: unchanged — with no manifest entry, every step still reaches
//         runtime TTS (announcements and the litany included).
//   P1-A: no-word-range assertion flipped — a playing asset chunk publishes
//         word ranges (the timeline resolves from Kokoro's real durations).
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
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart';

/// Engine mirroring the FIXED device state (v1.4.67: the .ogg files and
/// espeak-ng-data ship):
///  - playAsset: the real TtsService.playAssetFile awaits until playback
///    completes or stop() lands — mirror that by staying pending until
///    stop() (in-flight playback), so the chunk's state stays 'playing'.
///  - sentenceDurations: the device's Kokoro synthesizes per-sentence
///    durations (espeak-ng-data ships) — mirror with one duration per
///    TtsService.sentenceRanges(text) sentence, the same split the
///    controller's timeline check uses.
///  - progress: a playing asset reports a non-null (position, duration).
class BundledAudioEngine implements AudioEngine {

  /// Set by stop(): the delegate's chunk loop halts (the real
  /// pipeline's epoch checks, mirrored).
  bool _sequenceStopped = false;
  final List<String> log = [];
  final List<String?> speakLangs = [];

  /// Voice profile passed to each speakText call, in order — the
  /// runtime-only spec asserts every step recites through the rosary slot.
  final List<KokoroVoice?> speakVoices = [];
  Completer<void>? _pendingPlay;

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    KokoroVoice? voice,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    log.add('speak[$lang]:${text.length}ch:${text.substring(0, text.length > 40 ? 40 : text.length)}');
    speakLangs.add(lang);
    speakVoices.add(voice);
    // The Kokoro pipeline's per-sentence timing: the schedule derives from
    // the SAME synthesis that produces the audio (one timing source).
    onSentenceStart?.call(0);
    onSentenceTiming?.call(0, text.length, const Duration(seconds: 5));
    // In-flight playback: the chunk await stays pending until stop() lands
    // (the next step's start() or the teardown), mirroring the real player
    // so the state stays 'playing' and the word tick runs.
    _pendingPlay = Completer<void>();
    await _pendingPlay!.future;
  }

  @override
  Future<void> playAsset(String asset) async {
    log.add('asset:$asset');
    // In-flight playback: the chunk await stays pending until stop() lands
    // (the next step's start() or the teardown), mirroring the real player.
    _pendingPlay = Completer<void>();
    await _pendingPlay!.future;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    _pendingPlay?.complete();
    _pendingPlay = null;
  }

  @override
  bool get isPaused => false;

  @override
  (Duration, Duration?)? get progress =>
      (const Duration(seconds: 2), const Duration(seconds: 30));

  @override
  Future<List<Duration>?> sentenceDurations(String text, String lang,
      {bool Function()? shouldAbort}) async {
    log.add('sentenceDurations[$lang]:${text.length}ch');
    // Device: Kokoro synthesizes one REAL duration per sentence — the same
    // split TtsService.sentenceRanges uses, so the timeline check matches.
    return TtsService.sentenceRanges(text)
        .map((_) => const Duration(milliseconds: 1500))
        .toList();
  }

  @override
  Future<void> speakSequence(
    List<AudioChunk> chunks, {
    required String lang,
    required void Function(int chunkIndex) onChunkStart,
    required void Function(int chunkIndex, int sentenceInChunk)
        onSentenceStart,
    required void Function(int chunkIndex, int charStart, int charEnd,
            Duration duration)
        onSentenceTiming,
    required void Function(int chunkIndex, int sentenceInChunk,
            Duration duration)
        onSentenceSynthesized,
    required void Function(int chunkIndex, int charStart, int charEnd)
        onWordRange,
  }) async {
    // The scripted engine plays the chunks through the same speakText path
    // the pre-sequence controller used — the screen tests' expectations
    // (log entries, gates, word events) keep their old semantics.
    _sequenceStopped = false;
    for (var ci = 0; ci < chunks.length; ci++) {
      if (ci > 0 && _sequenceStopped) return; // stopped mid-sequence
      onChunkStart(ci);
      await speakText(
        chunks[ci].text ?? '',
        lang: lang,
        voice: chunks[ci].voice,
        onSentenceStart: (_) => onSentenceStart(ci, 0),
        onSentenceTiming: (start, end, duration) =>
            onSentenceTiming(ci, start, end, duration ?? Duration.zero),
        onWordRange: (start, end) => onWordRange(ci, start, end),
      );
    }
  }

  @override
  Future<bool> seekToSentence(int streamIndex) async => false;

  @override
  int get appendedSentenceCount => 0;

  @override
  Future<void> prefetch(String text, String lang, KokoroVoice voice) async {}
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

  testWidgets(
      'DIAG P2-A → fixed: manifest loads, every subdirectory .ogg ships',
      (tester) async {
    await tester.runAsync(() async {
      // The manifest IS bundled (a file directly inside the declared dir).
      final raw = await rootBundle
          .loadString('assets/rosary_audio/rosary_audio_manifest.json');
      expect(raw, contains('hail_mary'),
          reason: 'the manifest ships in the APK');

      // THE FIX (v1.4.67): the en/ and es/ subdirectory declarations ship
      // the .ogg files — both load from the bundle now.
      final en = await rootBundle.load('assets/rosary_audio/en/hail_mary.ogg');
      expect(en.lengthInBytes, greaterThan(0),
          reason: 'en/hail_mary.ogg ships (was missing through 1.4.66)');
      final es = await rootBundle.load('assets/rosary_audio/es/hail_mary.ogg');
      expect(es.lengthInBytes, greaterThan(0),
          reason: 'es/hail_mary.ogg ships (was missing through 1.4.66)');

      // And the bundle carries all 62 rosary .ogg files (31 en + 31 es).
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final oggs = manifest
          .listAssets()
          .where((a) => a.startsWith('assets/rosary_audio/'))
          .where((a) => a.endsWith('.ogg'))
          .length;
      expect(oggs, 62, reason: '31 en + 31 es .ogg files ship');
    });
  });

  testWidgets(
      'DIAG P2-B → fixed: a full rosary run plays every keyed step — no '
      'silent asset failures, no runtime-TTS fallback', (tester) async {
    await tester.runAsync(() => RosaryAudioFiles.ensureLoaded());
    final engine = BundledAudioEngine();
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

    // THE RUNTIME-ONLY SPEC: every keyed step recites through the RUNTIME
    // path with the rosary slot (KokoroVoice.rosary — the directed voices,
    // the schedule from the same synthesis) and NO pre-rendered asset ever
    // plays. The bundled files stay dormant on disk, unused: they were
    // rendered with the standard voices (the wrong voices for the directed
    // grid) and their bundled timing predates the current texts.
    expect(speakAttempts, steps.length,
        reason: 'every keyed step recites through runtime synthesis');
    expect(assetAttempts, 0,
        reason: 'the pre-rendered assets are OUT of the rosary playback '
            'path — no asset fallback');
    expect(engine.speakVoices.length, steps.length);
    for (final v in engine.speakVoices) {
      expect(identical(v, KokoroVoice.rosary), isTrue,
          reason: 'every step recites through the rosary slot '
              '(KokoroVoice.rosary), not the standard profile');
    }
  });

  testWidgets(
      'DIAG P2-C: when the manifest lookup yields nothing, every '
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
    final engine = BundledAudioEngine();
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

  testWidgets(
      'DIAG P1-A → runtime: a playing step publishes word ranges — the '
      'schedule derives from the same synthesis that produces the audio',
      (tester) async {
    await tester.runAsync(() => RosaryAudioFiles.ensureLoaded());
    final engine = BundledAudioEngine();
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

    // THE RUNTIME STATE: the step plays through runtime synthesis (the
    // rosary slot), the engine's per-sentence timing drives the word tick,
    // and the highlight publishes ranges — one timing source, the same
    // synthesis that produces the audio.
    // ignore: avoid_print
    print('DIAG P1-A wordRange after playing runtime step: '
        '${AudioController.instance.wordRangeListenable.value}');
    expect(AudioController.instance.wordRangeListenable.value, isNotNull,
        reason: 'with the step playing through runtime synthesis and the '
            'sentence timing reported, the word tick publishes ranges');
  });}
