import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/features/diagnostics/sid_rollcall.dart';
import 'package:fidelis/services/kokoro_engine.dart';
import 'package:fidelis/services/tts_text.dart';

/// THE SID ROLL-CALL: every speaker in the bundled Kokoro model, read from
/// the model metadata programmatically (the voices.bin speaker count — the
/// same source the relabeled audition used), the known voice names, the
/// roll-call line each speaker speaks, and the solo neutral profile the
/// roll-call synthesizes through. The last test drives the REAL production
/// synthesis when the host's sherpa native lib is on the loader path
/// (LD_LIBRARY_PATH — see test/runtime_slot_readout_test.dart); it skips
/// cleanly without it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the model metadata', () {
    test('the bundled voices.bin yields 54 speakers', () {
      final f = File('assets/kokoro/voices.bin');
      expect(f.existsSync(), isTrue, reason: 'the bundled model metadata');
      expect(KokoroEngine.kokoroSidCount(f.lengthSync()), 54,
          reason: 'each voice is a 510x256 float32 style tensor; the '
              'shipped voices.bin holds exactly 54');
    });

    test('kokoroSidCount floors partial tensors', () {
      expect(KokoroEngine.kokoroSidCount(0), 0);
      expect(KokoroEngine.kokoroSidCount(510 * 256 * 4 - 1), 0);
      expect(KokoroEngine.kokoroSidCount(510 * 256 * 4), 1);
      expect(KokoroEngine.kokoroSidCount(54 * 510 * 256 * 4), 54);
    });
  });

  group('the roll-call roster', () {
    test('every sid of the 54-speaker model is named', () {
      expect(kokoroSidNames.length, 54);
      for (var sid = 0; sid < 54; sid++) {
        expect(kokoroSidNames.containsKey(sid), isTrue,
            reason: 'sid $sid must carry its known Kokoro name');
      }
      expect(kokoroSidNames.containsKey(54), isFalse);
    });

    test('the directed grid sids carry their known names', () {
      // The owner's directed voice grid, verifiable against the model
      // metadata table (the same source the relabeled audition used).
      expect(kokoroSidNames[16], 'am_michael'); // Bible EN primary
      expect(kokoroSidNames[12], 'am_echo'); // Bible EN blend
      expect(kokoroSidNames[29], 'em_alex'); // Bible ES
      expect(kokoroSidNames[1], 'af_aoede'); // Rosary EN + ES primary
      expect(kokoroSidNames[28], 'ef_dora'); // Rosary ES blend
      expect(kokoroSidNames[26], 'bm_george'); // Readings EN (standard)
    });

    test('the directed sids are labeled for the ear test', () {
      expect(directedSidLabels.keys.toSet(),
          {16, 12, 29, 1, 28, 26});
      expect(directedSidLabels[16], contains('Bible EN'));
      expect(directedSidLabels[28], contains('Rosary ES blend'));
    });
  });

  group('the roll-call line and voice', () {
    test('the line states the speaker\'s number, then the fixed sentence', () {
      expect(
          rollCallLine(16),
          'I am speaker number 16. '
          'The Lord is my shepherd; I shall not want.');
      expect(
          rollCallLine(1),
          'I am speaker number 1. '
          'The Lord is my shepherd; I shall not want.');
      // The common sentence is the SAME for every sid.
      final tail = rollCallLine(53).split('. ').skip(1).join('. ');
      expect(tail, 'The Lord is my shepherd; I shall not want.');
    });

    test('the roll-call voice is a solo custom profile at neutral speed', () {
      final v = rollCallVoice(16);
      expect(v.enSid, 16);
      expect(v.esSid, 16);
      expect(v.enName, 'am_michael');
      expect(v.blendSidFor('en'), isNull, reason: 'solo — no blend partner');
      expect(v.blendSidFor('es'), isNull);
      expect(v.speed, 1.0, reason: 'neutral speed for the ear test');
      expect(v.enEqualizer, isNull, reason: 'no slot shaping');
      expect(v.esEqualizer, isNull);
      expect(slotNameFor(v), 'custom');
      // No rosary-scoped correction leaks into the roll-call synthesis.
      expect(v.lexiconFor('en').containsKey('blessed'), isFalse);
    });

    test('an unnamed sid falls back to a sid_N label', () {
      final v = rollCallVoice(999);
      expect(v.enName, 'sid_999');
    });
  });

  test('a roll-call line synthesizes through the production path', () async {
    late final bool ready;
    try {
      ready = await KokoroEngine.ensureReady('en');
    } catch (_) {
      ready = false;
    }
    if (!ready) {
      markTestSkipped('the host sherpa native lib is not on the loader '
          'path — run with LD_LIBRARY_PATH (see the file header)');
      return;
    }
    final audio = await KokoroEngine.synthesize(
      rollCallLine(1),
      'en',
      voice: rollCallVoice(1),
    );
    expect(audio, isNotNull,
        reason: 'the roll-call synthesis must deliver through the same '
            'KokoroEngine.synthesize a playback calls');
    expect(audio!.samples, isNotEmpty);
    expect(audio.blended, isFalse,
        reason: 'the roll-call voice is solo — no blend record');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
