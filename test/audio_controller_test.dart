import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_controller.dart';

/// Scriptable engine recording every call, so the single-stream rule and
/// state transitions are verified without real audio plugins.
class FakeAudioEngine implements AudioEngine {
  final List<String> log = [];

  /// Language passed to each speakText call, in order — lets tests verify
  /// the audio language routing without touching the text log format.
  final List<String?> langs = [];

  /// Gate of the chunk currently "playing"; completes when it finishes.
  Completer<void>? _gate;

  /// Mimics the flutter_tts path where pause() completes the pending chunk
  /// await early (the player path keeps it pending instead).
  bool completeOnPause = false;
  bool _paused = false;

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    log.add('speak:$text');
    langs.add(lang);
    onSentenceStart?.call(0);
    _gate = Completer<void>();
    await _gate!.future;
  }

  @override
  (Duration, Duration?)? get progress => null;

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
    if (completeOnPause) finishChunk();
  }

  @override
  Future<void> resume() async {
    log.add('resume');
    _paused = false;
  }

  @override
  Future<void> stop() async {
    log.add('stop');
    _paused = false;
    finishChunk();
  }

  @override
  bool get isPaused => _paused;

  /// Lets the current chunk finish (playback ran to completion).
  void finishChunk() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
}

/// Lets async controller loops and microtasks run.
Future<void> _settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('starting a new job stops the current one immediately (single stream)',
      () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);

    final jobA = controller.start(
      const AudioJob(id: 'bible', chunks: [
        AudioChunk(text: 'A1'),
        AudioChunk(text: 'A2'),
      ]),
      owner: 'screenA',
    );
    await _settle();
    expect(controller.state, AudioState.playing);
    expect(controller.currentJobId, 'bible');

    final jobB = controller.start(
      const AudioJob(id: 'rosary', chunks: [AudioChunk(asset: 'rosary.ogg')]),
      owner: 'screenB',
    );
    await _settle();

    // The engine-level stop of A strictly precedes B's first chunk.
    final stopIndex = engine.log.indexOf('stop');
    final bIndex = engine.log.indexOf('asset:rosary.ogg');
    expect(stopIndex, greaterThanOrEqualTo(0));
    expect(bIndex, greaterThan(stopIndex));

    // A's second chunk never plays: the old loop is dead.
    expect(engine.log.contains('speak:A2'), isFalse);

    // Exactly one stream is current.
    expect(controller.currentJobId, 'rosary');
    expect(controller.state, AudioState.playing);

    await controller.stop();
    await jobA;
    await jobB;
  });

  test('stop() halts the job loop and clears state', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);

    final job = controller.start(
      const AudioJob(id: 'bible', chunks: [
        AudioChunk(text: 'A1'),
        AudioChunk(text: 'A2'),
      ]),
    );
    await _settle();
    expect(controller.state, AudioState.playing);

    await controller.stop();
    await _settle();
    expect(engine.log.contains('speak:A2'), isFalse);
    expect(controller.state, AudioState.stopped);
    expect(controller.currentJobId, isNull);
    await job;
  });

  test('pause and resume transition state and drive the engine', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);

    final job = controller.start(
      const AudioJob(id: 'bible', chunks: [
        AudioChunk(text: 'A1'),
        AudioChunk(text: 'A2'),
      ]),
    );
    await _settle();

    await controller.pause();
    expect(controller.state, AudioState.paused);
    expect(engine.log, contains('pause'));

    await controller.resume();
    expect(controller.state, AudioState.playing);
    expect(engine.log, contains('resume'));

    // Chunk 1 finishes; the loop continues into chunk 2.
    engine.finishChunk();
    await _settle();
    expect(engine.log.contains('speak:A2'), isTrue);

    await controller.stop();
    await job;
  });

  test('flutter_tts-style pause holds the loop until the resume plays out',
      () async {
    final engine = FakeAudioEngine()..completeOnPause = true;
    final controller = AudioController(engine: engine);

    final job = controller.start(
      const AudioJob(id: 'bible', chunks: [
        AudioChunk(text: 'A1'),
        AudioChunk(text: 'A2'),
      ]),
    );
    await _settle();

    // A flutter_tts pause completes the chunk await early…
    await controller.pause();
    await _settle();
    expect(controller.state, AudioState.paused);
    // …but the loop must NOT skip to the next chunk while paused.
    expect(engine.log.contains('speak:A2'), isFalse);

    await controller.resume();
    await _settle();
    // After the resume plays the remainder out, the loop continues.
    expect(engine.log.contains('speak:A2'), isTrue);

    await controller.stop();
    await job;
  });

  test('sentence callbacks advance the exposed playback position', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    final sentences = <int>[];

    final job = controller.start(AudioJob(id: 'bible', chunks: [
      AudioChunk(
        text: 'chunk',
        onSentenceStart: sentences.add,
      ),
    ]));
    await _settle();

    expect(sentences, [0]);
    expect(controller.listenable.value.chunkIndex, 0);
    expect(controller.listenable.value.sentenceIndex, 0);

    await controller.stop();
    await job;
  });

  test('owner scenario: Bible audio stops when Rosary starts; only Rosary '
      'plays; each screen dispose stops only its own stream', () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    final bibleScreen = Object();
    final rosaryScreen = Object();

    // 1. Bible screen starts its audio.
    final bibleJob = controller.start(
      const AudioJob(id: 'bible', chunks: [AudioChunk(text: 'Bible chunk')]),
      owner: bibleScreen,
    );
    await _settle();
    expect(controller.isPlayingFor('bible'), isTrue);

    // 2. User leaves the Bible screen for the Rosary; the Rosary starts.
    final rosaryJob = controller.start(
      const AudioJob(id: 'rosary', chunks: [
        AudioChunk(asset: 'assets/rosary_audio/hail_mary.ogg'),
      ]),
      owner: rosaryScreen,
    );
    await _settle();

    // Bible stopped (single stream) — and it never restarts.
    expect(controller.isPlayingFor('bible'), isFalse);
    expect(engine.log.where((e) => e == 'speak:Bible chunk'), hasLength(1));
    expect(controller.isPlayingFor('rosary'), isTrue);

    // 3. The Bible screen's dispose fires stopIfOwner(bibleScreen):
    // the Rosary stream must survive.
    await controller.stopIfOwner(bibleScreen);
    expect(controller.isPlayingFor('rosary'), isTrue);
    expect(controller.state, AudioState.playing);

    // 4. The Rosary screen's dispose stops its own audio.
    await controller.stopIfOwner(rosaryScreen);
    expect(controller.state, AudioState.stopped);

    await bibleJob;
    await rosaryJob;
  });

  test('natural completion returns to stopped and fires onCompleted',
      () async {
    final engine = FakeAudioEngine();
    final controller = AudioController(engine: engine);
    var completed = 0;

    final job = controller.start(AudioJob(
      id: 'bible',
      chunks: const [AudioChunk(text: 'A1')],
      onCompleted: () => completed++,
    ));
    await _settle();
    engine.finishChunk();
    await _settle();
    expect(controller.state, AudioState.stopped);
    expect(completed, 1);
    await job;
  });

  testWidgets('Kokoro sentence timing + live position drive the word range '
      '(proportional estimate)', (tester) async {
    final engine = TimingFakeEngine(
      sentenceTimings: [(0, 12, const Duration(seconds: 10))],
      position: const Duration(seconds: 5),
      duration: const Duration(seconds: 10),
    );
    final controller = AudioController(engine: engine);

    final job = controller.start(const AudioJob(id: 'bible', chunks: [
      AudioChunk(text: 'Hello world.'),
    ]));
    await tester.pump();
    // The word timer ticks at 200ms — advance fake time past one tick.
    await tester.pump(const Duration(milliseconds: 250));

    final range = controller.wordRangeListenable.value;
    expect(range, isNotNull, reason: 'word-level highlight state must reach '
        'the UI stream while the voice advances');
    expect(range!.estimated, isTrue);
    // 5s of a 10s sentence → the middle of 'Hello world.' → the word
    // containing offset 6 is 'world' → [6, 11).
    expect(range.charStart, 6);
    expect(range.charEnd, 11);

    // Advancing the position advances the word range.
    engine.position = const Duration(seconds: 9);
    await tester.pump(const Duration(milliseconds: 250));
    expect(controller.wordRangeListenable.value!.charStart, 6);

    await controller.stop();
    await job;
  });

  testWidgets('flutter_tts word events drive the word range (engine-timed)',
      (tester) async {
    final engine = WordEventFakeEngine(events: [(0, 5), (6, 11)]);
    final controller = AudioController(engine: engine);

    final job = controller.start(const AudioJob(id: 'bible', chunks: [
      AudioChunk(text: 'Hello world.'),
    ]));
    await tester.pump();
    await tester.pump();

    final range = controller.wordRangeListenable.value;
    expect(range, isNotNull,
        reason: 'engine word events must reach the UI stream');
    expect(range!.estimated, isFalse);
    expect(range.charStart, 6);
    expect(range.charEnd, 11);

    await controller.stop();
    await job;
  });

  testWidgets('word range and progress clear when audio stops',
      (tester) async {
    final engine = TimingFakeEngine(
      sentenceTimings: [(0, 12, const Duration(seconds: 10))],
      position: const Duration(seconds: 5),
      duration: const Duration(seconds: 10),
    );
    final controller = AudioController(engine: engine);

    final job = controller.start(const AudioJob(id: 'bible', chunks: [
      AudioChunk(text: 'Hello world.'),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(controller.wordRangeListenable.value, isNotNull);
    expect(controller.progressListenable.value, isNotNull);

    await controller.stop();
    await tester.pump();
    expect(controller.wordRangeListenable.value, isNull);
    expect(controller.progressListenable.value, isNull);
    await job;
  });

  testWidgets('asset playback exposes live position and duration',
      (tester) async {
    final engine = TimingFakeEngine(
      sentenceTimings: [],
      position: const Duration(seconds: 3),
      duration: const Duration(seconds: 12),
    );
    final controller = AudioController(engine: engine);

    final job = controller.start(const AudioJob(id: 'rosary', chunks: [
      AudioChunk(asset: 'assets/rosary_audio/en/our_father.ogg'),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final progress = controller.progressListenable.value;
    expect(progress, isNotNull,
        reason: 'pre-rendered playback must expose position/duration so '
            'screens can sync line highlights');
    expect(progress!.position, const Duration(seconds: 3));
    expect(progress.duration, const Duration(seconds: 12));
    // Asset chunks carry no text: no word range of their own.
    expect(controller.wordRangeListenable.value, isNull);

    await controller.stop();
    await job;
  });

  testWidgets('pause freezes the word range; stop clears it', (tester) async {
    final engine = TimingFakeEngine(
      sentenceTimings: [(0, 12, const Duration(seconds: 10))],
      position: const Duration(seconds: 5),
      duration: const Duration(seconds: 10),
    );
    final controller = AudioController(engine: engine);

    final job = controller.start(const AudioJob(id: 'bible', chunks: [
      AudioChunk(text: 'Hello world.'),
    ]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final frozen = controller.wordRangeListenable.value;
    expect(frozen, isNotNull);

    await controller.pause();
    await tester.pump(const Duration(milliseconds: 250));
    // Paused: the highlight stays where the user paused (frozen), it does
    // not keep advancing.
    expect(controller.wordRangeListenable.value, frozen);

    await controller.stop();
    await tester.pump();
    expect(controller.wordRangeListenable.value, isNull);
    await job;
  });
}

/// Kokoro-like engine: reports per-sentence timing (character range in the
/// chunk text + the sentence's audio duration) and exposes a scriptable
/// live position/duration, as the real player path does.
class TimingFakeEngine implements AudioEngine {
  final List<String> log = [];

  /// (charStart, charEnd, duration) reported per speakText call.
  final List<(int, int, Duration?)> sentenceTimings;

  /// Scriptable live position/duration, as just_audio exposes.
  Duration position;
  Duration? duration;

  Completer<void>? _gate;
  bool _paused = false;
  TimingFakeEngine({required this.sentenceTimings, this.position = Duration.zero, this.duration});

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    log.add('speak:$text');
    for (final timing in sentenceTimings) {
      onSentenceStart?.call(0);
      onSentenceTiming?.call(timing.$1, timing.$2, timing.$3);
    }
    _gate = Completer<void>();
    await _gate!.future;
  }

  @override
  Future<void> playAsset(String asset) async {
    log.add('asset:$asset');
    _gate = Completer<void>();
    await _gate!.future;
  }

  @override
  (Duration, Duration?)? get progress => (position, duration);

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
    _paused = false;
    finishChunk();
  }

  @override
  bool get isPaused => _paused;

  void finishChunk() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
}

/// flutter_tts-like engine: fires real word-boundary events (onRangeStart)
/// with character ranges into the spoken text.
class WordEventFakeEngine implements AudioEngine {
  final List<String> log = [];
  final List<(int, int)> events;
  Completer<void>? _gate;
  bool _paused = false;
  WordEventFakeEngine({required this.events});

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    log.add('speak:$text');
    onSentenceStart?.call(0);
    for (final event in events) {
      onWordRange?.call(event.$1, event.$2);
    }
    _gate = Completer<void>();
    await _gate!.future;
  }

  @override
  (Duration, Duration?)? get progress => null;

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
    _paused = false;
    finishChunk();
  }

  @override
  bool get isPaused => _paused;

  void finishChunk() {
    final gate = _gate;
    _gate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
  }
}