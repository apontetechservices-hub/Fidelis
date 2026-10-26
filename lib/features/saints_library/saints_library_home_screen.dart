import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../../services/billing_service.dart';
import '../../services/saints_library_service.dart';
import '../premium/paywall_screen.dart';
import 'saint_detail_screen.dart';

/// Premium Lives of the Saints library: the fixed feasts of the 1962
/// calendar, grouped by month, with a name search and a pinned
/// "Today's saint" card.
class SaintsLibraryHomeScreen extends StatefulWidget {
  const SaintsLibraryHomeScreen({super.key});

  @override
  State<SaintsLibraryHomeScreen> createState() =>
      _SaintsLibraryHomeScreenState();
}

class _SaintsLibraryHomeScreenState extends State<SaintsLibraryHomeScreen> {
  bool _loading = true;
  List<SaintLibraryEntry>? _entries;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await SaintsLibraryService.all();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  void _openDetail(SaintLibraryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaintDetailScreen(entry: entry),
      ),
    );
  }

  /// Localized feast-day label, e.g. "March 7" / "7 de marzo".
  String _feastLabel(int month, int day) => AppStrings.isSpanish
      ? '$day de ${AppStrings.monthName(month)}'
      : '${AppStrings.monthName(month)} $day';

  @override
  Widget build(BuildContext context) {
    // Route-level premium guard: direct navigation to this screen
    // (named route, deep link, any push) still requires Premium.
    return ValueListenableBuilder<bool>(
      valueListenable: BillingService.premium,
      builder: (context, isPremium, _) {
        if (!isPremium) return const PaywallScreen();
        return _buildLibrary(context);
      },
    );
  }

  Widget _buildLibrary(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('saints_library'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(context, theme, isDark, accent),
    );
  }

  Widget _buildList(
      BuildContext context, ThemeData theme, bool isDark, Color accent) {
    final entries = _entries!;
    final now = DateTime.now();
    final query = _query.trim().toLowerCase();

    // Today's saint: the fixed 1962-calendar feast for today's date,
    // the same date the saint-of-the-day feature uses.
    SaintLibraryEntry? todayEntry;
    if (query.isEmpty) {
      for (final entry in entries) {
        if (entry.month == now.month && entry.day == now.day) {
          todayEntry = entry;
          break;
        }
      }
    }

    final results = query.isEmpty
        ? entries
        : entries
            .where((e) => e.name.toLowerCase().contains(query))
            .toList();

    // Group by month for the browsable sections.
    final sections = <int, List<SaintLibraryEntry>>{};
    for (final entry in results) {
      sections.putIfAbsent(entry.month, () => []).add(entry);
    }
    final months = sections.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: AppStrings.t('search'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.t('saints_no_results'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (todayEntry != null) ...[
                      _todayCard(context, theme, isDark, todayEntry),
                      const SizedBox(height: 20),
                    ],
                    for (final month in months) ...[
                      _sectionHeader(
                          theme, isDark, AppStrings.monthName(month)),
                      for (final entry in sections[month]!) ...[
                        _saintRow(context, theme, isDark, accent, entry),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _todayCard(BuildContext context, ThemeData theme, bool isDark,
      SaintLibraryEntry entry) {
    return Card(
      color: isDark ? const Color(0xFF2A1A3C) : FidelisTheme.rosePink,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(entry),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.auto_awesome,
                  size: 28, color: isDark ? FidelisTheme.gold : Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('todays_saint'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? FidelisTheme.gold : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? FidelisTheme.gold.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 28, color: isDark ? FidelisTheme.gold : Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _saintRow(BuildContext context, ThemeData theme, bool isDark,
      Color accent, SaintLibraryEntry entry) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _feastLabel(entry.month, entry.day),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 22, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
