import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:fidelis/services/kokoro_engine.dart';

/// GAIN STAGING (round 3, defect B — the clipping/crackle): the 48 kHz
/// resampler's gain is characterized (DC unity; pure tones never above
/// 1.0 in the interior; the adversarial tap-sign worst case exactly
/// 20/16 = 1.25; the clamped edge padding up to 18/16 = 1.125 at the
/// sequence boundaries), and the playback path stages synthesis peaks to
/// 0.8 = 1/1.25 BEFORE the resampler — so the post-conversion peak can
/// never PASS full scale for ANY input (0.8 × 1.25 = 1.0). These
/// measurements are the report's before/after evidence shape: the
/// unstaged chain clips past 0 dBFS (the crackle mechanism), the staged
/// chain does not.
void main() {
  /// The worst-case adversarial pattern: the input that matches the odd
  /// phase's tap signs (−1, +9, +9, −1)/16 — every interior odd-phase
  /// window sees the full alignment, so the output peaks at 1.25× the
  /// input peak.
  Float32List adversarial(int n, double peak) {
    const pattern = [-1.0, 1.0, 1.0, -1.0];
    final samples = Float32List(n);
    for (var i = 0; i < n; i++) {
      samples[i] = peak * pattern[i % 4];
    }
    return samples;
  }

  Float32List tone(double hz, int n, {double peak = 1.0}) {
    final samples = Float32List(n);
    for (var i = 0; i < n; i++) {
      samples[i] = peak * math.sin(2 * math.pi * hz * i / 24000);
    }
    return samples;
  }

  /// The peak of the resampler output EXCLUDING the edge samples (the
  /// first/last two) — the interior filter's response, isolated from the
  /// clamped edge padding's boundary artifact.
  double interiorPeak(Float32List out) {
    var peak = 0.0;
    for (var i = 2; i < out.length - 2; i++) {
      final v = out[i];
      if (v > peak) peak = v;
      if (-v > peak) peak = -v;
    }
    return peak;
  }

  test('the resampler DC gain is exactly unity (every output sample)', () {
    final out = resamplePcmTo48k(
        Float32List(1000)..fillRange(0, 1000, 0.5), 24000);
    for (final v in out) {
      expect(v, closeTo(0.5, 1e-6),
          reason: 'the even phase is an exact copy, the odd phase DC-unity');
    }
  });

  test('the resampler interior never exceeds the input peak for pure '
      'tones (the full frequency sweep)', () {
    for (var f = 20; f <= 11900; f += 137) {
      final out = resamplePcmTo48k(tone(f.toDouble(), 4800), 24000);
      expect(interiorPeak(out), lessThanOrEqualTo(1.0 + 1e-6),
          reason: 'tone $f Hz: the interior gain must stay within unity');
    }
  });

  test('the clamped edge padding can reach 1.125x at the sequence '
      'boundaries (the measured edge artifact the headroom also bounds)',
      () {
    // The end edge window (−x[n−2] + 17·x[n−1])/16 with opposite-signed
    // hot samples: 18/16 = 1.125.
    final samples = Float32List(64);
    for (var i = 0; i < 60; i++) {
      samples[i] = 0.5 * math.sin(2 * math.pi * 220 * i / 24000);
    }
    samples[62] = -1.0;
    samples[63] = 1.0;
    final out = resamplePcmTo48k(samples, 24000);
    final edgePeak = pcmPeak(out);
    expect(edgePeak, greaterThan(1.0),
        reason: 'the edge artifact is real: the clamped padding window '
            'exceeds the input peak');
    expect(edgePeak, lessThanOrEqualTo(1.125 + 1e-6),
        reason: 'the edge worst case is 18/16 = 1.125 (below the interior '
            'adversarial 1.25 the headroom is sized to)');
  });

  test('the adversarial tap-sign pattern measures exactly 1.25x (the '
      'worst case the headroom is sized to)', () {
    final out = resamplePcmTo48k(adversarial(4000, 1.0), 24000);
    expect(pcmPeak(out), closeTo(1.25, 1e-6),
        reason: 'the (−1,9,9,−1)/16 window fully aligned: 20/16');
  });

  test('the headroom staging: a hot sentence scales DOWN to 0.8; a normal '
      'sentence is untouched (never boosted)', () {
    final (staged, scaled) = stagePcmHeadroom(tone(220, 4000, peak: 0.95));
    expect(scaled, isTrue);
    expect(pcmPeak(staged), closeTo(0.8, 1e-6));

    final normal = tone(220, 4000, peak: 0.5);
    final (staged2, scaled2) = stagePcmHeadroom(normal);
    expect(scaled2, isFalse);
    expect(identical(staged2, normal), isTrue,
        reason: 'no copy, no touch — the peak already sits in the headroom');
  });

  test('THE GUARANTEE: the staged + resampled peak never passes full '
      'scale, for ANY input (the adversarial worst case through the '
      'production chain)', () {
    final hot = adversarial(4000, 1.0);
    expect(pcmPeak(hot), closeTo(1.0, 1e-6));
    final (staged, scaled) = stagePcmHeadroom(hot);
    expect(scaled, isTrue);
    expect(pcmPeak(staged), closeTo(0.8, 1e-6));
    final out = resamplePcmTo48k(staged, 24000);
    expect(pcmPeak(out), lessThanOrEqualTo(1.0 + 1e-6),
        reason: '0.8 × 1.25 = 1.0 — the chain is worst-case unity');
    expect(pcmClippedCount(out), 0,
        reason: 'no sample PAST full scale — the encode clamps nothing, '
            'no clipping, no crackle');
  });

  test('THE GUARANTEE holds across the full tone sweep staged (the '
      'production chain on every frequency)', () {
    for (var f = 20; f <= 11900; f += 137) {
      final (staged, _) = stagePcmHeadroom(tone(f.toDouble(), 4800));
      final out = resamplePcmTo48k(staged, 24000);
      expect(pcmPeak(out), lessThanOrEqualTo(1.0 + 1e-6),
          reason: 'tone $f Hz staged: the chain stays within full scale');
      expect(pcmClippedCount(out), 0, reason: 'tone $f Hz staged');
    }
  });

  test('the WAV encode round-trip: the staged chain encodes without '
      'distortion (the decoded samples match the expected rounding)', () {
    final (staged, _) = stagePcmHeadroom(adversarial(4000, 1.0));
    final out = resamplePcmTo48k(staged, 24000);
    final wav = encodeWav16(out, 48000);
    var maxDiff = 0;
    for (var i = 0; i < out.length; i++) {
      final v = out[i] > 1.0
          ? 1.0
          : (out[i] < -1.0 ? -1.0 : out[i]);
      final expected = (v * 32767).round();
      final hi = wav[44 + 2 * i + 1];
      final lo = wav[44 + 2 * i];
      final decoded = (hi << 8) | lo;
      final s = decoded >= 0x8000 ? decoded - 0x10000 : decoded;
      final diff = (s - expected).abs();
      if (diff > maxDiff) maxDiff = diff;
    }
    expect(maxDiff, lessThanOrEqualTo(1),
        reason: 'every encoded sample matches the expected rounding within '
            '1 LSB — the encode clamped nothing (no crackle)');
  });

  test('BEFORE/AFTER on the same sentence: the unstaged chain clips past '
      'full scale, the staged chain does not (the report\'s evidence)',
      () {
    // A sentence peaking at 0.9 with adversarial structure — the shape a
    // hot plosive can take.
    final sentence = adversarial(8000, 0.9);
    final before = resamplePcmTo48k(sentence, 24000);
    expect(pcmPeak(before), closeTo(1.125, 1e-6),
        reason: 'BEFORE: 0.9 × 1.25 = 1.125 — past full scale (the crackle '
            'mechanism)');
    expect(pcmClippedCount(before), greaterThan(0),
        reason: 'BEFORE: samples PAST full scale — the encode clamps them '
            '(the crackle)');
    final (staged, _) = stagePcmHeadroom(sentence);
    final after = resamplePcmTo48k(staged, 24000);
    expect(pcmPeak(after), lessThanOrEqualTo(1.0 + 1e-6),
        reason: 'AFTER: staged to 0.8 → 0.8 × 1.25 = 1.0 — clean');
    expect(pcmClippedCount(after), 0,
        reason: 'AFTER: zero samples past full scale');
  });
}
