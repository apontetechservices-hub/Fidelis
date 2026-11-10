// KOKORO ASSET-PREPARATION REGRESSION (v1.4.87+102).
//
// Ground truth from the 1.4.86 diagnostic build (Galaxy S25 Ultra): Kokoro
// has NEVER synthesized on the phone — every preparation crashed with
// "asset copy failed: Null check operator used on a null value" before any
// file was copied, so every playback silently fell back to flutter_tts.
//
// Root cause: the old _prepare() copied assets inside Isolate.run, where
// rootBundle is unusable — PlatformAssetBundle.load reaches for
// ServicesBinding.instance, which no background isolate has (statics are
// per-isolate; BackgroundIsolateBinaryMessenger.ensureInitialized registers
// the isolate with the engine but initializes no binding). In release
// builds the framework's descriptive assert is stripped and the bare
// null-check fires.
//
// These tests drive the REAL preparation path — the same static production
// calls, the same AssetManifest/rootBundle lookups against the REAL
// pubspec-declared asset set — from a clean state, a stale state, and an
// injected bundle-load failure. The old host tests never caught the crash
// because they ran their bundle lookups on the test root isolate (where the
// binding exists) and never executed the preparation itself.
import 'dart:io';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fidelis/services/kokoro_engine.dart';

/// The stamp the previous (1.4.86) build wrote — stale-state fixtures use it.
const _previousStamp = 'kokoro-int8-v1.0-2026-10-26';

Future<Directory> _tempRoot() => Directory.systemTemp
    .createTemp('fidelis-kokoro-prep-')
    .then((d) => d.createTemp('case-'));

/// Every file under [dir], as bundle-relative keys (assets/kokoro/...).
Future<Set<String>> _diskFiles(String dir) async {
  final files = <String>{};
  await for (final e in Directory(dir).list(recursive: true)) {
    if (e is File) files.add(e.path.substring(dir.length + 1));
  }
  return files;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    KokoroEngine.resetForTest();
  });

  tearDown(() {
    KokoroEngine.resetForTest();
  });

  test('REAL preparation from a CLEAN state copies the full bundle and '
      'reassembles the model', () async {
    final root = await _tempRoot();
    final dir = '${root.path}/kokoro';
    KokoroEngine.debugPrepDirOverride = dir;

    // The exact production entry point, against the real asset bundle.
    expect(await KokoroEngine.prepareAssets(), isTrue,
        reason: 'preparation succeeds from an empty directory');

    // The manifest is the bundle's source of truth (the October failure
    // class: a subdirectory not declared in pubspec.yaml never appears in
    // it, so a copy driven by it silently omits that subtree).
    final manifestAssets = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .where((a) => a.startsWith('assets/kokoro/'))
        .toSet();
    expect(manifestAssets, isNotEmpty);

    // Every manifest asset landed on disk, and nothing else did — except
    // the model reassembly (parts consumed into model.int8.onnx) and the
    // .ready marker.
    final parts = manifestAssets
        .where((a) => a.contains('model.int8.onnx.part-'))
        .toSet();
    final expectedDisk = manifestAssets
        .difference(parts)
        .union({'assets/kokoro/model.int8.onnx', '.ready'});
    final disk = await _diskFiles(dir);
    final diskKeys = disk
        .where((f) => f != '.ready')
        .map((f) => 'assets/kokoro/$f')
        .toSet();
    expect(diskKeys,
        manifestAssets.difference(parts).union({'assets/kokoro/model.int8.onnx'}),
        reason: 'the copied tree matches the bundle exactly');

    // The reassembled model is the CONCATENATION of all parts, in order —
    // a wrong-order or partial reassembly would leave a model file sherpa
    // cannot load (with a cryptic native error instead of this test).
    var expectedModelBytes = 0;
    for (final part in parts) {
      expectedModelBytes += (await rootBundle.load(part)).lengthInBytes;
    }
    final model = File('$dir/model.int8.onnx');
    expect(model.lengthSync(), expectedModelBytes,
        reason: 'model.int8.onnx is the byte-exact concatenation of the '
            '${parts.length} bundled parts');
    expect(
        disk.where((f) => f.contains('model.int8.onnx.part-')), isEmpty,
        reason: 'the parts are consumed by the reassembly');

    // The marker matches THIS build's stamp (an old stamp forces a re-copy).
    expect(File('$dir/.ready').readAsStringSync(), KokoroEngine.debugStamp);

    // The files the engine init reads carry the bundle's exact byte counts.
    for (final name in ['tokens.txt', 'voices.bin', 'espeak-ng-data/phontab']) {
      final bundled = await rootBundle.load('assets/kokoro/$name');
      expect(File('$dir/$name').lengthSync(), bundled.lengthInBytes,
          reason: '$name copied byte-exact');
    }

    await root.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('a bundle-load failure names the EXACT asset and step — never a '
      'generic "asset copy failed"', () async {
    final root = await _tempRoot();
    final dir = '${root.path}/kokoro';
    KokoroEngine.debugPrepDirOverride = dir;

    // The first asset in sorted order fails to load from the bundle — the
    // on-device shape of an asset missing from the build (undeclared in
    // pubspec.yaml, or dropped by the build).
    const missing = 'assets/kokoro/espeak-ng-data/af_dict';
    KokoroEngine.debugAssetLoaderOverride = (key) async {
      if (key == missing) {
        throw FlutterError('Unable to load asset: "$key".');
      }
      return rootBundle.load(key);
    };

    expect(await KokoroEngine.prepareAssets(), isFalse);
    expect(KokoroEngine.lastError, isNotNull);
    expect(KokoroEngine.lastError, contains(missing),
        reason: 'the error names the specific asset');
    expect(KokoroEngine.lastError, contains('not in the asset bundle'),
        reason: 'the error names the step (bundle load), not just "copy"');
    expect(KokoroEngine.lastError, startsWith('asset copy failed: '),
        reason: 'the diagnostics screen shows the recorded text verbatim');

    await root.delete(recursive: true);
  });

  test('STALE state from an older build is wiped and re-copied cleanly', () async {
    final root = await _tempRoot();
    final dir = '${root.path}/kokoro';
    final modelDir = Directory(dir)..createSync(recursive: true);

    // Whatever a previous install left: an old-stamp marker (so the old code
    // would trust this directory), a truncated file, a leftover model part
    // that would CORRUPT the reassembly if it survived (appended after the
    // real part-02), and unrelated garbage.
    File('${modelDir.path}/.ready').writeAsStringSync(_previousStamp);
    File('${modelDir.path}/tokens.txt').writeAsStringSync('truncated');
    File('${modelDir.path}/model.int8.onnx.part-99')
        .writeAsStringSync('stale part garbage');
    File('${modelDir.path}/leftover-from-old-build.txt')
        .writeAsStringSync('garbage');

    KokoroEngine.debugPrepDirOverride = dir;
    expect(await KokoroEngine.prepareAssets(), isTrue,
        reason: 'preparation recovers from stale/partial state');

    expect(File('$dir/.ready').readAsStringSync(), KokoroEngine.debugStamp,
        reason: 'the marker carries the CURRENT stamp');
    final bundledTokens = await rootBundle.load('assets/kokoro/tokens.txt');
    expect(File('$dir/tokens.txt').lengthSync(), bundledTokens.lengthInBytes,
        reason: 'the truncated file was re-copied byte-exact');
    expect(File('$dir/model.int8.onnx.part-99').existsSync(), isFalse,
        reason: 'the stale part is gone — it must never reach the '
            'reassembly');
    expect(File('$dir/leftover-from-old-build.txt').existsSync(), isFalse,
        reason: 'unrelated stale files are wiped');
    expect(File('$dir/model.int8.onnx').existsSync(), isTrue);

    await root.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 6)));

  test('a COMPLETE preparation is trusted (fast path) until a critical file '
      'is lost — then it is wiped and re-copied', () async {
    final root = await _tempRoot();
    final dir = '${root.path}/kokoro';
    KokoroEngine.debugPrepDirOverride = dir;
    expect(await KokoroEngine.prepareAssets(), isTrue);

    // New session semantics: statics reset, same on-device directory.
    File('$dir/sentinel.txt').writeAsStringSync('untouched');
    KokoroEngine.resetForTest();
    KokoroEngine.debugPrepDirOverride = dir;
    expect(await KokoroEngine.prepareAssets(), isTrue,
        reason: 'the fast path accepts a complete preparation');
    expect(File('$dir/sentinel.txt').existsSync(), isTrue,
        reason: 'no wipe ran — the directory was trusted, not re-copied');

    // A lost model file (corruption, partial system cleanup) must be
    // detected and repaired from a CLEAN wipe.
    File('$dir/model.int8.onnx').deleteSync();
    KokoroEngine.resetForTest();
    KokoroEngine.debugPrepDirOverride = dir;
    expect(await KokoroEngine.prepareAssets(), isTrue,
        reason: 'the missing critical file is detected and repaired');
    expect(File('$dir/model.int8.onnx').existsSync(), isTrue,
        reason: 'the model was re-copied and reassembled');
    expect(File('$dir/sentinel.txt').existsSync(), isFalse,
        reason: 'the repair wiped the directory first — no mixed state');

    await root.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
