// Addendum verification renders (the owner's addendum, item 3): puts the
// shipped pronunciations on the record with Whisper transcripts.
//
//   1. "A psalm for David." — the Douay-Rheims Psalm 22 superscription —
//      rendered with the ENGLISH-BIBLE slot (am_michael, speed 0.81, en-us
//      phonemization). Proves 'psalm' phonemizes
//      natively with no audible L (the round-2 'Salm' respelling is
//      REMOVED; the Bible-EN lexicon carries no psalm entry).
//   2. The Hail Mary opening — rendered with the ENGLISH-ROSARY slot
//      (af_aoede, speed 0.9, the rosary-scoped bless-ed correction
//      applied). Proves 'blessed' renders as two syllables.
//   3. The same Hail Mary opening WITHOUT the correction (control) — the
//      duration difference between the two renders' 'blessed' words is the
//      audible two-syllable evidence.
//
// Run from the repo root:
//   LD_LIBRARY_PATH=~/.pub-cache/hosted/pub.dev/sherpa_onnx_linux-1.13.8/linux/x64 \
//     dart run tool/addendum_renders.dart --out /tmp/addendum_renders
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fidelis/services/tts_text.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as s;
// ignore: implementation_imports
import 'package:sherpa_onnx/src/tts.dart' as nat;

const String modelDir = '/tmp/kokoro_verify';

final Map<String, nat.OfflineTts> _engines = {};

nat.OfflineTts _engineFor(String lang) {
  return _engines.putIfAbsent(lang, () {
    s.initBindings();
    return nat.OfflineTts(s.OfflineTtsConfig(
      model: s.OfflineTtsModelConfig(
        kokoro: s.OfflineTtsKokoroModelConfig(
          model: '$modelDir/model.int8.onnx',
          voices: '$modelDir/voices.bin',
          tokens: '$modelDir/tokens.txt',
          dataDir: '$modelDir/espeak-ng-data',
          lang: lang == 'en' ? 'en-us' : lang, // the app worker setting
        ),
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      ),
    ));
  });
}

/// The Bible slot's synthesis: the slot's sid at the slot's speed, ONE
/// render per sentence — every slot is a single voice.
(Float32List, int) synthesizeSlotSentence(
    nat.OfflineTts engine, String text, KokoroVoice voice, String lang) {
  final audio =
      engine.generate(text: text, sid: voice.sidFor(lang), speed: voice.speed);
  if (audio.samples.isEmpty) {
    throw StateError('empty synthesis (sid ${voice.sidFor(lang)}): $text');
  }
  return (Float32List.fromList(audio.samples), audio.sampleRate);
}

/// The proven WAV encoder from tool/word_timing_verify.dart (verbatim).
Uint8List encodeWav16(Float32List samples, int sampleRate) {
  final dataLen = samples.length * 2;
  final pcm = ByteData(dataLen);
  for (var i = 0; i < samples.length; i++) {
    var v = samples[i];
    if (v > 1.0) v = 1.0;
    if (v < -1.0) v = -1.0;
    pcm.setInt16(i * 2, (v * 32767).round(), Endian.little);
  }
  final header = ByteData(44);
  void str(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      header.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  header.setUint32(4, 36 + dataLen, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // fmt chunk size
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little); // block align
  header.setUint16(34, 16, Endian.little); // bits per sample
  str(36, 'data');
  header.setUint32(40, dataLen, Endian.little);
  final out = Uint8List(44 + dataLen);
  out.setAll(0, header.buffer.asUint8List());
  out.setAll(44, pcm.buffer.asUint8List());
  return out;
}

void main(List<String> args) {
  var outDir = '/tmp/addendum_renders';
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out') outDir = args[++i];
  }
  Directory(outDir).createSync(recursive: true);
  final engine = _engineFor('en');

  // 1. The Psalm 22 superscription through the ENGLISH-BIBLE slot (the
  //    lexicon applied exactly as the synthesis path does — it contains no
  //    psalm entry, so 'psalm' phonemizes natively).
  const psalmText = 'A psalm for David.';
  final (psalmSpoken, _) =
      applyPronunciationLexicon(psalmText, KokoroVoice.bible.lexiconFor('en'));
  final (psalmSamples, psalmRate) =
      synthesizeSlotSentence(engine, psalmSpoken, KokoroVoice.bible, 'en');
  final psalmWav = '$outDir/psalm_superscription_bible_en.wav';
  File(psalmWav).writeAsBytesSync(encodeWav16(psalmSamples, psalmRate));

  // 2. The Hail Mary opening through the ENGLISH-ROSARY slot (the
  //    rosary-scoped bless-ed correction applied).
  const hailMary =
      'Hail Mary, full of grace, the Lord is with thee. Blessed art thou '
      'amongst women, and blessed is the fruit of thy womb, Jesus.';
  final (hmSpoken, _) =
      applyPronunciationLexicon(hailMary, KokoroVoice.rosary.lexiconFor('en'));
  final (hmSamples, hmRate) =
      synthesizeSlotSentence(engine, hmSpoken, KokoroVoice.rosary, 'en');
  final hmWav = '$outDir/hail_mary_opening_rosary_en_blessed_corrected.wav';
  File(hmWav).writeAsBytesSync(encodeWav16(hmSamples, hmRate));

  // 3. The control: the same text WITHOUT the correction (solo af_aoede,
  //    same speed) — the 'blessed' duration difference is the evidence.
  final (hmRawSamples, hmRawRate) =
      synthesizeSlotSentence(engine, hailMary, KokoroVoice.rosary, 'en');
  final hmRawWav = '$outDir/hail_mary_opening_rosary_en_uncorrected.wav';
  File(hmRawWav).writeAsBytesSync(encodeWav16(hmRawSamples, hmRawRate));

  final manifest = {
    'renders': [
      {
        'wav': psalmWav,
        'slot': 'bible-en',
        'text': psalmText,
        'spokenText': psalmSpoken,
        'voice': {
          'primary': 'am_michael (sid 16)',
          'speed': KokoroVoice.bible.speed,
          'lexicon': KokoroVoice.bible.lexiconFor('en'),
          'phonemization': 'en-us',
        },
        'audioMs': psalmSamples.length * 1000 ~/ psalmRate,
      },
      {
        'wav': hmWav,
        'slot': 'rosary-en',
        'text': hailMary,
        'spokenText': hmSpoken,
        'voice': {
          'primary': 'af_aoede (sid 1)',
          'speed': KokoroVoice.rosary.speed,
          'lexicon': KokoroVoice.rosary.lexiconFor('en'),
          'phonemization': 'en-us',
        },
        'audioMs': hmSamples.length * 1000 ~/ hmRate,
      },
      {
        'wav': hmRawWav,
        'slot': 'rosary-en (control, correction NOT applied)',
        'text': hailMary,
        'spokenText': hailMary,
        'voice': {
          'primary': 'af_aoede (sid 1)',
          'speed': KokoroVoice.rosary.speed,
          'lexicon': const <String, String>{},
          'phonemization': 'en-us',
        },
        'audioMs': hmRawSamples.length * 1000 ~/ hmRawRate,
      },
    ],
  };
  File('$outDir/manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  stderr.writeln('renders written to $outDir');
  for (final r in manifest['renders'] as List<Map<String, Object?>>) {
    stderr.writeln('  ${r['wav']} (${r['audioMs']}ms)');
  }
}
