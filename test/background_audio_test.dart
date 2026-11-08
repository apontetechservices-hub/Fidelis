import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_controller.dart';

import 'audio_controller_test.dart';

/// The background/focus state machine (the media notification's contract):
///
///  - a natural end in the FOREGROUND stops the stream — the historical
///    behavior, unchanged;
///  - a natural end while the app is BACKGROUNDED parks the finished job as
///    PAUSED so the media notification stays (resumable, dismissable)
///    instead of vanishing;
///  - resuming a parked stream replays the chunk the playback ended on,
///    through the normal job loop;
///  - audio-focus loss (the injected externalPauseRequests stream — another
///    app, a call, an alarm) pauses the stream and it STAYS paused: no
///    auto-resume, the user resumes manually.
///
/// Runs outside the widget binding: the controller's WidgetsBinding observer
/// registration is best-effort and the foreground state is forced through
/// [AudioController.appInForegroundForTest].
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Starts a two-chunk job on [controller] and plays it to its natural end.
/// Returns the engine (the caller holds the reference; the controller's
/// engine swap is setter-only).
Future<FakeAudioEngine> _playToEnd(
  AudioController controller,
  FakeAudioEngine engine, {
  void Function()? onCompleted,
  String title = 'James 1',
}) async {
  unawaited(controller.start(
    AudioJob(
      id: 'bible',
      chunks: const [AudioChunk(text: 'A1'), AudioChunk(text: 'A2')],
      onCompleted: onCompleted,
      title: title,
    ),
    owner: 'screen',
  ));
  await _settle();
  engine.finishChunk();
  await _settle();
  engine.finishChunk();
  await _settle();
  return engine;
}

void main() {
  test('natural end in the foreground stops the stream (unchanged mechanics)',
      () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    var completions = 0;
    await _playToEnd(controller, engine, onCompleted: () => completions++);
    expect(controller.state, AudioState.stopped);
    expect(completions, 1);
    expect(controller.currentJobTitle, isNull);
    // Exactly one engine stop: start()'s single-stream pre-stop. A natural
    // end issues no engine stop of its own.
    expect(engine.log.where((e) => e == 'stop').length, 1);
    expect(engine.log.last, 'speak:A2');
  });

  test('natural end while backgrounded parks the stream paused', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    controller.appInForegroundForTest = false;
    var completions = 0;
    await _playToEnd(controller, engine, onCompleted: () => completions++);
    // The player stays (paused) for the media notification; the job is
    // parked at the chunk it ended on.
    expect(controller.state, AudioState.paused);
    expect(controller.currentJobId, 'bible');
    expect(controller.currentJobTitle, 'James 1');
    expect(completions, 1);
    // Exactly one engine stop (start()'s pre-stop): the parked stream is
    // not stopped — the media notification stays.
    expect(engine.log.where((e) => e == 'stop').length, 1);
    expect(engine.log.last, 'speak:A2');
  });

  test('resuming a parked stream replays the chunk it ended on', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    controller.appInForegroundForTest = false;
    await _playToEnd(controller, engine);

    unawaited(controller.resume());
    await _settle();
    expect(controller.state, AudioState.playing);
    expect(engine.log.last, 'speak:A2',
        reason: 'the replay runs the chunk the playback ended on');

    // The replayed chunk ends naturally, still backgrounded: parked again.
    engine.finishChunk();
    await _settle();
    expect(controller.state, AudioState.paused);
    expect(controller.currentJobId, 'bible');
  });

  test('stopping a parked stream ends it (the notification dismisses)',
      () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    controller.appInForegroundForTest = false;
    await _playToEnd(controller, engine);

    await controller.stop();
    expect(controller.state, AudioState.stopped);
    expect(controller.currentJobTitle, isNull);
    expect(engine.log.contains('stop'), isTrue);
  });

  test('a new job replaces a parked stream', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    controller.appInForegroundForTest = false;
    await _playToEnd(controller, engine);

    unawaited(controller.start(
      const AudioJob(id: 'rosary', chunks: [AudioChunk(asset: 'r.ogg')]),
      owner: 'screenB',
    ));
    await _settle();
    expect(controller.state, AudioState.playing);
    expect(controller.currentJobId, 'rosary');
  });

  test('audio-focus loss pauses the stream and it stays paused', () async {
    final losses = StreamController<void>();
    final engine = FakeAudioEngine();
    final controller = AudioController(
      engine: engine,
      externalPauseRequests: losses.stream,
    );
    unawaited(controller.start(
      const AudioJob(id: 'bible', chunks: [AudioChunk(text: 'A1')]),
      owner: 'screen',
    ));
    await _settle();
    expect(controller.state, AudioState.playing);

    losses.add(null); // another app took focus / a call started
    await _settle();
    expect(controller.state, AudioState.paused);

    // The interruption ends: Fidelis does NOT auto-resume.
    await _settle();
    await _settle();
    expect(controller.state, AudioState.paused);
    expect(engine.log.contains('resume'), isFalse);
    await losses.close();
  });

  test('a focus loss while parked is a no-op', () async {
    final losses = StreamController<void>();
    final engine = FakeAudioEngine();
    final controller = AudioController(
      engine: engine,
      externalPauseRequests: losses.stream,
    );
    controller.appInForegroundForTest = false;
    await _playToEnd(controller, engine);
    expect(controller.state, AudioState.paused);

    losses.add(null);
    await _settle();
    expect(controller.state, AudioState.paused);
    await losses.close();
  });

  test('a parked replay that ends in the foreground stops normally', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    controller.appInForegroundForTest = false;
    await _playToEnd(controller, engine);

    // The user returned to the app, then resumed.
    controller.appInForegroundForTest = true;
    unawaited(controller.resume());
    await _settle();
    expect(controller.state, AudioState.playing);

    engine.finishChunk();
    await _settle();
    expect(controller.state, AudioState.stopped,
        reason: 'a foreground end goes idle (the historical behavior)');
  });
}
