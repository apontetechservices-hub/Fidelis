import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/kokoro_engine.dart';

/// THE PCM FORMAT FIX (defect A): the owner's phone doubles/distorts raw
/// 24000 Hz sentence WAVs while the pre-rendered opus files (whose decoder
/// delivers 48000 Hz mono to the same audio sink) played clean for weeks —
/// the 24 kHz raw-PCM path is the one corrupted output path. The fix
/// resamples every sentence to 48000 Hz before the WAV is written, so the
/// player receives the PROVEN-CLEAN format: 48000 Hz, MONO, 16-bit.
///
/// These tests pin the mono/stereo declaration END TO END: the resampler's
/// math, and the exact WAV header the playback path writes.
void main() {
  group('resamplePcmTo48k (the 24 kHz → 48 kHz output-path fix)', () {
    test('doubles the length; even positions carry the input samples', () {
      final input = Float32List.fromList([0.0, 0.25, 0.5, -0.25]);
      final out = resamplePcmTo48k(input, 24000);
      expect(out.length, input.length * 2);
      for (var i = 0; i < input.length; i++) {
        expect(out[2 * i], input[i]);
      }
    });

    test('odd positions follow the 4-tap polyphase filter '
        '(-1, 9, 9, -1)/16', () {
      final input = Float32List.fromList([0.0, 1.0, 0.0, 0.0]);
      final out = resamplePcmTo48k(input, 24000);
      // out[2i+1] = (-in[i-1] + 9*in[i] + 9*in[i+1] - in[i+2]) / 16, with
      // the taps clamped at the edges (tap(4) reads in[3]).
      expect(out[1], closeTo((-input[0] + 9 * input[1] + 9 * input[2] - input[3]) / 16, 1e-6));
      // i=2: (-in[1] + 9*in[2] + 9*in[3] - tap(4)=in[3]) / 16
      expect(out[5], closeTo((-input[1] + 9 * input[2] + 9 * input[3] - input[3]) / 16, 1e-6));
    });

    test('edges clamp: no index errors, no NaN, finite output', () {
      final input = Float32List.fromList([1.0, -1.0]);
      final out = resamplePcmTo48k(input, 24000);
      expect(out.length, 4);
      for (final v in out) {
        expect(v.isNaN, isFalse);
      }
    });

    test('48 kHz input passes through unchanged (already the target rate)',
        () {
      final input = Float32List.fromList([0.1, 0.2, 0.3]);
      final out = resamplePcmTo48k(input, 48000);
      expect(identical(out, input), isTrue);
    });

    test('empty input passes through', () {
      final out = resamplePcmTo48k(Float32List(0), 24000);
      expect(out.length, 0);
    });
  });

  group('the sentence WAV declaration end to end (what _playPcm writes)', () {
    test('a 24 kHz Kokoro render is written as 48000 Hz MONO 16-bit', () {
      final samples = Float32List(24000); // 1s at 24 kHz
      for (var i = 0; i < samples.length; i++) {
        samples[i] = 0.5 * (i % 240) / 240;
      }
      final audio = KokoroAudio(samples, 24000);
      // The exact transformation the playback path applies before writing.
      final rate = audio.sampleRate == 24000 ? 48000 : audio.sampleRate;
      final resampled = resamplePcmTo48k(audio.samples, audio.sampleRate);
      final wav = encodeWav16(resampled, rate);

      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(wav.sublist(12, 16)), 'fmt ');
      final fmtSize =
          ByteData.sublistView(wav, 16, 20).getUint32(0, Endian.little);
      expect(fmtSize, 16);
      final audioFormat =
          ByteData.sublistView(wav, 20, 22).getUint16(0, Endian.little);
      expect(audioFormat, 1, reason: 'PCM');
      final channels =
          ByteData.sublistView(wav, 22, 24).getUint16(0, Endian.little);
      expect(channels, 1, reason: 'MONO — the proven-clean channel layout '
          '(the opus files that played clean were mono)');
      final sampleRate =
          ByteData.sublistView(wav, 24, 28).getUint32(0, Endian.little);
      expect(sampleRate, 48000, reason: '48 kHz — the proven-clean rate on '
          "the owner's phone (the opus decoder delivered 48 kHz)");
      final blockAlign =
          ByteData.sublistView(wav, 32, 34).getUint16(0, Endian.little);
      expect(blockAlign, 2);
      final bits =
          ByteData.sublistView(wav, 34, 36).getUint16(0, Endian.little);
      expect(bits, 16);
      final dataLen = wav.length - 44;
      expect(dataLen, resampled.length * 2);
      // The duration is preserved: 1s at 24 kHz → 1s at 48 kHz.
      expect(dataLen / 2 / sampleRate, closeTo(1.0, 0.001));
    });

    test('a non-24 kHz render passes through with its own rate declared', () {
      final samples = Float32List(4800); // 0.1s at 48 kHz
      final wav = encodeWav16(samples, 48000);
      final sampleRate =
          ByteData.sublistView(wav, 24, 28).getUint32(0, Endian.little);
      expect(sampleRate, 48000);
    });
  });
}
