import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/app_strings.dart';
import '../../services/billing_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});
  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    BillingService.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('premium_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.church,
                size: 48,
                color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppStrings.t('premium_headline'),
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            _featureRow(context, theme, Icons.auto_stories, AppStrings.t('premium_feat_loth')),
            _featureRow(context, theme, Icons.menu_book, AppStrings.t('premium_feat_bible')),
            _featureRow(context, theme, Icons.school, AppStrings.t('premium_feat_catechism')),
            _featureRow(context, theme, Icons.history_edu, AppStrings.t('premium_feat_fathers')),
            _featureRow(context, theme, Icons.local_fire_department, AppStrings.t('premium_feat_streaks')),
            _featureRow(context, theme, Icons.healing, AppStrings.t('premium_feat_confession')),
            _featureRow(context, theme, Icons.directions_walk, AppStrings.t('premium_feat_stations')),
            _featureRow(context, theme, Icons.all_inclusive, AppStrings.t('premium_feat_future')),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  FilledButton(
                    onPressed: _buying
                        ? null
                        : () async {
                            setState(() => _buying = true);
                            final ok = await BillingService.buyPremium();
                            if (mounted) setState(() => _buying = false);
                          },
                    child: Text(AppStrings.t('premium_buy').replaceAll('{{price}}', '\$9.99')),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => BillingService.restore(),
                    child: Text(AppStrings.t('premium_restore')),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.t('premium_onetime_note'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(BuildContext context, ThemeData theme, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDarkColor(context)),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      );

  Color isDarkColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? FidelisTheme.gold : FidelisTheme.deepRed;
}