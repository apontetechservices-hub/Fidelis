import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/audio_controller.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_service.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

import 'scripted_audio_harness.dart';

/// THE ENGINE EXCLUSIVITY ASSERTION (defect A, lead 'two output paths'):
/// the Bible screen's engine field showed '—' during playback, so the
/// engine actually serving was UNVERIFIED — a flutter_tts utterance
/// speaking ALONGSIDE the Kokoro pipeline would be exactly the reported
/// 'two voices at the same time'. These tests pin the invariant: when the
/// Kokoro pipeline serves (engine=kokoro), flutter_tts is NEVER invoked —
/// no speak, on either the single-chunk path or the sequence path — and
/// the fallback (Kokoro unavailable) DOES speak, proving the mock records.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ttsCalls = installPipelineChannelMocks();
  final platform = GatedPlatform();
  JustAudioPlatform.instance = platform;

  setUp(() {
    ttsCalls.clear();
    KokoroEngine.resetForTest();
    TtsService.readoutSink = null;
  });

  KokoroAudio audioFor(String text) {
    final n = 2400 + text.length;
    final samples = Float32List(n);
    for (var i = 0; i < n; i++) {
      samples[i] = 0.3 * (i % 100) / 100;
    }
    return KokoroAudio(samples, 24000);
  }

  /// Waits until the pipeline has a player with a PENDING play.
  Future<GatedPlayer> waitPendingPlay() => waitPendingPlayOn(platform);

  /// Plays the gated player through [count] sentence playbacks, waiting
  /// for each play to be PENDING before completing it (a premature
  /// completion would be lost — the pipeline's WAV writes are real I/O).
  Future<void> playThrough(int count) async {
    for (var i = 0; i < count; i++) {
      final player = await waitPendingPlay();
      player.completePlayback();
    }
    await settle();
  }

  test('speakPrayer (the single-chunk path): kokoro serves, flutter_tts '
      'never speaks', () async {
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        audioFor(text);
    final lines = <String>[];
    TtsService.readoutSink = lines.add;

    final done = TtsService.speakPrayer(
      'The Lord ruleth me. And I shall want nothing.',
      lang: 'en',
      voice: KokoroVoice.bible,
      onSentenceStart: (_) {},
      onSentenceTiming: (_, _, _) {},
    );
    await playThrough(2); // two sentences, each gated
    await done.timeout(const Duration(seconds: 5));

    expect(lines.any((l) => l.contains('engine=kokoro')), isTrue,
        reason: 'the Kokoro pipeline served the playback');
    expect(ttsCalls.where((c) => c == 'speak'), isEmpty,
        reason: 'flutter_tts must NEVER be invoked when engine=kokoro');
  });

  test('speakSequence (the multi-chunk path): kokoro serves, flutter_tts '
      'never speaks', () async {
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        audioFor(text);
    final lines = <String>[];
    TtsService.readoutSink = lines.add;

    final done = TtsService.speakSequence(
      const [
        AudioChunk(
            text: 'Alpha one. Alpha two.', lang: 'en', voice: KokoroVoice.bible),
        AudioChunk(text: 'Bravo one.', lang: 'en', voice: KokoroVoice.bible),
      ],
      lang: 'en',
      onChunkStart: (_) {},
      onSentenceStart: (_, _) {},
      onSentenceTiming: (_, _, _, _) {},
      onSentenceSynthesized: (_, _, _) {},
      onWordRange: (_, _, _) {},
    );
    await playThrough(3);
    await done.timeout(const Duration(seconds: 5));

    expect(lines.any((l) => l.contains('engine=kokoro')), isTrue);
    expect(ttsCalls.where((c) => c == 'speak'), isEmpty,
        reason: 'flutter_tts must NEVER be invoked when engine=kokoro');
  });

  test('the contrast: when Kokoro cannot serve, the fallback DOES speak '
      '(the mock records — the assertion above is meaningful)', () async {
    KokoroEngine.debugSynthesizeOverride = (text, lang, {voice}) async =>
        null; // Kokoro unavailable
    final lines = <String>[];
    TtsService.readoutSink = lines.add;

    await TtsService.speakPrayer(
      'The Lord ruleth me.',
      lang: 'en',
      voice: KokoroVoice.bible,
      onSentenceStart: (_) {},
      onSentenceTiming: (_, _, _) {},
    );

    expect(lines.any((l) => l.contains('FALLBACK')), isTrue);
    expect(ttsCalls.where((c) => c == 'speak'), isNotEmpty,
        reason: 'the fallback speaks in the system voice — recorded');
  });
}
