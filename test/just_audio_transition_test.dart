// Regression for the real just_audio 0.10.6 transition quirks behind the
// Rosary Next auto-continue defect, driven through the app's real
// [TtsService.playAssetFile] over a scripted platform:
//
//  - after a natural completion the Dart-side `playing` stays true (nothing
//    ever clears playWhenReady) and a bare play() early-returns without
//    sending a play request — on Android the player sits in STATE_ENDED,
//    where ExoPlayer will not restart without a seek;
//  - TtsService._playSource clears that stale playing state before loading
//    the next source, so its play() always reaches the platform.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class ScriptedPlatform extends JustAudioPlatform
    with MockPlatformInterfaceMixin {
  final players = <String, ScriptedPlayer>{};
  final log = <String>[];

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    log.add('init');
    final p = ScriptedPlayer(request, log);
    players[request.id] = p;
    return p;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    log.add('disposePlayer');
    players.remove(request.id);
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
      DisposeAllPlayersRequest request) async {
    log.add('disposeAllPlayers');
    players.clear();
    return DisposeAllPlayersResponse();
  }
}

/// Scripted single-source player: load -> ready (30s), play -> playing,
/// completeNaturally() -> the completed event (ExoPlayer STATE_ENDED:
/// playWhenReady stays true). Records every request.
class ScriptedPlayer extends AudioPlayerPlatform {
  final List<String> log;
  final eventController = StreamController<PlaybackEventMessage>.broadcast();
  ProcessingStateMessage _state = ProcessingStateMessage.idle;
  Duration _pos = Duration.zero;
  final Duration duration = const Duration(seconds: 30);

  ScriptedPlayer(InitRequest request, this.log) : super(request.id);

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
      currentIndex: 0,
      androidAudioSessionId: null,
      errorCode: null,
      errorMessage: null,
    ));
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    log.add('load');
    _state = ProcessingStateMessage.ready;
    _pos = request.initialPosition ?? Duration.zero;
    _broadcast();
    return LoadResponse(duration: duration);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    log.add('play');
    _broadcast();
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    log.add('pause');
    _broadcast();
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
    log.add('seek');
    _pos = request.position ?? Duration.zero;
    _broadcast();
    return SeekResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    log.add('dispose');
    return DisposeResponse();
  }

  /// Simulates playback running to the end (ExoPlayer STATE_ENDED:
  /// processingState=completed, playWhenReady stays true).
  void completeNaturally() {
    log.add('<<completed>>');
    _state = ProcessingStateMessage.completed;
    _pos = duration;
    _broadcast();
  }
}

/// Lets async chains and microtasks run.
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioSessionChannel = MethodChannel('com.ryanheise.audio_session');
  const ttsChannel = MethodChannel('flutter_tts');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    ..setMockMethodCallHandler(audioSessionChannel, (call) async => null)
    ..setMockMethodCallHandler(ttsChannel, (call) async => null)
    ..setMockMethodCallHandler(pathProviderChannel, (call) async {
      final dir = Directory.systemTemp.createTempSync('fidelis_transition');
      switch (call.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationSupportDirectory':
        case 'getApplicationDocumentsDirectory':
          return dir.path;
      }
      return null;
    });

  test('just_audio quirk: bare play() after a natural completion sends no '
      'play request (the stale playing state)', () async {
    final platform = ScriptedPlatform();
    JustAudioPlatform.instance = platform;
    final player = AudioPlayer();
    await player.setAudioSource(
        AudioSource.uri(Uri.parse('https://example.org/a.ogg')));
    await player.play();
    expect(platform.log.any((e) => e.startsWith('play')), isTrue);

    // The source finishes naturally: STATE_ENDED, playWhenReady stays true.
    platform.players.values.first.completeNaturally();
    await _settle();
    expect(player.processingState, ProcessingState.completed);
    expect(player.playing, isTrue,
        reason: 'just_audio never clears the Dart-side playing state after '
            'a natural completion');

    platform.log.clear();
    await player.setAudioSource(
        AudioSource.uri(Uri.parse('https://example.org/b.ogg')));
    await _settle();
    platform.log.clear();
    await player.play();
    await _settle();
    expect(platform.log.any((e) => e.startsWith('play')), isFalse,
        reason: 'the bare play() early-returns on the stale playing state — '
            'the device-level break the app must work around');
    await player.dispose();
  });

  test('TtsService.playAssetFile: the next source receives a play request '
      'even after a natural completion (stale playing state cleared)',
      () async {
    final platform = ScriptedPlatform();
    JustAudioPlatform.instance = platform;

    // First source: start, then let it finish naturally. The asset copy +
    // platform init/load run on real async — poll for the play request.
    final first = TtsService.playAssetFile('assets/app_icon.png');
    expect(await waitFor(() => platform.log.any((e) => e.startsWith('play'))),
        isTrue);
    platform.players.values.first.completeNaturally();
    await first.timeout(const Duration(seconds: 5));
    expect(platform.log.any((e) => e == '<<completed>>'), isTrue);

    // Second source right after the natural completion — the Rosary
    // Next/auto-continue transition. The stale playing state must be
    // cleared so the play request reaches the platform.
    platform.log.clear();
    final second = TtsService.playAssetFile('assets/app_icon.png');
    expect(await waitFor(() => platform.log.any((e) => e.startsWith('play'))),
        isTrue,
        reason: 'the second source must receive a play request despite the '
            'stale playing state left by the natural completion');
    await TtsService.stop();
    await second.timeout(const Duration(seconds: 5));
  });
}