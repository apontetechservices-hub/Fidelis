import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../../services/bible_service.dart';
import '../../services/billing_service.dart';
import '../../services/tts_service.dart';
import '../premium/paywall_screen.dart';

/// Arguments for the named '/bible/chapter' route.
class BibleChapterArgs {
  final BibleBook book;
  final int chapter;
  const BibleChapterArgs({required this.book, required this.chapter});
}

/// One chapter of the Douay-Rheims: scrollable verses, prev/next chapter
/// navigation, a book/chapter picker, and read-aloud audio in ~10-verse
/// chunks so Stop responds quickly.
class BibleChapterScreen extends StatefulWidget {
  final BibleBook book;
  final int chapter;

  const BibleChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  State<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _BibleChapterScreenState extends State<BibleChapterScreen> {
  List<BibleVerse>? _verses;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final verses = await BibleService.chapter(widget.book, widget.chapter);
    await BibleService.savePosition(widget.book, widget.chapter);
    if (mounted) setState(() => _verses = verses);
  }

  /// Neighbouring chapter, walking across book boundaries in canon order.
  Future<(BibleBook, int)?> _neighbour(int direction) async {
    final book = widget.book;
    final chapter = widget.chapter;
    if (direction < 0) {
      if (chapter > 1) return (book, chapter - 1);
      final books = await BibleService.books();
      final index = books.indexWhere((b) => b.key == book.key);
      if (index <= 0) return null;
      final prev = books[index - 1];
      return (prev, prev.chapters);
    }
    if (chapter < book.chapters) return (book, chapter + 1);
    final books = await BibleService.books();
    final index = books.indexWhere((b) => b.key == book.key);
    if (index < 0 || index >= books.length - 1) return null;
    return (books[index + 1], 1);
  }

  Future<void> _goTo(BibleBook book, int chapter) async {
    if (book.key == widget.book.key && chapter == widget.chapter) return;
    TtsService.stop();
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BibleChapterScreen(book: book, chapter: chapter),
      ),
    );
  }

  /// Book/chapter picker: first the books, then a chapter grid.
  Future<void> _openPicker() async {
    final picked = await showModalBottomSheet<(BibleBook, int)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BiblePickerSheet(
        currentBookKey: widget.book.key,
        currentChapter: widget.chapter,
      ),
    );
    if (picked != null) await _goTo(picked.$1, picked.$2);
  }

  /// Speaks the chapter in ~10-verse chunks; [_speaking] drives the
  /// stop button. The Douay-Rheims text is English, so lang is 'en'.
  Future<void> _playAudio() async {
    final verses = _verses;
    if (verses == null || verses.isEmpty || _speaking) return;
    setState(() => _speaking = true);
    for (var start = 0; start < verses.length; start += 10) {
      if (!_speaking) break;
      final end = (start + 10 < verses.length) ? start + 10 : verses.length;
      final text = verses
          .sublist(start, end)
          .map((v) => v.text)
          .join(' ');
      await TtsService.speakPrayer(text, lang: 'en');
    }
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _stopAudio() async {
    setState(() => _speaking = false);
    await TtsService.stop();
  }

  @override
  Widget build(BuildContext context) {
    // Route-level premium guard: direct navigation to this screen
    // (named route, deep link, any push) still requires Premium.
    return ValueListenableBuilder<bool>(
      valueListenable: BillingService.premium,
      builder: (context, isPremium, _) {
        if (!isPremium) return const PaywallScreen();
        return _buildReader(context);
      },
    );
  }

  Widget _buildReader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;

    return Scaffold(
      appBar: AppBar(
        title: Text('${BibleService.bookName(widget.book)} ${widget.chapter}'),
        actions: [
          IconButton(
            icon: Icon(_speaking ? Icons.volume_off : Icons.volume_up),
            tooltip: _speaking ? AppStrings.t('stop_audio') : AppStrings.t('listen'),
            onPressed: _speaking ? _stopAudio : _playAudio,
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: AppStrings.t('bible'),
            onPressed: _openPicker,
          ),
        ],
      ),
      body: _verses == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: _verses!.length,
              itemBuilder: (context, index) {
                final verse = _verses![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${verse.number} ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: verse.text,
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _navigationBar(theme, accent),
    );
  }

  Widget _navigationBar(ThemeData theme, Color accent) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FutureBuilder<(BibleBook, int)?>(
                future: _neighbour(-1),
                builder: (context, snap) {
                  final prev = snap.data;
                  return OutlinedButton.icon(
                    onPressed: prev == null ? null : () => _goTo(prev.$1, prev.$2),
                    icon: const Icon(Icons.chevron_left),
                    label: Text(AppStrings.t('previous')),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              tooltip: AppStrings.t('bible'),
              onPressed: _openPicker,
              icon: const Icon(Icons.menu_book),
              style: IconButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<(BibleBook, int)?>(
                future: _neighbour(1),
                builder: (context, snap) {
                  final next = snap.data;
                  return OutlinedButton.icon(
                    onPressed: next == null ? null : () => _goTo(next.$1, next.$2),
                    icon: const Icon(Icons.chevron_right),
                    label: Text(AppStrings.t('next')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet picker: stage 1 lists the books (OT/NT), stage 2 the
/// chapters of the chosen book. Pops with (book, chapter).
class _BiblePickerSheet extends StatefulWidget {
  final String? currentBookKey;
  final int? currentChapter;

  const _BiblePickerSheet({this.currentBookKey, this.currentChapter});

  @override
  State<_BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends State<_BiblePickerSheet> {
  List<BibleBook>? _books;
  BibleBook? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await BibleService.books();
    if (mounted) setState(() => _books = books);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? FidelisTheme.gold : FidelisTheme.deepRed;
    final selected = _selected;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (selected != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selected = null),
                    ),
                  Expanded(
                    child: Text(
                      selected == null
                          ? AppStrings.t('bible')
                          : BibleService.bookName(selected),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _books == null
                  ? const Center(child: CircularProgressIndicator())
                  : selected == null
                      ? _buildBooks(theme, isDark, accent)
                      : _buildChapters(theme, accent, selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooks(ThemeData theme, bool isDark, Color accent) {
    final books = _books!;
    final ot = books.where((b) => b.testament == 'OT').toList();
    final nt = books.where((b) => b.testament == 'NT').toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _pickerSection(theme, isDark, AppStrings.t('old_testament')),
        for (final book in ot)
          ListTile(
            dense: true,
            title: Text(BibleService.bookName(book)),
            trailing: Text(
              AppStrings.t('chapters_count').replaceAll('{{n}}', '${book.chapters}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            onTap: () => setState(() => _selected = book),
          ),
        _pickerSection(theme, isDark, AppStrings.t('new_testament')),
        for (final book in nt)
          ListTile(
            dense: true,
            title: Text(BibleService.bookName(book)),
            trailing: Text(
              AppStrings.t('chapters_count').replaceAll('{{n}}', '${book.chapters}'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            onTap: () => setState(() => _selected = book),
          ),
      ],
    );
  }

  Widget _pickerSection(ThemeData theme, bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChapters(ThemeData theme, Color accent, BibleBook book) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: book.chapters,
      itemBuilder: (context, index) {
        final chapter = index + 1;
        final isCurrent = book.key == widget.currentBookKey &&
            chapter == widget.currentChapter;
        return OutlinedButton(
          onPressed: () => Navigator.pop(context, (book, chapter)),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(
              color: isCurrent ? accent : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            backgroundColor: isCurrent ? accent.withValues(alpha: 0.15) : null,
          ),
          child: Text(
            '$chapter',
            style: TextStyle(
              color: isCurrent ? accent : null,
              fontWeight: isCurrent ? FontWeight.bold : null,
            ),
          ),
        );
      },
    );
  }
}
