import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fidelis/services/kokoro_engine.dart';

/// THE UPGRADE-INSTALL ENGINE REGRESSION (round 5, defect 1 — the standing
/// regression test): 1.4.98 installed OVER 1.4.96's data broke the engine
/// on every real updating device. The device evidence: every slot played
/// the SYSTEM voice; the banner read 'worker spawn failed:
/// TimeoutException after 0:00:30'; the pipeline log read 'synthesis
/// failed: Null check operator used on a null value'; a fresh install
/// (clear data) worked.
///
/// ROOT CAUSE: the model dir's .ready stamp is UNCHANGED across the
/// upgrade (the blends-cancelled bump predates both builds) and the
/// bundled model files are byte-identical, so preparation correctly takes
/// the fast path — the carried-over state is VALID. The failure was the
/// rosary screen's TWO concurrent render consumers (the screen-open
/// prefetch and the render-ahead walk, both new in round 4) racing TWO
/// worker spawns in the same event-loop drain: the second spawn overwrote
/// the first's hello completer (one caller hung the full 30 s spawn
/// timeout) and the worker SendPort flip-flopped between the two isolates
/// (gens routed to the worker that never received init — the null-check
/// error). A fresh install only escaped because the owner's test flow ran
/// the diagnostics probe first (a single-caller spawn).
///
/// THE FIX under test: the fast path still trusts a complete
/// matching-stamp preparation (an upgrade works with NO user action), and
/// concurrent ensure callers share ONE spawn attempt and ONE outcome.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    KokoroEngine.resetForTest();
  });

  tearDown(() {
    KokoroEngine.resetForTest();
  });

  /// The 1.4.96-era state as that build wrote it: a complete model dir
  /// with the CURRENT stamp (unchanged across the upgrade) and every file
  /// the engine init reads — plus a stale extra file the old build left
  /// behind. Byte contents are dummies: these tests never reach the
  /// engine init (the spawn is overridden); preparation only checks
  /// existence and the marker.
  Directory makeOldDataRow(Directory tmp) {
    final dir = Directory('${tmp.path}/kokoro');
    dir.createSync(recursive: true);
    File('${dir.path}/.ready').writeAsStringSync(KokoroEngine.debugStamp);
    for (final name in const [
      'model.int8.onnx',
      'voices.bin',
      'tokens.txt',
      'espeak-ng-data/phontab',
    ]) {
      final f = File('${dir.path}/$name');
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync([1, 2, 3]);
    }
    File('${dir.path}/stale-extra.bin').writeAsBytesSync([9]);
    return dir;
  }

  test('the upgrade fast path: a complete matching-stamp model dir is '
      'trusted, not re-copied — the upgrade works with NO user action',
      () async {
    final tmp = Directory.systemTemp.createTempSync('fidelis_upgrade');
    try {
      final dir = makeOldDataRow(tmp);
      final markerBefore = File('${dir.path}/.ready').readAsStringSync();
      final modelBytesBefore =
          File('${dir.path}/model.int8.onnx').readAsBytesSync();
      final staleBytesBefore =
          File('${dir.path}/stale-extra.bin').readAsBytesSync();

      KokoroEngine.debugPrepDirOverride = dir.path;
      final ok = await KokoroEngine.prepareAssets();

      expect(
          ok,
          isTrue,
          reason: 'the carried-over 1.4.96 preparation is complete and '
              'matches the stamp — the upgrade must take the fast path');
      expect(File('${dir.path}/.ready').readAsStringSync(), markerBefore,
          reason: 'the fast path must not rewrite the marker');
      expect(File('${dir.path}/model.int8.onnx').readAsBytesSync(),
          modelBytesBefore,
          reason: 'the fast path must not re-copy the model (the bundle is '
              'byte-identical across the 1.4.96→1.4.98 upgrade)');
      expect(File('${dir.path}/stale-extra.bin').readAsBytesSync(),
          staleBytesBefore,
          reason: "the fast path leaves the old build's extra files alone "
              '(no wipe, no re-copy)');
      expect(KokoroEngine.lastError, isNull);
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });

  test('concurrent ensure callers share ONE spawn attempt — the upgrade '
      'install regression (the screen-open prefetch + the render-ahead '
      'walk)', () async {
    final tmp = Directory.systemTemp.createTempSync('fidelis_upgrade_spawn');
    try {
      final dir = makeOldDataRow(tmp);
      KokoroEngine.debugPrepDirOverride = dir.path;
      // The spawn stands in for the isolate (no native engine in the unit
      // suite): the single-flight guard must admit exactly ONE attempt
      // for the two concurrent screen-open consumers.
      KokoroEngine.debugSpawnOverride = () async => true;

      final results = await Future.wait([
        KokoroEngine.ensureReady('en'),
        KokoroEngine.ensureReady('en'),
      ]);

      expect(
          KokoroEngine.debugSpawnAttempts,
          1,
          reason: 'two concurrent ensure callers (the rosary screen-open '
              'prefetch and the render-ahead walk) must produce exactly '
              'one worker spawn — the 1.4.98 upgrade failure raced two '
              'isolates into clobbered statics');
      // Both callers share the outcome: the spawn "succeeded", the init
      // then fails fast against the overridden spawn (no worker exists) —
      // but BOTH callers see the SAME verdict, no clobbered statics, and
      // the recorded failure is the init timeout (never the old bug's
      // 30 s spawn-timeout signature).
      expect(results[0], results[1]);
      expect(results[0], isFalse,
          reason: 'with no real worker behind the overridden spawn, the '
              'init fails fast — the sticky fallback gate engages');
      expect(KokoroEngine.lastError,
          contains('engine init timed out (worker unreachable)'));
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });

  test('a failed ensure clears the single-flight so a later attempt can '
      'retry', () async {
    final tmp = Directory.systemTemp.createTempSync('fidelis_upgrade_retry');
    try {
      final dir = makeOldDataRow(tmp);
      KokoroEngine.debugPrepDirOverride = dir.path;
      KokoroEngine.debugSpawnOverride = () async => false; // the spawn fails

      final first = await KokoroEngine.ensureReady('en');
      expect(first, isFalse);
      expect(KokoroEngine.debugSpawnAttempts, 1);
      expect(KokoroEngine.debugSpawnInFlight, isFalse,
          reason: 'the failed spawn must clear the in-flight cache so a '
              'later attempt can retry (a stale cached future would '
              'report the old result forever)');

      // The sticky failure gate would block a retry in production (by
      // design); reset it and prove a NEW attempt really spawns (the
      // counter restarts at 0 on reset — the assertion is 0 → 1).
      KokoroEngine.resetForTest();
      KokoroEngine.debugPrepDirOverride = dir.path;
      KokoroEngine.debugSpawnOverride = () async => false;

      final second = await KokoroEngine.ensureReady('en');
      expect(second, isFalse);
      expect(KokoroEngine.debugSpawnAttempts, 1,
          reason: 'after the reset a NEW spawn attempt was made (the '
              'counter went 0 → 1) — the retry path is live');
    } finally {
      tmp.deleteSync(recursive: true);
    }
  });
}
