import 'dart:async';
import 'dart:io';
import 'dart:math' show ln10, log;

import 'package:flutter/foundation.dart'
    show debugPrint, visibleForTesting;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_controller.dart' show AudioChunk;
import 'kokoro_engine.dart';
import 'tts_text.dart' as tts_text;

/// On-device text-to-speech for prayer audio (free feature).
///
/// Two engines:
///  - Kokoro (sherpa-onnx, bundled on-device): per-slot voice-grid profiles
///    — the standard voices (EN bm_george / ES em_alex at speed 0.9) for
///    readings and the rosary's timing-only synthesis, the Bible profile
///    (EN am_michael / ES em_alex at speed 0.81) when the caller passes
///    [KokoroVoice.bible], and the rosary's runtime slot
///    ([KokoroVoice.rosary] — EN af_aoede / ES af_aoede under Spanish
///    phonemization) for steps without a pre-rendered file — synthesized
///    SENTENCE-BY-SENTENCE so playback starts after the first sentence
///    and later sentences are generated while the current one plays.
///    Every slot is a single voice: one render per sentence, no blends.
///    stop() interrupts cleanly between sentences. Used for 'en'/'es'.
///  - flutter_tts (system engine): Latin ('la' — Italian voice approximates
///    ecclesiastical pronunciation) and the fallback whenever Kokoro is
///    unavailable or fails, so audio NEVER breaks. The mature male-voice
///    selection below is kept intact for that path.
///
/// A mature male voice is preferred on the flutter_tts path: known male Google
/// TTS voice codenames are applied per locale when the device actually exposes
/// them, and the pitch is lowered slightly so the active voice reads as
/// mature. When no male voice is available the engine default is kept —
/// selection never throws and never blocks speech.
class TtsService {
  static final FlutterTts _tts = FlutterTts();

  /// Slot-scoped equalizer: the shared player carries an Android equalizer
  /// so the English-Bible slot's boom-softening curve can be applied while
  /// that slot plays and cleared for every other slot. Best-effort — the
  /// effect is Android-only and all application errors are swallowed.
  static final AndroidEqualizer _equalizer = AndroidEqualizer();

  /// Interruption handling is the app's, not just_audio's: its default
  /// handler auto-RESUMES playback when an interruption (a call, another
  /// app's audio) ends, which the app must not do — after an interruption
  /// Fidelis stays paused until the user resumes. The pause reactions are
  /// wired to audio_session's streams at startup (see main.dart).
  static final AudioPlayer _player = AudioPlayer(
    handleInterruptions: false,
    audioPipeline: AudioPipeline(androidAudioEffects: [_equalizer]),
  );
  static bool _ready = false;

  /// Sink for the audio readout lines — the playback-start slot config, the
  /// engine outcome, the equalizer application, and every fallback. The
  /// owner's demand: every playback prints what is about to be heard, so a
  /// wrong voice is diagnosable from the build itself. Tests capture
  /// through the sink; production prints via debugPrint.
  static void Function(String line)? readoutSink;

  /// Emits one readout line (prefixed so the lines are greppable).
  static void _emitReadout(String line) {
    final full = '[Fidelis audio] $line';
    final sink = readoutSink;
    if (sink != null) {
      sink(full);
    } else {
      debugPrint(full);
    }
  }

  /// Timing/level measurement sink — the playback pipeline's real
  /// timestamps and PCM peaks, one line per event (the round-3 measurement
  /// path: logcat on the device via debugPrint, captured line-by-line by
  /// the host measurement runs). Null = the lines print via debugPrint.
  static void Function(String line)? measurementSink;

  /// Emits one measurement line (greppable prefix; the capture path stamps
  /// each line's arrival time — the deltas ARE the measured numbers).
  static void _measure(String line) {
    final full = '[Fidelis timing] $line';
    final sink = measurementSink;
    if (sink != null) {
      sink(full);
    } else {
      debugPrint(full);
    }
  }

  /// Incremented by every new playback request and by stop(); an in-flight
  /// Kokoro pipeline aborts as soon as its epoch no longer matches.
  static int _epoch = 0;
  static Completer<void>? _playDone;
  static Directory? _sentenceDir;

  /// The live sentence playlist's stream-sentence window: playlist item 0
  /// is stream sentence [_playlistBase]; [_appendedCount] items are loaded
  /// or queued. The notification's Next/Previous unit-move seeks within
  /// this window (see [seekToSentence]); reset by [stop] and at every
  /// playlist (re)start.
  static int _playlistBase = 0;
  static int _appendedCount = 0;

  /// The number of the running stream's sentences whose audio is loaded or
  /// queued (the seek window's end). 0 when nothing is loaded.
  static int get appendedSentenceCount => _playlistBase + _appendedCount;

  /// Moves the live pipeline to [streamIndex] (the notification's
  /// Next/Previous unit move): seeks the playlist to that sentence when
  /// its item is already appended — playing continues into it, paused
  /// moves the position. Returns false when the target lies outside the
  /// appended window or the flutter_tts path is active (the caller
  /// restarts from that sentence instead).
  static Future<bool> seekToSentence(int streamIndex) async {
    if (_lastViaFlutterTts) return false;
    final rel = streamIndex - _playlistBase;
    if (rel < 0 || rel >= _appendedCount) return false;
    try {
      await _player.seek(Duration.zero, index: rel);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---- pause/resume plumbing (driven by AudioController) ----

  static bool _paused = false;

  /// Gates the Kokoro sentence loop between sentences while paused, so a
  /// pause landing in the synthesis gap does not let the next sentence start.
  static Completer<void>? _pauseGate;

  /// Which engine produced the current/last playback: true = flutter_tts
  /// (pausable via the plugin's pause + resume-from-pauseText),
  /// false = just_audio player (pause/play).
  static bool _lastViaFlutterTts = false;

  /// Text handed to flutter_tts last, so resume() can re-speak it — the
  /// plugin continues from its internal pause position (pauseText).
  static String? _lastSpokenText;

  /// In-flight flutter_tts resume, shared by concurrent resume() callers.
  static Completer<void>? _resumeInFlight;

  /// Set when pause() lands while a resume is playing out; the resume
  /// continuation then keeps the paused state instead of clearing it.
  static bool _pausedDuringResume = false;

  static bool get isPaused => _paused;

  /// Sink for the active flutter_tts speak's word-boundary events; installed
  /// once in [init] and routed per speak. Null when nobody is listening.
  static void Function(int charStart, int charEnd)? _wordRangeSink;

  /// Live position within the active just_audio source and its total
  /// duration, when one is loaded. Null on the flutter_tts path (the plugin
  /// exposes no timing) — its word events carry the highlight instead.
  static (Duration, Duration?)? get playerProgress {
    if (_lastViaFlutterTts) return null;
    try {
      return (_player.position, _player.duration);
    } catch (_) {
      return null;
    }
  }

  /// Pauses the active engine. The just_audio player pauses in place (the
  /// pending chunk await stays open); flutter_tts pauses via the plugin,
  /// which completes the pending speak — the AudioController's job loop
  /// holds until resume() plays the remainder out. A pause landing while a
  /// resume is playing out pauses the remainder too (the plugin trims its
  /// pause position), so re-pausing works mid-remainder.
  static Future<void> pause() async {
    final resuming = _resumeInFlight != null;
    if (resuming) _pausedDuringResume = true;
    if (_paused && !resuming) return; // already fully paused
    _paused = true;
    _pauseGate ??= Completer<void>();
    try {
      await _player.pause();
    } catch (_) {}
    if (_lastViaFlutterTts) {
      try {
        await _tts.pause();
      } catch (_) {}
    }
  }

  /// Resumes paused playback. On the player path this returns after the
  /// player unpauses (the original chunk await is still pending and completes
  /// on its own). On the flutter_tts path it re-speaks the paused text — the
  /// plugin continues from its pause position — and the returned future
  /// completes when that remainder finishes, is paused again, or is stopped.
  static Future<void> resume() async {
    if (!_paused) return;
    final inFlight = _resumeInFlight;
    if (inFlight != null) return inFlight.future;
    if (_lastViaFlutterTts && _lastSpokenText != null) {
      final done = Completer<void>();
      _resumeInFlight = done;
      _pausedDuringResume = false;
      try {
        await _tts.speak(_lastSpokenText!);
      } catch (_) {}
      _resumeInFlight = null;
      if (!_pausedDuringResume) {
        _paused = false;
        _completePauseGate();
      }
      if (!done.isCompleted) done.complete();
      return;
    }
    _paused = false;
    _completePauseGate();
    try {
      await _player.play();
    } catch (_) {}
  }

  static void _completePauseGate() {
    _pauseGate?.complete();
    _pauseGate = null;
  }

  /// Known MALE Google TTS voice names per locale, in preference order.
  /// A candidate is only applied when it appears in the device's voice
  /// list; unmatched codenames are silently skipped so devices without
  /// them keep the engine default voice.
  static const Map<String, List<String>> _maleVoices = {
    'en-US': [
      'en-us-x-iom-local',
      'en-us-x-tpd-local',
      'en-us-x-afd-local',
      'en-us-x-afg-local',
    ],
    'es-ES': [
      'es-es-x-leb-local',
      'es-es-x-leb-network',
    ],
    'it-IT': [
      'it-it-x-lel-local',
      'it-it-x-ccd-local',
    ],
  };

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      // Slightly deeper pitch reads as mature regardless of which voice
      // is active (Android accepts 0.5-2.0).
      try {
        await _tts.setPitch(0.85);
      } catch (_) {}
      // Word-boundary events (Android UtteranceProgressListener.onRangeStart,
      // iOS willSpeakRangeOfCharacterRange) forwarded to the active speak's
      // sink — the flutter_tts path's engine-timed highlight source.
      _tts.setProgressHandler((text, start, end, word) {
        _wordRangeSink?.call(start, end);
      });
      _ready = true;
    } catch (_) {}
  }

  /// Copies the bundled Kokoro model files to disk in the background (first
  /// launch only; later launches are a cheap marker check). Fire-and-forget
  /// warmup for app startup — synthesis itself stays lazy.
  static Future<void> warmAssets() async {
    try {
      await KokoroEngine.prepareAssets();
    } catch (_) {}
  }

  /// Applies the active slot's equalizer shaping to the shared player
  /// (see [applyEqualizerGains]). The gains are also REMEMBERED in
  /// [_pendingSlotEq]: just_audio's equalizer parameters resolve only on the
  /// player's first platform activation (the first source load), so a
  /// shaping applied before any load times out unseen — [_playSource]
  /// re-applies the remembered shaping after each load, which is what
  /// actually reaches the platform.
  static Map<int, double>? _pendingSlotEq;

  static Future<void> applySlotEqualizer(Map<int, double>? gains) {
    _pendingSlotEq = gains;
    return applyEqualizerGains(_equalizer, gains);
  }

  /// Applies the pending slot shaping after a source load activated the
  /// player's platform. No-op for flat slots (null/empty shaping).
  static Future<void> _applyPendingSlotEqualizer() async {
    final gains = _pendingSlotEq;
    if (gains == null || gains.isEmpty) return;
    final applied = await applyEqualizerGains(_equalizer, gains);
    _emitReadout(applied
        ? 'eq applied: enabled=true '
            'bands{${gains.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(1)}dB').join(',')}}'
        : 'eq UNAVAILABLE: the platform parameters never resolved '
            '(shaping skipped)');
  }

  /// Returns the first available male voice for [language], or null to
  /// keep the engine default. Falls back to any device voice whose name
  /// carries an explicit gender marker (e.g. '#male_1' on some engines).
  static Future<String?> _maleVoiceFor(String language) async {
    try {
      final dynamic voices = await _tts.getVoices;
      if (voices is! List) return null;
      final names = <String>[];
      for (final v in voices) {
        if (v is Map && v['locale'] == language && v['name'] is String) {
          names.add(v['name'] as String);
        }
      }
      if (names.isEmpty) return null;
      for (final candidate in _maleVoices[language] ?? const <String>[]) {
        if (names.contains(candidate)) return candidate;
      }
      for (final name in names) {
        if (name.toLowerCase().contains('#male')) return name;
      }
    } catch (_) {}
    return null;
  }

  /// lang: 'en' | 'la' | 'es' — maps to a TTS voice.
  /// Latin uses the Italian voice (ecclesiastical pronunciation).
  ///
  /// [onSentenceStart] fires when each sentence starts PLAYING (Kokoro
  /// sentence-by-sentence pipeline; once with 0 on the flutter_tts path) so
  /// callers can sync highlights to the recited words.
  ///
  /// [onSentenceTiming] fires with each sentence's character range in [text]
  /// and its audio duration when the engine knows it (Kokoro WAV length;
  /// null on the flutter_tts path) — enables word-level proportional
  /// estimates.
  ///
  /// [onWordRange] fires with engine-reported recited character ranges
  /// (flutter_tts word-boundary events; not fired by Kokoro, which exposes
  /// no token timestamps in sherpa_onnx 1.13.8).
  static Future<void> speakPrayer(
    String text, {
    String? lang,
    KokoroVoice? voice,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    if (!_ready) await init();
    if (text.isEmpty) return;
    final myEpoch = ++_epoch;
    _finishPlayDone();
    final activeVoice = voice ?? KokoroVoice.standard;
    final kokoroLang = (lang == 'en' || lang == 'es') ? lang : null;
    // The playback-start readout: the ACTIVE slot config — the sids, speed,
    // and EQ state about to be heard (the owner's demand).
    if (kokoroLang != null) {
      _emitReadout('playback ${tts_text.slotReadoutLine(activeVoice, kokoroLang)}');
    } else {
      _emitReadout('playback slot=latin lang=${lang ?? 'la'} '
          'voice=system(flutter_tts) speed=0.42 eq=flat');
    }
    if (kokoroLang != null) {
      if (await _speakWithKokoro(
        text,
        kokoroLang,
        myEpoch,
        activeVoice,
        onSentenceStart,
        onSentenceTiming,
      )) {
        // The engine line ('engine=kokoro') fired inside the stream runner
        // the moment the FIRST sentence was served — the readout names the
        // engine during playback, not after the whole chunk.
        return;
      }
      _emitReadout('FALLBACK engine=flutter_tts (system voice) '
          'reason=kokoro unavailable for $kokoroLang'
          '${_kokoroFailureSuffix()}');
    }
    onSentenceStart?.call(0);
    await _speakWithFlutterTts(
      text,
      _localeFor(lang),
      onSentenceTiming: onSentenceTiming,
      onWordRange: onWordRange,
    );
  }

  /// Plays a bundled audio file (rosary pre-rendered OGG). Completes when
  /// playback finishes or stop() is called; never throws.
  static Future<void> playAssetFile(String assetPath) async {
    if (!_ready) await init();
    final myEpoch = ++_epoch;
    _finishPlayDone();
    // Bundled files (pre-rendered rosary audio) play flat: no slot shaping.
    unawaited(applySlotEqualizer(null));
    try {
      await _playSource(AudioSource.asset(assetPath), myEpoch);
    } catch (_) {}
  }

  static Future<void> stop() async {
    _epoch++;
    _finishPlayDone();
    _paused = false;
    _lastSpokenText = null;
    _resumeInFlight = null;
    _wordRangeSink = null;
    _playlistBase = 0;
    _appendedCount = 0;
    _completePauseGate();
    // Job transitions and screen exits clear any slot equalizer shaping;
    // the next slot re-applies its own (or stays flat).
    unawaited(applySlotEqualizer(null));
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static String _localeFor(String? lang) => switch (lang) {
        'la' => 'it-IT',
        'es' => 'es-ES',
        _ => 'en-US',
      };

  /// The Kokoro failure text appended to every fallback line (the on-screen
  /// banner shows the ROOT CAUSE, not just the fact of the fallback). Empty
  /// when the engine recorded no failure text.
  static String _kokoroFailureSuffix() {
    final err = KokoroEngine.lastError;
    return err == null ? '' : ' — Kokoro failed: $err';
  }

  // ---- Kokoro pipeline (en/es) ----

  /// Read-through synthesis cache: sentence audio rendered AHEAD of
  /// playback (the screens' opening-chunk prefetch, the rosary's next
  /// step, pre-fetched while the current one plays) so a Play press or
  /// the next page starts without synthesis latency. Keyed by
  /// (lang, voice identity, sentence); bounded FIFO. Entries are kept
  /// after consumption — the rosary's decade repeats one Hail Mary ten
  /// times, and every repeat then starts instantly.
  static final Map<String, KokoroAudio> _prefetchCache = {};

  /// In-flight prefetch renders, keyed like [_prefetchCache]. A playback
  /// starting while a screen-open prefetch is still rendering its opening
  /// sentences AWAITS the in-flight render instead of issuing a duplicate
  /// — the first sentence plays the moment its single render exists.
  static final Map<String, Future<KokoroAudio?>> _prefetchInFlight = {};
  static const int _prefetchCacheMax = 8;

  static String _prefetchKey(String sentence, String lang, KokoroVoice voice) =>
      '$lang|${identityHashCode(voice)}|$sentence';

  /// Test-only: clears the prefetch cache and the in-flight map (test
  /// isolation — the static maps would otherwise leak entries between
  /// suites and serve stale audio to a later test).
  @visibleForTesting
  static void debugResetPrefetchState() {
    _prefetchCache.clear();
    _prefetchInFlight.clear();
    _playlistBase = 0;
    _appendedCount = 0;
    _sentenceDirSwept = false;
  }

  /// Fire-and-forget: renders [text]'s OPENING sentences into the prefetch
  /// cache so a later playback of the same (lang, voice, text) starts
  /// without synthesis latency. Called when a screen opens (the Bible
  /// chapter screen, the rosary's current step) — the engine warm-up
  /// ([KokoroEngine.ensureReady]) and the first sentences' renders happen
  /// BEFORE Play is pressed, so Play finds the opening audio ready and
  /// starts instantly. The worker is FIFO: these renders queue behind the
  /// playing pipeline's own lookahead syntheses and fill the idle time
  /// between sentences. Capped at the cache capacity per call — the
  /// OPENING sentences are the ones Play needs first, and FIFO eviction
  /// would otherwise push them out in favor of later ones. Never throws.
  static Future<void> prefetch(String text, String lang, KokoroVoice voice) async {
    if ((lang != 'en' && lang != 'es') || text.isEmpty) return;
    _measure('prefetch-start lang=$lang cap=$_prefetchCacheMax');
    try {
      if (!await KokoroEngine.ensureReady(lang)) return;
      final (spoken, _) =
          tts_text.applyPronunciationLexicon(text, voice.lexiconFor(lang));
      var rendered = 0;
      for (final sentence in tts_text.splitSpeakableSentences(spoken)) {
        if (rendered >= _prefetchCacheMax) break;
        final key = _prefetchKey(sentence, lang, voice);
        if (_prefetchCache.containsKey(key) ||
            _prefetchInFlight.containsKey(key)) {
          continue;
        }
        rendered++;
        final issuedAt = DateTime.now().microsecondsSinceEpoch;
        final future = KokoroEngine.synthesize(sentence, lang, voice: voice);
        _prefetchInFlight[key] = future;
        try {
          final audio = await future;
          if (audio != null && audio.samples.isNotEmpty) {
            while (_prefetchCache.length >= _prefetchCacheMax) {
              _prefetchCache.remove(_prefetchCache.keys.first);
            }
            _prefetchCache[key] = audio;
            _measure('prefetch-land n=$rendered '
                'synthMs=${((DateTime.now().microsecondsSinceEpoch - issuedAt) / 1000).toStringAsFixed(0)} '
                'audioMs=${(audio.samples.length * 1000 / audio.sampleRate).round()}');
          }
        } finally {
          if (identical(_prefetchInFlight[key], future)) {
            _prefetchInFlight.remove(key);
          }
        }
      }
    } catch (_) {}
  }

  /// Plays [chunks] — ALL text chunks in one language ('en'|'es') — as ONE
  /// continuous Kokoro sentence pipeline with synthesis lookahead that
  /// SPANS CHUNK BOUNDARIES: while a sentence plays, the following
  /// sentences — including the next chunk's first — are already rendering
  /// in the worker, so a verse/page boundary costs no synthesis silence.
  /// Every slot renders ONE voice per sentence, so the lookahead budget
  /// is the same for all slots. Each chunk's slot readout + equalizer
  /// shaping apply at its
  /// start; the engine line fires when the FIRST sentence is served (the
  /// readout names the engine during playback, not minutes later).
  static Future<void> speakSequence(
    List<AudioChunk> chunks, {
    required String lang,
    required void Function(int chunkIndex) onChunkStart,
    required void Function(int chunkIndex, int sentenceInChunk) onSentenceStart,
    required void Function(int chunkIndex, int charStart, int charEnd,
            Duration duration)
        onSentenceTiming,
    required void Function(int chunkIndex, int sentenceInChunk,
            Duration duration)
        onSentenceSynthesized,
    required void Function(int chunkIndex, int charStart, int charEnd)
        onWordRange,
  }) async {
    if (!_ready) await init();
    if (chunks.isEmpty) return;
    final myEpoch = ++_epoch;
    _finishPlayDone();
    _playlistBase = 0;
    _appendedCount = 0;
    _measure('play-request lang=$lang chunks=${chunks.length} '
        'epoch=$myEpoch');
    final ensureSw = Stopwatch()..start();
    try {
      if (!await KokoroEngine.ensureReady(lang)) {
        _measure('ensure-ready ms=${ensureSw.elapsedMilliseconds} ok=false');
        _emitReadout('FALLBACK engine=flutter_tts (system voice) '
            'reason=kokoro unavailable for $lang${_kokoroFailureSuffix()}');
        for (var ci = 0; ci < chunks.length; ci++) {
          if (myEpoch != _epoch) return;
          onChunkStart(ci);
          onSentenceStart(ci, 0);
          await _speakWithFlutterTts(chunks[ci].text ?? '', _localeFor(lang));
          await _holdWhilePaused(myEpoch);
          if (myEpoch != _epoch) return;
        }
        return;
      }
      _measure('ensure-ready ms=${ensureSw.elapsedMilliseconds} ok=true');
      final stream = _buildStream(chunks, lang);
      if (stream.isEmpty) return;
      _measure('stream-built sentences=${stream.length}');
      await _runStream(
        stream,
        chunks,
        lang,
        myEpoch,
        _StreamCallbacks(
          onChunkStart: onChunkStart,
          onSentenceStart: onSentenceStart,
          onSentenceTiming: onSentenceTiming,
          onSentenceSynthesized: onSentenceSynthesized,
          onWordRange: onWordRange,
        ),
      );
      _measure('stream-done sentences=${stream.length}');
    } catch (_) {
      // Audio must never break the caller: swallow — the job loop ends the
      // stream the way a natural completion would.
    }
  }

  /// The continuous sentence stream across [chunks]: lexicon-applied,
  /// split, and aligned to each chunk's ORIGINAL text coordinates (the
  /// same split the engine speaks — highlight mapping stays exact).
  static List<_StreamSentence> _buildStream(
      List<AudioChunk> chunks, String lang) {
    final stream = <_StreamSentence>[];
    for (var ci = 0; ci < chunks.length; ci++) {
      final chunk = chunks[ci];
      final text = chunk.text ?? '';
      if (text.isEmpty) continue;
      final voice = chunk.voice ?? KokoroVoice.standard;
      final (spoken, align) =
          tts_text.applyPronunciationLexicon(text, voice.lexiconFor(lang));
      final sentences = tts_text.splitSpeakableSentences(spoken);
      final ranges = [
        for (final (start, end) in tts_text.speakableSentenceRanges(spoken))
          (align[start], align[end]),
      ];
      for (var si = 0; si < sentences.length && si < ranges.length; si++) {
        stream.add(_StreamSentence(ci, si, sentences[si], ranges[si]));
      }
    }
    return stream;
  }

  /// The rolling lookahead depth: sentences rendered AHEAD of playback.
  /// 4 keeps the worker busy across verse/page boundaries on the slowest
  /// device without over-rendering (every slot is one render per
  /// sentence, so one depth serves all slots).
  static const int _streamLookaheadDepth = 4;

  /// Runs the continuous pipeline over [stream]: a rolling lookahead of
  /// [_streamLookaheadDepth] syntheses keeps the worker rendering ahead of
  /// playback across chunk boundaries, and the sentences play as ONE
  /// playlist — the first render loads it, every later render APPENDS as
  /// it lands — so ExoPlayer prebuffers the next sentence while the
  /// current one plays and a verse/prayer boundary costs no source-load
  /// latency (the round-2 per-sentence setAudioSource was the measured
  /// fixed gap). The completion guard holds the playlist's end when the
  /// player catches up with synthesis (the frontier exposed) and the late
  /// append resumes via seek. The sentence-start callbacks fire from the
  /// player's currentIndex — the playback-side truth, so highlights sync
  /// to what is actually heard. A mid-stream synthesis failure drains the
  /// playlist and hands THAT chunk's remainder to flutter_tts, then the
  /// stream continues with the next chunk (Kokoro again).
  static Future<void> _runStream(
    List<_StreamSentence> stream,
    List<AudioChunk> chunks,
    String lang,
    int myEpoch,
    _StreamCallbacks callbacks, {
    bool emitSlotReadout = true,
  }) async {
    final depth = _streamLookaheadDepth;
    final pending = <_PendingSynth>[];
    var issued = 0;
    void issue() {
      while (issued < stream.length && pending.length < depth) {
        final s = stream[issued];
        final (future, source) = _streamSynthesize(s, chunks, lang);
        pending.add(_PendingSynth(
          future: future,
          source: source,
          issuedAt: DateTime.now().microsecondsSinceEpoch,
        ));
        issued++;
      }
    }

    issue();
    var engineLineServed = false;
    var lastChunkIndex = -1;
    final failedChunks = <int>{};
    final sentenceFiles = <File>[];
    final itemMeta = <_PlaylistItemMeta>[];
    StreamSubscription<int?>? indexSub;
    StreamSubscription<PlayerState>? stateSub;
    Completer<void>? segmentDone;
    var segmentEnding = false;
    var frontierExposed = false;
    try {
      // The playback-side callbacks: the player's currentIndex advances
      // through the playlist items; each CHANGE fires the sentence-start
      // callbacks for the stream sentence it maps to — highlights sync to
      // what is actually heard, and the measurement records the real
      // sentence-to-sentence gaps. Repeated events for the same item (the
      // position broadcasts) fire once.
      var lastFiredIndex = -1;
      indexSub = _player.currentIndexStream.listen((index) {
        if (index == null || index < 0 || index >= itemMeta.length) return;
        if (index == lastFiredIndex) return;
        lastFiredIndex = index;
        final meta = itemMeta[index];
        if (lastChunkIndex != meta.chunkIndex) {
          lastChunkIndex = meta.chunkIndex;
          callbacks.onChunkStart?.call(meta.chunkIndex);
          // Slot-scoped equalizer shaping per chunk (the English-Bible
          // boom softening); every other slot clears it. Fire-and-forget.
          unawaited(applySlotEqualizer(
              (chunks[meta.chunkIndex].voice ?? KokoroVoice.standard)
                  .equalizerFor(lang)));
          if (emitSlotReadout) {
            _emitReadout('playback ${tts_text.slotReadoutLine(
                chunks[meta.chunkIndex].voice ?? KokoroVoice.standard,
                lang)}');
          }
        }
        callbacks.onSentenceStart?.call(meta.chunkIndex, meta.sentenceInChunk);
        callbacks.onSentenceTiming
            ?.call(meta.chunkIndex, meta.range.$1, meta.range.$2, meta.duration);
        _measure('sentence-start i=${_playlistBase + index}');
      });
      // The completion guard: the playlist's natural end completes the
      // playback ONLY when nothing more is coming (the stream fully
      // appended, or a fallback takes over). The player catching up with
      // synthesis (the frontier exposed) holds the completion — the late
      // append resumes playback via seek. The guard is inert while no
      // playlist is loaded (a stale completed state from a previous
      // playback must not fire it — the state stream replays on
      // subscribe).
      stateSub = _player.playerStateStream.listen((s) {
        if (segmentDone == null) return;
        if (s.processingState != ProcessingState.completed) return;
        final allAppended = _playlistBase + _appendedCount >= stream.length;
        if (segmentEnding || allAppended) {
          frontierExposed = false;
          _finishPlayDone();
          // Clear the stale playing flag (the Android quirk leaves
          // playWhenReady true after a natural end) so the media
          // notification shows PAUSED — acoustically a no-op.
          unawaited(() async {
            try {
              await _player.pause();
            } catch (_) {}
          }());
        } else {
          frontierExposed = true;
          _measure('frontier-exposed '
              'appended=${_playlistBase + _appendedCount}');
        }
      });
      for (var i = 0; i < stream.length; i++) {
        final s = stream[i];
        if (failedChunks.contains(s.chunkIndex)) {
          // The chunk fell back to flutter_tts: drain its already-issued
          // synthesis futures without playing them, keep the lookahead full.
          if (pending.isNotEmpty) pending.removeAt(0);
          issue();
          continue;
        }
        final ps = pending.removeAt(0);
        final audio = await ps.future;
        if (myEpoch != _epoch) return; // stop() while generating
        issue();
        final landedAt = DateTime.now().microsecondsSinceEpoch;
        final synthMs = (landedAt - ps.issuedAt) / 1000.0;
        if (audio == null || audio.samples.isEmpty) {
          failedChunks.add(s.chunkIndex);
          _emitReadout('FALLBACK mid-pipeline engine=flutter_tts (system '
              'voice) reason=sentence ${s.sentenceInChunk + 1} of chunk '
              '${s.chunkIndex + 1} synthesis failed${_kokoroFailureSuffix()}');
          // The playlist (if loaded) drains to its frontier first: the
          // fallback speaks AFTER the loaded audio, never over it.
          if (segmentDone != null) {
            segmentEnding = true;
            if (frontierExposed) {
              frontierExposed = false;
              _finishPlayDone();
            }
            await segmentDone.future;
            segmentDone = null;
            segmentEnding = false;
            _playlistBase = 0;
            _appendedCount = 0;
            itemMeta.clear();
            if (myEpoch != _epoch) return;
          }
          if (lastChunkIndex != s.chunkIndex) {
            lastChunkIndex = s.chunkIndex;
            callbacks.onChunkStart?.call(s.chunkIndex);
            // The requested slot config still prints for a fallback chunk —
            // the FALLBACK line above names what actually served it.
            _emitReadout('playback ${tts_text.slotReadoutLine(
                chunks[s.chunkIndex].voice ?? KokoroVoice.standard, lang)}');
          }
          final rest = <String>[];
          for (var j = i;
              j < stream.length && stream[j].chunkIndex == s.chunkIndex;
              j++) {
            rest.add(stream[j].text);
          }
          if (rest.isNotEmpty) {
            callbacks.onSentenceStart?.call(s.chunkIndex, s.sentenceInChunk);
            await _speakWithFlutterTts(rest.join(' '), _localeFor(lang),
                onWordRange: (start, end) =>
                    callbacks.onWordRange?.call(s.chunkIndex, start, end));
            // A pause during the fallback completes the speak early; hold
            // until the resume plays the remainder out (the job loop's
            // hold, moved into the stream).
            await _holdWhilePaused(myEpoch);
          }
          if (myEpoch != _epoch) return;
          continue;
        }
        final duration = Duration(
            milliseconds:
                (audio.samples.length * 1000 / audio.sampleRate).round());
        // The render just landed — AHEAD of its playback (the lookahead):
        // the aggregate progress learns the page's total from here.
        callbacks.onSentenceSynthesized
            ?.call(s.chunkIndex, s.sentenceInChunk, duration);
        if (!engineLineServed) {
          engineLineServed = true;
          _emitReadout('engine=kokoro (the slot config above executed)');
        }
        final prepared = await _prepareSentenceWav(audio);
        if (myEpoch != _epoch) return; // stopped while preparing
        sentenceFiles.add(prepared.file);
        _measure('wav-ready i=$i synthMs=${synthMs.toStringAsFixed(0)} '
            'audioMs=${duration.inMilliseconds} src=${ps.source} '
            'peakIn=${prepared.peakInDb}dB peakOut=${prepared.peakOutDb}dB '
            'clipIn=${prepared.clipIn} clipOut=${prepared.clipOut} '
            'scaled=${prepared.scaled} writeMs=${prepared.writeMs}');
        if (segmentDone == null) {
          // ---- the playlist's first item: load, shape, play ----
          final gate = _pauseGate;
          if (gate != null) await gate.future;
          if (myEpoch != _epoch) return; // stopped while paused
          segmentDone = Completer<void>();
          _playDone = segmentDone;
          segmentEnding = false;
          frontierExposed = false;
          _playlistBase = i;
          _appendedCount = 1;
          // The playlist was replaced: the item-index space restarts, so
          // the sentence-start dedupe must too (the new segment's item 0
          // must fire even though the old segment also fired index 0).
          lastFiredIndex = -1;
          itemMeta.clear();
          itemMeta.add(_PlaylistItemMeta(
            chunkIndex: s.chunkIndex,
            sentenceInChunk: s.sentenceInChunk,
            range: s.range,
            duration: duration,
          ));
          _lastViaFlutterTts = false;
          final loadSw = Stopwatch()..start();
          if (_player.playing) {
            try {
              await _player.pause();
            } catch (_) {}
          }
          await _player
              .setAudioSources([AudioSource.file(prepared.file.path)]);
          if (myEpoch != _epoch) return;
          final loadMs = loadSw.elapsedMilliseconds;
          // The platform is active now (the load activated it): the slot
          // shaping actually applies HERE. A pre-load application times
          // out unseen on a cold player — just_audio's equalizer
          // parameters resolve only on this first activation.
          await _applyPendingSlotEqualizer();
          final eqMs = loadSw.elapsedMilliseconds - loadMs;
          _measure('segment-start i=$i loadMs=$loadMs eqMs=$eqMs');
          if (_paused) {
            // A pause landed during the load: the item stays loaded; the
            // controller's resume() starts it (the notification shows
            // paused, the position kept).
            _measure('play-held i=$i paused-during-load');
          } else {
            // Fire-and-forget: the play result stays pending until the
            // playback stops (the real Java semantics) — awaiting it here
            // would stall the append loop until the whole playlist ends.
            // The completion is the state guard's job.
            unawaited(_player.play().catchError((_) {}));
            _measure('play-called i=$i');
          }
        } else {
          // ---- append: the render lands ahead of its playback ----
          itemMeta.add(_PlaylistItemMeta(
            chunkIndex: s.chunkIndex,
            sentenceInChunk: s.sentenceInChunk,
            range: s.range,
            duration: duration,
          ));
          _appendedCount++;
          await _player.addAudioSource(AudioSource.file(prepared.file.path));
          if (myEpoch != _epoch) return;
          if (frontierExposed) {
            // The player drained the appended items while this render was
            // synthesizing: resume into the new item (the seek restarts
            // ExoPlayer from STATE_ENDED — the documented quirk). The play
            // is fire-and-forget (its result pends until the playback
            // stops — awaiting it would stall the append loop).
            frontierExposed = false;
            try {
              await _player.seek(Duration.zero, index: _appendedCount - 1);
            } catch (_) {}
            if (!_paused) {
              unawaited(_player.play().catchError((_) {}));
            }
            _measure('frontier-resume i=$i');
          }
        }
      }
      // The stream is fully appended: the playlist plays out to its end
      // (the completion guard fires when the last item finishes).
      if (segmentDone != null) {
        segmentEnding = true;
        if (frontierExposed) {
          frontierExposed = false;
          _finishPlayDone();
        }
        await segmentDone.future;
      }
    } finally {
      await indexSub?.cancel();
      await stateSub?.cancel();
      if (segmentDone != null && identical(_playDone, segmentDone)) {
        _playDone = null;
      }
      for (final f in sentenceFiles) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }

  /// Synthesizes one stream sentence: the prefetch cache first (a screen
  /// open or a previous prefetch already rendered it), then any in-flight
  /// prefetch render of the same sentence (awaited, not duplicated), else
  /// the engine. Cache hits keep the worker free for the lookahead; the
  /// in-flight reuse is what makes Play instant even when it lands
  /// mid-prefetch. Returns the future plus WHERE the audio comes from
  /// ('cache' | 'inflight' | 'engine') — the measurement's prefetch-
  /// engagement marker.
  static (Future<KokoroAudio?>, String) _streamSynthesize(
      _StreamSentence s, List<AudioChunk> chunks, String lang) {
    final voice = chunks[s.chunkIndex].voice ?? KokoroVoice.standard;
    final key = _prefetchKey(s.text, lang, voice);
    final cached = _prefetchCache[key];
    if (cached != null) {
      return (Future<KokoroAudio?>.value(cached), 'cache');
    }
    final inflight = _prefetchInFlight[key];
    if (inflight != null) return (inflight, 'inflight');
    return (
      KokoroEngine.synthesize(s.text, lang, voice: voice),
      'engine'
    );
  }

  /// Holds while paused (the flutter_tts fallback's early-completed speak):
  /// once a resume is in flight, waits for it to play the remainder out;
  /// otherwise polls until the pause lifts or the playback is replaced.
  static Future<void> _holdWhilePaused(int myEpoch) async {
    while (_paused && myEpoch == _epoch) {
      final inflight = _resumeInFlight;
      if (inflight != null) {
        await inflight.future;
        if (!_paused || myEpoch != _epoch) return;
        continue; // paused again mid-remainder
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Single-chunk Kokoro playback (the mixed-job path): the same continuous
  /// stream runner, one chunk. Returns true when the text was delivered
  /// (fully by Kokoro, or partially with the remainder handed to
  /// flutter_tts after a mid-pipeline failure). Returns false only when
  /// Kokoro could not start at all, so the caller falls back to flutter_tts
  /// for the whole text.
  static Future<bool> _speakWithKokoro(
    String text,
    String lang,
    int myEpoch,
    KokoroVoice voice,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
  ) async {
    try {
      if (!await KokoroEngine.ensureReady(lang)) return false;
      if (myEpoch != _epoch) return true; // stopped while the engine warmed up
      final chunk = AudioChunk(text: text, lang: lang, voice: voice);
      final stream = _buildStream([chunk], lang);
      if (stream.isEmpty) return false;
      await _runStream(
        stream,
        [chunk],
        lang,
        myEpoch,
        _StreamCallbacks(
          onSentenceStart: (_, si) => onSentenceStart?.call(si),
          onSentenceTiming: (_, start, end, duration) =>
              onSentenceTiming?.call(start, end, duration),
        ),
        // speakPrayer printed the single chunk's slot line already.
        emitSlotReadout: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Prepares one sentence's playback WAV (no playback — the playlist
  /// loads/appends it): the synthesis PCM is gain-staged to the headroom
  /// target first (peaks ≤ [pcmHeadroomScale] — the resampler's exact
  /// worst-case bound, so the post-conversion peak can never pass full
  /// scale; see stagePcmHeadroom), then RESAMPLED to 48000 Hz: the owner's
  /// phone doubles/distorts raw 24000 Hz sentence WAVs while the
  /// pre-rendered opus files (whose decoder delivers 48000 Hz mono to the
  /// same sink) played clean for weeks — the 24 kHz raw-PCM path is the
  /// one corrupted output path (see resamplePcmTo48k). The WAV declares
  /// 48000 Hz mono 16-bit. The measured peaks and clip counts ride the
  /// wav-ready timing line (the gain-staging evidence).
  static Future<_PreparedWav> _prepareSentenceWav(KokoroAudio audio) async {
    final sw = Stopwatch()..start();
    final (staged, scaled) = stagePcmHeadroom(audio.samples);
    final peakInDb = _dbfs(pcmPeak(audio.samples));
    final clipIn = pcmClippedCount(audio.samples);
    final rate = audio.sampleRate == 24000 ? 48000 : audio.sampleRate;
    final resampled = resamplePcmTo48k(staged, audio.sampleRate);
    final peakOutDb = _dbfs(pcmPeak(resampled));
    final clipOut = pcmClippedCount(resampled);
    final file = await _sentenceWavFile();
    await file.writeAsBytes(
      encodeWav16(resampled, rate),
      flush: false,
    );
    return _PreparedWav(
      file: file,
      peakInDb: peakInDb,
      peakOutDb: peakOutDb,
      clipIn: clipIn,
      clipOut: clipOut,
      scaled: scaled,
      writeMs: sw.elapsedMilliseconds,
    );
  }

  /// A peak in dBFS ('-inf' for silence) — the gain-staging measurement's
  /// unit.
  static String _dbfs(double peak) =>
      peak <= 0 ? '-inf' : (20 * log(peak) / ln10).toStringAsFixed(1);

  static Future<File> _sentenceWavFile() async {
    final dir = _sentenceDir ??=
        Directory('${(await getTemporaryDirectory()).path}/kokoro_sentences');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    if (!_sentenceDirSwept) {
      _sentenceDirSwept = true;
      // A previous session's orphaned sentence WAVs (a crash mid-playlist
      // leaves them behind): sweep once per process, before the first
      // playlist loads anything.
      try {
        for (final entity in dir.listSync()) {
          if (entity is File && entity.path.endsWith('.wav')) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    return File(
        '${dir.path}/s_${DateTime.now().microsecondsSinceEpoch}.wav');
  }

  /// Whether this process already swept the sentence-WAV dir (see
  /// [_sentenceWavFile]).
  static bool _sentenceDirSwept = false;

  /// Splits text into speakable sentences (see [tts_text.splitSpeakableSentences]).
  /// Public so screens can map sentence positions back to displayed text
  /// (verse highlighting) with the exact same split the engine speaks.
  static List<String> splitSentences(String text) =>
      tts_text.splitSpeakableSentences(text);

  /// Per-sentence audio durations for [text] in [lang], synthesized
  /// TIMING-ONLY through the Kokoro pipeline (no playback): each sentence's
  /// real generated WAV length. Used by asset-driven screens (pre-rendered
  /// rosary files carry no timing data) to build per-sentence highlight
  /// timelines. Returns null when Kokoro is unavailable or any sentence
  /// fails — callers keep their coarse fallback. The sentence split matches
  /// [splitSentences] / [sentenceRanges] exactly. [shouldAbort] cancels a
  /// long synthesis after the requesting playback was replaced.
  ///
  /// Keeps the standard voices: the rosary's pre-rendered files were
  /// generated with them, so their timing synthesis must match.
  static Future<List<Duration>?> synthesizeSentenceDurations(
    String text,
    String lang, {
    bool Function()? shouldAbort,
  }) async {
    if (!_ready) await init();
    final kokoroLang = (lang == 'en' || lang == 'es') ? lang : null;
    if (kokoroLang == null || text.isEmpty) return null;
    try {
      if (!await KokoroEngine.ensureReady(kokoroLang)) return null;
      final sentences = splitSentences(text);
      if (sentences.isEmpty) return null;
      final out = <Duration>[];
      for (final sentence in sentences) {
        if (shouldAbort?.call() ?? false) return null;
        final audio = await KokoroEngine.synthesize(sentence, kokoroLang);
        if (audio == null || audio.samples.isEmpty) return null;
        out.add(Duration(
            milliseconds:
                (audio.samples.length * 1000 / audio.sampleRate).round()));
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  // ---- playback plumbing (shared by Kokoro WAVs and bundled files) ----

  static Future<void> _playSource(AudioSource source, int myEpoch) async {
    _finishPlayDone();
    _lastViaFlutterTts = false;
    final done = Completer<void>();
    _playDone = done;
    // just_audio 0.10.6 quirk (verified in the installed source and a
    // scripted-platform probe): after a natural completion the Dart-side
    // `playing` stays true (nothing ever clears playWhenReady), so a later
    // play() early-returns at `if (playing) return;` and — on Android — the
    // player sits in STATE_ENDED, where ExoPlayer will not restart without
    // a seek. Clear the stale playing state before loading so the play()
    // below always reaches the platform.
    if (_player.playing) {
      try {
        await _player.pause();
      } catch (_) {}
    }
    await _player.setAudioSource(source);
    if (myEpoch != _epoch) {
      _finishPlayDone();
      return;
    }
    // The platform is active now (the load activated it): the slot shaping
    // actually applies HERE. A pre-load application times out unseen on a
    // cold player — just_audio's equalizer parameters resolve only on this
    // first activation, so the pre-load call could never reach the
    // platform.
    await _applyPendingSlotEqualizer();
    await _player.play();
    late final StreamSubscription<PlayerState> sub;
    sub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _finishPlayDone();
        // Clear the stale playing flag (the Android quirk leaves
        // playWhenReady true after a natural end) so the media notification
        // shows PAUSED rather than a phantom playing state. Acoustically a
        // no-op: the source already ended.
        unawaited(() async {
          try {
            await _player.pause();
          } catch (_) {}
        }());
      }
    });
    try {
      await done.future;
    } finally {
      sub.cancel();
      if (identical(_playDone, done)) _playDone = null;
    }
  }

  static void _finishPlayDone() {
    final done = _playDone;
    _playDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  // ---- flutter_tts path (Latin + fallback) — kept intact ----

  static Future<void> _speakWithFlutterTts(
    String text,
    String language, {
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) async {
    try {
      _lastViaFlutterTts = true;
      _lastSpokenText = text;
      // The fallback engine plays flat: no slot equalizer shaping.
      unawaited(applySlotEqualizer(null));
      // The whole text is one utterance with no known duration; its
      // word-boundary events (installed in init()) carry the highlight.
      _wordRangeSink = onWordRange;
      onSentenceTiming?.call(0, text.length, null);
      await _tts.stop();
      await _tts.setLanguage(language);
      await _tts.setSpeechRate(0.42);
      // setLanguage resets the voice on Android, so the male voice is
      // applied after it; on failure the default voice simply remains.
      final male = await _maleVoiceFor(language);
      if (male != null) {
        try {
          await _tts.setVoice({'name': male, 'locale': language});
        } catch (_) {}
      }
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Character range of each speakable sentence within [text], in the same
  /// order as [splitSentences]. Public so screens can map engine-reported
  /// ranges back to their displayed units with the exact same split the
  /// engine speaks.
  static List<(int, int)> sentenceRanges(String text) =>
      tts_text.speakableSentenceRanges(text);
}

/// One sentence in the continuous pipeline stream: which chunk it belongs
/// to, its index within that chunk, its spoken text, and its character
/// range within the chunk's ORIGINAL text (through the lexicon alignment).
class _StreamSentence {
  final int chunkIndex;
  final int sentenceInChunk;
  final String text;
  final (int, int) range;

  const _StreamSentence(
      this.chunkIndex, this.sentenceInChunk, this.text, this.range);
}

/// One lookahead synthesis in flight: its future, where its audio comes
/// from ('cache' | 'inflight' | 'engine' — the measurement's prefetch-
/// engagement marker), and the issue timestamp (the synthesis wall time).
class _PendingSynth {
  final Future<KokoroAudio?> future;
  final String source;
  final int issuedAt;

  const _PendingSynth({
    required this.future,
    required this.source,
    required this.issuedAt,
  });
}

/// One playlist item's playback metadata: which chunk/sentence it maps to
/// (the sentence-start callbacks) and its character range + duration (the
/// highlight timing).
class _PlaylistItemMeta {
  final int chunkIndex;
  final int sentenceInChunk;
  final (int, int) range;
  final Duration duration;

  const _PlaylistItemMeta({
    required this.chunkIndex,
    required this.sentenceInChunk,
    required this.range,
    required this.duration,
  });
}

/// One sentence's prepared playback WAV plus its measured gain staging
/// (the peaks and clip counts ride the wav-ready timing line).
class _PreparedWav {
  final File file;
  final String peakInDb;
  final String peakOutDb;
  final int clipIn;
  final int clipOut;
  final bool scaled;
  final int writeMs;

  const _PreparedWav({
    required this.file,
    required this.peakInDb,
    required this.peakOutDb,
    required this.clipIn,
    required this.clipOut,
    required this.scaled,
    required this.writeMs,
  });
}

/// The stream runner's callbacks (all optional; the single-chunk path
/// adapts the legacy per-chunk signatures onto them).
class _StreamCallbacks {
  final void Function(int chunkIndex)? onChunkStart;
  final void Function(int chunkIndex, int sentenceInChunk)? onSentenceStart;
  final void Function(int chunkIndex, int charStart, int charEnd,
      Duration duration)? onSentenceTiming;
  final void Function(int chunkIndex, int sentenceInChunk, Duration duration)?
      onSentenceSynthesized;
  final void Function(int chunkIndex, int charStart, int charEnd)? onWordRange;

  const _StreamCallbacks({
    this.onChunkStart,
    this.onSentenceStart,
    this.onSentenceTiming,
    this.onSentenceSynthesized,
    this.onWordRange,
  });
}

/// Applies slot equalizer [gains] (band index → dB gain) to [equalizer]:
/// non-null gains enable the effect and set the listed bands; null/empty
/// clears any earlier shaping. The band gains apply once the equalizer's
/// parameters resolve (the player's first platform activation); the bounded
/// wait keeps platforms without the effect from hanging the caller.
/// Best-effort: never throws — audio must never break. Returns true when
/// the shaping reached the platform (the clear always does; the gains only
/// when the parameters resolved in time). Public so the wiring is testable
/// against a scripted platform.
Future<bool> applyEqualizerGains(
  AndroidEqualizer equalizer,
  Map<int, double>? gains, {
  Duration parametersTimeout = const Duration(seconds: 3),
}) async {
  try {
    await equalizer.setEnabled(gains != null && gains.isNotEmpty);
    if (gains == null || gains.isEmpty) return true;
    final params = await equalizer.parameters
        .then<AndroidEqualizerParameters?>((p) => p)
        .timeout(parametersTimeout, onTimeout: () => null);
    if (params == null) return false;
    for (final entry in gains.entries) {
      final i = entry.key;
      if (i >= 0 && i < params.bands.length) {
        await params.bands[i].setGain(entry.value);
      }
    }
    return true;
  } catch (_) {
    return false;
  }
}