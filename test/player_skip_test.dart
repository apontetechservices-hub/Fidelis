import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/audio_service_handler.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart' show TtsService;

/// A fake engine with a SCRIPTED seek window: the unit-move tests drive
/// seekToSentence/appendedSentenceCount directly, and speakSequence
/// reports per-sentence durations (the aggregate re-sync's input).
/// Standalone (implements AudioEngine directly — the parent fake's
/// library-private state is out of reach here).
class SkipFakeEngine implements AudioEngine {
  SkipFakeEngine({this.appended = 0, this.durations = const []});
  final int appended;
  final List<Duration> durations;
  final List<int> seekRequests = [];
  bool seekResult = true;
  final List<String> log = [];
  bool _seqStopped = false;
  bool _paused = false;
  Completer<void>? _gate;

  /// Lets the current chunk finish (playback ran to completion).
  void finishChunk() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

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
    log.add('speak:$text');
    onSentenceStart?.call(0);
    _gate = Completer<void>();
    await _gate!.future;
  }

  @override
  (Duration, Duration?)? get progress =>
      (const Duration(milliseconds: 500), null);

  @override
  Future<List<Duration>?> sentenceDurations(String text, String lang,
      {bool Function()? shouldAbort}) async => null;

  @override
  Future<void> playAsset(String asset) async {
    log.add('asset:$asset');
    _gate = Completer<void>();
    await _gate!.future;
  }

  @override
  Future<void> pause() async {
    log.add('pause');
    _paused = true;
  }

  @override
  Future<void> resume() async {
    log.add('resume');
    _paused = false;
  }

  @override
  Future<void> stop() async {
    log.add('stop');
    _seqStopped = true;
    _paused = false;
    finishChunk();
  }

  @override
  bool get isPaused => _paused;

  @override
  Future<bool> seekToSentence(int streamIndex) async {
    seekRequests.add(streamIndex);
    return seekResult;
  }

  @override
  int get appendedSentenceCount => appended;

  @override
  Future<void> prefetch(String text, String lang, KokoroVoice voice) async {
    log.add('prefetch:$text');
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
    _seqStopped = false;
    var served = 0;
    for (var ci = 0; ci < chunks.length; ci++) {
      if (ci > 0 && _seqStopped) return;
      log.add('speak:${chunks[ci].text}');
      onChunkStart(ci);
      final sentences = TtsService.splitSentences(chunks[ci].text ?? '');
      for (var si = 0; si < sentences.length; si++) {
        final d = served < durations.length
            ? durations[served]
            : const Duration(seconds: 1);
        onSentenceSynthesized(ci, si, d);
        served++;
      }
      onSentenceStart(ci, 0);
      _gate = Completer<void>();
      await _gate!.future;
    }
  }
}

/// THE MEDIA NOTIFICATION'S NEXT/PREVIOUS (round 3, new 1): the BIBLE
/// moves by VERSE, the ROSARY by PRAYER. Playing, the newly selected
/// verse/prayer STARTS PLAYING (the seek continues into it; the rosary's
/// step job starts); paused, the position just moves (the seek moves it
/// in place, or an armed resume starts the moved-to unit on the next
/// Play). The controls live in the playbackState control set and route
/// through the controller's skipUnit into the loaded job's own unit move.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Waits (real time) until [predicate] holds or ~4s elapse.
  Future<bool> waitFor(bool Function() predicate) async {
    for (var i = 0; i < 200; i++) {
      if (predicate()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return predicate();
  }

  setUp(() {
    Directory('/tmp/fidelis_skip_test').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '/tmp/fidelis_skip_test');
  });

  tearDown(() async {
    await AudioController.instance.stop();
    AudioController.instance.engineForTest = const TtsAudioEngine();
    AudioController.instance.appInForegroundForTest = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
  });

  /// Starts a gated one-chunk job on the singleton controller.
  Future<SkipFakeEngine> startInFlight({
    Future<int?> Function(int direction)? onUnitMove,
    SkipFakeEngine? engine,
  }) async {
    final e = engine ?? SkipFakeEngine();
    AudioController.instance.engineForTest = e;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'bible',
        chunks: const [AudioChunk(text: 'A1', lang: 'en')],
        onUnitMove: onUnitMove,
      ),
      owner: 'screen',
    ));
    await settle();
    expect(AudioController.instance.state, AudioState.playing);
    return e;
  }

  test('the notification control set offers Next and Previous (compact '
      'Previous|Play/Pause|Next, Stop expanded)', () async {
    final handler = FidelisAudioHandler();
    await startInFlight();

    final state = handler.playbackState.value;
    expect(state.controls, contains(MediaControl.skipToNext));
    expect(state.controls, contains(MediaControl.skipToPrevious));
    expect(state.controls, contains(MediaControl.stop));
    // The compact row: Previous | Play/Pause | Next (the standard player
    // layout); Stop is the expanded view's action.
    expect(state.androidCompactActionIndices, [0, 1, 2]);
    expect(state.controls.first, MediaControl.skipToPrevious);
    expect(state.controls[2], MediaControl.skipToNext);
  });

  test('the Bible verse move (playing): Next/Previous seek the live '
      'pipeline to the target verse\'s first sentence', () async {
    final handler = FidelisAudioHandler();
    final engine = SkipFakeEngine(appended: 6);
    AudioController.instance.engineForTest = engine;
    final moved = <int>[];
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'bible',
        chunks: const [
          AudioChunk(text: 'Verse one. Verse two.', lang: 'en'),
          AudioChunk(text: 'Verse three.', lang: 'en'),
        ],
        title: 'Psalms 23',
        onUnitMove: (direction) async {
          moved.add(direction);
          return direction > 0 ? 3 : 1; // the verse-level targets
        },
      ),
      owner: 'screen',
    ));
    await settle();

    await handler.skipToNext();
    expect(moved, [1]);
    expect(engine.seekRequests, [3],
        reason: 'the controller seeks the pipeline to the target sentence');

    await handler.skipToPrevious();
    expect(moved, [1, -1]);
    expect(engine.seekRequests, [3, 1]);
    expect(AudioController.instance.state, AudioState.playing,
        reason: 'playing: the newly selected verse starts playing');
  });

  test('a blocked unit move (the chapter edge) issues no seek', () async {
    final handler = FidelisAudioHandler();
    final engine = await startInFlight(onUnitMove: (direction) async => null);

    await handler.skipToNext();
    await handler.skipToPrevious();
    expect(engine.seekRequests, isEmpty,
        reason: 'the boundary blocks the move — nothing seeks');
  });

  test('a job without unit moves: the skip controls no-op safely', () async {
    final handler = FidelisAudioHandler();
    final engine = await startInFlight();

    await handler.skipToNext();
    await handler.skipToPrevious();
    expect(engine.seekRequests, isEmpty);
    expect(AudioController.instance.state, AudioState.playing);
  });

  test('the paused verse move: the seek moves the position in place (the '
      'state stays paused — nothing sounds until Play)', () async {
    final handler = FidelisAudioHandler();
    final engine = SkipFakeEngine(appended: 6);
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'bible',
        chunks: const [
          AudioChunk(text: 'Verse one. Verse two.', lang: 'en'),
          AudioChunk(text: 'Verse three.', lang: 'en'),
        ],
        onUnitMove: (direction) async => direction > 0 ? 2 : 0,
      ),
      owner: 'screen',
    ));
    await settle();
    await AudioController.instance.pause();
    expect(AudioController.instance.state, AudioState.paused);

    await handler.skipToNext();
    expect(engine.seekRequests, [2]);
    expect(AudioController.instance.state, AudioState.paused,
        reason: 'the position just moves — nothing starts');
  });

  test('the paused prayer move (the rosary): the position moves via the '
      'armed resume and Play starts the moved-to step', () async {
    final handler = FidelisAudioHandler();
    final engine = SkipFakeEngine();
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'rosary',
        chunks: const [AudioChunk(text: 'step 1', lang: 'en')],
        title: 'The Holy Rosary',
        onUnitMove: (direction) async {
          // The rosary's move, mirrored: the screen advances the step and
          // arms the resume while paused — the position moves without
          // starting audio.
          if (AudioController.instance.state == AudioState.paused) {
            AudioController.instance.armResume(
              const AudioJob(
                  id: 'rosary',
                  chunks: [AudioChunk(text: 'step 2', lang: 'en')],
                  title: 'The Holy Rosary'),
              owner: 'screen',
            );
          }
          return null;
        },
      ),
      owner: 'screen',
    ));
    await settle();
    await AudioController.instance.pause();

    await handler.skipToNext();
    expect(AudioController.instance.state, AudioState.paused,
        reason: 'the position moved; nothing started');

    await handler.play();
    await waitFor(() =>
        engine.log.any((l) => l.contains('speak:step 2')));
    expect(
        engine.log.where((l) => l.contains('speak:step 2')), isNotEmpty,
        reason: 'Play starts the moved-to prayer');
  });

  test('the rosary prayer move (playing): the newly selected prayer '
      'starts playing (the step job replaces the stream)', () async {
    final handler = FidelisAudioHandler();
    final engine = SkipFakeEngine();
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'rosary',
        chunks: const [AudioChunk(text: 'step 1', lang: 'en')],
        onUnitMove: (direction) async {
          // The rosary's move while listening: the new step's job starts
          // (start() replaces the stream) — the move is handled here.
          unawaited(AudioController.instance.start(
            AudioJob(
                id: 'rosary',
                chunks: const [AudioChunk(text: 'step 2', lang: 'en')],
                title: 'The Holy Rosary'),
            owner: 'screen',
          ));
          return null;
        },
      ),
      owner: 'screen',
    ));
    await settle();

    await handler.skipToNext();
    await waitFor(() =>
        engine.log.any((l) => l.contains('speak:step 2')));
    expect(
        engine.log.where((l) => l.contains('speak:step 2')), isNotEmpty,
        reason: 'the newly selected prayer starts playing');
  });

  test('after a verse-move seek, the aggregate progress re-syncs to the '
      'target sentence (the bar never jumps backward)', () async {
    final handler = FidelisAudioHandler();
    final engine = SkipFakeEngine(
      appended: 6,
      durations: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
        Duration(seconds: 4),
      ],
    );
    AudioController.instance.engineForTest = engine;
    unawaited(AudioController.instance.start(
      AudioJob(
        id: 'bible',
        chunks: const [
          AudioChunk(text: 'Verse one. Verse two.', lang: 'en'),
          AudioChunk(text: 'Verse three.', lang: 'en'),
        ],
        onUnitMove: (direction) async => direction > 0 ? 2 : 0,
      ),
      owner: 'screen',
    ));
    await settle();

    await handler.skipToNext();
    expect(engine.seekRequests, [2]);
    // The word tick publishes the aggregate: the skipped sentences are
    // complete (1s + 2s) plus the live position within the target.
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final progress = AudioController.instance.progressListenable.value;
    expect(progress, isNotNull);
    expect(progress!.position.inMilliseconds, greaterThanOrEqualTo(2900),
        reason: 'the position spans the skipped sentences (1s + 2s) plus '
            'the live position — no backward jump to zero');
  });
}
