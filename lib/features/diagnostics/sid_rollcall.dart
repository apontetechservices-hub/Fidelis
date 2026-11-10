import '../../services/kokoro_engine.dart';

/// The sid roll-call data: every speaker in the bundled Kokoro model, the
/// known voice names (the sherpa-onnx kokoro v1.0 speaker table — the same
/// source the relabeled audition used), the roll-call line each speaker
/// speaks, and the solo neutral profile the roll-call synthesizes through.
///
/// The speaker COUNT comes from the model metadata programmatically
/// ([KokoroEngine.kokoroSidCount] on the bundled voices.bin — 54 for the
/// shipped model); the names below label each sid for the ear test.

/// Known Kokoro v1.0 speaker names by sid (the sherpa-onnx kokoro
/// multi-lang-v1_0 speaker table — the same source the relabeled audition
/// used). Every sid of the shipped 54-speaker model is named.
const Map<int, String> kokoroSidNames = {
  0: 'af_alloy',
  1: 'af_aoede',
  2: 'af_bella',
  3: 'af_heart',
  4: 'af_jessica',
  5: 'af_kore',
  6: 'af_nicole',
  7: 'af_nova',
  8: 'af_river',
  9: 'af_sarah',
  10: 'af_sky',
  11: 'am_adam',
  12: 'am_echo',
  13: 'am_eric',
  14: 'am_fenrir',
  15: 'am_liam',
  16: 'am_michael',
  17: 'am_onyx',
  18: 'am_puck',
  19: 'am_santa',
  20: 'bf_alice',
  21: 'bf_emma',
  22: 'bf_isabella',
  23: 'bf_lily',
  24: 'bm_daniel',
  25: 'bm_fable',
  26: 'bm_george',
  27: 'bm_lewis',
  28: 'ef_dora',
  29: 'em_alex',
  30: 'ff_siwis',
  31: 'hf_alpha',
  32: 'hf_beta',
  33: 'hm_omega',
  34: 'hm_psi',
  35: 'if_sara',
  36: 'im_nicola',
  37: 'jf_alpha',
  38: 'jf_gongitsune',
  39: 'jf_nezumi',
  40: 'jf_tebukuro',
  41: 'jm_kumo',
  42: 'pf_dora',
  43: 'pm_alex',
  44: 'pm_santa',
  45: 'zf_xiaobei',
  46: 'zf_xiaoni',
  47: 'zf_xiaoxiao',
  48: 'zf_xiaoyi',
  49: 'zm_yunjian',
  50: 'zm_yunxi',
  51: 'zm_yunxia',
  52: 'zm_yunyang',
  53: 'em_santa',
};

/// The voice-grid sids the owner directed, labeled so the roll-call rows
/// show where each directed voice sits in the shipped bundle.
const Map<int, String> directedSidLabels = {
  16: 'Bible EN primary',
  12: 'Bible EN blend',
  29: 'Bible ES',
  1: 'Rosary EN + Rosary ES primary',
  28: 'Rosary ES blend',
  26: 'Readings EN (standard)',
};

/// The roll-call line for [sid]: the voice states its own number, then the
/// fixed common sentence (the SAME sentence for every sid) the owner
/// identifies by ear.
String rollCallLine(int sid) =>
    'I am speaker number $sid. The Lord is my shepherd; I shall not want.';

/// The roll-call synthesis profile for [sid]: SOLO (no blend partner), no
/// equalizer shaping, neutral speed — the plainest possible render of that
/// sid through the production synthesis path. The voice name labels the
/// pronunciation-lexicon key (a known name's per-voice lexicon applies —
/// harmless for the roll-call text, which contains none of the respelled
/// words).
KokoroVoice rollCallVoice(int sid) => KokoroVoice(
      enSid: sid,
      esSid: sid,
      speed: 1.0,
      enName: kokoroSidNames[sid] ?? 'sid_$sid',
      esName: kokoroSidNames[sid] ?? 'sid_$sid',
    );
