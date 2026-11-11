import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/audio_focus.dart';

import 'audio_controller_test.dart';

/// AUDIO FOCUS (round 3, new 2): when another app takes focus (music, a
/// call, an alarm) or the headphones are unplugged, Fidelis pauses
/// IMMEDIATELY and STAYS PAUSED — no ducking, no auto-resume — until the
/// user presses Play. The wiring is the app's (just_audio's own handler
/// would auto-resume after an interruption ends); the interruption-END
/// event does NOTHING. Every reaction logs through the diagnostics path —
/// the device evidence that the event arrived and the pause executed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
    AudioController.instance.appInForegroundForTest = true;
  });

  /// Starts a gated one-chunk job on the singleton controller.
  Future<FakeAudioEngine> startInFlight() async {
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      const AudioJob(id: 'bible', chunks: [AudioChunk(text: 'A1')]),
      owner: 'screen',
    ));
    await settle();
    expect(AudioController.instance.state, AudioState.playing);
    return engine;
  }

  /// Wires the focus reactions to scripted streams; returns the event log
  /// and the subscription list (cancelled in the teardown).
  (List<String>, List<StreamSubscription<dynamic>>,
      StreamController<AudioInterruptionEvent>, StreamController<void>)
      wire() {
    final interruptions =
        StreamController<AudioInterruptionEvent>.broadcast();
    final noisy = StreamController<void>.broadcast();
    final events = <String>[];
    final subs = wireAudioFocus(
      interruptions: interruptions.stream,
      becomingNoisy: noisy.stream,
      controller: AudioController.instance,
      onEvent: events.add,
    );
    return (events, subs, interruptions, noisy);
  }

  test('a focus loss pauses the stream and it STAYS paused (the '
      'interruption end does nothing)', () async {
    await startInFlight();
    final (events, subs, interruptions, noisy) = wire();
    addTearDown(() async {
      for (final s in subs) {
        await s.cancel();
      }
      await interruptions.close();
      await noisy.close();
    });

    interruptions.add(AudioInterruptionEvent(
        true, AudioInterruptionType.pause));
    await settle();
    expect(AudioController.instance.state, AudioState.paused,
        reason: 'the focus loss pauses Fidelis immediately');
    expect(events.where((l) => l.contains('focus loss')), isNotEmpty,
        reason: 'the reaction is logged (the device evidence path)');

    // The interruption ENDS: nothing happens — Fidelis stays paused.
    interruptions.add(AudioInterruptionEvent(
        false, AudioInterruptionType.pause));
    await settle();
    expect(AudioController.instance.state, AudioState.paused,
        reason: 'no auto-resume — the user presses Play');

    // A later focus loss while already paused: still paused (no throw).
    interruptions.add(AudioInterruptionEvent(
        true, AudioInterruptionType.unknown));
    await settle();
    expect(AudioController.instance.state, AudioState.paused);
  });

  test('a duck-type focus loss also pauses (the speech session pauses '
      'rather than ducks)', () async {
    await startInFlight();
    final (events, subs, interruptions, noisy) = wire();
    addTearDown(() async {
      for (final s in subs) {
        await s.cancel();
      }
      await interruptions.close();
      await noisy.close();
    });

    interruptions.add(AudioInterruptionEvent(
        true, AudioInterruptionType.duck));
    await settle();
    expect(AudioController.instance.state, AudioState.paused,
        reason: 'no ducking — another app\'s audio never plays over '
            'Fidelis');
    expect(events.any((l) => l.contains('focus loss (duck)')), isTrue);
  });

  test('an unplug (becoming noisy) pauses the stream and it stays', () async {
    await startInFlight();
    final (events, subs, interruptions, noisy) = wire();
    addTearDown(() async {
      for (final s in subs) {
        await s.cancel();
      }
      await interruptions.close();
      await noisy.close();
    });

    noisy.add(null);
    await settle();
    expect(AudioController.instance.state, AudioState.paused);
    expect(events.any((l) => l.contains('headphones unplugged')), isTrue);
  });

  test('the focus loss pauses mid-job; the user\'s resume continues the '
      'same stream (the engine resumes, not restarts)', () async {
    final engine = await startInFlight();
    final (events, subs, interruptions, noisy) = wire();
    addTearDown(() async {
      for (final s in subs) {
        await s.cancel();
      }
      await interruptions.close();
      await noisy.close();
    });

    interruptions.add(AudioInterruptionEvent(
        true, AudioInterruptionType.pause));
    await settle();
    expect(AudioController.instance.state, AudioState.paused);
    expect(engine.log.contains('pause'), isTrue);

    engine.log.clear();
    unawaited(AudioController.instance.resume());
    await settle();
    expect(AudioController.instance.state, AudioState.playing);
    expect(engine.log.contains('resume'), isTrue,
        reason: 'the user\'s Play resumes the same stream');
  });
}
