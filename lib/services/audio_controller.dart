import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tts_service.dart';

/// Playback state of the single audio stream.
enum AudioState { stopped, playing, paused }

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
  }) {
    return TtsService.speakPrayer(text, lang: lang, onSentenceStart: onSentenceStart);
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

  AudioEngine _engine;
  int _epoch = 0;
  Object? _owner;
  AudioPlaybackInfo _info = const AudioPlaybackInfo.stopped();

  /// Opened by [resume] once the resumed audio has finished playing out —
  /// the job loop waits on it so a flutter_tts pause (which completes the
  /// current chunk early) does not skip to the next chunk while paused.
  Completer<void>? _resumeGate;
  final ValueNotifier<AudioPlaybackInfo> _notifier =
      ValueNotifier<AudioPlaybackInfo>(const AudioPlaybackInfo.stopped());

  /// State + position stream for UI toggles and highlight syncing.
  ValueListenable<AudioPlaybackInfo> get listenable => _notifier;
  AudioState get state => _info.state;
  String? get currentJobId => _info.jobId;

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
    for (var i = 0; i < job.chunks.length; i++) {
      if (myEpoch != _epoch) return;
      final chunk = job.chunks[i];
      _emit(job.id, AudioState.playing, i, 0);
      try {
        final asset = chunk.asset;
        if (asset != null) {
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
    job.onCompleted?.call();
  }

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