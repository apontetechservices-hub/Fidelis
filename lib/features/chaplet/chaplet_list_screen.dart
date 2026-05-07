import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'chaplet_data.dart';
import 'chaplet_prayer_screen.dart';

class ChapletListScreen extends StatelessWidget {
  const ChapletListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More Chaplets'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: chapletList.length,
        itemBuilder: (context, index) {
          final chaplet = chapletList[index];
          return _ChapletCard(chaplet: chaplet);
        },
      ),
    );
  }
}

class _ChapletCard extends StatelessWidget {
  final ChapletMeta chaplet;

  const _ChapletCard({required this.chaplet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChapletPrayerScreen(chapletId: chaplet.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: chaplet.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    chaplet.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chaplet.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chaplet.shortDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}