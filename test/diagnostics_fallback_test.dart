import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_diagnostics.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// THE NO-SILENT-FALLBACK PROOF: when Kokoro fails to load or synthesize,
/// the fallback to flutter_tts (the system voice) announces itself with the
/// ROOT CAUSE — the fallback line carries the Kokoro failure text, and the
/// AudioDiagnostics service (the on-screen banner's source) records both
/// the fallback and the error. The forced-failure hook drives the real
/// TtsService fallback path without the native engine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Directory('/tmp/fidelis_fallback_test').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '/tmp/fidelis_fallback_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_session'),
            (call) async => null);
    JustAudioPlatform.instance = FallbackMockPlatform();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_session'), null);
  });

  setUp(() {
    AudioDiagnostics.instance.clear();
  });

  test('a forced Kokoro failure surfaces the fallback with the root cause '
      'through the REAL speakPrayer path', () async {
    const cause = 'engine init failed: Failed to set eSpeak-ng voice';
    KokoroEngine.forceFailedForTest(cause);
    final lines = <String>[];
    TtsService.readoutSink = lines.add;
    try {
      await TtsService.speakPrayer(
        'The Lord is my shepherd; I shall not want.',
        lang: 'en',
      );
    } finally {
      TtsService.readoutSink = null;
    }
    // The playback-start line came first (the requested slot config).
    expect(
        lines.any((l) => l.contains('playback slot=standard')), isTrue);
    // The fallback announced itself — never silent.
    expect(lines.any((l) => l.contains('FALLBACK engine=flutter_tts '
        '(system voice)')), isTrue,
        reason: 'the fallback must announce itself');
    // The ROOT CAUSE rides the same line: the on-screen banner shows WHY.
    expect(lines.any((l) => l.contains('Kokoro failed: $cause')), isTrue,
        reason: 'the fallback line must carry the Kokoro failure text');

    // The diagnostics service (the banner's source) records the truth when
    // wired exactly as main.dart wires it.
    TtsService.readoutSink = AudioDiagnostics.instance.recordLine;
    KokoroEngine.failureSink = AudioDiagnostics.instance.recordKokoroError;
    try {
      KokoroEngine.forceFailedForTest(cause);
      await TtsService.speakPrayer(
        'The Lord is my shepherd; I shall not want.',
        lang: 'en',
      );
    } finally {
      TtsService.readoutSink = null;
      KokoroEngine.failureSink = null;
    }
    final d = AudioDiagnostics.instance;
    expect(d.slotReadout, isNotNull);
    expect(d.engineUsed, 'flutter_tts');
    expect(d.fallbackLine, contains('FALLBACK engine=flutter_tts'));
    expect(d.fallbackLine, contains('Kokoro failed: $cause'));
    expect(d.kokoroError, cause,
        reason: 'the sticky root cause feeds the banner and the readout');
  });

  test('a new playback start clears the fallback banner', () {
    final d = AudioDiagnostics.instance;
    d.recordLine('[Fidelis audio] FALLBACK engine=flutter_tts (system '
        'voice) reason=kokoro unavailable for en — Kokoro failed: x');
    expect(d.fallbackLine, isNotNull);
    d.recordLine('[Fidelis audio] playback slot=bible lang=en '
        'voice=am_michael(16) speed=0.81 eq=flat lexicon=2');
    expect(d.fallbackLine, isNull);
    expect(d.engineUsed, isNull);
  });

  test('the diagnostics state survives a Kokoro success after a failure '
      '(the sticky error stays, the banner clears on the next playback)',
      () {
    final d = AudioDiagnostics.instance;
    d.recordKokoroError('synthesis failed: boom');
    d.recordLine('[Fidelis audio] FALLBACK engine=flutter_tts (system '
        'voice) reason=kokoro unavailable for en — Kokoro failed: synthesis '
        'failed: boom');
    // The next playback starts (Kokoro recovered after a restart).
    d.recordLine('[Fidelis audio] playback slot=bible lang=en '
        'voice=am_michael(16)+am_echo(12) blend=0.70 speed=0.81 eq=flat '
        'lexicon=2');
    d.recordLine('[Fidelis audio] engine=kokoro (the slot config above '
        'executed)');
    expect(d.engineUsed, 'kokoro');
    expect(d.fallbackLine, isNull);
    // The sticky root cause remains visible in the readout even after a
    // recovery — the owner can still see what failed earlier.
    expect(d.kokoroError, 'synthesis failed: boom');
  });
}

/// Scripted just_audio platform for the fallback run: the fallback path
/// never loads a source, but TtsService's static player and equalizer
/// construct on first class touch — the stub keeps them off the real
/// channel (the same pattern as test/runtime_slot_readout_test.dart).
class FallbackMockPlatform extends JustAudioPlatform
    with MockPlatformInterfaceMixin {
  final players = <String, FallbackMockPlayer>{};

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final p = FallbackMockPlayer(request.id);
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

class FallbackMockPlayer extends AudioPlayerPlatform {
  final eventController = StreamController<PlaybackEventMessage>.broadcast();

  FallbackMockPlayer(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      eventController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async =>
      LoadResponse(duration: const Duration(seconds: 30));

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

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
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await eventController.close();
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
}
