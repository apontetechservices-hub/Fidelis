import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/config/app_strings.dart';
import 'package:fidelis/features/rosary/rosary_controller.dart';
import 'package:fidelis/features/rosary/rosary_prayer_screen.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/kokoro_engine.dart';

/// The rosary's RUNTIME-ONLY playback contract: every step of the rosary —
/// both languages, dead-variant personalization included — recites through
/// RUNTIME SYNTHESIS with the directed rosary slot (KokoroVoice.rosary: EN
/// af_aoede; ES af_aoede speaking Spanish — one voice in both languages,
/// blends cancelled), and NO pre-rendered
/// asset ever plays. The bundled files under assets/rosary_audio/ stay
/// dormant on disk, unused: they were rendered with the standard voices
/// (the wrong voices for the directed grid) and their bundled timing
/// predates the current texts, so their timeline drifted from the audio.
/// Recording engine: captures every chunk's language + voice identity and
/// stays pending until stop() (in-flight playback, like the real player).
/// The screen-open prefetch is recorded too (the current step's synthesis
/// starts before Play is pressed).
class RecordingEngine implements AudioEngine {

  /// Set by stop(): the delegate's chunk loop halts (the real
  /// pipeline's epoch checks, mirrored).
  bool _sequenceStopped = false;
  final List<String?> langs = [];
  final List<KokoroVoice?> voices = [];
  final List<String> texts = [];

  /// The screen-open prefetch: the current step's text, language, and
  /// voice, recorded when the prayer screen opens (before any Play).
  final List<String> prefetchTexts = [];
  final List<String?> prefetchLangs = [];
  final List<KokoroVoice?> prefetchVoices = [];
  Completer<void>? _pending;

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
    texts.add(text);
    langs.add(lang);
    voices.add(voice);
    onSentenceStart?.call(0);
    onSentenceTiming?.call(0, text.length, const Duration(seconds: 4));
    _pending = Completer<void>();
    await _pending!.future;
  }

  @override
  Future<void> playAsset(String asset) async {
    fail('an asset must NEVER play: $asset');
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    _pending?.complete();
    _pending = null;
  }

  @override
  bool get isPaused => false;

  @override
  (Duration, Duration?)? get progress =>
      (const Duration(seconds: 1), const Duration(seconds: 4));

  @override
  Future<List<Duration>?> sentenceDurations(String text, String lang,
      {bool Function()? shouldAbort}) async =>
      null;

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
  Future<void> prefetch(String text, String lang, KokoroVoice voice) async {
    prefetchTexts.add(text);
    prefetchLangs.add(lang);
    prefetchVoices.add(voice);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Walks every step of the rosary on [engine]: play, then Next through
  /// the whole sequence (listening mode auto-plays each new step). The
  /// litany consumes Next presses for its invocations, so keep tapping
  /// until the engine sees the next speak call.
  Future<void> walkAllSteps(WidgetTester tester, RecordingEngine engine,
      int stepCount) async {
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    int calls() => engine.texts.length;
    for (var i = 1; i < stepCount; i++) {
      final before = calls();
      for (var tap = 0; tap < 80 && calls() == before; tap++) {
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<RecordingEngine> assertRuntimeOnly(WidgetTester tester,
      String language,
      {bool isForDead = false, String deceasedName = ''}) async {
    final engine = RecordingEngine();
    AudioController.instance.engineForTest = engine;

    await tester.pumpWidget(MaterialApp(
      home: RosaryPrayerScreen(
        mysteryType: 'joyful',
        language: language,
        isForDead: isForDead,
        deceasedName: deceasedName.isEmpty ? null : deceasedName,
      ),
    ));
    await tester.pumpAndSettle();

    // THE SCREEN-OPEN PREFETCH: the CURRENT step's synthesis started
    // before Play — the engine recorded the prefetch with the rosary slot
    // and the screen language, and nothing is playing yet.
    expect(engine.prefetchTexts, isNotEmpty,
        reason: 'the prayer screen prefetches the current step on open');
    expect(engine.prefetchLangs.every((l) => l == language), isTrue);
    for (final v in engine.prefetchVoices) {
      expect(identical(v, KokoroVoice.rosary), isTrue,
          reason: 'the screen-open prefetch uses the rosary slot');
    }
    expect(engine.prefetchTexts.every((t) => t.isNotEmpty), isTrue);

    final steps = RosaryController.buildRosarySteps(
      mysteryTypes: const ['joyful', 'joyful', 'joyful', 'joyful', 'joyful'],
      includeLuminous: false,
      isForDead: isForDead,
    );
    await walkAllSteps(tester, engine, steps.length);

    expect(engine.texts.length, steps.length,
        reason: 'every step recites exactly once');
    expect(engine.langs.every((l) => l == language), isTrue,
        reason: 'every step recites in the screen language');
    for (var i = 0; i < engine.voices.length; i++) {
      expect(identical(engine.voices[i], KokoroVoice.rosary), isTrue,
          reason: 'step $i must recite through the rosary slot '
              '(KokoroVoice.rosary — the directed voices), not the standard '
              'profile and not an asset');
    }
    expect(engine.texts.every((t) => t.isNotEmpty), isTrue,
        reason: 'every step carries its spoken text');
    return engine;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppStrings.setLanguage('en');
  });

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
  });

  testWidgets('EN: every step of the rosary recites through the rosary '
      'slot — no asset ever plays', (tester) async {
    await assertRuntimeOnly(tester, 'en');
  });

  testWidgets('ES: every step recites through the rosary slot (Aoede '
      'speaking Spanish) — no asset ever plays', (tester) async {
    await assertRuntimeOnly(tester, 'es');
  });

  testWidgets('dead variant with a personalized name: runtime synthesis '
      'carries the name — no asset ever plays', (tester) async {
    final engine = await assertRuntimeOnly(tester, 'en',
        isForDead: true, deceasedName: 'Joseph');
    // The personalized text reached the engine (the name substitution only
    // exists in the runtime text).
    expect(engine.texts.any((t) => t.contains('Joseph')), isTrue,
        reason: 'the deceased name flows into the spoken text');
  });
}
