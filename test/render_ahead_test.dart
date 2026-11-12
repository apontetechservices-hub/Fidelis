import 'dart:async';
import 'dart:convert';
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

/// THE RENDER-AHEAD ARCHITECTURE (round 4, defect A): the whole chapter or
/// rosary renders to completion in the BACKGROUND (begun on screen-open
/// and on every Play) into the PERSISTENT render cache, and playback plays
/// from COMPLETED audio — a Play press, a verse boundary, and a
/// Next/Previous restart all resolve from cached files with zero
/// synthesis. The suites pin the three new mechanics:
///
///   1. the persistent cache (the keying, the LRU eviction, the
///      cache-hit lookup, the inert-until-initialized lifecycle);
///   2. the render-ahead service (the whole-stream walk without
///      playback, the latest-wins supersede, the cache-hit skip);
///   3. play-from-completed-audio (zero new synthesis after the
///      render-ahead, the Next-from-cache restart, the schedule from the
///      cached synthesis).
///
/// The synthesis is scripted ([KokoroEngine.debugSynthesizeOverride]); the
/// render cache runs against a REAL temp directory (the only way the
/// cache activates in tests — production wires it in main.dart, and the
/// existing suites' isolation depends on it staying inert there).
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
        Directory.systemTemp.createTempSync('fidelis_render_cache').path);
  });

  tearDown(() async {
    await TtsRenderCache.debugReset();
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

  /// The persistent cache key for one sentence (the same derivation the
  /// pipeline uses — the stable voice identity, never an identity hash).
  String keyOf(String sentence, String lang, KokoroVoice voice) =>
      TtsRenderCache.keyFor(
        lang: lang,
        voiceId:
            '${voice.nameFor(lang)}(${voice.sidFor(lang)})@${voice.speed}',
        text: sentence,
      );

  /// Waits (real time) until [predicate] holds or ~4s elapse.
  Future<bool> waitFor(bool Function() predicate) async {
    for (var i = 0; i < 200; i++) {
      if (predicate()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return predicate();
  }

  const alpha = 'Alpha one. Alpha two.';
  const bravo = 'Bravo one. Bravo two.';

  /// Plays [chunks] through the gated platform at the harness's semantics:
  /// each item completes in turn (waiting for the NEXT item's append
  /// first — the playlist auto-advance only happens within the loaded
  /// playlist), the last item completes the whole playback.
  Future<void> playThrough(
    GatedPlatform platform,
    List<AudioChunk> chunks,
    String lang, {
    void Function(int, int, Duration)? onSynthesized,
  }) async {
    final sentenceCount = TtsService.splitSentences(
            chunks.map((c) => c.text ?? '').join(' '))
        .length;
    final done = Completer<void>();
    unawaited(TtsService.speakSequence(
      chunks,
      lang: lang,
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: onSynthesized ?? (_, _, _) {},
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

  // ------------------------------------------------------------------
  // 1. THE PERSISTENT RENDER CACHE
  // ------------------------------------------------------------------

  test('the cache is inert until initialized: lookups and stores no-op',
      () async {
    await TtsRenderCache.debugReset(); // no init: the production-not-wired state
    expect(TtsRenderCache.isReady, isFalse);
    expect(TtsRenderCache.lookupSync(keyOf('Alpha one.', 'en',
        KokoroVoice.bible), expectText: 'Alpha one.'), isNull);
    final stored = await TtsRenderCache.store(
      key: keyOf('Alpha one.', 'en', KokoroVoice.bible),
      text: 'Alpha one.',
      lang: 'en',
      voiceId: 'am_michael(16)@0.81',
      durationMs: 1000,
      wav: Uint8List(44),
      peakInDb: '-3.0',
      peakOutDb: '-6.0',
      clipIn: 0,
      clipOut: 0,
      scaled: false,
    );
    expect(stored, isNull, reason: 'the inert cache stores nothing');
  });

  test('a rendered sentence is stored and served: the wav, the record, '
      'the timing data', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    await playThrough(platform, const [
      AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
    ], 'en');
    // Both sentences stored: the wav + the json record per sentence.
    final key1 = keyOf('Alpha one.', 'en', KokoroVoice.bible);
    final stats = await TtsRenderCache.stats();
    expect(stats['ready'], isTrue);
    expect(stats['entries'], 2,
        reason: 'every rendered sentence is a cache entry');
    // The lookup serves the entry with the recorded timing data (the
    // schedule comes from the same synthesis that produced the audio).
    final hit = TtsRenderCache.lookupSync(key1, expectText: 'Alpha one.');
    expect(hit, isNotNull);
    expect(hit!.duration.inMilliseconds,
        (2400 + 'Alpha one.'.length) * 1000 ~/ 24000);
    expect(hit.file.existsSync(), isTrue);
    // A different text does not serve (the record is verified per hit).
    expect(TtsRenderCache.lookupSync(key1, expectText: 'Alpha two.'), isNull);
    // A different voice's key does not collide.
    expect(
        TtsRenderCache.lookupSync(
            keyOf('Alpha one.', 'en', KokoroVoice.rosary),
            expectText: 'Alpha one.'),
        isNull,
        reason: 'the voice identity is part of the key');
    expect(requests, ['Alpha one.', 'Alpha two.']);
  });

  test('keying: the same sentence in another slot configuration renders '
      'again (a separate entry)', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    await playThrough(platform, const [
      AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
    ], 'en');
    final afterBible = requests.length;
    await playThrough(platform, const [
      AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.rosary),
    ], 'en');
    expect(requests.length, greaterThan(afterBible),
        reason: 'the rosary slot is a different voice identity — its '
            'sentences render into their own entries');
    final stats = await TtsRenderCache.stats();
    expect(stats['entries'], 4,
        reason: 'two sentences x two slot configurations');
  });

  test('LRU eviction: the least recently accessed entries evict at the '
      'cap; the active session survives', () async {
    // Five entries of ~1000 bytes each; the cap forces eviction of two.
    for (var i = 0; i < 5; i++) {
      await TtsRenderCache.store(
        key: 'k$i',
        text: 'sentence $i',
        lang: 'en',
        voiceId: 'am_michael(16)@0.81',
        durationMs: 1000,
        wav: Uint8List(1000),
        peakInDb: '-3.0',
        peakOutDb: '-6.0',
        clipIn: 0,
        clipOut: 0,
        scaled: false,
      );
    }
    // Backdate the access stamps deterministically (oldest first).
    final dir = Directory(
        (await TtsRenderCache.stats())['dir'] as String);
    for (var i = 0; i < 5; i++) {
      final f = File('${dir.path}/s_k$i.json');
      final map = jsonDecode(f.readAsStringSync()) as Map;
      map['a'] = 1000 * i;
      f.writeAsStringSync(jsonEncode(map));
    }
    // Touch k2 (a lookup re-stamps it): the active session's entry.
    expect(TtsRenderCache.lookupSync('k2', expectText: 'sentence 2'),
        isNotNull);
    TtsRenderCache.capBytes = 3500; // 5000 stored → evict 2000
    await TtsRenderCache.sweep();
    expect(File('${dir.path}/s_k0.wav').existsSync(), isFalse,
        reason: 'the least recently accessed entry evicts first');
    expect(File('${dir.path}/s_k1.wav').existsSync(), isFalse);
    expect(File('${dir.path}/s_k2.wav').existsSync(), isTrue,
        reason: 'the freshly touched (active-session) entry survives');
    expect(File('${dir.path}/s_k3.wav').existsSync(), isTrue);
    expect(File('${dir.path}/s_k4.wav').existsSync(), isTrue);
    final stats = await TtsRenderCache.stats();
    expect(stats['entries'], 3);
  });

  test('the sweep clears orphan files (a crashed store\u2019s half entry)',
      () async {
    final dir =
        Directory((await TtsRenderCache.stats())['dir'] as String);
    final orphan = File('${dir.path}/s_orphan.wav');
    orphan.writeAsBytesSync(Uint8List(500));
    orphan.setLastModifiedSync(
        DateTime.now().subtract(const Duration(hours: 2)));
    await TtsRenderCache.sweep();
    expect(orphan.existsSync(), isFalse, reason: 'the orphan sweeps');
  });

  // ------------------------------------------------------------------
  // 2. THE RENDER-AHEAD SERVICE
  // ------------------------------------------------------------------

  test('begin renders the whole stream to completion in the background '
      '— without any playback', () async {
    final requests = <String>[];
    final playersBefore = platform.players.length;
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    RenderAhead.begin(
      chunks: const [
        AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
        AudioChunk(text: bravo, lang: 'en', voice: KokoroVoice.bible),
      ],
      lang: 'en',
      label: 'bible test',
    );
    await RenderAhead.debugWaitIdle();
    expect(requests, ['Alpha one.', 'Alpha two.', 'Bravo one.', 'Bravo two.'],
        reason: 'the WHOLE content rendered to completion');
    final stats = await TtsRenderCache.stats();
    expect(stats['entries'], 4, reason: 'every render is cached');
    // NO PLAYBACK: the walk never touches the player (the player count is
    // unchanged — earlier tests' singleton player is the only one).
    final playersAfter = platform.players.length;
    expect(playersAfter, playersBefore,
        reason: 'the render-ahead is background preparation, not playback');
    expect(ttsCalls.where((c) => c == 'speak'), isEmpty);
  });

  test('the walk starts at fromSentence (the played position first)',
      () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    RenderAhead.begin(
      chunks: const [
        AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
        AudioChunk(text: bravo, lang: 'en', voice: KokoroVoice.bible),
      ],
      lang: 'en',
      fromSentence: 2, // the played verse's first sentence
    );
    await RenderAhead.debugWaitIdle();
    expect(requests, ['Bravo one.', 'Bravo two.'],
        reason: 'the walk renders from the played position forward');
  });

  test('the supersede: a new begin cancels the running walk (latest '
      'wins)', () async {
    final requests = <String>[];
    final release = Completer<void>();
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      if (text == 'Alpha two.') await release.future; // hold the walk here
      return audioFor(text);
    };
    RenderAhead.begin(
      chunks: const [
        AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
        AudioChunk(text: bravo, lang: 'en', voice: KokoroVoice.bible),
      ],
      lang: 'en',
      label: 'A',
    );
    await waitFor(() => requests.contains('Alpha two.'));
    // The user moved: the new content's walk supersedes the old one.
    RenderAhead.begin(
      chunks: const [
        AudioChunk(text: 'Charlie one.', lang: 'en', voice: KokoroVoice.bible),
      ],
      lang: 'en',
      label: 'B',
    );
    await waitFor(() => requests.contains('Charlie one.'));
    release.complete();
    await RenderAhead.debugWaitIdle(); // the CURRENT walk (B)
    // The old walk exits at its next checkpoint: it never rendered past
    // the held sentence — 'Bravo one.' and 'Bravo two.' are never
    // requested by it.
    expect(requests.contains('Bravo one.'), isFalse,
        reason: 'the superseded walk never rendered past its checkpoint');
    expect(requests.contains('Bravo two.'), isFalse,
        reason: 'the superseded walk never rendered past its checkpoint');
    expect(requests.contains('Charlie one.'), isTrue,
        reason: 'the new walk served the new content');
  });

  test('the cache-hit skip: a second begin of the same content renders '
      'nothing new', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    RenderAhead.begin(
      chunks: const [AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible)],
      lang: 'en',
    );
    await RenderAhead.debugWaitIdle();
    final afterFirst = requests.length;
    expect(afterFirst, 2);
    RenderAhead.begin(
      chunks: const [AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible)],
      lang: 'en',
    );
    await RenderAhead.debugWaitIdle();
    expect(requests.length, afterFirst,
        reason: 'the cached sentences skip instantly — zero new renders');
  });

  // ------------------------------------------------------------------
  // 3. PLAY FROM COMPLETED AUDIO
  // ------------------------------------------------------------------

  test('a playback after the render-ahead starts from the cache with '
      'ZERO new synthesis', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    RenderAhead.begin(
      chunks: const [
        AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
        AudioChunk(text: bravo, lang: 'en', voice: KokoroVoice.bible),
      ],
      lang: 'en',
    );
    await RenderAhead.debugWaitIdle();
    final before = requests.length;

    final timing = <String>[];
    TtsService.measurementSink = timing.add;
    addTearDown(() => TtsService.measurementSink = null);
    await playThrough(platform, const [
      AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
      AudioChunk(text: bravo, lang: 'en', voice: KokoroVoice.bible),
    ], 'en');
    expect(requests.length, before,
        reason: 'the play started from completed audio — no synthesis '
            'waited before the first sample or anywhere after');
    final wavLines =
        timing.where((l) => l.contains('wav-ready')).toList();
    expect(wavLines, isNotEmpty);
    expect(wavLines.every((l) => l.contains('src=cache')), isTrue,
        reason: 'every sentence served from the persistent render cache');
  });

  test('Next-from-cache: a playback restarted from a later sentence is '
      'instant (zero new synthesis)', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    // The whole content rendered ahead (the screen-open walk).
    RenderAhead.begin(
      chunks: const [
        AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
        AudioChunk(text: bravo, lang: 'en', voice: KokoroVoice.bible),
      ],
      lang: 'en',
    );
    await RenderAhead.debugWaitIdle();
    final before = requests.length;
    // The Next restart's shape: the job rebuilt from the target verse —
    // a DIFFERENT chunk slice of the same content. The target's sentences
    // are already cached: the restart is instant.
    await playThrough(platform, const [
      AudioChunk(text: bravo, lang: 'en', voice: KokoroVoice.bible),
    ], 'en');
    expect(requests.length, before,
        reason: 'the Next target resolved from the cached audio — no '
            'multi-second synthesis stall');
  });

  test('the cache-timing consistency: the schedule comes from the cached '
      'synthesis (the same durations, cached or live)', () async {
    final requests = <String>[];
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async {
      requests.add(text);
      return audioFor(text);
    };
    final liveDurations = <Duration>[];
    await playThrough(platform, const [
      AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
    ], 'en', onSynthesized: (_, _, d) => liveDurations.add(d));
    final cachedDurations = <Duration>[];
    await playThrough(platform, const [
      AudioChunk(text: alpha, lang: 'en', voice: KokoroVoice.bible),
    ], 'en', onSynthesized: (_, _, d) => cachedDurations.add(d));
    expect(cachedDurations, liveDurations,
        reason: 'the cached renders carry their synthesis timing — the '
            'highlight schedule is identical from the cache');
    expect(requests.length, 2,
        reason: 'the second play rendered nothing (all cache hits)');
  });
}
