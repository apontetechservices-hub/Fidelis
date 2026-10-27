import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tts_service.dart';

/// Playback state of the single audio stream.
enum AudioState { stopped, playing, paused }

/// Word-level highlight within the active chunk's text: the character range
/// currently being recited. Null when the active chunk exposes no text
/// timing (asset chunks) or nothing is playing.
class AudioWordRange {
  final int charStart;
  final int charEnd;

  /// True when the range is a character-proportional estimate from the live
  /// playback position (the Kokoro engine exposes no token timestamps in
  /// sherpa_onnx 1.13.8); false when the engine reported the boundary
  /// itself (flutter_tts word events).
  final bool estimated;

  const AudioWordRange({
    required this.charStart,
    required this.charEnd,
    required this.estimated,
  });
}

/// Live playback position within the active source and its total duration
/// when known. Drives screens that map position to their own text units
/// (pre-rendered rosary files carry no text in the chunk).
class AudioProgress {
  final Duration position;
  final Duration? duration;

  const AudioProgress({required this.position, this.duration});
}

/// Immutable snapshot of the audio controller's state, exposed for UI
/// play/pause toggles and for syncing highlights with what is being recited.
class AudioPlaybackInfo {
  final AudioState state;

  /// Id of the job currently loaded in the controller, or null when stopped.
  final String? jobId;

  /// Index of the chunk (verse group / prayer step / reading section)
  /// currently playing or paused.
  final int chunkIndex;

  /// Index of the sentence within the current chunk's TTS text, when the
  /// engine reports sentence progress (Kokoro pipeline).
  final int sentenceIndex;

  const AudioPlaybackInfo({
    required this.state,
    this.jobId,
    this.chunkIndex = 0,
    this.sentenceIndex = 0,
  });

  const AudioPlaybackInfo.stopped()
      : state = AudioState.stopped,
        jobId = null,
        chunkIndex = 0,
        sentenceIndex = 0;
}

/// One playable unit of an [AudioJob]: either TTS text or a bundled asset.
class AudioChunk {
  /// Text to speak through the TTS engines (Kokoro for en/es, flutter_tts
  /// otherwise). Null when [asset] is set.
  final String? text;

  /// Bundled audio file path (pre-rendered rosary OGG). Null when [text] is
  /// set.
  final String? asset;

  /// TTS language: 'en' | 'es' | 'la'.
  final String? lang;

  /// Called when sentence [sentenceIndex] of this chunk's text starts
  /// playing (Kokoro sentence-by-sentence pipeline; fires once with 0 on the
  /// flutter_tts path). Used for highlight syncing.
  final void Function(int sentenceIndex)? onSentenceStart;

  const AudioChunk({this.text, this.asset, this.lang, this.onSentenceStart});
}

/// A playback request: an ordered list of chunks played one after another.
/// Starting a new job always stops the current one (single audio stream).
class AudioJob {
  /// Identifies the job across state updates (e.g. 'bible', 'rosary',
  /// 'readings').
  final String id;
  final List<AudioChunk> chunks;

  /// Called when the job plays to completion (not when stopped/replaced).
  final VoidCallback? onCompleted;

  const AudioJob({required this.id, required this.chunks, this.onCompleted});
}

/// Low-level audio engine behind the controller. Abstracted so tests can
/// inject a fake instead of the real TTS plugins.
abstract class AudioEngine {
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  });
  Future<void> playAsset(String asset);
  Future<void> pause();

  /// Resumes paused playback. Returns a future that completes when the
  /// resumed audio finishes playing out, is paused again, or is stopped.
  /// The controller awaits it (fire-and-forget) before releasing its job
  /// loop, so a flutter_tts pause — which completes the current chunk
  /// early — does not skip ahead while the remainder is still playing.
  /// Concurrent callers share one in-flight resume.
  Future<void> resume();
  Future<void> stop();
  bool get isPaused;

  /// Live position within the active source and its total duration, when
  /// the engine can report them (just_audio sources). Null when idle or on
  /// the flutter_tts path (the plugin exposes no timing).
  (Duration, Duration?)? get progress;

  /// Per-sentence audio durations for [text] in [lang], synthesized
  /// TIMING-ONLY (no playback) with the same sentence split the playback
  /// path uses. Lets asset-driven screens (pre-rendered rosary files carry
  /// no timing data) build a per-sentence highlight timeline from the
  /// engine's real generated durations. Null when the engine cannot
  /// synthesize (Kokoro unavailable) — the caller keeps a coarse whole-text
  /// fallback. [shouldAbort] lets the caller cancel a long synthesis after
  /// the requesting playback was replaced.
  Future<List<Duration>?> sentenceDurations(
    String text,
    String lang, {
    bool Function()? shouldAbort,
  });
}

/// Real engine: delegates to [TtsService] (Kokoro + flutter_tts + bundled
/// files). Voice selection is untouched — the controller only orchestrates.
class TtsAudioEngine implements AudioEngine {
  const TtsAudioEngine();

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) {
    return TtsService.speakPrayer(
      text,
      lang: lang,
      onSentenceStart: onSentenceStart,
      onSentenceTiming: onSentenceTiming,
      onWordRange: onWordRange,
    );
  }

  @override
  Future<void> playAsset(String asset) => TtsService.playAssetFile(asset);

  @override
  Future<void> pause() => TtsService.pause();

  @override
  Future<void> resume() => TtsService.resume();

  @override
  Future<void> stop() => TtsService.stop();

  @override
  bool get isPaused => TtsService.isPaused;

  @override
  (Duration, Duration?)? get progress => TtsService.playerProgress;

  @override
  Future<List<Duration>?> sentenceDurations(
    String text,
    String lang, {
    bool Function()? shouldAbort,
  }) {
    return TtsService.synthesizeSentenceDurations(text, lang,
        shouldAbort: shouldAbort);
  }
}

/// Central audio coordinator — the ONLY way screens play audio.
///
/// Guarantees:
///  - ONE audio stream app-wide: [start] stops the current job immediately
///    (Kokoro pipeline aborted via epoch invalidation, just_audio player and
///    flutter_tts stopped), so Bible + Rosary can never play simultaneously.
///  - play / pause / resume / stop with a [listenable] state stream
///    (stopped / playing / paused) plus chunk + sentence position info for
///    highlight syncing.
///  - Jobs run their chunk loop here, not in the screens, so leaving a
///    screen cannot leave an orphaned loop restarting audio; screens call
///    [stopIfOwner] in dispose to end their own audio.
class AudioController {
  AudioController({AudioEngine? engine}) : _engine = engine ?? const TtsAudioEngine();

  static final AudioController instance = AudioController();

  /// Word-level highlight refresh rate while playing.
  static const _wordTickInterval = Duration(milliseconds: 200);

  AudioEngine _engine;
  int _epoch = 0;
  Object? _owner;
  AudioPlaybackInfo _info = const AudioPlaybackInfo.stopped();

  /// Text of the chunk currently loaded in the engine, for expanding
  /// recited offsets to word boundaries. Null for asset chunks.
  String? _activeChunkText;

  /// Character range + audio duration of the sentence currently playing
  /// (Kokoro pipeline). Null on the flutter_tts path (whose word events
  /// supersede estimates) and for asset chunks.
  (int, int, Duration?)? _sentenceTiming;

  /// Whether the active chunk is a bundled asset: its live position spans
  /// the whole source, unlike the Kokoro pipeline whose position resets
  /// with every sentence WAV.
  bool _activeChunkIsAsset = false;

  /// Per-sentence highlight timeline of the active ASSET chunk: character
  /// ranges of the chunk's highlight text + each sentence's REAL generated
  /// duration (Kokoro WAV lengths, timing-only synthesis). The live player
  /// position maps through the cumulative durations (scaled to the asset's
  /// total) to the current sentence and proportionally within it — the
  /// highlight resets at every sentence boundary, so drift never
  /// accumulates. Null while unresolved or when synthesis is unavailable
  /// (the coarse whole-text fallback estimate applies instead).
  List<(int, int, Duration)>? _sentenceTimeline;

  /// Chunk index the installed timeline was resolved for; the timeline only
  /// drives ticks while that chunk is still the active one.
  int? _timelineChunkIndex;

  /// Resolved sentence-duration timelines, keyed by '$lang|$text' — repeated
  /// steps sharing one pre-rendered file (all decade Hail Marys) synthesize
  /// once. Instance-scoped so tests start clean.
  final Map<String, List<Duration>> _timelineCache = {};

  Timer? _wordTimer;

  /// Opened by [resume] once the resumed audio has finished playing out —
  /// the job loop waits on it so a flutter_tts pause (which completes the
  /// current chunk early) does not skip to the next chunk while paused.
  Completer<void>? _resumeGate;
  final ValueNotifier<AudioPlaybackInfo> _notifier =
      ValueNotifier<AudioPlaybackInfo>(const AudioPlaybackInfo.stopped());

  final ValueNotifier<AudioWordRange?> _wordRange =
      ValueNotifier<AudioWordRange?>(null);

  final ValueNotifier<AudioProgress?> _progress =
      ValueNotifier<AudioProgress?>(null);

  /// State + position stream for UI toggles and highlight syncing.
  ValueListenable<AudioPlaybackInfo> get listenable => _notifier;
  AudioState get state => _info.state;
  String? get currentJobId => _info.jobId;

  /// Word-level highlight stream for the active chunk's text.
  ValueListenable<AudioWordRange?> get wordRangeListenable => _wordRange;

  /// Live position/duration stream for the active source.
  ValueListenable<AudioProgress?> get progressListenable => _progress;

  /// True when [jobId] is the loaded job and it is actively playing.
  bool isPlayingFor(String jobId) =>
      _info.state == AudioState.playing && _info.jobId == jobId;

  /// Test hook: swap the engine (never used in production).
  @visibleForTesting
  // ignore: avoid_setters_without_getters
  set engineForTest(AudioEngine engine) => _engine = engine;

  /// Starts [job], stopping whatever is currently playing. The chunk loop
  /// lives here so it can always be halted centrally.
  Future<void> start(AudioJob job, {Object? owner}) async {
    // Single stream: the engine-level stop of the current job strictly
    // precedes the first chunk of the new one.
    await stop();
    final myEpoch = ++_epoch;
    _owner = owner;
    _emit(job.id, AudioState.playing, 0, 0);
    _startWordTimer();
    for (var i = 0; i < job.chunks.length; i++) {
      if (myEpoch != _epoch) return;
      final chunk = job.chunks[i];
      _emit(job.id, AudioState.playing, i, 0);
      _activeChunkText = chunk.text;
      _sentenceTiming = null;
      _sentenceTimeline = null;
      _timelineChunkIndex = null;
      _activeChunkIsAsset = chunk.asset != null;
      _wordRange.value = null;
      try {
        final asset = chunk.asset;
        if (asset != null) {
          // Asset chunks may carry the displayed text for highlight timing:
          // resolve the per-sentence timeline (real Kokoro durations) in the
          // background; until it lands, the coarse whole-text estimate
          // drives the highlight.
          final text = chunk.text;
          final lang = chunk.lang;
          if (text != null && text.isNotEmpty && lang != null) {
            unawaited(_ensureSentenceTimeline(text, lang, i, myEpoch));
          }
          await _engine.playAsset(asset);
        } else {
          await _engine.speakText(
            chunk.text ?? '',
            lang: chunk.lang,
            onSentenceStart: (s) {
              if (myEpoch == _epoch) {
                _emit(job.id, AudioState.playing, i, s);
                chunk.onSentenceStart?.call(s);
              }
            },
            onSentenceTiming: (charStart, charEnd, duration) {
              if (myEpoch != _epoch) return;
              _sentenceTiming = (charStart, charEnd, duration);
            },
            onWordRange: (charStart, charEnd) {
              if (myEpoch != _epoch) return;
              // Engine word events supersede proportional estimates.
              _sentenceTiming = null;
              _publishWordRange(charStart, charEnd, estimated: false);
            },
          );
        }
      } catch (_) {}
      if (myEpoch != _epoch) return;
      // A flutter_tts pause completes the current chunk early; hold the loop
      // until a resume plays the remainder out (no-op on the player path,
      // whose chunk await stays pending while paused).
      while (_info.state == AudioState.paused && myEpoch == _epoch) {
        final gate = _resumeGate;
        if (gate == null) break;
        await gate.future;
      }
      if (myEpoch != _epoch) return;
    }
    _finish(myEpoch, job);
  }

  /// Resolves the per-sentence highlight timeline for an asset chunk's
  /// [text] (timing-only synthesis through the engine) and installs it when
  /// that chunk is still active. Cached per (lang, text) — repeated steps
  /// sharing one pre-rendered file resolve once.
  Future<void> _ensureSentenceTimeline(
      String text, String lang, int chunkIndex, int myEpoch) async {
    final cacheKey = '$lang|$text';
    var durations = _timelineCache[cacheKey];
    if (durations == null) {
      durations = await _engine.sentenceDurations(
        text,
        lang,
        shouldAbort: () => myEpoch != _epoch,
      );
      if (durations == null) return; // synthesis unavailable: coarse fallback
      if (myEpoch != _epoch) return; // replaced while synthesizing
      _timelineCache[cacheKey] = durations;
    }
    if (myEpoch != _epoch || _info.chunkIndex != chunkIndex) return;
    final ranges = TtsService.sentenceRanges(text);
    if (ranges.length != durations.length) return; // split mismatch: fallback
    _sentenceTimeline = List.generate(
        durations.length, (i) => (ranges[i].$1, ranges[i].$2, durations![i]));
    _timelineChunkIndex = chunkIndex;
  }

  Future<void> pause() async {
    if (_info.state != AudioState.playing) return;
    // Flip the state FIRST: a flutter_tts pause completes the pending chunk
    // await, and the job loop must already see 'paused' so it waits instead
    // of starting the next chunk.
    _resumeGate = Completer<void>();
    _emit(_info.jobId, AudioState.paused, _info.chunkIndex, _info.sentenceIndex);
    await _engine.pause();
  }

  Future<void> resume() async {
    if (_info.state != AudioState.paused) return;
    _emit(_info.jobId, AudioState.playing, _info.chunkIndex, _info.sentenceIndex);
    final gate = _resumeGate;
    unawaited(() async {
      try {
        await _engine.resume();
      } catch (_) {}
      // Release the job loop only after the resumed audio finished playing
      // out (flutter_tts remainder); the player path returns immediately —
      // its original chunk await is still pending and completes on its own.
      if (gate != null && !gate.isCompleted) gate.complete();
      if (identical(_resumeGate, gate)) _resumeGate = null;
    }());
  }

  /// Stops whatever is playing, regardless of owner.
  Future<void> stop() async {
    _epoch++;
    _owner = null;
    _info = const AudioPlaybackInfo.stopped();
    _notifier.value = _info;
    _clearHighlight();
    final gate = _resumeGate;
    _resumeGate = null;
    if (gate != null && !gate.isCompleted) gate.complete();
    await _engine.stop();
  }

  /// Stops only when [owner] owns the current job — used by screens in
  /// dispose() so exiting ends their audio, while a replacement screen that
  /// already started its own job (Next-chapter auto-continue) is not killed.
  Future<void> stopIfOwner(Object owner) async {
    if (identical(_owner, owner)) await stop();
  }

  void _finish(int myEpoch, AudioJob job) {
    if (myEpoch != _epoch) return;
    _epoch++;
    _owner = null;
    _info = const AudioPlaybackInfo.stopped();
    _notifier.value = _info;
    _clearHighlight();
    job.onCompleted?.call();
  }

  void _clearHighlight() {
    _wordTimer?.cancel();
    _wordTimer = null;
    _activeChunkText = null;
    _sentenceTiming = null;
    _sentenceTimeline = null;
    _timelineChunkIndex = null;
    _activeChunkIsAsset = false;
    _wordRange.value = null;
    _progress.value = null;
  }

  void _startWordTimer() {
    _wordTimer?.cancel();
    _wordTimer = Timer.periodic(_wordTickInterval, (_) => _onWordTick());
  }

  /// Advances the word-level highlight from the live playback position.
  /// Three timing models, in order of precision:
  ///  - asset chunks with a resolved per-sentence timeline: the position
  ///    maps through the sentences' REAL generated durations to the current
  ///    sentence and proportionally within it — resets at every sentence
  ///    boundary, no accumulated drift;
  ///  - Kokoro runtime chunks: character-proportional within the current
  ///    sentence (whose duration the pipeline knows from its WAV length);
  ///  - asset chunks without a timeline (synthesis unavailable): a coarse
  ///    whole-text proportional estimate — the degraded fallback.
  /// Engine word events (flutter_tts) supersede all estimates.
  void _onWordTick() {
    if (_info.state != AudioState.playing) return;
    final prog = _engine.progress;
    if (prog == null) return;
    final (position, totalDuration) = prog;
    _progress.value = AudioProgress(position: position, duration: totalDuration);
    final timeline = _sentenceTimeline;
    if (timeline != null && _timelineChunkIndex == _info.chunkIndex) {
      _publishTimelineRange(timeline, position, totalDuration);
      return;
    }
    final timing = _sentenceTiming;
    if (timing == null) {
      // Degraded fallback for asset chunks whose per-sentence timeline is
      // unavailable: whole-text proportional from the live position.
      final text = _activeChunkText;
      if (_activeChunkIsAsset &&
          text != null &&
          text.isNotEmpty &&
          totalDuration != null &&
          totalDuration.inMilliseconds > 0) {
        final fraction =
            (position.inMilliseconds / totalDuration.inMilliseconds)
                .clamp(0.0, 1.0);
        final offset =
            (fraction * text.length).round().clamp(0, text.length);
        _publishWordRange(offset, offset, estimated: true);
      }
      return;
    }
    final (start, end, sentenceDuration) = timing;
    final duration = sentenceDuration ?? totalDuration;
    if (duration == null || duration.inMilliseconds <= 0 || end <= start) {
      return;
    }
    final fraction =
        (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final offset = start + (fraction * (end - start)).round();
    _publishWordRange(offset, offset, estimated: true);
  }

  /// Maps the live [position] through the per-sentence [timeline] to the
  /// current sentence and proportionally within it. Sentence boundaries
  /// come from the sentences' REAL generated durations, scaled to the
  /// source's total duration so the timeline spans the whole asset (the
  /// synthesized scale holds when the total is unknown); the within-sentence
  /// offset resets at every boundary — drift never accumulates.
  void _publishTimelineRange(
      List<(int, int, Duration)> timeline, Duration position, Duration? total) {
    final text = _activeChunkText;
    if (text == null || text.isEmpty) return;
    var totalSynth = 0;
    for (final (_, _, d) in timeline) {
      totalSynth += d.inMilliseconds;
    }
    if (totalSynth <= 0) return;
    final span = (total != null && total.inMilliseconds > 0)
        ? total.inMilliseconds
        : totalSynth;
    final posMs = position.inMilliseconds.clamp(0, span);
    var windowStart = 0;
    for (var i = 0; i < timeline.length; i++) {
      final (start, end, d) = timeline[i];
      final window = (d.inMilliseconds / totalSynth * span).round();
      final windowEnd = windowStart + window;
      if (posMs < windowEnd || i == timeline.length - 1) {
        final fraction = window <= 0
            ? 0.0
            : ((posMs - windowStart) / window).clamp(0.0, 1.0);
        final offset = start + (fraction * (end - start)).round();
        _publishWordRange(offset, offset, estimated: true);
        return;
      }
      windowStart = windowEnd;
    }
  }

  /// Expands a recited offset to the word boundaries containing it and
  /// publishes the range. Engine-reported ranges pass through as-is.
  void _publishWordRange(int start, int end, {required bool estimated}) {
    final text = _activeChunkText;
    if (text == null || text.isEmpty) {
      _wordRange.value = null;
      return;
    }
    var s = start.clamp(0, text.length);
    var e = end.clamp(0, text.length);
    if (estimated) {
      while (s > 0 && _isWordChar(text[s - 1])) {
        s--;
      }
      while (e < text.length && _isWordChar(text[e])) {
        e++;
      }
    }
    _wordRange.value = AudioWordRange(charStart: s, charEnd: e, estimated: estimated);
  }

  static final RegExp _wordChar = RegExp(r'[0-9A-Za-z\u00C0-\u024F]');

  static bool _isWordChar(String char) => _wordChar.hasMatch(char);

  void _emit(String? jobId, AudioState state, int chunkIndex, int sentenceIndex) {
    _info = AudioPlaybackInfo(
      state: state,
      jobId: jobId,
      chunkIndex: chunkIndex,
      sentenceIndex: sentenceIndex,
    );
    _notifier.value = _info;
  }
}