import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/app_strings.dart';
import 'lot_service.dart';
import 'lot_hour_screen.dart';

class LotScreen extends StatefulWidget {
  const LotScreen({super.key});
  @override
  State<LotScreen> createState() => _LotScreenState();
}

class _LotScreenState extends State<LotScreen> {
  bool _loading = true;
  LotHour? _lauds;
  LotHour? _vespers;
  LotHour? _compline;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final lauds = await LotService.getHour('lauds');
    final vespers = await LotService.getHour('vespers');
    final compline = await LotService.getHour('compline');
    if (mounted) {
      setState(() {
        _lauds = lauds;
        _vespers = vespers;
        _compline = compline;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('lot_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _hourCard(context, theme, isDark, 'lauds', _lauds),
                  const SizedBox(height: 16),
                  _hourCard(context, theme, isDark, 'vespers', _vespers),
                  const SizedBox(height: 16),
                  _hourCard(context, theme, isDark, 'compline', _compline),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      AppStrings.t('lot_attribution'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _hourCard(BuildContext context, ThemeData theme, bool isDark, String key, LotHour? hour) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hour == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LotHourScreen(hour: hour)),
                ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                key == 'lauds'
                    ? Icons.wb_sunny
                    : key == 'vespers'
                        ? Icons.nightlight
                        : Icons.bedtime,
                size: 24,
                color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hour?.title ??
                      (key == 'lauds'
                          ? AppStrings.t('lot_lauds')
                          : key == 'vespers'
                              ? AppStrings.t('lot_vespers')
                              : AppStrings.t('lot_compline')),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (hour == null)
                Text(
                  AppStrings.t('unable_today'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}