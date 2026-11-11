import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'kokoro_engine.dart';
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

  /// Kokoro voice profile for this chunk's synthesis (en/es). Null keeps
  /// the standard voices; the Bible passes [KokoroVoice.bible] (Michael
  /// EN / Alex ES at 0.81) and the rosary's runtime steps pass
  /// [KokoroVoice.rosary] (Aoede EN / Aoede ES speaking Spanish) so their
  /// pronunciation lexicons and speeds apply.
  final KokoroVoice? voice;

  /// Called when sentence [sentenceIndex] of this chunk's text starts
  /// playing (Kokoro sentence-by-sentence pipeline; fires once with 0 on the
  /// flutter_tts path). Used for highlight syncing.
  final void Function(int sentenceIndex)? onSentenceStart;

  const AudioChunk({
    this.text,
    this.asset,
    this.lang,
    this.voice,
    this.onSentenceStart,
  });
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

  /// Human title of the playing content for the media notification
  /// (e.g. 'James 1', 'The Holy Rosary'). Null keeps the app name.
  final String? title;

  /// The media notification's Next/Previous routing (the playback-unit
  /// move: the Bible = one verse, the rosary = one prayer/step). The
  /// screen owns the units — verse offsets, the step list — so the
  /// controller routes the notification's controls here. The callback
  /// returns the TARGET STREAM SENTENCE INDEX to move to (the controller
  /// seeks the live pipeline to it: playing continues into it, paused
  /// moves the position), or null when the move is blocked (a boundary)
  /// or the screen handled it itself (the rosary's step advance, a
  /// restart beyond the synthesized frontier, an armed paused resume).
  /// Null on jobs without unit moves (the controls then no-op).
  final Future<int?> Function(int direction)? onUnitMove;

  const AudioJob({
    required this.id,
    required this.chunks,
    this.onCompleted,
    this.title,
    this.onUnitMove,
  });
}

/// Low-level audio engine behind the controller. Abstracted so tests can
/// inject a fake instead of the real TTS plugins.
abstract class AudioEngine {
  Future<void> speakText(
    String text, {
    String? lang,
    KokoroVoice? voice,
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

  /// Plays [chunks] — ALL text chunks in one language ('en'|'es') — as ONE
  /// continuous sentence pipeline with synthesis lookahead that SPANS
  /// CHUNK BOUNDARIES: while a chunk plays, the next chunks are already
  /// synthesizing (blend slots budget double — two renders per sentence),
  /// so a verse/page boundary costs no synthesis silence. The callbacks
  /// drive the controller's per-chunk state and the aggregate progress:
  /// [onSentenceSynthesized] fires when a sentence's render LANDS (ahead
  /// of its playback) so the whole-page duration is learned early.
  Future<void> speakSequence(
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
  });

  /// Fire-and-forget lookahead prefetch: renders [text]'s sentences into
  /// the engine's cache so a later playback of the same content (the
  /// rosary's next step) starts without synthesis latency. Queues behind
  /// the playing pipeline's own syntheses; never blocks the caller.
  Future<void> prefetch(String text, String lang, KokoroVoice voice);

  /// Moves the live pipeline to [streamIndex] (the notification's
  /// Next/Previous unit move): seeks the playlist to that sentence when
  /// its item is already appended — playing continues into it, paused
  /// moves the position. Returns false when the target lies outside the
  /// appended window (the caller restarts from that sentence instead).
  Future<bool> seekToSentence(int streamIndex);

  /// The number of the running stream's sentences whose audio is loaded
  /// or queued (the seek window's end). 0 when nothing is loaded.
  int get appendedSentenceCount;
}

/// Real engine: delegates to [TtsService] (Kokoro + flutter_tts + bundled
/// files). Voice selection is untouched — the controller only orchestrates.
class TtsAudioEngine implements AudioEngine {
  const TtsAudioEngine();

  @override
  Future<void> speakText(
    String text, {
    String? lang,
    KokoroVoice? voice,
    void Function(int sentenceIndex)? onSentenceStart,
    void Function(int charStart, int charEnd, Duration? duration)?
        onSentenceTiming,
    void Function(int charStart, int charEnd)? onWordRange,
  }) {
    return TtsService.speakPrayer(
      text,
      lang: lang,
      voice: voice,
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

  @override
  Future<void> speakSequence(
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
  }) {
    return TtsService.speakSequence(
      chunks,
      lang: lang,
      onChunkStart: onChunkStart,
      onSentenceStart: onSentenceStart,
      onSentenceTiming: onSentenceTiming,
      onSentenceSynthesized: onSentenceSynthesized,
      onWordRange: onWordRange,
    );
  }

  @override
  Future<void> prefetch(String text, String lang, KokoroVoice voice) {
    return TtsService.prefetch(text, lang, voice);
  }

  @override
  Future<bool> seekToSentence(int streamIndex) =>
      TtsService.seekToSentence(streamIndex);

  @override
  int get appendedSentenceCount => TtsService.appendedSentenceCount;
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
class AudioController with WidgetsBindingObserver {
  AudioController({AudioEngine? engine, this.externalPauseRequests})
      : _engine = engine ?? const TtsAudioEngine() {
    // Foreground/background tracking drives the parked-after-end state (the
    // media notification stays paused when a backgrounded playback ends).
    // Best-effort: tests without a binding skip the observer.
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    externalPauseRequests?.listen((_) => unawaited(pause()));
  }

  static final AudioController instance = AudioController();

  /// Word-level highlight refresh rate while playing.
  static const _wordTickInterval = Duration(milliseconds: 200);

  AudioEngine _engine;
  int _epoch = 0;
  Object? _owner;
  AudioPlaybackInfo _info = const AudioPlaybackInfo.stopped();

  /// Title of the current job for the media notification; null when stopped.
  String? _currentJobTitle;

  /// The most recently started job with its owner, kept across stop() so
  /// the media session's play can RESTART the last-played content when
  /// nothing is loaded (e.g. a headset play button after a stop). Not the
  /// parked playback (which resume() handles) — the full job from its
  /// first chunk.
  _LastJob? _lastJob;

  /// The currently loaded job (the notification's Next/Previous routes
  /// through its [AudioJob.onUnitMove]). Null when stopped or finished.
  AudioJob? _loadedJob;

  /// A pending resume replacement, armed while paused (the notification's
  /// Next/Previous moved the position to a unit whose audio is not the
  /// loaded stream — the rosary's next step): the next resume starts THIS
  /// job instead of unpausing the loaded one, so the position moves
  /// without starting audio and the notification keeps showing Play.
  /// Cleared by stop()/start().
  AudioJob? _pendingResumeJob;
  Object? _pendingResumeOwner;

  /// A job that finished naturally while the app was backgrounded: parked
  /// so the media notification stays in a paused state and a resume replays
  /// the chunk the playback ended on. Null when nothing is parked.
  _ParkedPlayback? _parked;

  /// Whether the app is in the foreground (WidgetsBinding observer).
  /// Defaults to true: the parked-after-end state applies only when the
  /// user has actually left the app mid-playback.
  bool _inForeground = true;

  /// Text of the chunk currently loaded in the engine, for expanding
  /// recited offsets to word boundaries. Null for asset chunks.
  String? _activeChunkText;

  /// Character range + audio duration of the sentence currently playing
  /// (Kokoro pipeline). Null on the flutter_tts path (whose word events
  /// supersede estimates) and for asset chunks.
  (int, int, Duration?)? _sentenceTiming;

  /// Aggregate-progress state for sequence jobs (all-text): the per-sentence
  /// durations in stream order (learned from the lookahead's synthesis,
  /// AHEAD of playback), how many sentences have been served, the expected
  /// total sentence count (the job's texts through the same split), and the
  /// cumulative seconds of the served sentences. The published progress
  /// spans the WHOLE job: position = completed sentences + the live
  /// position within the current sentence; duration = the learned total +
  /// the remaining sentences at the running average — converging on the
  /// true total as renders land.
  List<double>? _sequenceSentenceSeconds;
  int _sequenceServedCount = 0;
  int _sequenceExpectedCount = 0;
  double _sequenceCompletedSeconds = 0;

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

  /// External pause requests — audio-focus loss (another app, a call) and
  /// headset unplug — wired to audio_session's streams at startup (see
  /// main.dart); tests inject a stream. Each event pauses the current
  /// playback, which then STAYS paused: no auto-resume, the user resumes
  /// manually.
  final Stream<void>? externalPauseRequests;
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

  /// Human title of the playing content (the media notification). Null when
  /// stopped.
  String? get currentJobTitle => _currentJobTitle;

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

  /// Test hook: force the foreground/background state (production reads the
  /// WidgetsBinding observer).
  @visibleForTesting
  // ignore: avoid_setters_without_getters
  set appInForegroundForTest(bool value) => _inForeground = value;

  /// Starts [job], stopping whatever is currently playing. The chunk loop
  /// lives here so it can always be halted centrally.
  Future<void> start(AudioJob job, {Object? owner}) async {
    // Single stream: the engine-level stop of the current job strictly
    // precedes the first chunk of the new one.
    await stop();
    final myEpoch = ++_epoch;
    _owner = owner;
    _lastJob = _LastJob(job: job, owner: owner);
    _loadedJob = job;
    _currentJobTitle = job.title;
    _requestAudioFocus();
    _emit(job.id, AudioState.playing, 0, 0);
    _startWordTimer();
    _beginAggregateProgress(job);
    // All-text en/es jobs run as ONE continuous sentence pipeline with
    // synthesis lookahead across chunk boundaries (no inter-chunk silence);
    // everything else keeps the per-chunk loop (asset chunks, Latin, mixed
    // jobs).
    if (_isSequenceJob(job)) {
      await _runSequenceJob(job, myEpoch);
    } else {
      await _runChunkLoop(job, myEpoch);
    }
    if (myEpoch != _epoch) return;
    _finish(myEpoch, job);
  }

  /// True when every chunk of [job] is non-empty 'en'/'es' text — the
  /// continuous sequence pipeline's domain.
  static bool _isSequenceJob(AudioJob job) {
    return job.chunks.isNotEmpty &&
        job.chunks.every((c) =>
            c.asset == null &&
            (c.lang == 'en' || c.lang == 'es') &&
            (c.text?.isNotEmpty ?? false));
  }

  /// The sequence path: one continuous sentence pipeline across all the
  /// job's text chunks (the lookahead spans chunk boundaries — no
  /// inter-chunk synthesis silence). Per-chunk state (highlight text,
  /// timeline reset) and the aggregate progress advance through the
  /// pipeline's callbacks.
  Future<void> _runSequenceJob(AudioJob job, int myEpoch) async {
    final chunks = job.chunks;
    try {
      await _engine.speakSequence(
        chunks,
        lang: chunks.first.lang!,
        onChunkStart: (ci) {
          if (myEpoch != _epoch) return;
          final chunk = chunks[ci];
          // The CURRENT state, not a forced playing: a paused unit-move
          // seek advances the chunk while paused — the state must stay
          // paused (the notification keeps showing Play).
          _emit(job.id, _info.state, ci, 0);
          _activeChunkText = chunk.text;
          _sentenceTiming = null;
          _sentenceTimeline = null;
          _timelineChunkIndex = null;
          _activeChunkIsAsset = false;
          _wordRange.value = null;
        },
        onSentenceStart: (ci, si) {
          if (myEpoch != _epoch) return;
          _emit(job.id, _info.state, ci, si);
          chunks[ci].onSentenceStart?.call(si);
          _noteSequenceSentenceServed();
        },
        onSentenceTiming: (ci, charStart, charEnd, duration) {
          if (myEpoch != _epoch) return;
          _sentenceTiming = (charStart, charEnd, duration);
        },
        onSentenceSynthesized: (ci, si, duration) {
          if (myEpoch != _epoch) return;
          _noteSequenceSentenceDuration(duration);
        },
        onWordRange: (ci, charStart, charEnd) {
          if (myEpoch != _epoch) return;
          // Engine word events supersede proportional estimates.
          _sentenceTiming = null;
          _publishWordRange(charStart, charEnd, estimated: false);
        },
      );
    } catch (_) {}
  }

  /// The per-chunk loop for jobs the sequence pipeline does not cover
  /// (asset chunks, Latin, mixed jobs) — the historical behavior.
  Future<void> _runChunkLoop(AudioJob job, int myEpoch) async {
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
            voice: chunk.voice,
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
  }

  /// Fire-and-forget lookahead prefetch (the rosary's next step): renders
  /// [chunk]'s text into the engine's cache so the next page starts
  /// without synthesis latency. No-op for non-text or non-en/es chunks.
  void prefetch(AudioChunk chunk) {
    final text = chunk.text;
    final lang = chunk.lang;
    if (text == null || text.isEmpty || lang == null) return;
    if (lang != 'en' && lang != 'es') return;
    unawaited(
        _engine.prefetch(text, lang, chunk.voice ?? KokoroVoice.standard));
  }

  /// The number of the loaded job's stream sentences whose audio is
  /// loaded or queued (the unit-move seek window's end). 0 when nothing
  /// is loaded.
  int get loadedSentenceCount => _engine.appendedSentenceCount;

  /// The media notification's Next/Previous: moves by the loaded job's
  /// playback unit (the Bible = one verse, the rosary = one prayer/step)
  /// through the job's [AudioJob.onUnitMove]. The callback returns the
  /// target stream sentence index to seek within the live pipeline
  /// (playing continues into it, paused moves the position), or null when
  /// the move is blocked (a boundary) or the screen handled it itself
  /// (the rosary's step advance, a restart beyond the synthesized
  /// frontier, an armed paused resume). No-op without a loaded job or
  /// without unit moves.
  Future<void> skipUnit(int direction) async {
    final job = _loadedJob;
    final move = job?.onUnitMove;
    if (move == null) return;
    final int? target;
    try {
      target = await move(direction);
    } catch (_) {
      return;
    }
    if (target == null || _loadedJob != job) return;
    final seeked = await _engine.seekToSentence(target);
    if (seeked) _resyncAggregateAfterSeek(target);
  }

  /// Re-syncs the aggregate progress after a unit-move seek to stream
  /// sentence [target]: the skipped sentences are complete (their renders
  /// landed — the seek window guarantees it), so the served count and the
  /// completed seconds jump to the target instead of recounting from zero
  /// (the progress bar would jump backward after every Next/Previous).
  void _resyncAggregateAfterSeek(int target) {
    final list = _sequenceSentenceSeconds;
    if (list == null || target <= 0 || target > list.length) return;
    var completed = 0.0;
    for (var i = 0; i < target; i++) {
      completed += list[i];
    }
    _sequenceCompletedSeconds = completed;
    _sequenceServedCount = target;
  }

  /// Arms a pending resume replacement while paused (the notification's
  /// Next/Previous moved the position to a unit whose audio is not the
  /// loaded stream — the rosary's next step): the next resume starts THIS
  /// job instead of unpausing the loaded one. The stream stays paused —
  /// the position moved, nothing started, the notification keeps showing
  /// Play. No-op when not paused.
  void armResume(AudioJob job, {Object? owner}) {
    if (_info.state != AudioState.paused) return;
    _pendingResumeJob = job;
    _pendingResumeOwner = owner;
  }

  /// Takes audio focus for the new job so other apps' audio pauses while
  /// Fidelis plays (the player path re-requests on every play() too;
  /// idempotent while focus is held). Best-effort: never blocks or fails
  /// playback (the plugin may be unavailable, e.g. in tests).
  void _requestAudioFocus() {
    unawaited(() async {
      try {
        await (await AudioSession.instance).setActive(true);
      } catch (_) {}
    }());
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

  /// Initializes the aggregate-progress state for a new job: sequence jobs
  /// (all-text en/es) learn their whole-page duration from the lookahead's
  /// synthesis; every other job keeps the raw per-source timing.
  void _beginAggregateProgress(AudioJob job) {
    _sequenceServedCount = 0;
    _sequenceExpectedCount = 0;
    _sequenceCompletedSeconds = 0;
    if (!_isSequenceJob(job)) {
      _sequenceSentenceSeconds = null;
      return;
    }
    _sequenceSentenceSeconds = <double>[];
    for (final c in job.chunks) {
      _sequenceExpectedCount += TtsService.splitSentences(c.text ?? '').length;
    }
  }

  /// Records a stream sentence's render duration (the lookahead lands it
  /// AHEAD of its playback — the whole-page duration is learned early).
  void _noteSequenceSentenceDuration(Duration duration) {
    _sequenceSentenceSeconds?.add(duration.inMilliseconds / 1000.0);
  }

  /// Advances the aggregate position to the sentence about to be heard:
  /// every sentence before it is complete (its render duration is known —
  /// the lookahead guarantees it).
  void _noteSequenceSentenceServed() {
    final list = _sequenceSentenceSeconds;
    if (list != null) {
      var completed = 0.0;
      for (var i = 0; i < _sequenceServedCount && i < list.length; i++) {
        completed += list[i];
      }
      _sequenceCompletedSeconds = completed;
    }
    _sequenceServedCount++;
  }

  /// The published progress for the whole job: sequence jobs aggregate
  /// (cumulative position across completed sentences + the live position,
  /// against the whole-page duration — the learned renders plus the
  /// remaining sentences at the running average, converging on the true
  /// total); every other job keeps the raw per-source timing.
  AudioProgress _aggregateProgress(Duration position, Duration? totalDuration) {
    final list = _sequenceSentenceSeconds;
    // No render has landed yet (or a non-sequence job): the raw per-source
    // timing is all there is — publish it unchanged.
    if (list == null || list.isEmpty) {
      return AudioProgress(position: position, duration: totalDuration);
    }
    var learned = 0.0;
    for (final s in list) {
      learned += s;
    }
    final average = list.isEmpty ? 0.0 : learned / list.length;
    final remaining =
        (_sequenceExpectedCount - list.length).clamp(0, _sequenceExpectedCount);
    final totalSeconds = learned + remaining * average;
    final positionSeconds =
        _sequenceCompletedSeconds + position.inMilliseconds / 1000.0;
    return AudioProgress(
      position: Duration(milliseconds: (positionSeconds * 1000).round()),
      duration: Duration(milliseconds: (totalSeconds * 1000).round()),
    );
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
    final pendingJob = _pendingResumeJob;
    if (pendingJob != null) {
      // The notification's Next/Previous moved the position while paused
      // (the armed replacement job): resume starts THAT unit — the loaded
      // stream is replaced, the position the user moved to is honored.
      _pendingResumeJob = null;
      final owner = _pendingResumeOwner;
      _pendingResumeOwner = null;
      await start(pendingJob, owner: owner);
      return;
    }
    final parked = _parked;
    if (parked != null) {
      // The job finished naturally while the app was backgrounded (the
      // media notification stayed paused): "resume" replays the chunk the
      // playback ended on, through the normal job loop.
      await start(
        AudioJob(
          id: parked.job.id,
          chunks: parked.job.chunks.sublist(parked.chunkIndex),
          onCompleted: parked.job.onCompleted,
          title: parked.job.title,
        ),
        owner: parked.owner,
      );
      return;
    }
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

  /// The media notification's Stop: halt the playback and STAY. The player
  /// pauses at the current position, the job and its position are kept, and
  /// the media session remains paused so the notification stays showing
  /// Play — a later play resumes from the kept position. NOT the full
  /// [stop]: the in-app stop (which clears the job and dismisses the
  /// player, with play-after-stop restarting the chapter) is unchanged.
  /// No-op when nothing is playing (already halted, parked, or stopped —
  /// a parked stream is already halted and stays parked).
  Future<void> haltAndStay() async {
    if (_info.state != AudioState.playing) return;
    await pause();
  }

  /// Restarts the last-played content (the media session's play when
  /// nothing is loaded — e.g. a headset play button after a stop). No-op
  /// when nothing has played yet this session. The original owner is kept:
  /// while its screen still exists, leaving it still ends the stream.
  Future<void> restartLast() async {
    final last = _lastJob;
    if (last == null) return;
    await start(last.job, owner: last.owner);
  }

  /// Stops whatever is playing, regardless of owner.
  Future<void> stop() async {
    _epoch++;
    _owner = null;
    _parked = null;
    _loadedJob = null;
    _pendingResumeJob = null;
    _pendingResumeOwner = null;
    _currentJobTitle = null;
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
    // The pipeline finished: nothing is loaded anymore (the parked state
    // keeps the job for its resume via _parked).
    _loadedJob = null;
    if (_inForeground) {
      // Foreground end (the historical behavior): the stream goes idle and
      // the screen's own controls take over from here.
      _owner = null;
      _currentJobTitle = null;
      _info = const AudioPlaybackInfo.stopped();
    } else {
      // Backgrounded end: the media notification must stay in a PAUSED
      // state (resumable, dismissable) instead of vanishing — park the
      // finished job; a later resume replays the chunk it ended on. The
      // owner is kept so leaving the page still ends the parked stream.
      _parked = _ParkedPlayback(
        job: job,
        owner: _owner,
        chunkIndex: _info.chunkIndex,
      );
      _info = AudioPlaybackInfo(
        state: AudioState.paused,
        jobId: job.id,
        chunkIndex: _info.chunkIndex,
        sentenceIndex: _info.sentenceIndex,
      );
    }
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
    // The WHOLE-JOB progress (sequence jobs aggregate; the rest keep the
    // raw per-source timing) — the progress bar spans the chapter/page.
    _progress.value = _aggregateProgress(position, totalDuration);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _inForeground = true;
    } else if (state == AppLifecycleState.paused) {
      _inForeground = false;
    }
  }
}

/// The most recently started job (see [AudioController._lastJob]).
class _LastJob {
  final AudioJob job;
  final Object? owner;

  const _LastJob({required this.job, required this.owner});
}

/// A job that finished naturally while the app was backgrounded (see
/// [AudioController._finish]).
class _ParkedPlayback {
  final AudioJob job;
  final Object? owner;
  final int chunkIndex;

  const _ParkedPlayback({
    required this.job,
    required this.owner,
    required this.chunkIndex,
  });
}