import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import 'reflection_service.dart';

class ReflectionScreen extends StatelessWidget {
  final DailyReflection reflection;

  const ReflectionScreen({super.key, required this.reflection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reflection'),
        actions: [
          if (reflection.link.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              tooltip: 'Read full reflection online',
              onPressed: () => _launchUrl(reflection.link),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Feast Day header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A1A3C), const Color(0xFF1A2332)]
                      : [FidelisTheme.rosePink, FidelisTheme.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    reflection.date,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (reflection.feastDay.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      reflection.feastDay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (reflection.title.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      reflection.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gospel verse
            if (reflection.gospelVerse.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.menu_book, size: 18,
                    color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reflection.gospelVerse,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Gospel text
            if (reflection.gospelText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E).withValues(alpha: 0.5)
                      : const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? FidelisTheme.gold.withValues(alpha: 0.3) : FidelisTheme.deepRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '\u201c${reflection.gospelText}\u201d',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.7,
                    color: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Reflection
            if (reflection.reflection.isNotEmpty) ...[
              Text(
                'Reflection',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                ),
              ),
              const SizedBox(height: 12),
              ...reflection.reflection.split('\n\n').map((paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  paragraph,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                ),
              )),
              const SizedBox(height: 24),
            ],

            // Closing prayer
            if (reflection.prayer.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E).withValues(alpha: 0.5)
                      : const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reflection.prayer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        height: 1.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Attribution
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Source: mycatholic.life',
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}