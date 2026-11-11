import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:fidelis/services/tts_text.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The owner's voice grid — BLENDS CANCELLED, every slot ONE voice: the
/// four per-slot Kokoro configurations (Bible EN Michael solo + EQ, Bible
/// ES Alex solo, Rosary EN Aoede solo, Rosary ES Aoede solo speaking
/// Spanish), the blend-path removal (one render per sentence, no fused
/// voices, no voices.bin appends, no mix path), and the slot-scoped
/// Android-equalizer wiring driven against a scripted just_audio platform.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('voice grid slots', () {
    test('slot 1 — English Bible: Michael SOLO, softened by the EQ on '
        'the English slot only', () {
      const v = KokoroVoice.bible;
      expect(v.enSid, 16); // am_michael
      expect(v.enName, 'am_michael');
      expect(v.speed, 0.81);
      expect(v.enEqualizer, {0: -4.0, 1: -2.0});
      expect(v.equalizerFor('en'), {0: -4.0, 1: -2.0});
      // THE SOFTENING IS THE EQ: the slot speaks ONE voice (Michael) and
      // the gentle low-band shaping is the only softening — no blend
      // partner, no second voice.
      // Michael's addendum pronunciation list is the Bible's standing EN
      // lexicon: ruleth + pasture; the round-2 'Salm' respelling is
      // REMOVED ('psalm' phonemizes natively under en-us — no audible L).
      expect(v.lexiconFor('en'), {'ruleth': 'Rouleth', 'pasture': 'Pastsher'});
      // The Bible slot carries NO slot-scoped corrections — the rosary's
      // bless-ed correction must not leak into Bible processing.
      expect(kokoroVoiceLexicon['am_michael']!.containsKey('psalm'), isFalse);
      expect(v.lexiconFor('en').containsKey('blessed'), isFalse);
    });

    test('slot 2 — Spanish Bible: Alex solo, unchanged', () {
      const v = KokoroVoice.bible;
      expect(v.esSid, 29); // em_alex
      expect(v.esName, 'em_alex');
      expect(v.esEqualizer, isNull); // no EQ
      expect(v.lexiconFor('es'), isEmpty); // no corrections
      expect(v.speed, 0.81);
    });

    test('slot 3 — English Rosary: Aoede solo at the auditioned pace', () {
      const v = KokoroVoice.rosary;
      expect(v.enSid, 1); // af_aoede
      expect(v.enName, 'af_aoede');
      expect(v.enEqualizer, isNull); // no EQ
      expect(v.speed, 0.9);
      // The rosary-scoped bless-ed correction (the owner's addendum): the
      // Hail Mary's 'blessed' renders as two syllables in the rosary
      // synthesis input.
      expect(v.enSlotLexicon, {'blessed': 'bless-ed'});
      expect(v.lexiconFor('en'), {'blessed': 'bless-ed'});
    });

    test('slot 4 — Spanish Rosary: Aoede SOLO speaking Spanish (no Dora '
        'anywhere)', () {
      const v = KokoroVoice.rosary;
      expect(v.esSid, 1); // af_aoede — the SAME voice as the EN slot
      expect(v.esName, 'af_aoede');
      expect(v.speed, 0.9);
      expect(v.esEqualizer, isNull); // no EQ
      // ONE rosary voice in both languages: the ES slot speaks Aoede
      // under the Spanish phonemization; her non-native accent is the
      // owner's accepted trade-off — NOT improved by blending or swapping.
      // The Spanish rosary is unaffected by the bless-ed correction: no
      // ES slot lexicon, and the voice-name lexicon for af_aoede is empty.
      expect(v.esSlotLexicon, isNull);
      expect(v.lexiconFor('es'), isEmpty);
    });

    test('the bless-ed correction is ROSARY-SCOPED — it never leaks into '
        'Bible processing', () {
      // The Bible slot's EN lexicon has no blessed entry.
      expect(KokoroVoice.bible.enSlotLexicon, isNull);
      expect(KokoroVoice.bible.lexiconFor('en').containsKey('blessed'),
          isFalse);
      // The standard slot (readings + rosary asset timing) has none either.
      expect(KokoroVoice.standard.lexiconFor('en').containsKey('blessed'),
          isFalse);
      // The correction applies to the rosary slot only.
      expect(KokoroVoice.rosary.lexiconFor('en').containsKey('blessed'),
          isTrue);
    });

    test('the bless-ed correction renders the Hail Mary as ordered', () {
      const hailMary =
          'Hail Mary, full of grace, the Lord is with thee; blessed art '
          'thou among women, and blessed is the fruit of thy womb, Jesus.';
      final (spoken, _) = applyPronunciationLexicon(
          hailMary, KokoroVoice.rosary.lexiconFor('en'));
      expect(
          spoken,
          'Hail Mary, full of grace, the Lord is with thee; bless-ed art '
          'thou among women, and bless-ed is the fruit of thy womb, Jesus.');
      // Idempotent: the respelling never matches its source word.
      final (again, _) = applyPronunciationLexicon(
          spoken, KokoroVoice.rosary.lexiconFor('en'));
      expect(again, spoken);
    });

    test('ef_dora appears NOWHERE in the voice grid', () {
      for (final v in const [
        KokoroVoice.standard,
        KokoroVoice.bible,
        KokoroVoice.rosary,
      ]) {
        expect(v.enSid, isNot(28), reason: '${v.enName} EN primary');
        expect(v.esSid, isNot(28), reason: '${v.esName} ES primary');
        expect(v.enName, isNot('ef_dora'));
        expect(v.esName, isNot('ef_dora'));
      }
      // BLENDS CANCELLED: she appears NOWHERE — no slot speaks her, no
      // fused voice carries her, nothing references her sid.
      expect(KokoroVoice.rosary.esSid, isNot(28));
    });

    test('standard profile unchanged (readings + rosary asset timing)', () {
      const v = KokoroVoice.standard;
      expect(v.enSid, 26); // bm_george
      expect(v.esSid, 29); // em_alex
      expect(v.speed, 0.9);
      expect(v.enName, 'bm_george');
      expect(v.esName, 'em_alex');
      expect(v.enEqualizer, isNull);
      expect(v.esEqualizer, isNull);
    });
  });

  group('the blend-path removal (no fused voices, no appends, no mix)', () {
    test("every slot synthesizes ONE render per sentence — the slot's own "
        'sid, no partner render', () {
      final cases = [
        (KokoroVoice.bible, 'en', 16),
        (KokoroVoice.bible, 'es', 29),
        (KokoroVoice.rosary, 'en', 1),
        (KokoroVoice.rosary, 'es', 1),
        (KokoroVoice.standard, 'en', 26),
        (KokoroVoice.standard, 'es', 29),
      ];
      for (final (voice, lang, expectedSid) in cases) {
        var generateCalls = 0;
        final sids = <int>[];
        (Float32List, int) generate(String text, int sid, double speed) {
          generateCalls++;
          sids.add(sid);
          expect(speed, voice.speed);
          return (Float32List(16), 24000);
        }

        synthesizeSlotSentence(
            generate, 'The Lord is my shepherd.', voice, lang);
        expect(generateCalls, 1,
            reason: '$lang ${voice.enName}: ONE render — the removed '
                'two-render blend path would have generated twice');
        expect(sids, [expectedSid],
            reason: 'the slot speaks its OWN voice — no fused sid, no '
                'partner sid');
      }
    });

    test('the slot readout names the single voice — no blend/fused markers',
        () {
      final cases = [
        (KokoroVoice.bible, 'en', 'am_michael', 16),
        (KokoroVoice.bible, 'es', 'em_alex', 29),
        (KokoroVoice.rosary, 'en', 'af_aoede', 1),
        (KokoroVoice.rosary, 'es', 'af_aoede', 1),
      ];
      for (final (voice, lang, name, sid) in cases) {
        final line = slotReadoutLine(voice, lang);
        expect(line, contains('voice=$name($sid)'));
        expect(line, isNot(contains('blend=')));
        expect(line, isNot(contains('fused(')));
      }
    });
  });

  group('applyEqualizerGains (the EQ wiring)', () {
    late EqualizerMockPlatform platform;

    setUp(() {
      platform = EqualizerMockPlatform();
      JustAudioPlatform.instance = platform;
      const audioSessionChannel = MethodChannel('com.ryanheise.audio_session');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(audioSessionChannel, (call) async => null);
      // just_audio's _setPlatformActive resolves a cache directory through
      // path_provider when loading asset sources; the scripted platform
      // must answer it or asset loads throw MissingPluginException.
      const pathProviderChannel =
          MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (call) async => '/tmp');
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.ryanheise.audio_session'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'), null);
    });

    test('slot gains enable the equalizer and set the listed bands', () async {
      final eq = AndroidEqualizer();
      final player = AudioPlayer(
        handleInterruptions: false,
        audioPipeline: AudioPipeline(androidAudioEffects: [eq]),
      );
      // Loading activates the pipeline's effects: the mock's parameters
      // (5 bands, like a real Android equalizer) resolve.
      await player.setAudioSource(
          AudioSource.asset('assets/rosary_audio/en/hail_mary.ogg'));
      await applyEqualizerGains(eq, {0: -4.0, 1: -2.0});
      expect(platform.enabledLog, [true]);
      expect(platform.gainLog,
          containsAllInOrder([(0, -4.0), (1, -2.0)]));
      expect(platform.gainLog.length, 2);
      await player.dispose();
    });

    test('null gains clear the shaping (the equalizer is disabled)', () async {
      final eq = AndroidEqualizer();
      final player = AudioPlayer(
        handleInterruptions: false,
        audioPipeline: AudioPipeline(androidAudioEffects: [eq]),
      );
      await player.setAudioSource(
          AudioSource.asset('assets/rosary_audio/en/hail_mary.ogg'));
      await applyEqualizerGains(eq, {0: -4.0, 1: -2.0});
      await applyEqualizerGains(eq, null);
      expect(platform.enabledLog, [true, false]);
      // No further band writes on the clear.
      expect(platform.gainLog.length, 2);
      await player.dispose();
    });

    test('out-of-range band indexes are skipped, never thrown', () async {
      final eq = AndroidEqualizer();
      final player = AudioPlayer(
        handleInterruptions: false,
        audioPipeline: AudioPipeline(androidAudioEffects: [eq]),
      );
      await player.setAudioSource(
          AudioSource.asset('assets/rosary_audio/en/hail_mary.ogg'));
      await applyEqualizerGains(eq, {0: -4.0, 9: -1.0, -1: -2.0});
      expect(platform.enabledLog, [true]);
      expect(platform.gainLog, [(0, -4.0)]);
      await player.dispose();
    });

    test('without platform activation the bounded wait returns cleanly',
        () async {
      // No load: the player is not active, so setEnabled's platform send
      // is skipped (just_audio AudioEffect.setEnabled only reaches the
      // platform when _active) and the parameters future never resolves —
      // the gains call must return after the (short) test timeout without
      // throwing and without any platform writes.
      final eq = AndroidEqualizer();
      final player = AudioPlayer(
        handleInterruptions: false,
        audioPipeline: AudioPipeline(androidAudioEffects: [eq]),
      );
      await applyEqualizerGains(eq, {0: -4.0, 1: -2.0},
          parametersTimeout: const Duration(milliseconds: 200));
      expect(platform.enabledLog, isEmpty);
      expect(platform.gainLog, isEmpty);
      await player.dispose();
    });
  });
}

/// Scripted just_audio platform for the EQ wiring tests: a single player
/// whose equalizer reports 5 bands (a common Android equalizer shape) and
/// records every effect call.
class EqualizerMockPlatform extends JustAudioPlatform
    with MockPlatformInterfaceMixin {
  final players = <String, EqualizerMockPlayer>{};
  final enabledLog = <bool>[];
  final gainLog = <(int, double)>[];

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    final p = EqualizerMockPlayer(request.id, enabledLog, gainLog);
    players[request.id] = p;
    return p;
  }

  @override
  Future<DisposePlayerResponse> disposePlayer(
      DisposePlayerRequest request) async {
    players.remove(request.id);
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
      DisposeAllPlayersRequest request) async {
    players.clear();
    return DisposeAllPlayersResponse();
  }
}

class EqualizerMockPlayer extends AudioPlayerPlatform {
  final List<bool> enabledLog;
  final List<(int, double)> gainLog;
  final eventController = StreamController<PlaybackEventMessage>.broadcast();

  EqualizerMockPlayer(super.id, this.enabledLog, this.gainLog);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      eventController.stream;

  void _broadcast(ProcessingStateMessage state) {
    eventController.add(PlaybackEventMessage(
      processingState: state,
      updatePosition: Duration.zero,
      updateTime: DateTime.now(),
      bufferedPosition: Duration.zero,
      icyMetadata: null,
      duration: const Duration(seconds: 14),
      currentIndex: 0,
      androidAudioSessionId: null,
      errorCode: null,
      errorMessage: null,
    ));
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _broadcast(ProcessingStateMessage.ready);
    return LoadResponse(duration: const Duration(seconds: 14));
  }

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
      AudioEffectSetEnabledRequest request) async {
    enabledLog.add(request.enabled);
    return AudioEffectSetEnabledResponse();
  }

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
              lowerFrequency: i == 0 ? 30.0 : 30.0 * (1 << i),
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
      AndroidEqualizerBandSetGainRequest request) async {
    gainLog.add((request.bandIndex, request.gain));
    return AndroidEqualizerBandSetGainResponse();
  }
}
