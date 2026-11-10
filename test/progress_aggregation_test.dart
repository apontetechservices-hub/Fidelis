import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/kokoro_engine.dart';

/// THE PROGRESS AGGREGATION (defect C): the progress bar used to reset
/// every sentence (the player only knew per-chunk timing). The fix
/// aggregates: position = the completed sentences + the live position
/// within the current one; duration = the whole page (the learned renders
/// + the remaining at the running average). The bar spans the chapter.

/// Drives the sequence callbacks the way the real pipeline does — every
/// sentence's render lands AHEAD of playback (the lookahead), then the
/// chunk/sentence starts fire in stream order, gated so the test steps
/// through the playback sentence by sentence.
class _SequenceFakeEngine implements AudioEngine {
  final List<double> sentenceSeconds;
  final List<int> chunkSentenceCounts;
  Duration livePosition = Duration.zero;
  Completer<void>? _gate;

  _SequenceFakeEngine(this.sentenceSeconds, this.chunkSentenceCounts);

  Future<void> _hold() {
    _gate ??= Completer<void>();
    return _gate!.future;
  }

  /// Releases the currently "playing" sentence.
  void advance() {
    final g = _gate;
    _gate = null;
    if (g != null && !g.isCompleted) g.complete();
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
    var gi = 0;
    for (var ci = 0; ci < chunks.length; ci++) {
      for (var si = 0; si < chunkSentenceCounts[ci]; si++) {
        onSentenceSynthesized(ci, si,
            Duration(milliseconds: (sentenceSeconds[gi] * 1000).round()));
        gi++;
      }
    }
    for (var ci = 0; ci < chunks.length; ci++) {
      onChunkStart(ci);
      for (var si = 0; si < chunkSentenceCounts[ci]; si++) {
        onSentenceStart(ci, si);
        await _hold();
      }
    }
  }

  @override
  Future<void> speakText(String text,
      {String? lang,
      KokoroVoice? voice,
      void Function(int sentenceIndex)? onSentenceStart,
      void Function(int charStart, int charEnd, Duration? duration)?
          onSentenceTiming,
      void Function(int charStart, int charEnd)? onWordRange}) async {}

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
  (Duration, Duration?)? get progress => (livePosition, null);

  @override
  Future<List<Duration>?> sentenceDurations(String text, String lang,
      {bool Function()? shouldAbort}) async =>
      null;

  @override
  Future<void> prefetch(String text, String lang, KokoroVoice voice) async {}
}

/// A sequence fake whose render notifications lag one sentence behind the
/// playback (the lookahead mid-flight) — exercises the running-average
/// estimate of the not-yet-learned sentences.
class _LateRenderFakeEngine implements AudioEngine {
  final List<double> sentenceSeconds;
  final List<int> chunkSentenceCounts;
  Duration livePosition = Duration.zero;
  Completer<void>? _gate;
  int _synthesized = 0;

  _LateRenderFakeEngine(this.sentenceSeconds, this.chunkSentenceCounts);

  Future<void> _hold() {
    _gate ??= Completer<void>();
    return _gate!.future;
  }

  void advance() {
    final g = _gate;
    _gate = null;
    if (g != null && !g.isCompleted) g.complete();
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
    for (var ci = 0; ci < chunks.length; ci++) {
      onChunkStart(ci);
      for (var si = 0; si < chunkSentenceCounts[ci]; si++) {
        // The render for THIS sentence lands as it starts (one behind the
        // ideal lookahead) — the aggregate learns late.
        onSentenceSynthesized(
            ci,
            si,
            Duration(
                milliseconds:
                    (sentenceSeconds[_synthesized++] * 1000).round()));
        onSentenceStart(ci, si);
        await _hold();
      }
    }
  }

  @override
  Future<void> speakText(String text,
      {String? lang,
      KokoroVoice? voice,
      void Function(int sentenceIndex)? onSentenceStart,
      void Function(int charStart, int charEnd, Duration? duration)?
          onSentenceTiming,
      void Function(int charStart, int charEnd)? onWordRange}) async {}

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
  (Duration, Duration?)? get progress => (livePosition, null);

  @override
  Future<List<Duration>?> sentenceDurations(String text, String lang,
      {bool Function()? shouldAbort}) async =>
      null;

  @override
  Future<void> prefetch(String text, String lang, KokoroVoice voice) async {}
}

void main() {
  const job = AudioJob(
    id: 'bible',
    chunks: [
      AudioChunk(
          text: 'Alpha one. Alpha two.', lang: 'en', voice: KokoroVoice.bible),
      AudioChunk(text: 'Bravo one.', lang: 'en', voice: KokoroVoice.bible),
    ],
  );

  testWidgets('the published progress spans the whole job and advances '
      'across chunk boundaries', (tester) async {
    final fake = _SequenceFakeEngine(const [2.0, 3.0, 4.0], const [2, 1]);
    final controller = AudioController(engine: fake);
    final started = controller.start(job);
    await tester.pump();
    await tester.pump(); // the callbacks run to the first sentence's gate

    // Sentence 1 playing at 1s of its 2s: position 1s, whole-page 9s.
    fake.livePosition = const Duration(seconds: 1);
    await tester.pump(const Duration(milliseconds: 200));
    var progress = controller.progressListenable.value!;
    expect(progress.position, const Duration(seconds: 1));
    expect(progress.duration, const Duration(seconds: 9),
        reason: 'the whole-page duration (all renders learned upfront)');

    // Sentence 2 (still chunk 0) at 1.5s: position = 2.0 + 1.5 = 3.5s.
    fake.advance();
    await tester.pump();
    fake.livePosition = const Duration(milliseconds: 1500);
    await tester.pump(const Duration(milliseconds: 200));
    progress = controller.progressListenable.value!;
    expect(progress.position, const Duration(milliseconds: 3500));

    // Chunk 1's sentence at 2s: position = 5.0 + 2.0 = 7s — the position
    // ADVANCED across the chunk boundary (no reset to the chunk's start).
    fake.advance();
    await tester.pump();
    fake.livePosition = const Duration(seconds: 2);
    await tester.pump(const Duration(milliseconds: 200));
    progress = controller.progressListenable.value!;
    expect(progress.position, const Duration(seconds: 7));
    expect(progress.duration, const Duration(seconds: 9));

    fake.advance();
    await started;
  });

  testWidgets('the aggregate duration converges when renders land late',
      (tester) async {
    // The lookahead lands renders AHEAD of playback; this fake reports the
    // durations one sentence behind the playback to exercise the estimate.
    final fake = _LateRenderFakeEngine(const [2.0, 3.0, 4.0], const [2, 1]);
    final controller = AudioController(engine: fake);
    final started = controller.start(job);
    await tester.pump();
    await tester.pump();

    // Sentence 1 playing; only its own render has landed (2s learned of a
    // 3-sentence page): duration = 2 + 2×(2/1) = 6s (the running-average
    // estimate), position = 1s.
    fake.livePosition = const Duration(seconds: 1);
    await tester.pump(const Duration(milliseconds: 200));
    var progress = controller.progressListenable.value!;
    expect(progress.position, const Duration(seconds: 1));
    expect(progress.duration, const Duration(seconds: 6));

    // Sentence 2 playing; renders 1+2 landed (5s learned): duration =
    // 5 + 1×(5/2) = 7.5s, position = 2 + 1 = 3s. The bar keeps advancing.
    fake.advance();
    await tester.pump();
    fake.livePosition = const Duration(seconds: 1);
    await tester.pump(const Duration(milliseconds: 200));
    progress = controller.progressListenable.value!;
    expect(progress.position, const Duration(seconds: 3));
    expect(progress.duration, const Duration(milliseconds: 7500));

    fake.advance();
    fake.advance();
    await started;
  });
}
