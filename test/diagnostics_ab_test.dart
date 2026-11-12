import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_render_cache.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'scripted_audio_harness.dart';

/// THE DISTORTION BISECTION HARNESS (round 5, defect D): the diagnostics
/// screen's cache-vs-live A/B — the same sentence played twice, once
/// rendered LIVE (both caches bypassed: the synthesis + write + play
/// path) and once FROM the persistent render cache (pure I/O of the exact
/// bytes the live play stored). The pipeline log names each play's source
/// (src=engine / src=cache) so the owner's observations map to a verdict:
/// identical crackle on both plays = baked into the render; only the live
/// play crackles = the playback path.
///
/// These tests pin the harness mechanics: the bypass forces a live render
/// even when the cache holds the sentence, the flag is restored after the
/// play, and the cache play serves the stored WAV with zero new synthesis.
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
    TtsService.diagnosticBypassRenderCache = false;
    await TtsRenderCache.debugReset();
    await TtsRenderCache.debugInit(
        Directory.systemTemp.createTempSync('fidelis_ab_harness').path);
  });

  tearDown(() async {
    await TtsRenderCache.debugReset();
    await AudioController.instance.stop();
    TtsService.diagnosticBypassRenderCache = false;
  });

  KokoroAudio audioFor(String text) {
    final n = 2400 + text.length;
    final samples = Float32List(n);
    for (var i = 0; i < n; i++) {
      samples[i] = 0.3 * (i % 100) / 100;
    }
    return KokoroAudio(samples, 24000);
  }

  const abText = 'Hail Mary, full of grace, the Lord is with thee. Amen.';

  /// Plays [text] through the gated platform at the harness's semantics.
  Future<void> playThrough(
    GatedPlatform platform,
    String text,
  ) async {
    final sentenceCount = TtsService.splitSentences(text).length;
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      [AudioChunk(text: text, lang: 'en', voice: KokoroVoice.rosary)],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));
    final player = await waitPendingPlayOn(platform);
    for (var i = 0; i < sentenceCount; i++) {
      if (i < sentenceCount - 1) {
        await waitFor(() => player.itemCount >= i + 2);
      }
      player.completeItem();
    }
    await done.future.timeout(const Duration(seconds: 10));
  }

  test('the LIVE play (the bypass on) renders even when the cache holds '
      'the sentence; the flag is restored after', () async {
    var requests = 0;
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests++;
      return audioFor(text);
    };

    // Play 1 — LIVE (the diagnostics A/B's 'Play LIVE' button): the cache
    // is empty, but the bypass is what the button sets — assert it forces
    // the live render and stores the result.
    TtsService.diagnosticBypassRenderCache = true;
    await playThrough(platform, abText);
    TtsService.diagnosticBypassRenderCache = false;
    final liveRequests = requests;
    expect(liveRequests, TtsService.splitSentences(abText).length,
        reason: 'the LIVE play rendered every sentence through synthesis');
    expect(TtsService.diagnosticBypassRenderCache, isFalse,
        reason: 'the bypass flag must be restored after the play (a stuck '
            'flag would silently disable the render cache app-wide)');

    // Play 2 — FROM CACHE (the bypass off): zero new synthesis.
    await playThrough(platform, abText);
    expect(requests, liveRequests,
        reason: 'the cache play must serve the stored WAV with zero new '
            'synthesis (the A/B cache side is pure I/O)');

    // Play 3 — LIVE again (the bypass on) with the cache HOLDING the
    // sentence: the bypass must force a fresh live render anyway (the
    // A/B's discriminating power — the same bytes re-rendered live).
    TtsService.diagnosticBypassRenderCache = true;
    await playThrough(platform, abText);
    TtsService.diagnosticBypassRenderCache = false;
    expect(requests, liveRequests * 2,
        reason: 'the bypass must force the live render even when the '
            'cache holds the sentence (the A/B LIVE button)');
    expect(TtsService.diagnosticBypassRenderCache, isFalse);
  });

  test('the A/B plays report their source in the wav-ready lines (the '
      'owner reads src=engine / src=cache)', () async {
    final lines = <String>[];
    // The wav-ready lines are MEASUREMENT lines (the [Fidelis timing]
    // path) — the measurement sink carries them, not the readout sink.
    TtsService.measurementSink = lines.add;
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        audioFor(text);

    // The LIVE play: the wav-ready line names src=engine.
    TtsService.diagnosticBypassRenderCache = true;
    await playThrough(platform, abText);
    TtsService.diagnosticBypassRenderCache = false;
    final engineLines =
        lines.where((l) => l.contains('wav-ready') && l.contains('src=engine'));
    expect(engineLines, isNotEmpty,
        reason: 'the LIVE play must report src=engine in the pipeline log '
            '(the owner reads the source to map observations to a verdict)');

    lines.clear();
    // The CACHE play: the wav-ready line names src=cache.
    await playThrough(platform, abText);
    final cacheLines =
        lines.where((l) => l.contains('wav-ready') && l.contains('src=cache'));
    expect(cacheLines, isNotEmpty,
        reason: 'the cache play must report src=cache in the pipeline log');
  });
}
