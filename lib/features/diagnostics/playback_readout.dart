import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/audio_controller.dart';
import '../../services/audio_diagnostics.dart';

/// The diagnostic build's on-screen playback readout: what the pipeline
/// REQUESTED (the slot config — sids, blend weights, speed, phonemizer
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
  /// instrument. Null progress is itself the finding: the flutter_tts
  /// fallback path exposes no timing, so nothing can move any bar.
  Widget _progressRow(BuildContext context, Color accent) {
    return ValueListenableBuilder<AudioProgress?>(
      valueListenable: AudioController.instance.progressListenable,
      builder: (context, progress, _) {
        final String value;
        if (progress == null) {
          value = 'no timing (idle, or the flutter_tts path exposes none)';
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
