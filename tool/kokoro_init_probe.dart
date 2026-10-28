// Real-init probe: proves the BUNDLED Kokoro assets initialize the real
// engine and synthesize (the revival assertion for v1.4.67 — espeak-ng-data
// now ships; through 1.4.66 init succeeded but phonemization failed and
// generate() returned 0 samples).
//
// Run from the repo root:
//   /home/chris/flutter/bin/dart run tool/kokoro_init_probe.dart
//
// Mirrors the app's KokoroEngine.prepareAssets(): reassembles
// model.int8.onnx from the bundled parts, copies voices.bin + tokens.txt,
// and points dataDir at the bundled espeak-ng-data tree (symlinked — the
// engine reads through it). Exits non-zero on any failure.
import 'dart:io';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

Future<void> main() async {
  if (!Directory('assets/kokoro').existsSync()) {
    stderr.writeln('Run from the fidelis repo root (assets/kokoro missing).');
    exit(2);
  }
  // Cache dir: reassembling the 109MB model each run is wasteful; rebuild
  // only when the bundled inputs change (stamp = part/voice/token sizes +
  // espeak file count).
  final espeakFiles = Directory('assets/kokoro/espeak-ng-data')
      .listSync(recursive: true)
      .whereType<File>()
      .length;
  final stamp = [
    for (var i = 0; i < 3; i++)
      File('assets/kokoro/model.int8.onnx.part-0$i').lengthSync(),
    File('assets/kokoro/voices.bin').lengthSync(),
    File('assets/kokoro/tokens.txt').lengthSync(),
    espeakFiles,
  ].join('|');
  final dir = Directory(
      '${Directory.systemTemp.path}/fidelis_kokoro_init_probe');
  final stampFile = File('${dir.path}/stamp.txt');
  if (!stampFile.existsSync() || stampFile.readAsStringSync() != stamp) {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final sink =
        File('${dir.path}/model.int8.onnx').openWrite(mode: FileMode.write);
    for (var i = 0; i < 3; i++) {
      await sink
          .addStream(File('assets/kokoro/model.int8.onnx.part-0$i').openRead());
    }
    await sink.flush();
    await sink.close();
    for (final f in ['voices.bin', 'tokens.txt']) {
      File('assets/kokoro/$f').copySync('${dir.path}/$f');
    }
    Link('${dir.path}/espeak-ng-data').createSync(
        Directory('assets/kokoro/espeak-ng-data').absolute.path,
        recursive: true);
    stampFile.writeAsStringSync(stamp);
  }
  stdout.writeln('probe dir: ${dir.path} (espeak files: $espeakFiles)');

  sherpa.initBindings();
  try {
    final tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        kokoro: sherpa.OfflineTtsKokoroModelConfig(
          model: '${dir.path}/model.int8.onnx',
          voices: '${dir.path}/voices.bin',
          tokens: '${dir.path}/tokens.txt',
          dataDir: '${dir.path}/espeak-ng-data',
          lang: 'en',
        ),
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      ),
    ));
    stdout.writeln('INIT: OK (sampleRate=${tts.sampleRate})');
    final audio = tts.generate(
        text: 'Hail Mary, full of grace.', sid: 26, speed: 0.9);
    if (audio.samples.isEmpty) {
      stderr.writeln('GENERATE: 0 samples — phonemization failed');
      exit(1);
    }
    stdout.writeln('GENERATE: OK samples=${audio.samples.length} '
        'rate=${audio.sampleRate} '
        '(${(audio.samples.length / audio.sampleRate).toStringAsFixed(2)}s)');
  } catch (e) {
    stderr.writeln('FAILED → $e');
    exit(1);
  }
}