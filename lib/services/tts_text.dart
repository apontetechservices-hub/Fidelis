/// Pure Dart text/voice pipeline shared by the TTS service and the
/// word-timing verification tool (tool/word_timing_verify.dart runs on the
/// host Dart VM, which cannot import the Flutter-plugin service files) —
/// everything here must stay free of Flutter imports.
///
/// Holds the per-voice Kokoro synthesis profiles (sid + speed per language),
/// the per-voice pronunciation-override lexicon, the sentence splitter the
/// engine speaks with, and the word-schedule computation the highlight
/// timing derives from.
library;

/// Per-voice Kokoro synthesis profile: the voice sid per language in
/// voices.bin, the speaking speed, and the voice names the pronunciation
/// lexicon is keyed by.
class KokoroVoice {
  final int enSid;
  final int esSid;
  final double speed;

  /// Kokoro voice names (lexicon keys), e.g. 'bm_daniel'.
  final String enName;
  final String esName;

  const KokoroVoice({
    required this.enSid,
    required this.esSid,
    required this.speed,
    required this.enName,
    required this.esName,
  });

  /// Sid for [lang] ('en' | 'es').
  int sidFor(String lang) => lang == 'es' ? esSid : enSid;

  /// Voice name for [lang] — the pronunciation-lexicon key.
  String nameFor(String lang) => lang == 'es' ? esName : enName;

  /// The voice's pronunciation-override lexicon for [lang] (possibly empty).
  Map<String, String> lexiconFor(String lang) =>
      kokoroVoiceLexicon[nameFor(lang)] ?? const {};

  /// Readings + rosary-timing voices — the long-standing configuration
  /// (EN bm_george sid 26, ES em_alex sid 29, speed 0.9). Every synthesis
  /// path that does not ask for a specific profile keeps these.
  static const KokoroVoice standard = KokoroVoice(
    enSid: 26,
    esSid: 29,
    speed: 0.9,
    enName: 'bm_george',
    esName: 'em_alex',
  );

  /// Bible voices — the owner's final round-2 decision: EN bm_daniel
  /// (sid 24), ES em_alex (sid 29, voice unchanged), both at speed 0.81.
  static const KokoroVoice bible = KokoroVoice(
    enSid: 24,
    esSid: 29,
    speed: 0.81,
    enName: 'bm_daniel',
    esName: 'em_alex',
  );
}

/// Per-voice pronunciation-override lexicon — the Bible's standing list,
/// grown from the round-2 voice auditions. Key: Kokoro voice name; value:
/// {source word (lowercase): respelling spoken instead}. Entries match
/// case-insensitively as whole words and are applied to the text before
/// sentence splitting. Respellings are tuned PER VOICE — a respelling
/// verified for one voice must never be copied to another (the audition
/// voices differ in which words they already say correctly; e.g. Daniel's
/// round-2 "Lord", "pasture", "psalm", and "led" all verified correctly
/// WITHOUT correction, so the other voices' respellings of those words are
/// deliberately absent here).
const Map<String, Map<String, String>> kokoroVoiceLexicon = {
  'bm_daniel': {'ruleth': 'Rouleth'},
  'em_alex': {},
};

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