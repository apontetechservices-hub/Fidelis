import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/bible_service.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'scripted_audio_harness.dart';

/// THE ROUND-3 PLAYBACK MEASUREMENT (defect A + defect B): the REAL
/// pipeline — the real Kokoro engine (sherpa-onnx, the bundled INT8
/// model), the real synthesis worker, the real gain-staged WAV prep, the
/// real playlist wiring — driven on the host through the same code path
/// the device runs, with REALTIME playback pacing. The measurement lines
/// ([TtsService.measurementSink] — the same lines logcat carries on the
/// device) are aggregated and printed:
///
///   - the Play-press → play-called latency (cold vs prefetched);
///   - the per-sentence synthesis wall times vs their audio durations;
///   - the chunk-to-chunk gaps under realtime playback (the frontier
///     waits — the audible-gap equivalent);
///   - the gain staging: the synthesis peak vs the post-conversion peak
///     per sentence (the before/after evidence), the clip counts.
///
/// GATED: the run needs the host sherpa native lib on the loader path and
/// the pre-warmed model dir:
///
///   FIDELIS_MEASURE_PLAYBACK=1 \
///   LD_LIBRARY_PATH=/home/chris/.pub-cache/hosted/pub.dev/sherpa_onnx_linux-1.13.8/linux/x64 \
///   flutter test test/playback_measurement_test.dart
///
/// The model dir: /tmp/fidelis_kokoro_readout/kokoro (the pre-warmed copy
/// carrying the current stamp; the engine's prep is re-pointed there).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final gated = Platform.environment['FIDELIS_MEASURE_PLAYBACK'] == '1' &&
      Platform.environment['LD_LIBRARY_PATH'] != null;
  final ttsCalls = installPipelineChannelMocks();
  final platform = GatedPlatform();
  JustAudioPlatform.instance = platform;

  /// The measurement line collector (installed per scenario by setUp).
  final lines = <String>[];

  setUp(() {
    ttsCalls.clear();
    KokoroEngine.resetForTest();
    TtsService.readoutSink = null;
    TtsService.debugResetPrefetchState();
    // The measurement sink: the pipeline's timing/peak lines collect here
    // (the same lines logcat carries on the device).
    TtsService.measurementSink = lines.add;
    // The pre-warmed model dir (the current stamp) — the engine's asset
    // preparation verifies it and skips the copy.
    KokoroEngine.debugPrepDirOverride = '/tmp/fidelis_kokoro_readout/kokoro';
  });

  tearDown(() {
    TtsService.measurementSink = null;
  });

  /// Waits (real time) until [predicate] holds or ~[seconds] elapse.
  Future<bool> waitFor(bool Function() predicate, {int seconds = 120}) async {
    for (var i = 0; i < seconds * 50; i++) {
      if (predicate()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return predicate();
  }

  List<String> kindOf() => lines
      .where((l) => l.startsWith('[Fidelis timing] '))
      .map((l) => l.substring('[Fidelis timing] '.length).split(' ').first)
      .toList();

  /// The wav-ready records: (index, synthMs, audioMs, src, peakIn, peakOut,
  /// clipIn, clipOut, scaled).
  List<(int, double, int, String, String, String, int, int, bool)>
      wavRecords() {
    final out = <(int, double, int, String, String, String, int, int, bool)>[];
    for (final l in lines) {
      if (!l.contains('wav-ready')) continue;
      double num(String field) {
        final m = RegExp(' $field=(-?[0-9.]+)').firstMatch(l);
        return m == null ? 0 : double.parse(m.group(1)!);
      }

      int intOf(String field) => num(field).round();
      final src = RegExp('src=(\\w+)').firstMatch(l)?.group(1) ?? '?';
      out.add((
        intOf('i'),
        num('synthMs'),
        intOf('audioMs'),
        src,
        RegExp('peakIn=(-?[0-9.inf]+)dB').firstMatch(l)?.group(1) ?? '?',
        RegExp('peakOut=(-?[0-9.inf]+)dB').firstMatch(l)?.group(1) ?? '?',
        intOf('clipIn'),
        intOf('clipOut'),
        l.contains('scaled=true'),
      ));
    }
    return out;
  }

  (int, double, int, String, String, String, int, int, bool) recordOf(int i) =>
      wavRecords().firstWhere(
          (r) => r.$1 == i,
          orElse: () => (i, 0, 0, '?', '', '', 0, 0, false));

  /// Waits for a pending play with a synthesis-scale timeout (a long
  /// sentence's first synthesis can exceed the harness's 4s default).
  Future<GatedPlayer> waitPendingPlayLong() async {
    await waitFor(
        () => platform.players.values.any((p) => p.hasPendingPlay),
        seconds: 300);
    return platform.players.values.firstWhere((p) => p.hasPendingPlay,
        orElse: () => throw StateError('no pending play'));
  }

  /// Plays the loaded playlist through at REALTIME pace (the caller has
  /// already awaited the play-called line — the clock starts there):
  /// item i's playback ends audioMs[i] after it started; the wait for
  /// item i+1's APPEND beyond that end is the audible-gap equivalent (the
  /// device sits in silence for exactly that long — the playlist cannot
  /// advance into an unappended item). The durations parse lazily from
  /// the wav-ready lines (each render lands ahead of its playback —
  /// waiting for a late render IS the gap). Returns (gapCount, maxGapMs,
  /// totalGapMs).
  Future<(int, int, int)> playInRealtime(
      GatedPlayer player, int sentenceCount) async {
    int itemCount() => player.itemCount;
    var gaps = 0;
    var maxGapMs = 0;
    var totalGapMs = 0;
    final clock = Stopwatch()..start();
    var tPrev = clock.elapsedMilliseconds; // item 0's playback started
    var prevAudio = recordOf(0).$3;
    for (var i = 1; i < sentenceCount; i++) {
      final endAt = tPrev + prevAudio;
      final now = clock.elapsedMilliseconds;
      if (endAt > now) {
        await Future<void>.delayed(
            Duration(milliseconds: (endAt - now).round()));
      }
      final sw = Stopwatch()..start();
      await waitFor(() => itemCount() >= i + 1);
      final gapMs = sw.elapsedMilliseconds;
      if (gapMs > 10) {
        gaps++;
        if (gapMs > maxGapMs) maxGapMs = gapMs;
        totalGapMs += gapMs;
      }
      player.completeItem(); // the index advances into item i
      tPrev = clock.elapsedMilliseconds;
      prevAudio = recordOf(i).$3;
    }
    // The last item plays out, then the playlist completes.
    final endAt = tPrev + prevAudio;
    final now = clock.elapsedMilliseconds;
    if (endAt > now) {
      await Future<void>.delayed(
          Duration(milliseconds: (endAt - now).round()));
    }
    player.completeItem();
    return (gaps, maxGapMs, totalGapMs);
  }

  /// Drains a playback without pacing (the latency scenarios): wait for
  /// every append (the synthesis done), then advance through the playlist.
  Future<void> drain(GatedPlayer player, int sentenceCount) async {
    await waitFor(() => player.itemCount >= sentenceCount, seconds: 600);
    for (var i = 0; i < sentenceCount; i++) {
      player.completeItem();
    }
  }

  void printSummary(String title) {
    final records = wavRecords();
    if (records.isEmpty) {
      debugPrint('MEASURE $title: no wav-ready records');
      return;
    }
    final synth = records.map((r) => r.$2).toList();
    final audio = records.map((r) => r.$3).toList();
    final ratios = [
      for (var i = 0; i < records.length; i++)
        audio[i] > 0 ? synth[i] / audio[i] : 0.0
    ];
    double mean(List<double> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    final cacheHits = records.where((r) => r.$4 == 'cache').length;
    final engineRenders = records.where((r) => r.$4 == 'engine').length;
    double peakDb(String s) => s == '-inf' ? -99 : double.parse(s);
    final maxPeakIn = records
        .map((r) => peakDb(r.$5))
        .reduce((a, b) => a > b ? a : b);
    final maxPeakOut = records
        .map((r) => peakDb(r.$6))
        .reduce((a, b) => a > b ? a : b);
    final clipIn = records.fold<int>(0, (a, r) => a + r.$7);
    final clipOut = records.fold<int>(0, (a, r) => a + r.$8);
    final scaled = records.where((r) => r.$9).length;
    debugPrint('MEASURE $title');
    debugPrint('  sentences=${records.length} '
        'cacheHits=$cacheHits engineRenders=$engineRenders '
        'stagedDown=$scaled');
    debugPrint('  synthesis: mean=${mean(synth).toStringAsFixed(0)}ms '
        'max=${synth.fold(0.0, (a, b) => a > b ? a : b).toStringAsFixed(0)}ms '
        '| audio: mean=${mean(audio.map((e) => e.toDouble()).toList()).toStringAsFixed(0)}ms '
        'max=${audio.fold(0, (a, b) => a > b ? a : b)}ms');
    debugPrint('  synth/audio ratio: mean=${mean(ratios).toStringAsFixed(2)} '
        'max=${ratios.fold(0.0, (a, b) => a > b ? a : b).toStringAsFixed(2)} '
        '(>1 means synthesis slower than realtime — the starvation risk)');
    debugPrint('  peaks dBFS: synthesis max=${maxPeakIn.toStringAsFixed(1)} '
        'post-conversion max=${maxPeakOut.toStringAsFixed(1)}');
    debugPrint('  clipped samples (PAST full scale): synthesis=$clipIn '
        'post-conversion=$clipOut (0 = no crackle mechanism)');
  }

  test('the Bible chapter: the Play-press latency (cold vs prefetched), '
      'the realtime gaps, the synthesis timing, the gain staging',
      timeout: const Timeout(Duration(minutes: 45)),
      skip: gated
          ? false
          : 'engine-gated (FIDELIS_MEASURE_PLAYBACK=1 + LD_LIBRARY_PATH, '
              'the pre-warmed model dir)', () async {
    // The reference chapter: Psalms 22 (DR numbering — the shepherd
    // psalm, the previous rounds' comparison chapter).
    final books = await BibleService.books();
    final psalms = books.firstWhere((b) => b.key == 'Psalms');
    final verses = await BibleService.chapter(psalms, 22);
    debugPrint('MEASURE chapter: Psalms 22 — ${verses.length} verses');
    final text = verses.map((v) => v.text).join(' ');
    final sentenceCount = TtsService.splitSentences(text).length;
    debugPrint('MEASURE chapter: $sentenceCount sentences');

    // ---- the COLD Play latency: no prefetch — the Play press waits for
    // the first sentence's synthesis. ----
    lines.clear();
    final coldWatch = Stopwatch()..start();
    final coldDone = Completer<void>();
    unawaited(TtsService.speakSequence(
      [AudioChunk(text: text, lang: 'en', voice: KokoroVoice.bible)],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => coldDone.complete()));
    await waitPendingPlayLong();
    await waitFor(() => kindOf().contains('play-called'));
    debugPrint('MEASURE COLD Play-press → play-called: '
        '${coldWatch.elapsedMilliseconds} ms (the first synthesis included; '
        'the device adds its ExoPlayer prepare — the logcat loadMs)');
    await drain(platform.players.values.first, sentenceCount);
    await coldDone.future.timeout(const Duration(minutes: 10));

    // ---- the PREFETCHED Play latency: the screen-open prefetch renders
    // the opening sentences BEFORE Play (the cache serves them). ----
    lines.clear();
    unawaited(TtsService.prefetch(text, 'en', KokoroVoice.bible));
    // The prefetch renders into the CACHE (no playback WAVs — the
    // prefetch-land lines are its evidence).
    await waitFor(
        () => kindOf().where((k) => k == 'prefetch-land').length >=
            sentenceCount.clamp(1, 8),
        seconds: 600);
    final prefetched = kindOf().where((k) => k == 'prefetch-land').length;
    debugPrint('MEASURE PREFETCH: $prefetched sentence(s) rendered ahead of '
        'Play (the screen-open prefetch engaged)');

    lines.clear();
    final warmWatch = Stopwatch()..start();
    final warmDone = Completer<void>();
    unawaited(TtsService.speakSequence(
      [AudioChunk(text: text, lang: 'en', voice: KokoroVoice.bible)],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => warmDone.complete()));
    await waitPendingPlayLong();
    await waitFor(() => kindOf().contains('play-called'));
    debugPrint('MEASURE PREFETCHED Play-press → play-called: '
        '${warmWatch.elapsedMilliseconds} ms (the cache hit — the device '
        'adds its ExoPlayer prepare)');
    await drain(platform.players.values.first, sentenceCount);
    await warmDone.future.timeout(const Duration(minutes: 10));

    // ---- the FULL CHAPTER at REALTIME pace: the gaps (the audible-gap
    // equivalent), the synthesis timing, the gain staging. ----
    lines.clear();
    final chapterWatch = Stopwatch()..start();
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      [AudioChunk(text: text, lang: 'en', voice: KokoroVoice.bible)],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    ).then((_) => done.complete()));
    final player = await waitPendingPlayLong();
    await waitFor(() => kindOf().contains('play-called'));
    final playLatency = chapterWatch.elapsedMilliseconds;
    final (gaps, maxGapMs, totalGapMs) =
        await playInRealtime(player, sentenceCount);
    await done.future.timeout(const Duration(minutes: 10));
    debugPrint('MEASURE CHAPTER Play-press → play-called (warm engine): '
        '$playLatency ms');
    debugPrint('MEASURE CHAPTER realtime gaps: $gaps sentence boundary(ies) '
        'waited for synthesis (max ${maxGapMs}ms, total ${totalGapMs}ms) '
        'across ${sentenceCount - 1} boundaries — 0 means verse-to-verse '
        'continuous at the host\'s synthesis speed');
    printSummary('CHAPTER (Psalms 22, bible slot, EN)');

    // The gain-staging invariants hold on the REAL synthesis output.
    for (final r in wavRecords()) {
      final peakOut =
          r.$6 == '-inf' ? -99.0 : double.parse(r.$6);
      expect(peakOut, lessThanOrEqualTo(0.0),
          reason: 'wav ${r.$1}: the post-conversion peak must sit below '
              '0 dBFS (the headroom guarantee) — got $peakOut dBFS');
      expect(r.$8, 0,
          reason: 'wav ${r.$1}: no post-conversion sample past full scale');
    }
  });

  test('the rosary decade: the step latencies (the prefetch cache), the '
      'realtime gaps, the synthesis timing, the gain staging',
      timeout: const Timeout(Duration(minutes: 45)),
      skip: gated
          ? false
          : 'engine-gated (FIDELIS_MEASURE_PLAYBACK=1 + LD_LIBRARY_PATH, '
              'the pre-warmed model dir)', () async {
    // The decade's steps: the announcement, the Our Father, ten Hail
    // Marys, the Glory Be — the rosary's repeating unit (a full rosary =
    // this structure per mystery; the repeats hit the prefetch cache).
    const announcement = 'The first joyful mystery: The Annunciation. '
        'And the angel said to her: Fear not, Mary, for thou hast found '
        'grace with God.';
    const ourFather =
        'Our Father, who art in heaven, hallowed be thy name; thy kingdom '
        'come; thy will be done on earth as it is in heaven. Give us this '
        'day our daily bread; and forgive us our trespasses as we forgive '
        'those who trespass against us; and lead us not into temptation, '
        'but deliver us from evil. Amen.';
    const hailMary =
        'Hail Mary, full of grace, the Lord is with thee. Blessed art thou '
        'amongst women, and blessed is the fruit of thy womb, Jesus. Holy '
        'Mary, Mother of God, pray for us sinners, now and at the hour of '
        'our death. Amen.';
    const gloryBe =
        'Glory be to the Father, and to the Son, and to the Holy Ghost. As '
        'it was in the beginning, is now, and ever shall be, world without '
        'end. Amen.';
    final steps = <String>[
      announcement,
      ourFather,
      for (var i = 0; i < 10; i++) hailMary,
      gloryBe,
    ];
    debugPrint('MEASURE decade: ${steps.length} steps');

    final stepLatencies = <int>[];
    var totalGaps = 0;
    var maxGapMs = 0;
    for (var step = 0; step < steps.length; step++) {
      // The screen-open/next-step prefetch (the rosary screen prefetches
      // the CURRENT step on open and the NEXT step while playing).
      if (step + 1 < steps.length) {
        unawaited(
            TtsService.prefetch(steps[step + 1], 'en', KokoroVoice.rosary));
      }
      lines.clear();
      final watch = Stopwatch()..start();
      final done = Completer<void>();
      unawaited(TtsService.speakSequence(
        [AudioChunk(text: steps[step], lang: 'en', voice: KokoroVoice.rosary)],
        lang: 'en',
        onChunkStart: (_) {},
        onSentenceStart: (_, _) {},
        onSentenceTiming: (_, _, _, _) {},
        onSentenceSynthesized: (_, _, _) {},
        onWordRange: (_, _, _) {},
      ).then((_) => done.complete()));
      final player = await waitPendingPlayLong();
      await waitFor(() => kindOf().contains('play-called'));
      stepLatencies.add(watch.elapsedMilliseconds);
      final sentenceCount = TtsService.splitSentences(steps[step]).length;
      final (gaps, maxStepGap, _) = await playInRealtime(player, sentenceCount);
      totalGaps += gaps;
      if (maxStepGap > maxGapMs) maxGapMs = maxStepGap;
      await done.future.timeout(const Duration(minutes: 10));
    }
    debugPrint('MEASURE DECADE step latencies (Play-press → play-called): '
        '${stepLatencies.join(", ")} ms — the repeats (the ten Hail Marys) '
        'hit the prefetch cache and start instantly');
    debugPrint('MEASURE DECADE realtime gaps: $totalGaps prayer boundary(ies) '
        'waited for synthesis (max ${maxGapMs}ms) — 0 means '
        'prayer-to-prayer continuous');
    printSummary('DECADE (rosary slot, EN)');
  });
}
