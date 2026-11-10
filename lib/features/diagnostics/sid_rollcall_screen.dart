import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/audio_controller.dart';
import '../../services/kokoro_engine.dart';
import 'sid_rollcall.dart';

/// The sid roll-call screen: EVERY speaker in the bundled Kokoro model,
/// read from the model metadata programmatically (the voices.bin speaker
/// count — the same source the relabeled audition used). Tapping a speaker
/// plays the production-path synthesis of the roll-call line: the voice
/// states its own number, then the fixed common sentence. The owner
/// identifies by ear which sid actually sounds like Michael, Alex, or
/// Aoede in the shipped bundle.
class SidRollCallScreen extends StatefulWidget {
  const SidRollCallScreen({super.key});

  @override
  State<SidRollCallScreen> createState() => _SidRollCallScreenState();
}

class _SidRollCallScreenState extends State<SidRollCallScreen> {
  static const _jobId = 'diagnostics-rollcall';

  int? _sidCount;
  String? _loadError;
  int? _playingSid;

  @override
  void initState() {
    super.initState();
    _load();
    AudioController.instance.listenable.addListener(_onAudioChanged);
  }

  @override
  void dispose() {
    AudioController.instance.listenable.removeListener(_onAudioChanged);
    // Single-stream discipline: leaving the screen ends its playback
    // (deferred out of the unmount phase — see the Bible screen's note).
    scheduleMicrotask(() => AudioController.instance.stopIfOwner(this));
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final status = await KokoroEngine.diagnosticStatus();
      if (mounted) {
        setState(() => _sidCount = status.sidCount);
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
  }

  /// Clears the playing-row highlight when this screen's audio stops or is
  /// replaced by another screen's stream.
  void _onAudioChanged() {
    final info = AudioController.instance.listenable.value;
    final mine = info.jobId == _jobId && info.state != AudioState.stopped;
    if (!mine && _playingSid != null) {
      setState(() => _playingSid = null);
    }
  }

  /// Plays the roll-call line for [sid] through the production path: the
  /// AudioController's text chunk with the sid's solo neutral profile —
  /// the same pipeline (controller → TtsService → KokoroEngine) a Bible or
  /// rosary playback runs, so the readout lines and any fallback surface
  /// identically.
  Future<void> _play(int sid) async {
    setState(() => _playingSid = sid);
    await AudioController.instance.start(
      AudioJob(
        id: _jobId,
        chunks: [
          AudioChunk(
            text: rollCallLine(sid),
            lang: 'en',
            voice: rollCallVoice(sid),
          ),
        ],
        title: 'Speaker $sid',
      ),
      owner: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        theme.brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed;
    final count = _sidCount;
    return Scaffold(
      appBar: AppBar(title: const Text('Speaker roll-call')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              count == null
                  ? (_loadError ?? 'Reading the model metadata…')
                  : '$count speakers in the bundled model (voices.bin)',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: accent, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Tap a speaker: it states its own number, then the fixed '
              'sentence ("The Lord is my shepherd; I shall not want."). '
              'Identify by ear which sid is Michael, Alex, or Aoede.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: count == null
                ? Center(
                    child: _loadError == null
                        ? const CircularProgressIndicator()
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_loadError!),
                          ),
                  )
                : ListView.builder(
                    itemCount: count,
                    itemBuilder: (context, index) => _row(context, index, accent),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int index, Color accent) {
    final sid = index;
    final name = kokoroSidNames[sid] ?? 'sid_$sid';
    final directed = directedSidLabels[sid];
    final playing = _playingSid == sid;
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      tileColor: playing ? accent.withValues(alpha: 0.12) : null,
      leading: SizedBox(
        width: 44,
        child: Text(
          '$sid',
          style: theme.textTheme.titleMedium?.copyWith(
            color: playing ? accent : null,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: playing ? accent : null,
          fontWeight: playing ? FontWeight.w700 : null,
        ),
      ),
      subtitle: directed == null
          ? null
          : Text(
              directed,
              style: theme.textTheme.bodySmall?.copyWith(color: accent),
            ),
      trailing: IconButton(
        icon: Icon(playing ? Icons.volume_up : Icons.play_circle_fill),
        color: accent,
        onPressed: () => _play(sid),
      ),
    );
  }
}
