import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/features/diagnostics/playback_readout.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/audio_diagnostics.dart';

import 'audio_controller_test.dart';

/// THE SILENT-FALLBACK KILLER (round 5, defect 1c): when Kokoro is
/// unavailable, the user must SEE it — a substituted voice playing with no
/// sign is worse than a visible failure. The diagnostics banner existed;
/// round 5 adds the PlaybackFallbackBanner to the player UI itself (the
/// Bible/Rosary screens), INDEPENDENT of the diagnostics readout toggle
/// (which stays off-by-default for production).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioDiagnostics.instance.clear();
  });

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
  });

  testWidgets('the fallback banner shows while a fallback playback is '
      'loaded and hides when the audio stops', (tester) async {
    // The diagnostics state as the broken session produced it: a playback
    // start, then the FALLBACK line (the system voice served it).
    AudioDiagnostics.instance.recordLine('[Fidelis audio] playback '
        'slot=rosary lang=en voice=af_aoede(1) speed=0.90 eq=flat '
        'lexicon=1');
    AudioDiagnostics.instance.recordLine('[Fidelis audio] FALLBACK '
        'engine=flutter_tts (system voice) reason=kokoro unavailable for '
        'en — Kokoro failed: worker spawn failed: TimeoutException after '
        '0:00:30.000000: Future not completed');
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PlaybackFallbackBanner()),
    ));
    // Nothing loaded: hidden (no audio, no banner — the diagnostics
    // screen keeps the history).
    expect(find.textContaining('device voice'), findsNothing);

    // A loaded (playing) playback with a fallback recorded: VISIBLE —
    // independent of the diagnostics readout toggle (which is OFF here).
    unawaited(AudioController.instance.start(
      AudioJob(
          id: 'rosary',
          chunks: const [AudioChunk(text: 'x', lang: 'en')],
          title: 'The Holy Rosary'),
      owner: 'banner-test',
    ));
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.isPlayingFor('rosary'), isTrue);
    expect(find.textContaining('device voice'), findsOneWidget,
        reason: 'the system-voice playback must be visible in the player '
            'UI — the silent fallback is the defect');
    expect(find.textContaining('TimeoutException'), findsOneWidget,
        reason: 'the banner carries the ROOT CAUSE text');

    // Stopped: hidden again.
    await AudioController.instance.stop();
    await tester.pump();
    expect(find.textContaining('device voice'), findsNothing);
  });

  testWidgets('the banner stays hidden when Kokoro served the playback '
      '(no fallback recorded)', (tester) async {
    AudioDiagnostics.instance.recordLine('[Fidelis audio] playback '
        'slot=bible lang=en voice=am_michael(16) speed=0.81 '
        'eq=bands{0:-4.0dB,1:-2.0dB} lexicon=2');
    AudioDiagnostics.instance.recordLine(
        '[Fidelis audio] engine=kokoro (the slot config above executed)');
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PlaybackFallbackBanner()),
    ));
    unawaited(AudioController.instance.start(
      AudioJob(
          id: 'bible',
          chunks: const [AudioChunk(text: 'x', lang: 'en')],
          title: 'James 1'),
      owner: 'banner-test',
    ));
    await tester.pump();
    await tester.pump();
    expect(AudioController.instance.isPlayingFor('bible'), isTrue);
    expect(find.textContaining('device voice'), findsNothing,
        reason: 'a healthy Kokoro playback shows no banner');

    // Cancel the word timer inside the body (the pending-timer invariant
    // checks before tearDown runs).
    await AudioController.instance.stop();
    await tester.pump();
  });

  testWidgets('a new playback start clears a previous fallback banner',
      (tester) async {
    AudioDiagnostics.instance.recordLine('[Fidelis audio] FALLBACK '
        'engine=flutter_tts (system voice) reason=kokoro unavailable for '
        'en — Kokoro failed: x');
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PlaybackFallbackBanner()),
    ));
    unawaited(AudioController.instance.start(
      AudioJob(
          id: 'rosary',
          chunks: const [AudioChunk(text: 'x', lang: 'en')],
          title: 'The Holy Rosary'),
      owner: 'banner-test',
    ));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('device voice'), findsOneWidget);

    // The next playback start (Kokoro healthy) clears the banner state.
    AudioDiagnostics.instance.recordLine('[Fidelis audio] playback '
        'slot=rosary lang=en voice=af_aoede(1) speed=0.90 eq=flat '
        'lexicon=1');
    await tester.pump();
    expect(find.textContaining('device voice'), findsNothing,
        reason: 'a new playback start resets the banner');

    // Cancel the word timer inside the body (the pending-timer invariant
    // checks before tearDown runs).
    await AudioController.instance.stop();
    await tester.pump();
  });
}
