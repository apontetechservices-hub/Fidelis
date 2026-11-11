import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'scripted_audio_harness.dart';

/// THE PAUSE INSTRUMENTATION (round 3, defect A): the playback pipeline's
/// real timestamps and PCM peaks surface through
/// [TtsService.measurementSink] — the same lines logcat carries on the
/// device (`adb logcat -s flutter | grep 'Fidelis timing'`), the
/// measurement path the round-3 numbers come from. This test pins the
/// event sequence and the gain-staging fields so the instrumentation
/// cannot silently regress: the Play-press decomposition (play-request →
/// ensure-ready → stream-built → wav-ready → segment-start(loadMs/eqMs) →
/// play-called), the per-sentence renders with their synthesis wall times
/// and prefetch-source markers, and the sentence-start gaps.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ttsCalls = installPipelineChannelMocks();
  final platform = GatedPlatform();
  JustAudioPlatform.instance = platform;

  setUp(() {
    ttsCalls.clear();
    KokoroEngine.resetForTest();
    TtsService.readoutSink = null;
    TtsService.debugResetPrefetchState();
  });

  KokoroAudio audioFor(String text) {
    final n = 2400 + text.length;
    final samples = Float32List(n);
    for (var i = 0; i < n; i++) {
      samples[i] = 0.3 * (i % 100) / 100;
    }
    return KokoroAudio(samples, 24000);
  }

  String kindOf(String line) =>
      line.substring('[Fidelis timing] '.length).split(' ').first;

  test('the measurement lines carry the full event sequence and the '
      'gain-staging fields', () async {
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        audioFor(text);
    final timing = <String>[];
    TtsService.measurementSink = timing.add;
    addTearDown(() => TtsService.measurementSink = null);

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
    await waitFor(() => player.itemCount >= 2);
    player.completeItem();
    player.completeItem();
    await done.future.timeout(const Duration(seconds: 5));

    final kinds = timing.map(kindOf).toList();
    for (final k in [
      'play-request',
      'ensure-ready',
      'stream-built',
      'wav-ready',
      'segment-start',
      'play-called',
      'sentence-start',
      'stream-done',
    ]) {
      expect(kinds, contains(k), reason: 'the $k event must be measured');
    }
    // The Play-press decomposition: the request precedes the build, the
    // build precedes the first render, the render precedes the load, the
    // load precedes the play call.
    final iReq = kinds.indexOf('play-request');
    final iBuilt = kinds.indexOf('stream-built');
    final iWav = kinds.indexOf('wav-ready');
    final iSeg = kinds.indexOf('segment-start');
    final iPlay = kinds.indexOf('play-called');
    expect(iReq, lessThan(iBuilt), reason: timing.join('\n'));
    expect(iBuilt, lessThan(iWav), reason: timing.join('\n'));
    expect(iWav, lessThan(iSeg), reason: timing.join('\n'));
    expect(iSeg, lessThan(iPlay), reason: timing.join('\n'));

    // The gain-staging fields ride every wav-ready line (the synthesis
    // wall time, the prefetch source, the peaks, the clip counts, the
    // staging flag, the write latency).
    final wavLines =
        timing.where((l) => l.contains('wav-ready')).toList();
    expect(wavLines, isNotEmpty);
    for (final line in wavLines) {
      for (final field in [
        'synthMs=',
        'audioMs=',
        'src=',
        'peakIn=',
        'peakOut=',
        'clipIn=',
        'clipOut=',
        'scaled=',
        'writeMs=',
      ]) {
        expect(line, contains(field), reason: line);
      }
    }
    // The segment start carries the load and EQ latencies (the Play-press
    // decomposition's player-side terms).
    final seg = timing.firstWhere((l) => l.contains('segment-start'));
    expect(seg, contains('loadMs='), reason: seg);
    expect(seg, contains('eqMs='), reason: seg);
  });

  test('the prefetch engagement marker: a prefetched playback renders '
      'src=cache (no synthesis waited before the first sample)', () async {
    TtsService.debugResetPrefetchState();
    const hailMary =
        'Hail Mary, full of grace. Blessed art thou amongst women.';
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    // The screen-open prefetch (fire-and-forget) renders the opening
    // sentences BEFORE Play.
    unawaited(TtsService.prefetch(hailMary, 'en', KokoroVoice.rosary));
    await waitFor(() => requests.length >= 2);

    final timing = <String>[];
    TtsService.measurementSink = timing.add;
    addTearDown(() => TtsService.measurementSink = null);

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

    final player = await waitPendingPlayOn(platform);
    await waitFor(() => player.itemCount >= 2);
    player.completeItem();
    player.completeItem();
    await done.future.timeout(const Duration(seconds: 5));

    final wavLines =
        timing.where((l) => l.contains('wav-ready')).toList();
    expect(wavLines, isNotEmpty);
    expect(wavLines.every((l) => l.contains('src=cache')), isTrue,
        reason: 'the prefetched audio served the playback — the measurement '
            'proves the prefetch engaged (no synthesis waited)');
  });

  test('the engine-served marker: without a prefetch the renders name '
      'src=engine (the synthesis the Play press waited on)', () async {
    TtsService.debugResetPrefetchState();
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        audioFor(text);
    final timing = <String>[];
    TtsService.measurementSink = timing.add;
    addTearDown(() => TtsService.measurementSink = null);

    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Glory be to the Father.',
            lang: 'en',
            voice: KokoroVoice.rosary),
      ],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));

    final player = await waitPendingPlayOn(platform);
    player.completeItem();
    await done.future.timeout(const Duration(seconds: 5));

    final wavLines =
        timing.where((l) => l.contains('wav-ready')).toList();
    expect(wavLines, isNotEmpty);
    expect(wavLines.every((l) => l.contains('src=engine')), isTrue,
        reason: 'no prefetch: the renders came from the engine');
  });
}
