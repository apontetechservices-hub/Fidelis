/// Pure Dart text/voice pipeline shared by the TTS service and the
/// word-timing verification tool (tool/word_timing_verify.dart runs on the
/// host Dart VM, which cannot import the Flutter-plugin service files) —
/// everything here must stay free of Flutter imports.
///
/// Holds the per-slot voice grid (Kokoro synthesis profiles: sid, speed,
/// blend partner, equalizer shaping per language), the per-voice
/// pronunciation-override lexicon, the sentence splitter the engine speaks
/// with, and the word-schedule computation the highlight timing derives
/// from.
library;

import 'dart:typed_data';

/// Per-slot Kokoro synthesis profile: the voice sid per language in
/// voices.bin, the speaking speed, an optional Android-equalizer shaping
/// per language, and the voice names the pronunciation lexicon is keyed
/// by. Every slot speaks ONE voice — one render per sentence, no blends,
/// no PCM mixing.
class KokoroVoice {
  final int enSid;
  final int esSid;
  final double speed;

  /// Kokoro voice names (lexicon keys), e.g. 'bm_daniel'.
  final String enName;
  final String esName;

  /// Android-equalizer shaping per language (band index → dB gain), applied
  /// slot-scoped at playback (see TtsService.applySlotEqualizer). Null or
  /// empty = flat: the slot plays unshaped and any earlier shaping is
  /// cleared. Only the English-Bible slot carries a curve.
  final Map<int, double>? enEqualizer;
  final Map<int, double>? esEqualizer;

  /// Slot-scoped pronunciation corrections per language, merged into
  /// [lexiconFor] on top of the voice-name lexicon. These apply ONLY where
  /// this slot synthesizes — they never leak into another slot's text
  /// processing (the English rosary's bless-ed correction lives here; the
  /// Bible and the Spanish rosary carry none).
  final Map<String, String>? enSlotLexicon;
  final Map<String, String>? esSlotLexicon;

  const KokoroVoice({
    required this.enSid,
    required this.esSid,
    required this.speed,
    required this.enName,
    required this.esName,
    this.enEqualizer,
    this.esEqualizer,
    this.enSlotLexicon,
    this.esSlotLexicon,
  });

  /// Sid for [lang] ('en' | 'es').
  int sidFor(String lang) => lang == 'es' ? esSid : enSid;

  /// Voice name for [lang] — the pronunciation-lexicon key.
  String nameFor(String lang) => lang == 'es' ? esName : enName;

  /// The slot's equalizer shaping for [lang], or null when flat.
  Map<int, double>? equalizerFor(String lang) =>
      lang == 'es' ? esEqualizer : enEqualizer;

  /// The slot's pronunciation-override lexicon for [lang]: the voice-name
  /// lexicon plus the slot-scoped corrections (possibly empty).
  Map<String, String> lexiconFor(String lang) => {
        ...kokoroVoiceLexicon[nameFor(lang)] ?? const {},
        ...(lang == 'es' ? esSlotLexicon : enSlotLexicon) ?? const {},
      };

  /// Readings + rosary-timing voices — the long-standing configuration
  /// (EN bm_george sid 26, ES em_alex sid 29, speed 0.9). Every synthesis
  /// path that does not ask for a specific profile keeps these — including
  /// the rosary's ASSET timing synthesis, whose pre-rendered files were
  /// generated with them.
  static const KokoroVoice standard = KokoroVoice(
    enSid: 26,
    esSid: 29,
    speed: 0.9,
    enName: 'bm_george',
    esName: 'em_alex',
  );

  /// Bible voices — the owner's voice-grid decision: EN am_michael (sid
  /// 16) SOLO at speed 0.81, softened by a gentle boom-softening
  /// equalizer on the English slot only (the softening IS the equalizer —
  /// no voice mixing); ES em_alex (sid 29) solo, no EQ. The lexicon key
  /// is 'am_michael'.
  static const KokoroVoice bible = KokoroVoice(
    enSid: 16,
    enName: 'am_michael',
    esSid: 29,
    esName: 'em_alex',
    speed: 0.81,
    enEqualizer: {0: -4.0, 1: -2.0},
  );

  /// Rosary voices — the runtime-TTS slot (steps without a pre-rendered
  /// file): EN af_aoede (sid 1); ES af_aoede (sid 1) speaking Spanish
  /// (the es phonemization) — ONE voice across both languages, the
  /// owner's accepted trade-off (her non-native Spanish accent stays).
  /// Speed 0.9 — the auditioned rosary pace. No EQ. The English slot
  /// carries the rosary-scoped bless-ed correction (the Hail Mary's
  /// 'blessed' renders as two syllables; it never leaks into Bible
  /// processing, and the Spanish rosary is unaffected). ef_dora appears
  /// NOWHERE — no slot speaks it.
  static const KokoroVoice rosary = KokoroVoice(
    enSid: 1,
    enName: 'af_aoede',
    esSid: 1,
    esName: 'af_aoede',
    speed: 0.9,
    enSlotLexicon: {'blessed': 'bless-ed'},
  );
}

/// Per-voice pronunciation-override lexicon — grown from the voice
/// auditions. Key: Kokoro voice name; value: {source word (lowercase):
/// respelling spoken instead}. Entries match case-insensitively as whole
/// words and are applied to the text before sentence splitting. Respellings
/// are tuned PER VOICE — a respelling verified for one voice must never be
/// copied to another (the audition voices differ in which words they
/// already say correctly).
///
/// NOTE (the owner's addendum, 2026-11-08): Michael's list is 'ruleth' →
/// 'Rouleth' and 'pasture' → 'Pastsher'. The round-2 'Salm' respelling for
/// 'psalm' is REMOVED — under the en-us phonemizer 'psalm' is phonemized
/// natively with no audible L, while 'Salm' itself carries an audible L.
/// The Bible-EN lexicon must NOT contain a psalm entry.
const Map<String, Map<String, String>> kokoroVoiceLexicon = {
  'am_michael': {'ruleth': 'Rouleth', 'pasture': 'Pastsher'},
  'em_alex': {},
  'af_aoede': {},
  'ef_dora': {},
};

/// A Kokoro engine render callback: synthesizes [text] with [sid] at
/// [speed], returning the raw samples and the engine's sample rate.
typedef KokoroGenerate = (Float32List, int) Function(
    String text, int sid, double speed);

/// The app's ONE slot-synthesis path: renders [text] for [voice]'s slot in
/// [lang] through [generate] — the slot's sid at the slot's speed, ONE
/// render per sentence. Every slot is a single voice: no blend partner
/// renders, no PCM mixing. The engine worker (kokoro_engine.dart) and the
/// word-timing verifier (tool/word_timing_verify.dart) BOTH synthesize
/// through this function — the tool's synthesis call is the app's
/// playback path by construction, not a replica.
(Float32List, int) synthesizeSlotSentence(
    KokoroGenerate generate, String text, KokoroVoice voice, String lang) {
  final sid = voice.sidFor(lang);
  return generate(text, sid, voice.speed);
}

/// The slot label for the readout line: the grid's named slots, or
/// 'custom' for ad-hoc profiles.
String slotNameFor(KokoroVoice voice) {
  if (identical(voice, KokoroVoice.bible)) return 'bible';
  if (identical(voice, KokoroVoice.rosary)) return 'rosary';
  if (identical(voice, KokoroVoice.standard)) return 'standard';
  return 'custom';
}

/// The playback-start readout line for [voice]'s slot in [lang]: the active
/// sid(s), speed, and equalizer state — the owner's demand that every
/// playback print what is about to be heard. The app's TtsService logs this
/// at playback start and the word-timing verifier prints the same line for
/// every verified slot (one format, one source).
String slotReadoutLine(KokoroVoice voice, String lang) {
  final sid = voice.sidFor(lang);
  final voiceDesc = '${voice.nameFor(lang)}($sid)';
  final eq = voice.equalizerFor(lang);
  final eqDesc = (eq == null || eq.isEmpty)
      ? 'flat'
      : 'bands{${eq.entries.map((e) => '${e.key}:${e.value.toStringAsFixed(1)}dB').join(',')}}';
  return 'slot=${slotNameFor(voice)} lang=$lang voice=$voiceDesc '
      'speed=${voice.speed.toStringAsFixed(2)} eq=$eqDesc '
      'lexicon=${voice.lexiconFor(lang).length}';
}

/// Word characters the highlight mapping treats as part of a word (same
/// class the AudioController expands recited offsets with).
const String _wordCharClass = '0-9A-Za-z\\u00C0-\\u024F';

/// Applies [lexicon] to [text]: every whole-word, case-insensitive match of
/// a lexicon key is replaced by its respelling (as specified — the
/// respelling is written verbatim). Returns the spoken text plus an
/// alignment: `align[i]` is the index in the ORIGINAL text that spoken
/// position [i] corresponds to, with `align[spoken.length]` mapping the
/// final boundary — highlight ranges computed on the spoken text are mapped
/// back to the displayed text through it. Applying an already-applied
/// lexicon is a no-op (respellings never match their source words).
(String, List<int>) applyPronunciationLexicon(
    String text, Map<String, String> lexicon) {
  if (lexicon.isEmpty) {
    return (text, List<int>.generate(text.length + 1, (i) => i));
  }
  final pattern = RegExp(
    '(?<![$_wordCharClass])(?:'
    '${lexicon.keys.map(RegExp.escape).join('|')}'
    ')(?![$_wordCharClass])',
    caseSensitive: false,
  );
  final spoken = StringBuffer();
  final align = <int>[];
  var src = 0;
  for (final m in pattern.allMatches(text)) {
    final resp = lexicon[m[0]!.toLowerCase()] ?? m[0]!;
    // 1:1 region before the match.
    for (var i = src; i < m.start; i++) {
      align.add(i);
      spoken.writeCharCode(text.codeUnitAt(i));
    }
    // The respelling occupies resp.length spoken positions, all anchored at
    // the match start in the original text.
    for (var i = 0; i < resp.length; i++) {
      align.add(m.start);
      spoken.write(resp[i]);
    }
    src = m.end;
  }
  for (var i = src; i <= text.length; i++) {
    align.add(i);
    if (i < text.length) spoken.writeCharCode(text.codeUnitAt(i));
  }
  return (spoken.toString(), align);
}

/// Splits text into speakable sentences: sentence-ending punctuation and
/// paragraph/line breaks are boundaries; very short fragments (V., R., St.)
/// merge into what follows so markers are not spoken alone; overly long
/// sentences are split at clause punctuation to bound per-sentence latency.
///
/// Public so screens can map sentence positions back to displayed text
/// (verse highlighting) with the exact same split the engine speaks.
List<String> splitSpeakableSentences(String text) {
  final raw = text
      .split(RegExp(r'(?<=[.!?…])\s+|\n+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  // Merge tiny fragments (liturgical markers, abbreviations) forward.
  final merged = <String>[];
  for (final part in raw) {
    if (merged.isNotEmpty && merged.last.length <= 3) {
      merged[merged.length - 1] = '${merged.last} $part';
    } else {
      merged.add(part);
    }
  }
  // Bound per-sentence synthesis latency on slow devices.
  const maxLen = 280;
  final bounded = <String>[];
  for (final sentence in merged) {
    var rest = sentence;
    while (rest.length > maxLen) {
      var cut = -1;
      for (final pat in const [', ', '; ', ',']) {
        final idx = rest.lastIndexOf(pat, maxLen);
        if (idx > 40) {
          cut = idx + pat.length;
          break;
        }
      }
      if (cut <= 0) {
        cut = rest.lastIndexOf(' ', maxLen);
        if (cut <= 0) cut = maxLen;
      }
      bounded.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trim();
    }
    if (rest.isNotEmpty) bounded.add(rest);
  }
  return bounded;
}

/// Character range of each speakable sentence within [text], in the same
/// order as [splitSpeakableSentences]. Public so screens can map
/// engine-reported ranges back to their displayed units with the exact same
/// split the engine speaks.
List<(int, int)> speakableSentenceRanges(String text) {
  final ranges = <(int, int)>[];
  var cursor = 0;
  for (final sentence in splitSpeakableSentences(text)) {
    var at = text.indexOf(sentence, cursor);
    if (at < 0) at = cursor;
    ranges.add((at, at + sentence.length));
    cursor = at + sentence.length;
  }
  return ranges;
}

/// One word's expected audio-time window in the app's word schedule: the
/// highlight enters the word at [start] and leaves it at [end].
class WordTiming {
  final int charStart;
  final int charEnd;
  final Duration start;
  final Duration end;

  const WordTiming(this.charStart, this.charEnd, this.start, this.end);
}

/// The app's word-level schedule for [text]: for every word (in reading
/// order), the audio-time window the highlight maps it to, derived from the
/// per-sentence REAL durations (the synthesis pass's own WAV lengths) and
/// the same within-sentence proportional mapping the AudioController applies
/// live — never a separate estimate. [sentenceDurations] must come from the
/// same synthesis that produces the audio, in [speakableSentenceRanges]
/// order. Returns [] when the counts mismatch (the caller's split and
/// durations disagree).
List<WordTiming> computeWordSchedule(
    String text, List<Duration> sentenceDurations) {
  final ranges = speakableSentenceRanges(text);
  if (ranges.length != sentenceDurations.length) return const [];
  final wordChar = RegExp('[$_wordCharClass]');
  final out = <WordTiming>[];
  var sentenceStartMs = 0;
  for (var i = 0; i < ranges.length; i++) {
    final (s, e) = ranges[i];
    final sentenceMs = sentenceDurations[i].inMilliseconds;
    if (e > s && sentenceMs > 0) {
      // Contiguous word runs within the sentence's char range; each maps to
      // its proportional audio window inside the sentence's real duration —
      // the exact inverse of the controller's position → offset mapping.
      var runStart = -1;
      for (var p = s; p <= e; p++) {
        final isWord = p < e && wordChar.hasMatch(text[p]);
        if (isWord && runStart < 0) {
          runStart = p;
        } else if (!isWord && runStart >= 0) {
          final fs = (runStart - s) / (e - s);
          final fe = (p - s) / (e - s);
          out.add(WordTiming(
            runStart,
            p,
            Duration(
                milliseconds: sentenceStartMs + (fs * sentenceMs).round()),
            Duration(
                milliseconds: sentenceStartMs + (fe * sentenceMs).round()),
          ));
          runStart = -1;
        }
      }
    }
    sentenceStartMs += sentenceMs;
  }
  return out;
}