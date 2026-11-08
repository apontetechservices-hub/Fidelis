// Word-timing verification tool: proves the app's word-level highlight
// schedules against the audio they drive, using the app's OWN pipeline.
//
// For each requested chapter (book + chapter + language) this tool:
//   1. loads the same Bible content the app displays (assets/bible/*.json,
//      asterisk markup stripped, verses sorted — BibleService.chapter),
//   2. chunks it exactly like BibleChapterScreen._startAudio (10 verses,
//      joined with single spaces),
//   3. applies the slot voice's pronunciation lexicon and splits the
//      spoken text with the app's own splitter (lib/services/tts_text.dart —
//      the same code TtsService speaks with),
//   4. synthesizes every sentence with the app's bundled Kokoro engine
//      (sherpa-onnx 1.13.8 FFI, assets/kokoro int8 model, the slot's sid +
//      speed — and the slot's BLEND: both sids render, PCM-mixed at the
//      slot's ratio, exactly what the engine worker does) and measures each
//      MIXED sentence's REAL duration,
//   5. computes the word schedule with the app's own computeWordSchedule
//      (per-sentence real durations + the within-sentence proportional
//      mapping the AudioController applies live — no separate estimate),
//   6. writes the concatenated chunk audio (16-bit PCM WAV) + the schedule
//      as JSON, then runs tool/word_timing_whisper.py, which transcribes
//      the audio with whisper WORD TIMESTAMPS and aligns the heard words
//      against the schedule to report per-word drift.
//
// --rosary-decade verifies ONE rosary decade (the first joyful) in BOTH
// languages through BOTH timing mechanisms the rosary path uses:
//   - runtime slots: the decade's step texts (announcement + Our Father +
//     Hail Mary + Glory Be + Fatima prayer) synthesized with the rosary
//     slot config (EN af_aoede; ES af_aoede blended 70/30 with ef_dora
//     under Spanish phonemization) — the synthesis-pass schedule the
//     runtime path highlights with;
//   - pre-rendered assets: the bundled .ogg files the decade actually
//     plays, against the app's asset-timeline schedule (timing-only
//     synthesis with the STANDARD voices — the voice the files were
//     generated with — scaled to the asset's real duration, exactly
//     AudioController._publishTimelineRange's mapping).
//
// Run from the repo root:
//   LD_LIBRARY_PATH=~/.pub-cache/hosted/pub.dev/sherpa_onnx_linux-1.13.8/linux/x64 \
//     dart run tool/word_timing_verify.dart --suite --out /tmp/bible_word_timing
// (single chapter: --book Psalms --chapter 23 --lang en; Bible slot:
//  --slot bible|rosary; rosary decade: --rosary-decade)
//
// The model must be reassembled once from its bundled parts:
//   cat assets/kokoro/model.int8.onnx.part-* > /tmp/kokoro_verify/model.int8.onnx
//   ln -s (repo)/assets/kokoro/{voices.bin,tokens.txt,espeak-ng-data} /tmp/kokoro_verify/
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fidelis/features/rosary/mystery_data.dart';
import 'package:fidelis/features/rosary/rosary_prayers.dart';
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
          // The app's worker phonemization fix (2026-11-05): 'en' is
          // British RP (non-rhotic); the app ships 'en-us' (American,
          // rhotic). The verifier must synthesize the SAME audio the app
          // ships — 'en' here would verify against audio nobody hears.
          lang: lang == 'en' ? 'en-us' : lang,
        ),
        numThreads: 2, // the app's worker setting
        debug: false,
        provider: 'cpu',
      ),
    ));
  });
}

/// Synthesizes one sentence with [voice]'s slot config for [lang] — through
/// the app's ONE slot-synthesis path ([synthesizeSlotSentence] in
/// lib/services/tts_text.dart, the same function the engine worker runs).
/// The tool's synthesis call IS the app's playback path by construction.
(Float32List, int) renderSlotSentence(
    nat.OfflineTts engine, String text, KokoroVoice voice, String lang) {
  return synthesizeSlotSentence(
    (t, sid, speed) {
      final audio = engine.generate(text: t, sid: sid, speed: speed);
      return (Float32List.fromList(audio.samples), audio.sampleRate);
    },
    text,
    voice,
    lang,
  );
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
    String lang, String bookKey, int chapter, String outDir,
    {String slot = 'bible'}) {
  final voice = slot == 'rosary' ? KokoroVoice.rosary : KokoroVoice.bible;
  final verses = loadChapter(lang, bookKey, chapter);
  final engine = _engineFor(lang);
  final chapterDir = '$outDir/${bookKey}_$chapter-$lang';
  Directory(chapterDir).createSync(recursive: true);

  stdout.writeln('[readout] playback ${slotReadoutLine(voice, lang)}');

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

    // Synthesize every sentence with the app's engine (the slot's blend
    // included); measure the REAL generated duration of each MIXED render
    // (the schedule's only timing source).
    final allSamples = <Float32List>[];
    final durations = <Duration>[];
    var sampleRate = 0;
    for (var i = 0; i < sentences.length; i++) {
      final (samples, rate) =
          renderSlotSentence(engine, sentences[i], voice, lang);
      if (samples.isEmpty) {
        throw StateError('empty synthesis for chunk $start sentence $i');
      }
      sampleRate = rate;
      allSamples.add(samples);
      durations.add(Duration(
          milliseconds: (samples.length * 1000 / rate).round()));
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
    'slot': slot,
    'voice': {
      'slot': slot,
      'en': voice.enName,
      'es': voice.esName,
      'enSid': voice.enSid,
      'esSid': voice.esSid,
      'enBlendSid': voice.enBlendSid,
      'esBlendSid': voice.esBlendSid,
      'enBlendName': voice.enBlendName,
      'esBlendName': voice.esBlendName,
      'blendRatio': voice.blendRatio,
      'speed': voice.speed,
      // JSON object keys must be strings: the EQ map is band-index → dB.
      'enEqualizer': voice.enEqualizer == null
          ? null
          : {
              for (final e in voice.enEqualizer!.entries)
                e.key.toString(): e.value,
            },
      'esEqualizer': voice.esEqualizer == null
          ? null
          : {
              for (final e in voice.esEqualizer!.entries)
                e.key.toString(): e.value,
            },
      'lexicon': voice.lexiconFor(lang),
    },
    'engine': 'sherpa-onnx 1.13.8, assets/kokoro int8 model, numThreads 2, '
        'phonemization en-us/es (the app worker setting)',
    'verseCount': verses.length,
    'chunkCount': chunksReport.length,
    'totalAudioMs': totalAudioMs,
    'totalWords': totalWords,
    'chunks': chunksReport,
  };
}

/// The mystery announcement text exactly as rosary_prayer_screen.dart's
/// _mysteryAnnouncementText composes it — the runtime path's speech text
/// and the pre-rendered files' source text.
String mysteryAnnouncementText(MysteryData m, String lang) {
  final n = m.number.clamp(1, 5);
  if (lang == 'es') {
    const ord = ['Primer', 'Segundo', 'Tercer', 'Cuarto', 'Quinto'];
    const set = {
      'joyful': 'Gozoso',
      'sorrowful': 'Doloroso',
      'glorious': 'Glorioso',
      'luminous': 'Luminoso',
    };
    final v = mysteryVersesEs[m.id] ?? [m.verseRef, m.verseText];
    return '${ord[n - 1]} Misterio ${set[m.type] ?? m.type}: ${m.titleEs}.\n\n'
        '${v[0]}.\n\n${v[1]}\n\n${m.meditationEs}\n\n'
        'Fruto Espiritual: ${m.fruitEs}.';
  }
  const ord = ['First', 'Second', 'Third', 'Fourth', 'Fifth'];
  const set = {
    'joyful': 'Joyful',
    'sorrowful': 'Sorrowful',
    'glorious': 'Glorious',
    'luminous': 'Luminous',
  };
  return 'The ${ord[n - 1]} ${set[m.type] ?? m.type} Mystery: ${m.titleEn}.\n\n'
      '${m.verseRef}.\n\n${m.verseText}\n\n${m.meditationEn}\n\n'
      'Spiritual Fruit: ${m.fruitEn}.';
}

/// The first joyful decade's steps in recitation order — announcement,
/// Our Father, Hail Mary, Glory Be, Fatima prayer — with the exact texts
/// the rosary path recites (RosaryPrayers + the announcement format).
List<(String, String)> rosaryDecadeSteps(String lang) {
  final m = MysteryData.joyful[0];
  return [
    ('joyful_1', mysteryAnnouncementText(m, lang)),
    ('our_father', RosaryPrayers.get('our_father', lang)),
    ('hail_mary', RosaryPrayers.get('hail_mary', lang)),
    ('glory_be', RosaryPrayers.get('glory_be', lang)),
    ('fatima_prayer', RosaryPrayers.get('fatima_prayer', lang)),
  ];
}

Map<String, Object?> _rosaryChapterEntry({
  required String label,
  required String lang,
  required Map<String, Object?> voiceConfig,
  required List<Map<String, Object?>> chunks,
  required int totalAudioMs,
  required int totalWords,
}) {
  return {
    'book': label,
    'chapter': 1,
    'lang': lang,
    'voice': voiceConfig,
    'engine': 'sherpa-onnx 1.13.8, assets/kokoro int8 model, numThreads 2, '
        'phonemization en-us/es (the app worker setting)',
    'verseCount': chunks.length,
    'chunkCount': chunks.length,
    'totalAudioMs': totalAudioMs,
    'totalWords': totalWords,
    'chunks': chunks,
  };
}

Map<String, Object?> _rosaryVoiceConfig(KokoroVoice voice, String lang,
        {String slot = 'rosary'}) =>
    {
      'slot': slot,
      'en': voice.enName,
      'es': voice.esName,
      'enSid': voice.enSid,
      'esSid': voice.esSid,
      'enBlendSid': voice.enBlendSid,
      'esBlendSid': voice.esBlendSid,
      'enBlendName': voice.enBlendName,
      'esBlendName': voice.esBlendName,
      'blendRatio': voice.blendRatio,
      'speed': voice.speed,
      // JSON object keys must be strings: the EQ map is band-index → dB.
      'enEqualizer': voice.enEqualizer == null
          ? null
          : {
              for (final e in voice.enEqualizer!.entries)
                e.key.toString(): e.value,
            },
      'esEqualizer': voice.esEqualizer == null
          ? null
          : {
              for (final e in voice.esEqualizer!.entries)
                e.key.toString(): e.value,
            },
      'lexicon': voice.lexiconFor(lang),
    };

/// Verifies ONE rosary decade (the first joyful) in [lang] through the
/// APP'S REAL PLAYBACK PATH: after the runtime-only fix the rosary plays
/// every step through the rosary slot config ([KokoroVoice.rosary]) with
/// the schedule derived from the SAME synthesis that produces the audio —
/// there is no asset path anymore (the pre-rendered files are dormant).
/// The synthesis runs through the shared [synthesizeSlotSentence] — the
/// same function the app's engine worker runs — so the tool's synthesis
/// call is the app's playback path by construction. Returns ONE chapter
/// entry (runtime) for the manifest.
List<Map<String, Object?>> verifyRosaryDecade(String lang, String outDir) {
  final engine = _engineFor(lang);
  final slotVoice = KokoroVoice.rosary;
  final steps = rosaryDecadeSteps(lang);

  stdout.writeln('[readout] playback ${slotReadoutLine(slotVoice, lang)}');

  final runtimeChunks = <Map<String, Object?>>[];
  var runtimeAudioMs = 0;
  var runtimeWords = 0;

  for (var s = 0; s < steps.length; s++) {
    final (key, text) = steps[s];
    final stepDir = '$outDir/rosary_$lang/$key';
    Directory(stepDir).createSync(recursive: true);

    // The runtime slot config (synthesis-pass schedule) — the app's only
    // rosary path now.
    final (spokenA, _) =
        applyPronunciationLexicon(text, slotVoice.lexiconFor(lang));
    final sentencesA = splitSpeakableSentences(spokenA);
    if (sentencesA.isEmpty) continue;
    final allSamples = <Float32List>[];
    final durations = <Duration>[];
    var rate = 0;
    for (var i = 0; i < sentencesA.length; i++) {
      final (samples, r) =
          renderSlotSentence(engine, sentencesA[i], slotVoice, lang);
      rate = r;
      allSamples.add(samples);
      durations
          .add(Duration(milliseconds: (samples.length * 1000 / r).round()));
      stderr.writeln('  [rosary $key $lang runtime] sentence '
          '${i + 1}/${sentencesA.length} '
          '(${durations.last.inMilliseconds}ms)');
    }
    final totalLen = allSamples.fold<int>(0, (n, x) => n + x.length);
    final concat = Float32List(totalLen);
    var at = 0;
    for (final x in allSamples) {
      concat.setAll(at, x);
      at += x.length;
    }
    final wavFile = File('$stepDir/runtime.wav');
    wavFile.writeAsBytesSync(encodeWav16(concat, rate));
    final schedule = computeWordSchedule(spokenA, durations);
    final words = [
      for (final w in schedule)
        {
          'word': spokenA.substring(w.charStart, w.charEnd),
          'charStart': w.charStart,
          'charEnd': w.charEnd,
          'startMs': w.start.inMilliseconds,
          'endMs': w.end.inMilliseconds,
        },
    ];
    runtimeAudioMs += totalLen * 1000 ~/ rate;
    runtimeWords += words.length;
    runtimeChunks.add({
      'index': s,
      'firstVerse': s,
      'lastVerse': s,
      'originalText': text,
      'spokenText': spokenA,
      'wav': wavFile.path,
      'sampleRate': rate,
      'sentenceCount': sentencesA.length,
      'audioMs': totalLen * 1000 ~/ rate,
      'words': words,
    });
  }

  return [
    _rosaryChapterEntry(
      label: 'Rosary-joyful1-runtime',
      lang: lang,
      voiceConfig: _rosaryVoiceConfig(slotVoice, lang),
      chunks: runtimeChunks,
      totalAudioMs: runtimeAudioMs,
      totalWords: runtimeWords,
    ),
  ];
}

void main(List<String> args) {
  String? book;
  int? chapter;
  String? lang;
  var suite = false;
  var rosaryDecade = false;
  var slot = 'bible';
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
      case '--rosary-decade':
        rosaryDecade = true;
      case '--slot':
        slot = args[++i];
      case '--skip-whisper':
        skipWhisper = true;
      default:
        stderr.writeln('unknown arg ${args[i]}');
        exit(2);
    }
  }

  final chapters = <Map<String, Object?>>[];
  Directory(outDir).createSync(recursive: true);
  final manifestFile = File('$outDir/manifest.json');

  // The manifest is rewritten after EVERY chapter: a late crash (or a
  // whisper invocation) must never lose the chapters already verified.
  void writeManifest() {
    final manifest = <String, Object?>{
      'generatedWith': 'the app pipeline: tts_text.dart + sherpa-onnx 1.13.8 '
          '(assets/kokoro int8 model), voice-grid slot profiles',
      'chapters': chapters,
    };
    manifestFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(manifest));
    stdout.writeln('[manifest] ${manifestFile.path} '
        '(${chapters.length} chapters)');
  }

  if (rosaryDecade) {
    for (final l in const ['en', 'es']) {
      chapters.addAll(verifyRosaryDecade(l, outDir));
      writeManifest();
    }
  } else {
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
        stderr.writeln(
            'usage: --suite | --rosary-decade | (--book K --chapter N --lang en|es)');
        exit(2);
      }
      targets.add((book, chapter, lang));
    }
    for (final (b, c, l) in targets) {
      chapters.add(verifyChapter(l, b, c, outDir, slot: slot));
      writeManifest();
    }
  }

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