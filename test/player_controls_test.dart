import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/audio_service_handler.dart';

import 'audio_controller_test.dart';

/// The media notification's contract (the owner's field-test defects):
///
///  - play after STOP restarts the last-played content (the old handler's
///    play → resume() was a dead button once the job was cleared);
///  - play after PAUSE resumes; play while playing is a no-op;
///  - play after a natural BACKGROUNDED end resumes the parked stream;
///  - the MediaItem is fully populated: title 'Fidelis', the recited
///    content as the subtitle, the app icon as the artwork, and the live
///    duration;
///  - the live position/duration are published so the progress bar
///    displays and moves.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The artwork copy needs a real support directory.
    Directory('/tmp/fidelis_player_test').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '/tmp/fidelis_player_test');
  });

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
    AudioController.instance.appInForegroundForTest = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
  });

  /// Starts a two-chunk job on the SINGLETON controller (the handler's
  /// binding target) and lets the first chunk go in-flight.
  Future<FakeAudioEngine> startInFlight(
      {String title = 'Psalms 23'}) async {
    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'bible',
        chunks: const [AudioChunk(text: 'A1'), AudioChunk(text: 'A2')],
        title: title,
      ),
      owner: 'screen',
    ));
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return engine;
  }

  test('play → pause → play: the notification play resumes the paused '
      'stream', () async {
    final handler = FidelisAudioHandler();
    final engine = await startInFlight();

    await handler.pause();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(AudioController.instance.state, AudioState.paused);
    expect(engine.log.contains('pause'), isTrue);

    engine.log.clear();
    await handler.play();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(AudioController.instance.state, AudioState.playing);
    expect(engine.log.contains('resume'), isTrue,
        reason: 'the notification play must resume the paused stream');
  });

  test('play → stop → play: the notification play RESTARTS the last-played '
      'content (the old resume-only play was a dead button)', () async {
    final handler = FidelisAudioHandler();
    final engine = await startInFlight(title: 'James 1');

    await handler.stop();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(AudioController.instance.state, AudioState.stopped);

    engine.log.clear();
    await handler.play();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(AudioController.instance.state, AudioState.playing,
        reason: 'play after stop must restart the last-played content, not '
            'do nothing');
    expect(engine.log.where((e) => e == 'speak:A1').length, 1,
        reason: 'the restart replays the job from its first chunk');
    expect(AudioController.instance.currentJobTitle, 'James 1',
        reason: 'the restarted job keeps its content title');
  });

  test('natural end while backgrounded → play: the parked stream resumes',
      () async {
    final handler = FidelisAudioHandler();
    AudioController.instance.appInForegroundForTest = false;
    final engine = await startInFlight();

    // Play both chunks to their natural end: the controller parks the
    // finished job as paused (the notification stays, resumable).
    engine.finishChunk();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    engine.finishChunk();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(AudioController.instance.state, AudioState.paused,
        reason: 'a backgrounded natural end parks the stream paused');

    engine.log.clear();
    await handler.play();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(engine.log.contains('speak:A2'), isTrue,
        reason: 'the parked resume replays the chunk the playback ended on');
  });

  test('play while playing is a no-op (no duplicate stream)', () async {
    final handler = FidelisAudioHandler();
    final engine = await startInFlight();

    engine.log.clear();
    await handler.play();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(engine.log.where((e) => e.startsWith('speak')).length, 0,
        reason: 'a duplicate play must not restart or double-start audio');
  });

  test('the MediaItem is fully populated: Fidelis title, the content as '
      'the subtitle, the app icon artwork, the live duration', () async {
    final handler = FidelisAudioHandler();
    // Give the artwork copy a moment to land.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final engine = FakeAudioEngine();
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'bible',
        chunks: const [AudioChunk(text: 'A1')],
        title: 'Psalms 23',
      ),
      owner: 'screen',
    ));
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    final item = handler.mediaItem.value;
    expect(item, isNotNull);
    expect(item!.title, 'Fidelis',
        reason: 'the player reads as Fidelis, not a blank box');
    expect(item.artist, 'Psalms 23',
        reason: 'the recited content is the subtitle');
    expect(item.album, 'Fidelis');
    expect(item.artUri, isNotNull,
        reason: 'the app icon is the notification artwork');
    expect(File(item.artUri!.toFilePath()).existsSync(), isTrue,
        reason: 'the artwork file exists (the bundled app icon copied)');
  });

  test('the live position and duration are published so the progress bar '
      'displays and moves', () async {
    final handler = FidelisAudioHandler();
    final engine = TimingFakeEngine(
      sentenceTimings: [(0, 12, const Duration(seconds: 30))],
      position: const Duration(seconds: 5),
      duration: const Duration(seconds: 30),
    );
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'bible',
        chunks: const [AudioChunk(text: 'The Lord is my shepherd')],
        title: 'Psalms 23',
      ),
      owner: 'screen',
    ));
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    // The first word tick (200ms) publishes the engine's live progress.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final state = handler.playbackState.value;
    expect(state.processingState, AudioProcessingState.ready);
    expect(state.playing, isTrue);
    expect(state.updatePosition, const Duration(seconds: 5),
        reason: 'the live position is published (the progress bar moves)');
    expect(state.speed, 1.0);

    final item = handler.mediaItem.value;
    expect(item!.duration, const Duration(seconds: 30),
        reason: 'the audio duration is published (the progress bar '
            'displays a filled track)');

    // The position advances: the next tick publishes the new position.
    engine.position = const Duration(seconds: 9);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(handler.playbackState.value.updatePosition,
        const Duration(seconds: 9),
        reason: 'the progress bar moves with the audio');
  });

  test('stop idles the session (the notification dismisses)', () async {
    final handler = FidelisAudioHandler();
    await startInFlight();

    await handler.stop();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    final state = handler.playbackState.value;
    expect(state.processingState, AudioProcessingState.idle);
    expect(state.playing, isFalse);
    expect(state.controls, isEmpty,
        reason: 'no audio, no player — the notification dismisses');
  });
}
