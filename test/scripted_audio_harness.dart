// Scripted just_audio platform + channel mocks for the audio-pipeline
// tests (the lookahead pipeline, the kokoro-exclusive engine, the progress
// aggregation). The gated player mirrors the real Java play semantics —
// the play result stays PENDING until the test completes the playback —
// so a test can assert on the pipeline state mid-play.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Scripted single-source/playlist player: load -> ready, play -> the play
/// result PENDING until [completePlayback] (real Java semantics, gated).
/// Playlist-aware: [concatenatingInsertAll] records the appended items
/// (the pipeline appends each sentence's render as it lands),
/// [completeItem] advances the currentIndex to the next appended item
/// (ExoPlayer's seamless auto-advance), and the playlist's LAST item
/// completes the whole playback (STATE_ENDED semantics). The audio-effect
/// surface (the shared player's AudioPipeline) is answered so the
/// load/play sequence never breaks.
class GatedPlayer extends AudioPlayerPlatform {
  final eventController = StreamController<PlaybackEventMessage>.broadcast();
  ProcessingStateMessage _state = ProcessingStateMessage.idle;
  Duration _pos = Duration.zero;
  Completer<void>? _pendingPlay;
  int playCount = 0;
  int loadCount = 0;
  final Duration duration;

  /// The playlist's item count: 1 after the initial load, +1 per appended
  /// source (the pipeline's sentence appends).
  int itemCount = 0;

  /// The current playlist item index (the sentence-start callbacks fire
  /// from the currentIndex stream).
  int _currentIndex = 0;

  /// The seek requests received (index+position) — the unit-move and
  /// frontier-resume seeks are asserted in the tests.
  final seeks = <(int?, Duration?)>[];

  GatedPlayer(InitRequest request, {this.duration = const Duration(seconds: 3)})
      : super(request.id);

  /// True while a play result is pending (the pipeline is mid-playback) —
  /// the tests wait for this before completing a playback, so a premature
  /// completion is never lost.
  bool get hasPendingPlay => _pendingPlay != null && !_pendingPlay!.isCompleted;

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      eventController.stream;

  void _broadcast() {
    eventController.add(PlaybackEventMessage(
      processingState: _state,
      updatePosition: _pos,
      updateTime: DateTime.now(),
      bufferedPosition: _pos,
      icyMetadata: null,
      duration: duration,
      currentIndex: _currentIndex,
      androidAudioSessionId: null,
      errorCode: null,
      errorMessage: null,
    ));
  }

  void _completePlay() {
    final c = _pendingPlay;
    _pendingPlay = null;
    if (c != null && !isCompleted(c)) c.complete();
  }

  static bool isCompleted(Completer<void> c) => c.isCompleted;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    loadCount++;
    // The playlist arrives as ONE concatenated source message (the
    // platform interface's shape): its children are the playlist items.
    final source = request.audioSourceMessage;
    itemCount = source is ConcatenatingAudioSourceMessage
        ? source.children.length
        : 1;
    _currentIndex = request.initialIndex ?? 0;
    _state = ProcessingStateMessage.ready;
    _pos = request.initialPosition ?? Duration.zero;
    _broadcast();
    return LoadResponse(duration: duration);
  }

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
      ConcatenatingInsertAllRequest request) async {
    itemCount += request.children.length;
    return ConcatenatingInsertAllResponse();
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    playCount++;
    _broadcast();
    final prior = _pendingPlay;
    _pendingPlay = Completer<void>();
    if (prior != null && !prior.isCompleted) prior.complete();
    return _pendingPlay!.future.then((_) => PlayResponse());
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    _completePlay();
    return PauseResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();
  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();
  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
          SetSkipSilenceRequest request) async =>
      SetSkipSilenceResponse();
  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();
  @override
  Future<SetShuffleModeResponse> setShuffleMode(
          SetShuffleModeRequest request) async =>
      SetShuffleModeResponse();
  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
          SetShuffleOrderRequest request) async =>
      SetShuffleOrderResponse();
  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    seeks.add((request.index, request.position));
    if (request.index != null) _currentIndex = request.index!;
    _pos = request.position ?? Duration.zero;
    _broadcast();
    return SeekResponse();
  }

  /// Completes the CURRENT item: the player advances to the next appended
  /// item (ExoPlayer's seamless playlist auto-advance — the currentIndex
  /// changes, the play stays pending) or, at the playlist's end, completes
  /// the whole playback (STATE_ENDED semantics: processingState=completed,
  /// the pending play result completes).
  void completeItem() {
    if (_currentIndex + 1 < itemCount) {
      _currentIndex++;
      _state = ProcessingStateMessage.ready;
      _pos = Duration.zero;
      _broadcast();
    } else {
      completePlayback();
    }
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    _completePlay();
    return DisposeResponse();
  }

  @override
  Future<AudioEffectSetEnabledResponse> audioEffectSetEnabled(
          AudioEffectSetEnabledRequest request) async =>
      AudioEffectSetEnabledResponse();

  @override
  Future<AndroidEqualizerGetParametersResponse> androidEqualizerGetParameters(
      AndroidEqualizerGetParametersRequest request) async {
    return AndroidEqualizerGetParametersResponse(
      parameters: AndroidEqualizerParametersMessage(
        minDecibels: -15.0,
        maxDecibels: 15.0,
        bands: [
          for (var i = 0; i < 5; i++)
            AndroidEqualizerBandMessage(
              index: i,
              lowerFrequency: 30.0 * (1 << i),
              upperFrequency: 30.0 * (1 << (i + 1)),
              centerFrequency: 30.0 * (1 << i) * 1.4,
              gain: 0.0,
            ),
        ],
      ),
    );
  }

  @override
  Future<AndroidEqualizerBandSetGainResponse> androidEqualizerBandSetGain(
          AndroidEqualizerBandSetGainRequest request) async =>
      AndroidEqualizerBandSetGainResponse();

  /// Completes the pending playback (ExoPlayer STATE_ENDED semantics:
  /// processingState=completed, the pending play result completes).
  void completePlayback() {
    _state = ProcessingStateMessage.completed;
    _pos = duration;
    _broadcast();
    _completePlay();
  }
}

/// The gated platform: one [GatedPlayer] per just_audio player id.
class GatedPlatform extends JustAudioPlatform with MockPlatformInterfaceMixin {
  final players = <String, GatedPlayer>{};

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final p = GatedPlayer(request);
    players[request.id] = p;
    return p;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    players.remove(request.id)?.dispose(DisposeRequest());
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
      DisposeAllPlayersRequest request) async {
    for (final p in players.values) {
      p.dispose(DisposeRequest());
    }
    players.clear();
    return DisposeAllPlayersResponse();
  }
}

/// Installs the channel mocks the pipeline tests need. Returns the list
/// the flutter_tts method calls are recorded into (the kokoro-exclusive
/// assertion reads it).
List<String> installPipelineChannelMocks() {
  final ttsCalls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    ..setMockMethodCallHandler(
        const MethodChannel('com.ryanheise.audio_session'),
        (call) async => null)
    ..setMockMethodCallHandler(const MethodChannel('flutter_tts'),
        (call) async {
      ttsCalls.add(call.method);
      return null;
    })
    ..setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async {
      final dir = Directory.systemTemp.createTempSync('fidelis_pipeline');
      switch (call.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationSupportDirectory':
        case 'getApplicationDocumentsDirectory':
          return dir.path;
      }
      return null;
    });
  return ttsCalls;
}

/// Waits until [platform] has a player with a PENDING play (the pipeline
/// is mid-playback) and returns that player. The pipeline's WAV writes are
/// real async I/O — a premature completion would be lost, so tests wait
/// for this before completing a playback.
Future<GatedPlayer> waitPendingPlayOn(GatedPlatform platform) async {
  await waitFor(
      () => platform.players.values.any((p) => p.hasPendingPlay));
  return platform.players.values.firstWhere((p) => p.hasPendingPlay,
      orElse: () => throw StateError('no pending play'));
}

/// Lets async chains and microtasks run.
Future<void> settle() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Waits (real time) until [predicate] holds or ~4s elapse.
Future<bool> waitFor(bool Function() predicate) async {
  for (var i = 0; i < 200; i++) {
    if (predicate()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  return predicate();
}
