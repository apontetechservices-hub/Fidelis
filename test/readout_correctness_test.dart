import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/features/diagnostics/playback_readout.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/audio_diagnostics.dart';
import 'package:fidelis/services/kokoro_engine.dart';

/// THE READOUT CORRECTNESS (defect D):
///  - the engine field must ALWAYS name the engine during playback (the
///    Bible screen showed '—' because the engine line fired only after the
///    WHOLE chunk — the pipeline now emits it at the FIRST sentence);
///  - 'no timing' distinguishes idle from the fallback path;
///  - the readout lives behind Settings → About → Audio diagnostics; the
///    prayer screens show it only through the off-by-default toggle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async {
    switch (call.method) {
      case 'getAll':
        return <String, Object>{};
      case 'set':
        return null;
    }
    return null;
  });

  setUp(() {
    AudioDiagnostics.instance.clear();
  });

  group('the engine field names the engine DURING playback', () {
    test('the engine line at the first sentence sets engine=kokoro '
        'immediately', () {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] playback slot=bible lang=en '
          'voice=am_michael(16)+am_echo(12) blend=0.70 speed=0.81 '
          'eq=bands{0:-4.0dB,1:-2.0dB} lexicon=2');
      expect(d.slotReadout, isNotNull);
      expect(d.engineUsed, isNull, reason: 'nothing served yet');
      // The pipeline emits this the moment the FIRST sentence is served —
      // mid-playback, not after the whole chunk.
      d.recordLine('[Fidelis audio] engine=kokoro (the slot config above '
          'executed)');
      expect(d.engineUsed, 'kokoro');
    });

    test('a later mid-pipeline fallback overrides the engine field', () {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] playback slot=bible lang=en '
          'voice=am_michael(16)+am_echo(12) blend=0.70 speed=0.81 eq=flat '
          'lexicon=2');
      d.recordLine('[Fidelis audio] engine=kokoro (the slot config above '
          'executed)');
      d.recordLine('[Fidelis audio] FALLBACK mid-pipeline engine=flutter_tts '
          '(system voice) reason=sentence 3 of chunk 1 synthesis failed');
      expect(d.engineUsed, 'flutter_tts');
      expect(d.fallbackLine, isNotNull);
    });

    test('a new playback start clears the engine field until a sentence is '
        'served', () {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] engine=kokoro (the slot config above '
          'executed)');
      expect(d.engineUsed, 'kokoro');
      d.recordLine('[Fidelis audio] playback slot=rosary lang=en '
          'voice=af_aoede(1) speed=0.90 eq=flat lexicon=1');
      expect(d.engineUsed, isNull,
          reason: 'the new playback has not served a sentence yet');
      expect(d.fallbackLine, isNull);
    });
  });

  group('the no-timing label distinguishes idle from the fallback path', () {
    testWidgets("'no timing — idle' when nothing is playing", (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PlaybackReadout()),
      ));
      await tester.pump();
      expect(find.textContaining('no timing — idle'), findsOneWidget);
      expect(find.textContaining('fallback path'), findsNothing);
    });

    testWidgets("'no timing — fallback path' when the fallback served the "
        'audio (which exposes no timing)', (tester) async {
      final d = AudioDiagnostics.instance;
      d.recordLine('[Fidelis audio] playback slot=bible lang=en '
          'voice=am_michael(16)+am_echo(12) blend=0.70 speed=0.81 eq=flat '
          'lexicon=2');
      d.recordLine('[Fidelis audio] FALLBACK engine=flutter_tts (system '
          'voice) reason=kokoro unavailable for en');
      // Drive the controller into the playing state with a gated fake.
      final controller = AudioController.instance..engineForTest = _GatedFake();
      final started = controller.start(const AudioJob(
        id: 'bible',
        chunks: [AudioChunk(text: 'One. Two.', lang: 'en')],
      ));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: PlaybackReadout()),
      ));
      await tester.pump();
      expect(find.textContaining('no timing — fallback path'), findsOneWidget);
      await controller.stop();
      await started;
      await tester.pump();
    });
  });

  group('the prayer-screen readout toggle', () {
    test('defaults OFF', () {
      expect(PlaybackReadoutVisibility.onPrayerScreens.value, isFalse);
    });

    test('set() flips the notifier and persists', () async {
      await PlaybackReadoutVisibility.set(true);
      expect(PlaybackReadoutVisibility.onPrayerScreens.value, isTrue);
      await PlaybackReadoutVisibility.set(false);
      expect(PlaybackReadoutVisibility.onPrayerScreens.value, isFalse);
    });
  });
}

/// A gated fake engine: each playback opens a FRESH gate (start() runs
/// stop() first, which releases the previous one) and holds until stop()
/// releases it — the playing state for the readout widget tests.
class _GatedFake implements AudioEngine {
  Completer<void> _gate = Completer<void>();

  @override
  Future<void> speakText(String text,
      {String? lang,
      KokoroVoice? voice,
      void Function(int sentenceIndex)? onSentenceStart,
      void Function(int charStart, int charEnd, Duration? duration)?
          onSentenceTiming,
      void Function(int charStart, int charEnd)? onWordRange}) async {
    _gate = Completer<void>();
    onSentenceStart?.call(0);
    await _gate.future;
  }

  @override
  Future<void> playAsset(String asset) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  bool get isPaused => false;

  @override
  (Duration, Duration?)? get progress => null;

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
    // A fresh gate for THIS playback (start()'s stop() released the old
    // one): hold while "playing" so the controller's state stays playing
    // for the widget under test (stop() releases the gate).
    _gate = Completer<void>();
    await _gate.future;
  }

  @override
  Future<void> prefetch(String text, String lang, KokoroVoice voice) async {}
}
