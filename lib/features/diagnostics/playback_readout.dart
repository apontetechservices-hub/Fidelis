import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../services/audio_controller.dart';
import '../../services/audio_diagnostics.dart';

/// Whether the playback readout ALSO shows on the prayer screens (the
/// Bible chapter and the rosary prayer screens). Default OFF — the readout
/// lives behind Settings → About → Audio diagnostics; the toggle is the
/// owner's opt-in for on-screen debugging during playback.
class PlaybackReadoutVisibility {
  PlaybackReadoutVisibility._();

  static const _prefKey = 'playback_readout_on_prayer_screens';

  /// The toggle state (default OFF).
  static final ValueNotifier<bool> onPrayerScreens = ValueNotifier<bool>(false);

  /// Loads the stored toggle (call once at startup; default OFF).
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      onPrayerScreens.value = prefs.getBool(_prefKey) ?? false;
    } catch (_) {}
  }

  /// Sets the toggle and persists it.
  static Future<void> set(bool value) async {
    onPrayerScreens.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }
}

/// THE SILENT-FALLBACK KILLER (round 5, defect 1c): the prayer screens'
/// fallback banner — shown whenever the loaded playback was served (whole
/// or in part) by the system voice, INDEPENDENT of the diagnostics readout
/// toggle. A substituted voice playing with no sign is worse than a
/// visible failure: the user must SEE the engine state. Hidden while the
/// audio is stopped (the playback ended — the diagnostics screen keeps
/// the history) and never shown for Latin (flutter_tts is Latin's
/// DESIGNED engine — no FALLBACK line fires for it).
class PlaybackFallbackBanner extends StatelessWidget {
  const PlaybackFallbackBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AudioDiagnostics.instance,
      builder: (context, _) => ValueListenableBuilder<AudioPlaybackInfo>(
        valueListenable: AudioController.instance.listenable,
        builder: (context, info, _) {
          final line = AudioDiagnostics.instance.fallbackLine;
          if (line == null || info.state == AudioState.stopped) {
            return const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFB3261E).withValues(alpha: 0.12),
              border: Border.all(color: const Color(0xFFB3261E), width: 1.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Playing with the device voice — the offline voice engine '
              'is unavailable.\n$line',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB3261E),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The diagnostic build's on-screen playback readout: what the pipeline
/// REQUESTED (the slot config — sids, speed, phonemizer
/// language, EQ), what actually SERVED the audio (Kokoro or the
/// flutter_tts fallback — with the failure text), and the live numeric
/// duration/position. Embedded on the Bible and Rosary screens, visible
/// during playback; the full history lives on the diagnostics screen.
///
/// The progress row is the root-cause instrument for the frozen progress
/// bar: when the numbers update here but the media notification's bar does
/// not move, the fault is downstream (the notification); when the numbers
/// are absent, the source publishes nothing (the flutter_tts fallback path
/// exposes no timing at all).
class PlaybackReadout extends StatelessWidget {
  const PlaybackReadout({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;
    return AnimatedBuilder(
      animation: AudioDiagnostics.instance,
      builder: (context, _) {
        final d = AudioDiagnostics.instance;
        return Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF101B26) : const Color(0xFFF6F1E7),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (d.fallbackLine != null) _banner(context, d.fallbackLine!),
              _row(context, 'slot', d.slotReadout ?? '—', label),
              _row(context, 'engine', d.engineUsed ?? '—', label),
              if (d.kokoroError != null)
                _row(context, 'kokoro error', d.kokoroError!, label),
              _progressRow(context, label),
              _stateRow(context, label),
            ],
          ),
        );
      },
    );
  }

  /// The prominent fallback banner: the system voice served this playback —
  /// never silent, with the Kokoro failure text inline.
  Widget _banner(BuildContext context, String fallbackLine) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB3261E).withValues(alpha: 0.14),
        border: Border.all(color: const Color(0xFFB3261E), width: 1.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'FALLBACK: flutter_tts (system voice)\n$fallbackLine',
        style: theme.textTheme.bodySmall?.copyWith(
          color: const Color(0xFFB3261E),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color accent) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// The live numeric duration/position — the progress-bar root-cause
  /// instrument, now AGGREGATED across the whole chapter/page (sequence
  /// jobs). Null progress is itself the finding, and the label says WHICH
  /// finding: 'no timing — idle' when nothing is loaded, 'no timing —
  /// fallback path' when the flutter_tts fallback (which exposes no
  /// timing) served the audio.
  Widget _progressRow(BuildContext context, Color accent) {
    return ValueListenableBuilder<AudioProgress?>(
      valueListenable: AudioController.instance.progressListenable,
      builder: (context, progress, _) {
        final String value;
        if (progress == null) {
          final info = AudioController.instance.listenable.value;
          final fallback =
              AudioDiagnostics.instance.engineUsed == 'flutter_tts';
          value = (info.state == AudioState.stopped || !fallback)
              ? 'no timing — idle'
              : 'no timing — fallback path (flutter_tts exposes none)';
        } else {
          final duration = progress.duration;
          value = 'duration ${_seconds(duration)} · '
              'position ${_seconds(progress.position)}'
              '${duration == null ? ' · duration UNKNOWN' : ''}';
        }
        return _row(context, 'progress', value, accent);
      },
    );
  }

  Widget _stateRow(BuildContext context, Color accent) {
    return ValueListenableBuilder<AudioPlaybackInfo>(
      valueListenable: AudioController.instance.listenable,
      builder: (context, info, _) {
        return _row(
          context,
          'state',
          '${info.state.name} job=${info.jobId ?? '-'} '
              'chunk=${info.chunkIndex} sentence=${info.sentenceIndex}',
          accent,
        );
      },
    );
  }

  String _seconds(Duration? d) =>
      d == null ? '—' : '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
}
