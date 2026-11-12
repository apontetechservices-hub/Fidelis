import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/render_ahead.dart';
import 'package:fidelis/services/tts_render_cache.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'scripted_audio_harness.dart';

/// THE RENDER-AHEAD YIELD (round 5, the Bible/rosary latency asymmetry and
/// the frontier stalls): the worker is FIFO — a walk render issued while
/// the playback pipeline has synthesis in flight would queue ahead of the
/// pipeline's FUTURE lookahead requests and halve the playback's synthesis
/// throughput. The rosary's step pipeline covers only the CURRENT step, so
/// the whole-rosary walk's theft starved the step's own frontier; the
/// Bible's pipeline covers the whole chapter, so its walk only ever
/// deduped onto the pipeline's own renders — the measured asymmetry.
///
/// The fix: the walk YIELDS while [TtsService.liveEngineRenders] is
/// non-zero — the pipeline's renders land first, the walk fills the idle
/// capacity; cache-hit stretches leave the gap open instantly. The second
/// half of the fix (the screens re-target the walk BEFORE the playback
/// start) is pinned by the composition tests in render_ahead_test.dart's
/// suite shape: a jump supersedes the old walk immediately, so the target
/// sentence's own renders win the worker.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ttsCalls = installPipelineChannelMocks();
  final platform = GatedPlatform();
  JustAudioPlatform.instance = platform;

  setUp(() async {
    ttsCalls.clear();
    KokoroEngine.resetForTest();
    TtsService.readoutSink = null;
    TtsService.debugResetPrefetchState();
    await TtsRenderCache.debugReset();
    await TtsRenderCache.debugInit(
        Directory.systemTemp.createTempSync('fidelis_render_yield').path);
  });

  tearDown(() async {
    await TtsRenderCache.debugReset();
    await AudioController.instance.stop();
  });

  KokoroAudio audioFor(String text) {
    final n = 2400 + text.length;
    final samples = Float32List(n);
    for (var i = 0; i < n; i++) {
      samples[i] = 0.3 * (i % 100) / 100;
    }
    return KokoroAudio(samples, 24000);
  }

  test('the walk yields: no walk render issues while the playback pipeline '
      'has synthesis in flight', () async {
    // The scripted synthesis records the issue/land order; each render
    // takes real time so the walk's 50 ms yield poll observes the demand.
    final events = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      events.add('start:$text');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      events.add('end:$text');
      return audioFor(text);
    };

    // The playback pipeline: two Alpha sentences (its own lookahead keeps
    // liveEngineRenders non-zero while they render).
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Alpha one. Alpha two.',
            lang: 'en',
            voice: KokoroVoice.standard),
      ],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));
    final player = await waitPendingPlayOn(platform);

    // The walk: two Bravo sentences — DIFFERENT content, so no dedupe:
    // every walk render would be a NEW worker request (the theft).
    RenderAhead.begin(
      chunks: const [
        AudioChunk(
            text: 'Bravo one. Bravo two.',
            lang: 'en',
            voice: KokoroVoice.standard),
      ],
      lang: 'en',
      label: 'yield-test',
    );
    await RenderAhead.debugWaitIdle();

    // THE YIELD: the walk's first render started only after the pipeline's
    // last render ENDED (the demand hit zero) — the pipeline's frontier
    // renders were never queued behind walk requests.
    expect(
        events.indexOf('start:Bravo one.'),
        greaterThan(events.indexOf('end:Alpha two.')),
        reason: 'the walk must yield while the playback pipeline has '
            'synthesis in flight (the FIFO worker: a walk render issued '
            'mid-pipeline queues ahead of the pipeline\'s future lookahead '
            'requests and starves the frontier)');
    // The pipeline still rendered everything (the yield never starves the
    // pipeline itself).
    expect(events, containsAll(const [
      'start:Alpha one.',
      'end:Alpha one.',
      'start:Alpha two.',
      'end:Alpha two.',
    ]));
    // The walk rendered its own content after the gap opened.
    expect(events, containsAll(const ['start:Bravo one.', 'end:Bravo two.']));

    // Finish the playback cleanly.
    await waitFor(() => player.itemCount >= 2);
    player.completeItem();
    player.completeItem();
    await done.future.timeout(const Duration(seconds: 10));
  });

  test('the walk proceeds freely when the pipeline serves cache hits (the '
      'gap is open instantly)', () async {
    // Render the Alpha sentences once (populating the persistent cache).
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        audioFor(text);
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Cache one. Cache two.',
            lang: 'en',
            voice: KokoroVoice.standard),
      ],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));
    final player = await waitPendingPlayOn(platform);
    await waitFor(() => player.itemCount >= 2);
    player.completeItem();
    player.completeItem();
    await done.future.timeout(const Duration(seconds: 10));

    // A SECOND playback of the same content: every sentence is a cache
    // hit — zero live renders — so a concurrent walk must NOT wait.
    final events = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      events.add('start:$text');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      events.add('end:$text');
      return audioFor(text);
    };
    final done2 = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Cache one. Cache two.',
            lang: 'en',
            voice: KokoroVoice.standard),
      ],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done2.complete()));
    final player2 = await waitPendingPlayOn(platform);

    final walkStart = DateTime.now();
    RenderAhead.begin(
      chunks: const [
        AudioChunk(
            text: 'Fresh one. Fresh two.',
            lang: 'en',
            voice: KokoroVoice.standard),
      ],
      lang: 'en',
      label: 'cache-gap-test',
    );
    await RenderAhead.debugWaitIdle();
    final walkMs = DateTime.now().difference(walkStart).inMilliseconds;

    // The walk rendered its fresh content without waiting on the cache-hit
    // playback (the demand counter never rose — the walk's own two renders
    // dominate the elapsed time; a 50 ms poll granularity bounds the
    // overhead, so anything under ~1 s proves no pipeline-demand wait).
    expect(walkMs, lessThan(1000),
        reason: 'the walk must proceed freely while the playback serves '
            'cache hits (the yield only waits for LIVE renders)');
    expect(events, containsAll(const ['start:Fresh one.', 'end:Fresh two.']));

    await waitFor(() => player2.itemCount >= 2);
    player2.completeItem();
    player2.completeItem();
    await done2.future.timeout(const Duration(seconds: 10));
  });
}
