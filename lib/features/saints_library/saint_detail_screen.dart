import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../../services/billing_service.dart';
import '../../services/saints_library_service.dart';
import '../premium/paywall_screen.dart';

/// Arguments for the named '/saints/library/detail' route.
class SaintDetailArgs {
  final SaintLibraryEntry entry;
  const SaintDetailArgs({required this.entry});
}

/// One saint's life: the name in the app's reverent Cinzel style, the
/// full life text, and the public-domain source citation at the bottom.
class SaintDetailScreen extends StatelessWidget {
  final SaintLibraryEntry entry;

  const SaintDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    // Route-level premium guard: direct navigation to this screen
    // (named route, deep link, any push) still requires Premium.
    return ValueListenableBuilder<bool>(
      valueListenable: BillingService.premium,
      builder: (context, isPremium, _) {
        if (!isPremium) return const PaywallScreen();
        return _buildDetail(context);
      },
    );
  }

  Widget _buildDetail(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;
    final feastLabel = AppStrings.isSpanish
        ? '${entry.day} de ${AppStrings.monthName(entry.month)}'
        : '${AppStrings.monthName(entry.month)} ${entry.day}';

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('saints_library'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Text(
            entry.name,
            style: theme.textTheme.headlineMedium?.copyWith(color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            feastLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            entry.life,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.t('source_label')}: ${entry.source}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
