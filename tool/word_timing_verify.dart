// Word-timing verification tool: proves the Bible's word-level highlight
// schedule against the audio it drives, using the app's OWN pipeline.
//
// For each requested chapter (book + chapter + language) this tool:
//   1. loads the same Bible content the app displays (assets/bible/*.json,
//      asterisk markup stripped, verses sorted — BibleService.chapter),
//   2. chunks it exactly like BibleChapterScreen._startAudio (10 verses,
//      joined with single spaces),
//   3. applies the Bible voice's pronunciation lexicon and splits the
//      spoken text with the app's own splitter (lib/services/tts_text.dart —
//      the same code TtsService speaks with),
//   4. synthesizes every sentence with the app's bundled Kokoro engine
//      (sherpa-onnx 1.13.8 FFI, assets/kokoro int8 model, the Bible voice's
//      sid + speed) and measures each sentence's REAL generated duration,
//   5. computes the word schedule with the app's own computeWordSchedule
//      (per-sentence real durations + the within-sentence proportional
//      mapping the AudioController applies live — no separate estimate),
//   6. writes the concatenated chunk audio (16-bit PCM WAV) + the schedule
//      as JSON, then runs tool/word_timing_whisper.py, which transcribes
//      the audio with whisper WORD TIMESTAMPS and aligns the heard words
//      against the schedule to report per-word drift.
//
// Run from the repo root:
//   LD_LIBRARY_PATH=~/.pub-cache/hosted/pub.dev/sherpa_onnx_linux-1.13.8/linux/x64 \
//     dart run tool/word_timing_verify.dart --suite --out /tmp/bible_word_timing
// (single chapter: --book Psalms --chapter 23 --lang en)
//
// The model must be reassembled once from its bundled parts:
//   cat assets/kokoro/model.int8.onnx.part-* > /tmp/kokoro_verify/model.int8.onnx
//   ln -s (repo)/assets/kokoro/{voices.bin,tokens.txt,espeak-ng-data} /tmp/kokoro_verify/
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fidelis/services/tts_text.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as s;
// The host VM's conditional export picks the web TTS binding; the native
// OfflineTts lives in src/tts.dart (the app's own engine binding).
// ignore: implementation_imports
import 'package:sherpa_onnx/src/tts.dart' as nat;

/// Verses per TTS chunk — BibleChapterScreen._versesPerChunk.
const int versesPerChunk = 10;

/// The app's bundled model, reassembled (see header).
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
          lang: lang,
        ),
        numThreads: 2, // the app's worker setting
        debug: false,
        provider: 'cpu',
      ),
    ));
  });
}

/// Loads one chapter's verses exactly like BibleService.chapter: asterisk
/// markup stripped, verse-number order.
List<(int, String)> loadChapter(String lang, String bookKey, int chapter) {
  final asset = lang == 'es'
      ? 'assets/bible/sp_bible.json'
      : 'assets/bible/dr_bible.json';
  final bible = jsonDecode(File(asset).readAsStringSync())
      as Map<String, dynamic>;
  final bookData = bible[bookKey] as Map<String, dynamic>?;
  if (bookData == null) {
    throw StateError('book $bookKey missing from $asset');
  }
  final ch = bookData['$chapter'] as Map<String, dynamic>?;
  if (ch == null) {
    throw StateError('chapter $chapter missing from $bookKey ($asset)');
  }
  final verses = <(int, String)>[];
  for (final entry in ch.entries) {
    final number = int.tryParse(entry.key);
    if (number == null) continue;
    verses.add((number, (entry.value as String).replaceAll('*', '')));
  }
  verses.sort((a, b) => a.$1.compareTo(b.$1));
  return verses;
}

/// Encodes mono float PCM samples as a 16-bit WAV byte buffer (same format
/// the app's encodeWav16 writes for sentence playback).
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

Map<String, Object?> verifyChapter(
    String lang, String bookKey, int chapter, String outDir) {
  final voice = KokoroVoice.bible;
  final verses = loadChapter(lang, bookKey, chapter);
  final engine = _engineFor(lang);
  final chapterDir = '$outDir/${bookKey}_$chapter-$lang';
  Directory(chapterDir).createSync(recursive: true);

  final chunksReport = <Object?>[];
  var totalAudioMs = 0;
  var totalWords = 0;
  for (var start = 0; start < verses.length; start += versesPerChunk) {
    final end = (start + versesPerChunk < verses.length)
        ? start + versesPerChunk
        : verses.length;
    final group = verses.sublist(start, end);
    final original = group.map((v) => v.$2).join(' ');
    // The app's synthesis path: lexicon BEFORE sentence splitting.
    final (spoken, _) =
        applyPronunciationLexicon(original, voice.lexiconFor(lang));
    final sentences = splitSpeakableSentences(spoken);
    if (sentences.isEmpty) continue;

    // Synthesize every sentence with the app's engine; measure the REAL
    // generated duration of each (the schedule's only timing source).
    final allSamples = <Float32List>[];
    final durations = <Duration>[];
    var sampleRate = 0;
    for (var i = 0; i < sentences.length; i++) {
      final audio = engine.generate(
        text: sentences[i],
        sid: voice.sidFor(lang),
        speed: voice.speed,
      );
      if (audio.samples.isEmpty) {
        throw StateError('empty synthesis for chunk $start sentence $i');
      }
      sampleRate = audio.sampleRate;
      allSamples.add(Float32List.fromList(audio.samples));
      durations.add(Duration(
          milliseconds:
              (audio.samples.length * 1000 / audio.sampleRate).round()));
      stderr.writeln(
          '  [$bookKey $chapter $lang] chunk ${start ~/ versesPerChunk} '
          'sentence ${i + 1}/${sentences.length} '
          '(${durations.last.inMilliseconds}ms)');
    }

    // Concatenate the sentence audio back-to-back — exactly the schedule's
    // model of playback (per-sentence WAVs played in sequence).
    final totalLen = allSamples.fold<int>(0, (n, s) => n + s.length);
    final concat = Float32List(totalLen);
    var at = 0;
    for (final s in allSamples) {
      concat.setAll(at, s);
      at += s.length;
    }
    final wavFile = File('$chapterDir/chunk_${start ~/ versesPerChunk}.wav');
    wavFile.writeAsBytesSync(encodeWav16(concat, sampleRate));

    // The app's own word schedule for this chunk.
    final schedule = computeWordSchedule(spoken, durations);
    final words = [
      for (final w in schedule)
        {
          'word': spoken.substring(w.charStart, w.charEnd),
          'charStart': w.charStart,
          'charEnd': w.charEnd,
          'startMs': w.start.inMilliseconds,
          'endMs': w.end.inMilliseconds,
        },
    ];
    totalAudioMs += totalLen * 1000 ~/ sampleRate;
    totalWords += words.length;
    chunksReport.add({
      'index': start ~/ versesPerChunk,
      'firstVerse': group.first.$1,
      'lastVerse': group.last.$1,
      'originalText': original,
      'spokenText': spoken,
      'wav': wavFile.path,
      'sampleRate': sampleRate,
      'sentenceCount': sentences.length,
      'audioMs': totalLen * 1000 ~/ sampleRate,
      'words': words,
    });
  }

  return {
    'book': bookKey,
    'chapter': chapter,
    'lang': lang,
    'voice': {
      'en': voice.enName,
      'es': voice.esName,
      'enSid': voice.enSid,
      'esSid': voice.esSid,
      'speed': voice.speed,
      'lexicon': voice.lexiconFor(lang),
    },
    'engine': 'sherpa-onnx 1.13.8, assets/kokoro int8 model, numThreads 2',
    'verseCount': verses.length,
    'chunkCount': chunksReport.length,
    'totalAudioMs': totalAudioMs,
    'totalWords': totalWords,
    'chunks': chunksReport,
  };
}

void main(List<String> args) {
  String? book;
  int? chapter;
  String? lang;
  var suite = false;
  var outDir = '/tmp/bible_word_timing';
  var skipWhisper = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--book':
        book = args[++i];
      case '--chapter':
        chapter = int.parse(args[++i]);
      case '--lang':
        lang = args[++i];
      case '--out':
        outDir = args[++i];
      case '--suite':
        suite = true;
      case '--skip-whisper':
        skipWhisper = true;
      default:
        stderr.writeln('unknown arg ${args[i]}');
        exit(2);
    }
  }

  final targets = <(String, int, String)>[];
  if (suite) {
    targets.addAll([
      ('Psalms', 23, 'en'),
      ('Psalms', 23, 'es'),
      ('John', 1, 'en'),
      ('John', 1, 'es'),
    ]);
  } else {
    if (book == null || chapter == null || lang == null) {
      stderr.writeln('usage: --suite | (--book K --chapter N --lang en|es)');
      exit(2);
    }
    targets.add((book, chapter, lang));
  }

  Directory(outDir).createSync(recursive: true);
  final manifest = <String, Object?>{
    'generatedWith': 'the app pipeline: tts_text.dart + sherpa-onnx 1.13.8 '
        '(assets/kokoro int8 model), Bible voice profile',
    'chapters': [
      for (final (b, c, l) in targets) verifyChapter(l, b, c, outDir),
    ],
  };
  final manifestFile = File('$outDir/manifest.json');
  manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest));
  stdout.writeln('[manifest] ${manifestFile.path}');

  if (skipWhisper) {
    stdout.writeln('[done] synthesis + schedule written (whisper skipped)');
    return;
  }
  // Hand the artifacts to the whisper verifier (word timestamps + alignment).
  final r = Process.runSync('python3', [
    'tool/word_timing_whisper.py',
    outDir,
  ], stderrEncoding: utf8);
  stdout.write(r.stdout);
  stderr.write(r.stderr);
  exit(r.exitCode);
}