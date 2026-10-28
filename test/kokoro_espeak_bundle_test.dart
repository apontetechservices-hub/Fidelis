// KOKORO REVIVAL GUARD (v1.4.67+82) — espeak-ng-data ships in the bundle.
//
// The 1.4.65/1.4.66 APKs bundled no espeak-ng-data (a SUBDIRECTORY of the
// declared assets/kokoro/ dir — Flutter directory declarations are
// non-recursive), so Kokoro could initialize but never phonemize: every
// synthesis returned 0 samples ("Failed to set eSpeak-ng voice") and the
// rosary highlight had no timeline. v1.4.67 declares espeak-ng-data/ and
// every subdirectory containing files (lang/ + its 33 family dirs +
// voices/!v/). These tests guard the bundled state that the device's
// KokoroEngine.prepareAssets() copies from. The real-engine init proof
// lives in tool/kokoro_init_probe.dart (run from the repo root).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled assets ship the full espeak-ng-data tree Kokoro needs',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final espeak = assets
        .where((a) => a.startsWith('assets/kokoro/espeak-ng-data/'))
        .toList();

    // The whole tree ships: 118 top-level files (113 *_dict + the 5 phoneme
    // data files), 133 lang/ voice definitions, 104 voices/!v variants.
    expect(espeak.length, 355,
        reason: 'the full espeak-ng-data tree ships (0 shipped through '
            '1.4.66 — Kokoro could not phonemize)');
    expect(espeak.where((a) => a.endsWith('_dict')).length,
        greaterThanOrEqualTo(100),
        reason: 'the per-language dictionary files ship');
    expect(espeak.where((a) => a.contains('/lang/')).length,
        greaterThanOrEqualTo(100),
        reason: 'the lang/ voice definitions ship — without them Kokoro '
            'initializes but phonemization fails (0 samples)');
    expect(espeak.where((a) => a.contains('/voices/!v/')).length,
        greaterThanOrEqualTo(50),
        reason: 'the voice-variant files ship');

    bool ships(String suffix) => assets.any((a) => a.endsWith(suffix));
    // Phonemization-critical files: init reads the phoneme data; the voice
    // lookup for 'en'/'es' reads the lang/ definitions.
    for (final f in [
      'espeak-ng-data/phontab',
      'espeak-ng-data/phonindex',
      'espeak-ng-data/phondata',
      'espeak-ng-data/phondata-manifest',
      'espeak-ng-data/intonations',
      'espeak-ng-data/lang/gmw/en',
      'espeak-ng-data/lang/roa/es',
    ]) {
      expect(ships(f), isTrue, reason: '$f ships');
    }
    // The model inputs (already bundled via assets/kokoro/).
    for (final f in [
      'model.int8.onnx.part-00',
      'model.int8.onnx.part-01',
      'model.int8.onnx.part-02',
      'tokens.txt',
      'voices.bin',
    ]) {
      expect(ships(f), isTrue, reason: '$f ships');
    }
  });

  test('bundled espeak-ng-data + model files load from the bundle', () async {
    for (final f in [
      'espeak-ng-data/phontab',
      'espeak-ng-data/lang/gmw/en',
      'tokens.txt',
      'voices.bin',
    ]) {
      final bytes = await rootBundle.load('assets/kokoro/$f');
      expect(bytes.lengthInBytes, greaterThan(0), reason: '$f loads');
    }
  });
}