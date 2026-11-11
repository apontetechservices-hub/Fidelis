import 'package:flutter/foundation.dart';

/// The diagnostic build's central audio-diagnostics state: the single place
/// the on-screen readout reads from. Captures the TTS pipeline's structured
/// events — the playback-start slot config, the engine that actually served
/// the audio, every fallback (with the Kokoro failure text), and the audio
/// controller's state transitions — so the truth about what is playing is
/// visible IN THE APP UI, not just in logs.
///
/// Production wiring (main.dart): TtsService.readoutSink lands here,
/// KokoroEngine.failureSink lands here, and the AudioController's listenable
/// feeds [recordState]. Tests drive the record methods directly.
class AudioDiagnostics extends ChangeNotifier {
  AudioDiagnostics._();
  static final AudioDiagnostics instance = AudioDiagnostics._();

  /// Bounded recent-line log (the diagnostics screen shows the history).
  static const _maxLines = 60;

  /// The recent TTS pipeline readout lines, oldest first.
  final List<String> lines = [];

  /// The playback-start slot readout of the current/last playback — the
  /// REQUESTED config (slot, sids, speed, phonemizer language, EQ).
  String? slotReadout;

  /// The engine that served the current/last playback:
  /// 'kokoro' | 'flutter_tts' | null (nothing played yet).
  String? engineUsed;

  /// The fallback line when one fired for the current/last playback — the
  /// on-screen banner's source. Null while Kokoro served the whole audio.
  /// A new playback start clears it; a mid-pipeline fallback keeps it for
  /// the rest of that playback (the system voice IS audible in it).
  String? fallbackLine;

  /// The Kokoro failure text (why the engine is unavailable), sticky for
  /// the session: the banner and the readout show the ROOT CAUSE.
  String? kokoroError;

  /// The audio controller's state transitions (playing/paused/stopped with
  /// chunk + sentence), oldest first — the Pause→Play evidence.
  final List<String> stateLog = [];

  /// Records one TTS pipeline readout line (TtsService.readoutSink lands
  /// here in the diagnostic build). The '[Fidelis audio] ' transport prefix
  /// is stripped — the stored lines are the display content. Parses the
  /// structured kinds into the fields above:
  ///  - 'playback slot=...' — a new playback start: the requested config;
  ///    clears the previous playback's fallback banner.
  ///  - 'engine=kokoro' — the Kokoro pipeline delivered (only when no
  ///    fallback fired during this playback — a mid-pipeline fallback line
  ///    precedes it and stays).
  ///  - 'FALLBACK ...' — the system voice served (whole or remainder).
  void recordLine(String rawLine) {
    final line = rawLine.replaceFirst('[Fidelis audio] ', '');
    _push(lines, line);
    if (line.contains('playback slot=')) {
      slotReadout = line;
      fallbackLine = null;
      engineUsed = null;
    } else if (line.contains('FALLBACK')) {
      fallbackLine = line;
      engineUsed = 'flutter_tts';
    } else if (line.contains('engine=kokoro')) {
      if (fallbackLine == null) engineUsed = 'kokoro';
    }
    notifyListeners();
  }

  /// Records a Kokoro engine failure (KokoroEngine.failureSink lands here).
  void recordKokoroError(String error) {
    kokoroError = error;
    notifyListeners();
  }

  /// Records one audio-controller state transition. Consecutive duplicates
  /// collapse (the notifier fires often while playing).
  void recordState(String entry) {
    if (stateLog.isNotEmpty && stateLog.last == entry) return;
    _push(stateLog, entry);
    notifyListeners();
  }

  /// Clears every per-playback field (the diagnostics screen's reset).
  void clear() {
    lines.clear();
    stateLog.clear();
    slotReadout = null;
    engineUsed = null;
    fallbackLine = null;
    kokoroError = null;
    notifyListeners();
  }

  void _push(List<String> list, String line) {
    list.add(line);
    while (list.length > _maxLines) {
      list.removeAt(0);
    }
  }
}
