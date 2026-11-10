import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'scripted_audio_harness.dart';

/// THE LOOKAHEAD PIPELINE (defect B): the long synthesis pauses between
/// verses/pages existed because nothing rendered ahead — each chunk's
/// first sentence was synthesized only after the previous chunk's last
/// sentence finished PLAYING. The fix runs ALL of a job's text chunks as
/// ONE continuous sentence pipeline whose rolling lookahead SPANS chunk
/// boundaries: while a sentence plays, the following sentences — including
/// the next chunk's first — are already rendering in the worker.
///
/// The synthesis is scripted ([KokoroEngine.debugSynthesizeOverride]); the
/// player's play result is GATED so each assertion lands mid-play. All
/// synchronization is real-time polling ([waitFor]): the pipeline's WAV
/// writes are real async I/O, which microtask-only settling never crosses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ttsCalls = installPipelineChannelMocks();
  final platform = GatedPlatform();
  JustAudioPlatform.instance = platform;

  setUp(() {
    ttsCalls.clear();
    KokoroEngine.resetForTest();
    TtsService.readoutSink = null;
  });

  KokoroAudio audioFor(String text) {
    // 24000 Hz; the length encodes the sentence so requests are greppable.
    final n = 2400 + text.length;
    final samples = Float32List(n);
    for (var i = 0; i < n; i++) {
      samples[i] = 0.3 * (i % 100) / 100;
    }
    return KokoroAudio(samples, 24000);
  }

  /// Waits until the pipeline has a player with a PENDING play (it is
  /// mid-playback) and returns that player.
  Future<GatedPlayer> waitPendingPlay() => waitPendingPlayOn(platform);

  test('solo slot (depth 2): the next chunk renders while the current '
      'chunk plays', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    final lines = <String>[];
    TtsService.readoutSink = lines.add;

    final chunkStarts = <int>[];
    final sentenceStarts = <(int, int)>[];
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Alpha one. Alpha two. Alpha three.',
            lang: 'en',
            voice: KokoroVoice.standard),
        AudioChunk(
            text: 'Bravo one. Bravo two.',
            lang: 'en',
            voice: KokoroVoice.standard),
      ],
      lang: 'en',
      onChunkStart: chunkStarts.add,
      onSentenceStart: (ci, si) => sentenceStarts.add((ci, si)),
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));

    // THE SOLO DEPTH-2 LOOKAHEAD: while sentence 1 PLAYS (the play result
    // is pending), sentences 2 AND 3 are already rendering.
    var player = await waitPendingPlay();
    expect(requests, ['Alpha one.', 'Alpha two.', 'Alpha three.']);
    // THE ENGINE LINE FIRES AT THE FIRST SENTENCE (defect D): the readout
    // names the engine DURING playback, not after the whole chunk.
    expect(lines.where((l) => l.contains('engine=kokoro')), isNotEmpty);

    player.completePlayback(); // sentence 1 done
    player = await waitPendingPlay();
    // CROSS-CHUNK LOOKAHEAD: chunk 1 is still playing (sentence 2 now),
    // and chunk 2's FIRST sentence is already requested.
    expect(requests, contains('Bravo one.'));

    player.completePlayback(); // sentence 2 done
    player = await waitPendingPlay();
    // Chunk 1's LAST sentence plays; chunk 2's second is already rendering.
    expect(requests, contains('Bravo two.'));

    player.completePlayback(); // sentence 3 (chunk 1's last) done
    player = await waitPendingPlay();
    player.completePlayback(); // bravo one done
    player = await waitPendingPlay();
    player.completePlayback(); // bravo two done
    await done.future.timeout(const Duration(seconds: 5));

    // The chunk callbacks fired in stream order across the boundary.
    expect(chunkStarts, [0, 1]);
    expect(sentenceStarts, [
      (0, 0),
      (0, 1),
      (0, 2),
      (1, 0),
      (1, 1),
    ]);
    // The slot readout printed per chunk (the requested config).
    expect(
        lines.where((l) => l.contains('playback slot=standard lang=en')).length,
        2);
    // flutter_tts NEVER spoke on the Kokoro path.
    expect(ttsCalls.where((c) => c == 'speak'), isEmpty);
  });

  test('blend slot (depth 4 — the doubled budget): the whole next page '
      'renders while the current chunk plays', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    TtsService.readoutSink = (_) {};

    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Alpha one. Alpha two. Alpha three.',
            lang: 'en',
            voice: KokoroVoice.bible),
        AudioChunk(
            text: 'Bravo one. Bravo two.',
            lang: 'en',
            voice: KokoroVoice.bible),
      ],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));

    // THE BLEND BUDGET (double): while sentence 1 PLAYS, the lookahead has
    // already issued FOUR renders — including BOTH of chunk 2's sentences.
    // The cross-chunk lookahead is the point: chunk 2 renders while chunk
    // 1 plays, so the boundary costs no synthesis silence.
    final player = await waitPendingPlay();
    expect(requests, [
      'Alpha one.',
      'Alpha two.',
      'Alpha three.',
      'Bravo one.',
      'Bravo two.',
    ]);

    for (var i = 0; i < 4; i++) {
      player.completePlayback();
      await waitPendingPlay();
    }
    player.completePlayback();
    await done.future.timeout(const Duration(seconds: 5));
  });

  test('mid-stream synthesis failure: that chunk falls back to flutter_tts '
      'and the stream continues with the next chunk', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      if (text == 'Alpha two.') return null; // the mid-stream failure
      return audioFor(text);
    };
    final lines = <String>[];
    TtsService.readoutSink = lines.add;

    final sentenceStarts = <(int, int)>[];
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Alpha one. Alpha two. Alpha three.',
            lang: 'en',
            voice: KokoroVoice.standard),
        AudioChunk(text: 'Bravo one.', lang: 'en', voice: KokoroVoice.standard),
      ],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (ci, si) => sentenceStarts.add((ci, si)),
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));

    var player = await waitPendingPlay();
    player.completePlayback(); // sentence 1 done
    // The failure fired: the FALLBACK line names the system voice, the
    // chunk's remainder went to flutter_tts, and the stream CONTINUED —
    // chunk 2's sentence is requested through Kokoro again.
    await waitFor(() => lines.any((l) => l.contains('FALLBACK mid-pipeline')));
    expect(ttsCalls.where((c) => c == 'speak'), isNotEmpty);
    expect(requests, contains('Bravo one.'));

    player = await waitPendingPlay();
    player.completePlayback(); // bravo one done
    await done.future.timeout(const Duration(seconds: 5));
    // The fallback's remainder started at the failed sentence; chunk 2
    // played through the pipeline.
    expect(sentenceStarts, contains((1, 0)));
  });

  test('prefetch: the cache serves a later playback of the same content '
      'without a new synthesis request', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };

    const hailMary =
        'Hail Mary, full of grace. Blessed art thou amongst women.';
    // The rosary's next-step prefetch (fire-and-forget).
    unawaited(TtsService.prefetch(hailMary, 'en', KokoroVoice.rosary));
    await waitFor(() => requests.length >= 2);
    expect(requests.length, 2);

    final before = requests.length;
    // A playback of the SAME content consumes the cache: no new requests.
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [AudioChunk(text: hailMary, lang: 'en', voice: KokoroVoice.rosary)],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));
    var player = await waitPendingPlay();
    player.completePlayback();
    player = await waitPendingPlay();
    player.completePlayback();
    await done.future.timeout(const Duration(seconds: 5));
    expect(requests.length, before,
        reason: 'the prefetch cache served the playback — no new synthesis');
  });
}
