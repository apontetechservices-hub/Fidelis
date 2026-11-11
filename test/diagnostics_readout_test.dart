import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/features/diagnostics/playback_readout.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/audio_diagnostics.dart';
import 'package:fidelis/services/kokoro_engine.dart';

/// THE ON-SCREEN READOUT: the AudioDiagnostics service parses the TTS
/// pipeline's readout lines into the structured state (slot config, engine,
/// fallback, error), and the PlaybackReadout widget renders that state plus
/// the live numeric duration/position — the diagnostic build's evidence
/// surface, in the app UI, not logs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioDiagnostics.instance.clear();
  });

  group('the diagnostics state parsing', () {
    test('a playback-start line records the requested slot config and '
        'clears a previous fallback', () {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] FALLBACK engine=flutter_tts (system '
          'voice) reason=kokoro unavailable for en — Kokoro failed: x');
      expect(d.fallbackLine, isNotNull);
      d.recordLine('[Fidelis audio] playback slot=bible lang=en '
          'voice=am_michael(16) speed=0.81 '
          'eq=bands{0:-4.0dB,1:-2.0dB} lexicon=2');
      expect(d.slotReadout,
          'playback slot=bible lang=en voice=am_michael(16) '
          'speed=0.81 eq=bands{0:-4.0dB,1:-2.0dB} lexicon=2');
      expect(d.fallbackLine, isNull,
          reason: 'a new playback start resets the banner');
      expect(d.engineUsed, isNull, reason: 'the engine outcome is pending');
    });

    test('the transport prefix is stripped from stored lines', () {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] engine=kokoro (the slot config above '
          'executed)');
      expect(d.lines.single, 'engine=kokoro (the slot config above executed)');
      expect(d.engineUsed, 'kokoro');
    });

    test('a fallback line records the system-voice outcome', () {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] playback slot=rosary lang=es '
          'voice=af_aoede(1) speed=0.90 eq=flat lexicon=0');
      d.recordLine('[Fidelis audio] FALLBACK engine=flutter_tts (system '
          'voice) reason=kokoro unavailable for es — Kokoro failed: engine '
          'init failed: boom');
      expect(d.engineUsed, 'flutter_tts');
      expect(d.fallbackLine, contains('FALLBACK engine=flutter_tts'));
      expect(d.fallbackLine, contains('Kokoro failed: engine init failed: '
          'boom'));
    });

    test('engine=kokoro after a mid-pipeline fallback keeps the banner', () {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] playback slot=bible lang=en '
          'voice=am_michael(16) speed=0.81 eq=flat lexicon=2');
      d.recordLine('[Fidelis audio] FALLBACK mid-pipeline engine=flutter_tts '
          '(system voice) reason=sentence 3/12 synthesis failed — Kokoro '
          'failed: synthesis failed: boom');
      d.recordLine('[Fidelis audio] engine=kokoro (the slot config above '
          'executed)');
      // The audio was PARTLY system-voice: the banner stays for the whole
      // playback and the engine outcome stays the fallback.
      expect(d.fallbackLine, contains('mid-pipeline'));
      expect(d.engineUsed, 'flutter_tts');
    });

    test('a Kokoro failure records the sticky root cause', () {
      final d = AudioDiagnostics.instance;
      d.recordKokoroError('engine init failed: Failed to set eSpeak-ng '
          'voice');
      expect(d.kokoroError, contains('Failed to set eSpeak-ng voice'));
    });

    test('state transitions append, dedupe, and bound', () {
      final d = AudioDiagnostics.instance;
      for (var i = 0; i < 70; i++) {
        d.recordState('state=playing job=bible chunk=$i sentence=0');
      }
      // The log is bounded at the service's cap.
      expect(d.stateLog.length, 60);
      // Consecutive duplicates collapse.
      final before = d.stateLog.length;
      d.recordState('state=playing job=bible chunk=69 sentence=0');
      expect(d.stateLog.length, before);
      // The oldest entries dropped: the first remaining is chunk 10.
      expect(d.stateLog.first, 'state=playing job=bible chunk=10 sentence=0');
      expect(d.stateLog.last, 'state=playing job=bible chunk=69 sentence=0');
    });
  });

  group('the PlaybackReadout widget', () {
    testWidgets('renders the slot config, the engine outcome, the fallback '
        'banner, and the root cause', (tester) async {
      final d = AudioDiagnostics.instance;
      d.recordKokoroError('engine init failed: boom');
      d.recordLine('[Fidelis audio] playback slot=bible lang=en '
          'voice=am_michael(16) speed=0.81 '
          'eq=bands{0:-4.0dB,1:-2.0dB} lexicon=2');
      d.recordLine('[Fidelis audio] FALLBACK engine=flutter_tts (system '
          'voice) reason=kokoro unavailable for en — Kokoro failed: engine '
          'init failed: boom');
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PlaybackReadout()),
      ));
      await tester.pumpAndSettle();

      // The requested slot config.
      expect(find.textContaining('slot: playback slot=bible'), findsOneWidget);
      expect(find.textContaining('am_michael(16)'), findsOneWidget);
      // The engine outcome: the SYSTEM voice served this playback.
      expect(find.textContaining('engine: flutter_tts'), findsOneWidget);
      // The prominent fallback banner with the root cause inline.
      expect(find.textContaining('FALLBACK: flutter_tts (system voice)'),
          findsOneWidget);
      expect(find.textContaining('Kokoro failed: engine init failed: boom'),
          findsWidgets);
      // The sticky Kokoro error row.
      expect(find.textContaining('kokoro error: engine init failed: boom'),
          findsOneWidget);
      // No progress published: the readout says so explicitly (the
      // flutter_tts path exposes no timing — the frozen-bar finding).
      expect(find.textContaining('no timing'), findsOneWidget);
      // The controller state row.
      expect(find.textContaining('state: stopped'), findsOneWidget);
    });

    testWidgets('shows no banner while Kokoro served the audio',
        (tester) async {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] playback slot=rosary lang=en '
          'voice=af_aoede(1) speed=0.90 eq=flat lexicon=1');
      d.recordLine('[Fidelis audio] engine=kokoro (the slot config above '
          'executed)');
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PlaybackReadout()),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('engine: kokoro'), findsOneWidget);
      expect(find.textContaining('FALLBACK'), findsNothing);
      expect(find.textContaining('kokoro error'), findsNothing);
    });

    testWidgets('shows numeric duration and position while playing',
        (tester) async {
      final controller = AudioController.instance;
      final fake = _ProgressEngine();
      controller.engineForTest = fake;
      unawaited(controller.start(const AudioJob(
        id: 'readout-progress',
        chunks: [AudioChunk(text: 'The Lord is my shepherd.', lang: 'en')],
      )));
      await tester.pump(); // the job loop starts (the fake gates the chunk)
      await tester.pump(const Duration(milliseconds: 200)); // one word tick
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PlaybackReadout()),
      ));
      await tester.pumpAndSettle();
      // The numbers the controller publishes from the engine's live
      // position — the frozen-bar root-cause instrument.
      expect(find.textContaining('duration 61.2s'), findsOneWidget);
      expect(find.textContaining('position 23.4s'), findsOneWidget);
      expect(find.textContaining('state: playing'), findsOneWidget);
      // Cleanup: end the gated chunk and stop the job.
      fake.finishChunk();
      await tester.pumpAndSettle();
      await controller.stop();
    });
  });
}

/// Scriptable engine whose progress publishes fixed numeric values — the
/// readout's duration/position flow from the engine through the
/// controller's word tick to the widget.
class _ProgressEngine implements AudioEngine {

  /// Set by stop(): the delegate's chunk loop halts (the real
  /// pipeline's epoch checks, mirrored).
  bool _sequenceStopped = false;
  Completer<void>? _gate;

  @override
  Future<void> speakText(String text,
      {String? lang,
      KokoroVoice? voice,
      void Function(int sentenceIndex)? onSentenceStart,
      void Function(int charStart, int charEnd, Duration? duration)?
          onSentenceTiming,
      void Function(int charStart, int charEnd)? onWordRange}) async {
    onSentenceStart?.call(0);
    _gate = Completer<void>();
    await _gate!.future;
  }

  void finishChunk() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  @override
  Future<void> playAsset(String asset) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  bool get isPaused => false;

  @override
  (Duration, Duration?)? get progress => (
        const Duration(milliseconds: 23400),
        const Duration(milliseconds: 61200),
      );

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
  Future<void> prefetch(String text, String lang, KokoroVoice voice) async {}
}
