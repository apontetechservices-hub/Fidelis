import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../../services/bible_service.dart';
import 'bible_chapter_screen.dart';

/// Premium Bible reader home: the 73 books of the Douay-Rheims,
/// grouped into the Old and New Testament, plus a "Continue reading" card.
class BibleHomeScreen extends StatefulWidget {
  const BibleHomeScreen({super.key});

  @override
  State<BibleHomeScreen> createState() => _BibleHomeScreenState();
}

class _BibleHomeScreenState extends State<BibleHomeScreen> {
  bool _loading = true;
  List<BibleBook>? _books;
  (BibleBook, int)? _lastRead;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await BibleService.books();
    final last = await BibleService.lastPosition();
    if (mounted) {
      setState(() {
        _books = books;
        _lastRead = last;
        _loading = false;
      });
    }
  }

  void _openChapter(BibleBook book, int chapter) {
    BibleService.savePosition(book, chapter);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BibleChapterScreen(book: book, chapter: chapter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('bible'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(context, theme, isDark, accent),
    );
  }

  Widget _buildList(
      BuildContext context, ThemeData theme, bool isDark, Color accent) {
    final books = _books!;
    final ot = books.where((b) => b.testament == 'OT').toList();
    final nt = books.where((b) => b.testament == 'NT').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_lastRead != null) ...[
          _continueCard(context, theme, isDark, accent, _lastRead!),
          const SizedBox(height: 20),
        ],
        _sectionHeader(theme, isDark, AppStrings.t('old_testament')),
        for (final book in ot) ...[
          _bookRow(context, theme, isDark, accent, book),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        _sectionHeader(theme, isDark, AppStrings.t('new_testament')),
        for (final book in nt) ...[
          _bookRow(context, theme, isDark, accent, book),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _continueCard(BuildContext context, ThemeData theme, bool isDark,
      Color accent, (BibleBook, int) last) {
    final (book, chapter) = last;
    return Card(
      color: isDark ? const Color(0xFF2A1A3C) : FidelisTheme.rosePink,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openChapter(book, chapter),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.auto_stories, size: 28, color: isDark ? FidelisTheme.gold : Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('continue_reading'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? FidelisTheme.gold : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${BibleService.bookName(book)} $chapter',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? FidelisTheme.gold.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow, size: 28, color: isDark ? FidelisTheme.gold : Colors.white),
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

  Widget _bookRow(BuildContext context, ThemeData theme, bool isDark,
      Color accent, BibleBook book) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openChapter(book, 1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  BibleService.bookName(book),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                AppStrings.t('chapters_count')
                    .replaceAll('{{n}}', '${book.chapters}'),
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