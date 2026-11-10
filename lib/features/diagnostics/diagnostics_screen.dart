import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../../services/audio_controller.dart';
import '../../services/audio_diagnostics.dart';
import '../../services/kokoro_engine.dart';
import 'playback_readout.dart';
import 'sid_rollcall_screen.dart';

/// The diagnostic build's audio-diagnostics screen: the Kokoro engine's
/// on-device state (assets, model metadata, failures), a probe synthesis
/// through the production path, the bundled reference renders with play
/// buttons, the sid roll-call entry, and the recent pipeline lines and
/// state transitions. Evidence, not fixes — the owner reads the truth
/// about what the phone's audio pipeline actually does.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  static const _jobId = 'diagnostics';

  /// The bundled reference renders (assets/diagnostics_renders/): the six
  /// fixed passages rendered through the app's OWN production synthesis
  /// function — the exact code path a playback calls — so the owner can
  /// compare them against what the phone plays live.
  static const _renders = <(String, String)>[
    (
      'assets/diagnostics_renders/psalm23_en.wav',
      'Psalm 23:1-3 EN — Bible slot (Michael+Echo blend, 0.81)',
    ),
    (
      'assets/diagnostics_renders/psalm23_es.wav',
      'Psalm 23:1-3 ES — Bible slot (Alex solo, 0.81)',
    ),
    (
      'assets/diagnostics_renders/our_father_en.wav',
      'Our Father EN — Rosary slot (Aoede, 0.9)',
    ),
    (
      'assets/diagnostics_renders/our_father_es.wav',
      'Our Father ES — Rosary slot (Aoede+Dora blend, 0.9)',
    ),
    (
      'assets/diagnostics_renders/hail_mary_en.wav',
      'Hail Mary EN — Rosary slot (Aoede, bless-ed, 0.9)',
    ),
    (
      'assets/diagnostics_renders/hail_mary_es.wav',
      'Hail Mary ES — Rosary slot (Aoede+Dora blend, 0.9)',
    ),
  ];

  Future<KokoroEngineStatus>? _status;
  String? _probeResult;
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    _status = KokoroEngine.diagnosticStatus();
  }

  @override
  void dispose() {
    // Single-stream discipline: leaving the screen ends its render playback
    // (deferred out of the unmount phase — see the Bible screen's note).
    scheduleMicrotask(() => AudioController.instance.stopIfOwner(this));
    super.dispose();
  }

  /// Probe synthesis through the production path: the exact function a
  /// playback calls ([KokoroEngine.synthesize]). The outcome — sample count
  /// or the failure text — appears ON SCREEN.
  Future<void> _probe() async {
    setState(() {
      _probing = true;
      _probeResult = 'probing…';
    });
    final audio = await KokoroEngine.synthesize(
      'The Lord is my shepherd; I shall not want.',
      'en',
    );
    if (!mounted) return;
    setState(() {
      _probing = false;
      _probeResult = audio == null
          ? 'FAILED — ${KokoroEngine.lastError ?? 'no error recorded'}'
          : 'OK — ${audio.samples.length} samples at ${audio.sampleRate} Hz '
              '(blended=${audio.blended})';
    });
  }

  /// Plays a bundled reference render through the central controller (the
  /// production asset-file path — the same playAssetFile route the rosary's
  /// pre-rendered files used).
  Future<void> _playRender(String asset, String label) async {
    await AudioController.instance.start(
      AudioJob(
        id: _jobId,
        chunks: [AudioChunk(asset: asset)],
        title: label,
      ),
      owner: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        theme.brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('audio_diagnostics'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // The live playback readout (moved OFF the prayer screens): the
          // slot config, the engine that served the audio, any fallback,
          // and the aggregated whole-page duration/position.
          const PlaybackReadout(),
          const SizedBox(height: 16),
          _engineStatusCard(context, theme, accent),
          const SizedBox(height: 16),
          _rendersCard(context, theme, accent),
          const SizedBox(height: 16),
          _rollCallCard(context, theme, accent),
          const SizedBox(height: 16),
          _logCard(
            context,
            theme,
            accent,
            AppStrings.t('diagnostics_pipeline_log'),
            AudioDiagnostics.instance.lines,
          ),
          const SizedBox(height: 16),
          _logCard(
            context,
            theme,
            accent,
            AppStrings.t('diagnostics_state_log'),
            AudioDiagnostics.instance.stateLog,
          ),
        ],
      ),
    );
  }

  Widget _engineStatusCard(
      BuildContext context, ThemeData theme, Color accent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('diagnostics_engine_status'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<KokoroEngineStatus>(
              future: _status,
              builder: (context, snap) {
                final s = snap.data;
                if (s == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(context, 'assets prepared', '${s.assetsPrepared}'),
                    if (s.modelDir != null)
                      _kv(context, 'model dir', s.modelDir!),
                    _kv(context, 'bundled speakers (voices.bin)',
                        '${s.sidCount}'),
                    _kv(context, 'failed this session',
                        '${s.failedThisSession}'),
                    if (s.lastError != null)
                      _kv(context, 'last error', s.lastError!),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _probing ? null : _probe,
                  icon: const Icon(Icons.graphic_eq, size: 18),
                  label: Text(AppStrings.t('diagnostics_probe')),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      setState(() => _status = KokoroEngine.diagnosticStatus()),
                  child: const Text('refresh'),
                ),
              ],
            ),
            if (_probeResult != null) ...[
              const SizedBox(height: 6),
              Text(
                _probeResult!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _probeResult!.startsWith('OK')
                      ? Colors.green.shade700
                      : const Color(0xFFB3261E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rendersCard(BuildContext context, ThemeData theme, Color accent) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t('diagnostics_renders'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Rendered through the app\'s own production synthesis — '
              'compare against the live playback.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            for (final (asset, label) in _renders)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(label, style: theme.textTheme.bodyMedium),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  color: accent,
                  onPressed: () => _playRender(asset, label),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rollCallCard(BuildContext context, ThemeData theme, Color accent) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.record_voice_over, color: accent),
        title: Text(
          AppStrings.t('diagnostics_rollcall'),
          style: theme.textTheme.titleMedium
              ?.copyWith(color: accent, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(AppStrings.t('diagnostics_rollcall_note')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SidRollCallScreen()),
        ),
      ),
    );
  }

  Widget _logCard(BuildContext context, ThemeData theme, Color accent,
      String title, List<String> entries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (entries.isEmpty)
              Text(
                '—',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              )
            else
              for (final line in entries.reversed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
