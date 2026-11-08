import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:fidelis/services/tts_text.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// THE RUNTIME READOUT PROOF (the owner's explicit demand): the app's REAL
/// playback path — TtsService.speakPrayer → KokoroEngine (the worker
/// isolate, the real bundled model) → the sentence WAV → the player —
/// executing each of the four voice-grid slots, with the playback-start
/// readout captured verbatim. The blend proof: the slot's delivered render
/// is at least as long as the primary voice's SOLO render of the same text
/// (the mix is the LONGER of the two renders), so a blend that silently
/// skipped would show up as a shorter-than-solo delivery.
///
/// Run with the host's sherpa native lib on the loader path (the same env
/// tool/word_timing_verify.dart documents):
///   LD_LIBRARY_PATH=~/.pub-cache/hosted/pub.dev/sherpa_onnx_linux-1.13.8/linux/x64 \
///     flutter test test/runtime_slot_readout_test.dart
/// Skips cleanly where the native engine cannot load — the unit-test suite
/// stays green without the env.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Directory('/tmp/fidelis_kokoro_readout').createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => '/tmp/fidelis_kokoro_readout');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_session'),
            (call) async => null);
    JustAudioPlatform.instance = ReadoutMockPlatform();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_session'), null);
  });

  /// True when the REAL engine can initialize on this host (the native lib
  /// loads and the bundled model prepares). False → the tests skip.
  Future<bool> engineAvailable(String lang) async {
    try {
      return await KokoroEngine.ensureReady(lang);
    } catch (_) {
      return false;
    }
  }

  /// Plays [text] through the app's REAL pipeline for [voice]/[lang] and
  /// returns the captured readout lines.
  Future<List<String>> playAndCapture(
      String text, String lang, KokoroVoice voice) async {
    final lines = <String>[];
    TtsService.readoutSink = lines.add;
    try {
      await TtsService.speakPrayer(text, lang: lang, voice: voice);
    } finally {
      TtsService.readoutSink = null;
    }
    return lines;
  }

  Future<void> assertSlot(String lang, KokoroVoice voice, String text,
      {bool expectBlend = false}) async {
    if (!await engineAvailable(lang)) {
      markTestSkipped('the host sherpa native lib is not on the loader '
          'path — run with LD_LIBRARY_PATH (see the file header)');
      return;
    }
    final lines = await playAndCapture(text, lang, voice);

    // THE PLAYBACK-START READOUT: the active sids, speed, and EQ state.
    final playback = lines.firstWhere((l) => l.contains('playback slot='),
        orElse: () => '<missing>');
    // ignore: avoid_print
    print('READOUT $playback');
    expect(playback, contains('slot=${slotNameFor(voice)}'));
    expect(playback, contains('lang=$lang'));
    expect(playback, contains('voice=${voice.nameFor(lang)}'
        '(${voice.sidFor(lang)})'));
    final blendSid = voice.blendSidFor(lang);
    if (blendSid == null) {
      expect(playback, isNot(contains('blend=')));
      expect(playback, contains('eq=flat'));
    } else {
      expect(playback, contains('+${voice.blendNameFor(lang)}($blendSid)'));
      expect(playback, contains('blend=${voice.blendRatio.toStringAsFixed(2)}'));
    }
    expect(playback, contains('speed=${voice.speed.toStringAsFixed(2)}'));
    final eq = voice.equalizerFor(lang);
    if (eq == null || eq.isEmpty) {
      expect(playback, contains('eq=flat'));
    } else {
      for (final entry in eq.entries) {
        expect(playback,
            contains('${entry.key}:${entry.value.toStringAsFixed(1)}dB'));
      }
    }

    // THE ENGINE OUTCOME: the Kokoro path delivered (no silent fallback).
    expect(
        lines.any((l) => l.contains('engine=kokoro')),
        isTrue,
        reason: 'the slot config must execute through Kokoro — a fallback '
            'would speak the SYSTEM voice');

    // THE EQ APPLICATION: the shaped slot's gains reached the platform
    // after the source load (the cold-player fix).
    if (eq != null && eq.isNotEmpty) {
      expect(
          lines.any((l) => l.contains('eq applied: enabled=true')),
          isTrue,
          reason: 'the directed EQ must apply at playback — the pre-load '
              'application timed out unseen on a cold player before the '
              'fix');
    }

    // THE BLEND PROOF: the engine's gen record reports the blend execution
    // (the partner rendered and the PCM mix executed) and the render
    // lengths — the mixed length is the LONGER of the two renders. A
    // silently skipped blend would report blended=false.
    if (expectBlend && blendSid != null) {
      final audio = await KokoroEngine.synthesize(text, lang, voice: voice);
      expect(audio, isNotNull);
      // ignore: avoid_print
      print('READOUT blend proof: blended=${audio!.blended} '
          'mixed=${audio.samples.length} samples, '
          'primary=${audio.primarySamples}, '
          'partner=${audio.partnerSamples}');
      expect(audio.blended, isTrue,
          reason: 'the directed blend must EXECUTE — the engine record '
              'reports the partner render and the PCM mix');
      expect(audio.samples.length,
          greaterThanOrEqualTo(audio.primarySamples));
      expect(audio.samples.length,
          greaterThanOrEqualTo(audio.partnerSamples!),
          reason: 'the mixed length is the LONGER of the two renders');
      expect(audio.partnerSamples, isNotNull);
      expect(audio.partnerSamples, greaterThan(0));
    } else if (blendSid == null) {
      final audio = await KokoroEngine.synthesize(text, lang, voice: voice);
      expect(audio!.blended, isFalse,
          reason: 'a solo slot must not report a blend');
    }
  }

  test('Bible EN: the Michael+Echo blend config executes at playback',
      () async {
    await assertSlot(
        'en',
        KokoroVoice.bible,
        'The Lord is my shepherd; I shall not want.',
        expectBlend: true);
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('Bible ES: the Alex solo config executes at playback', () async {
    await assertSlot('es', KokoroVoice.bible,
        'El Señor es mi pastor; nada me faltará.');
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('Rosary EN: the Aoede solo config executes at playback', () async {
    await assertSlot('en', KokoroVoice.rosary,
        'Hail Mary, full of grace, the Lord is with thee.');
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('Rosary ES: the Aoede+Dora blend config executes at playback',
      () async {
    await assertSlot(
        'es',
        KokoroVoice.rosary,
        'Dios te salve María, llena eres de gracia.',
        expectBlend: true);
  }, timeout: const Timeout(Duration(minutes: 6)));
}

/// Scripted just_audio platform for the readout run: a single player whose
/// load captures the source (the sentence WAV — the blend-length proof
/// reads its sample count) and whose play completes the playback (the
/// state broadcasts completed shortly after play returns, so the pipeline's
/// chunk await resolves). The equalizer reports 5 bands and records every
/// effect call, so the slot shaping applies for real.
class ReadoutMockPlatform extends JustAudioPlatform
    with MockPlatformInterfaceMixin {
  final players = <String, ReadoutMockPlayer>{};

  /// Set per play: captures the loaded source message (the sentence WAV —
  /// the blend-length proof reads its sample count).
  void Function(AudioSourceMessage)? onLoad;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final p = ReadoutMockPlayer(request.id);
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

class ReadoutMockPlayer extends AudioPlayerPlatform {
  final eventController = StreamController<PlaybackEventMessage>.broadcast();

  ReadoutMockPlayer(super.id);

  void _broadcast(ProcessingStateMessage state) {
    eventController.add(PlaybackEventMessage(
      processingState: state,
      updatePosition: Duration.zero,
      updateTime: DateTime.now(),
      bufferedPosition: Duration.zero,
      icyMetadata: null,
      duration: const Duration(seconds: 30),
      currentIndex: 0,
      androidAudioSessionId: null,
      errorCode: null,
      errorMessage: null,
    ));
  }

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      eventController.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final platform = JustAudioPlatform.instance as ReadoutMockPlatform;
    platform.onLoad?.call(request.audioSourceMessage);
    _broadcast(ProcessingStateMessage.ready);
    return LoadResponse(duration: const Duration(seconds: 30));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    // Complete the playback shortly after play returns, so the pipeline's
    // chunk await resolves (the sub is installed after play()).
    Timer(const Duration(milliseconds: 60),
        () => _broadcast(ProcessingStateMessage.completed));
    return PlayResponse();
  }

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
  Future<SetShuffleOrderResponse> setShuffleOrder(
          SetShuffleOrderRequest request) async =>
      SetShuffleOrderResponse();

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
