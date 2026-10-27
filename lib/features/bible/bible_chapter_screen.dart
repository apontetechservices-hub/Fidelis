import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/app_strings.dart';
import '../../config/theme.dart';
import '../../services/audio_controller.dart';
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
/// chunks so playback starts quickly.
///
/// All audio routes through the central [AudioController] (one stream
/// app-wide): a centered play/pause toggle below the navigation bar, verse
/// highlighting synced to the recited sentences, and auto-continue —
/// navigating to another chapter while playing carries the audio over.
class BibleChapterScreen extends StatefulWidget {
  final BibleBook book;
  final int chapter;

  /// Start playing automatically once the chapter loads (auto-continue:
  /// the previous screen was playing when the user navigated here).
  final bool autoPlay;

  const BibleChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.autoPlay = false,
  });

  @override
  State<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _BibleChapterScreenState extends State<BibleChapterScreen> {
  static const _jobId = 'bible';

  /// Verses per TTS chunk — keeps the first spoken sentence fast.
  static const _versesPerChunk = 10;

  List<BibleVerse>? _verses;
  int? _speakingVerse;
  final Map<int, GlobalKey> _verseKeys = {};

  @override
  void initState() {
    super.initState();
    AudioController.instance.listenable.addListener(_onAudioChanged);
    _load();
  }

  @override
  void dispose() {
    AudioController.instance.listenable.removeListener(_onAudioChanged);
    // Audio is tied to this screen — never keep playing after exit. Owner-
    // scoped so a replacement chapter screen that already auto-continued is
    // not cut off.
    AudioController.instance.stopIfOwner(this);
    super.dispose();
  }

  /// Clears the verse highlight when this screen's audio stops or is
  /// replaced by another screen's stream.
  void _onAudioChanged() {
    final info = AudioController.instance.listenable.value;
    final gone = info.state == AudioState.stopped || info.jobId != _jobId;
    if (gone && _speakingVerse != null && mounted) {
      setState(() => _speakingVerse = null);
    }
  }

  Future<void> _load() async {
    final verses = await BibleService.chapter(widget.book, widget.chapter);
    await BibleService.savePosition(widget.book, widget.chapter);
    if (mounted) {
      setState(() => _verses = verses);
      if (widget.autoPlay) unawaited(_startAudio());
    }
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

  /// Chapter navigation while PLAYING auto-continues with the new chapter
  /// (the new screen starts its own stream; the single-stream controller
  /// replaces the old one). Paused or never started: navigate silently.
  Future<void> _goTo(BibleBook book, int chapter) async {
    if (book.key == widget.book.key && chapter == widget.chapter) return;
    final wasPlaying = AudioController.instance.isPlayingFor(_jobId);
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BibleChapterScreen(
          book: book,
          chapter: chapter,
          autoPlay: wasPlaying,
        ),
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

  Future<void> _toggleAudio() async {
    final controller = AudioController.instance;
    if (controller.isPlayingFor(_jobId)) {
      await controller.pause();
    } else if (controller.state == AudioState.paused &&
        controller.currentJobId == _jobId) {
      await controller.resume();
    } else {
      await _startAudio();
    }
  }

  /// Plays the whole chapter as ~10-verse chunks. Each chunk reports its
  /// sentences as they start being recited; sentences are mapped back to
  /// verse indices so the spoken verse highlights in sync (the Kokoro
  /// engine exposes no word timestamps, so verse level is the finest sync
  /// available). The Douay-Rheims text is English, so lang is 'en'.
  Future<void> _startAudio() async {
    final verses = _verses;
    if (verses == null || verses.isEmpty) return;
    final chunks = <AudioChunk>[];
    for (var start = 0; start < verses.length; start += _versesPerChunk) {
      final end = (start + _versesPerChunk < verses.length)
          ? start + _versesPerChunk
          : verses.length;
      final group = verses.sublist(start, end);
      final text = group.map((v) => v.text).join(' ');
      final verseForSentence = _sentenceVerseIndices(group, start, text);
      chunks.add(AudioChunk(
        text: text,
        lang: 'en',
        onSentenceStart: (sentence) {
          if (!mounted) return;
          final verse = sentence < verseForSentence.length
              ? verseForSentence[sentence]
              : verseForSentence.last;
          if (verse != _speakingVerse) {
            setState(() => _speakingVerse = verse);
            _scrollToVerse(verse);
          }
        },
      ));
    }
    await AudioController.instance.start(
      AudioJob(id: _jobId, chunks: chunks),
      owner: this,
    );
  }

  /// Maps each speakable sentence of [text] (same split the TTS engine
  /// uses) to the index of the verse it starts in. Sentences are substrings
  /// of the joined chunk text, so offsets align with verse boundaries.
  List<int> _sentenceVerseIndices(
    List<BibleVerse> group,
    int firstVerse,
    String text,
  ) {
    final verseStarts = <int>[];
    var offset = 0;
    for (final v in group) {
      verseStarts.add(offset);
      offset += v.text.length + 1; // +1 for the joining space
    }
    final indices = <int>[];
    var cursor = 0;
    for (final sentence in TtsService.splitSentences(text)) {
      var at = text.indexOf(sentence, cursor);
      if (at < 0) at = cursor;
      var verse = 0;
      for (var k = 0; k < verseStarts.length; k++) {
        if (verseStarts[k] <= at) verse = k;
      }
      indices.add(firstVerse + verse);
      cursor = at + sentence.length;
    }
    if (indices.isEmpty) indices.add(firstVerse);
    return indices;
  }

  void _scrollToVerse(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _verseKeys[index]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.25,
      );
    });
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
              itemBuilder: (context, index) => _buildVerse(context, index, accent),
            ),
      bottomNavigationBar: _navigationBar(theme, accent),
    );
  }

  Widget _buildVerse(BuildContext context, int index, Color accent) {
    final verse = _verses![index];
    final theme = Theme.of(context);
    final speaking = index == _speakingVerse;
    return Padding(
      key: _verseKeys.putIfAbsent(index, GlobalKey.new),
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
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: speaking ? accent : null,
                fontWeight: speaking ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navigationBar(ThemeData theme, Color accent) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Centered play/pause toggle for the chapter's read-aloud audio.
            ValueListenableBuilder<AudioPlaybackInfo>(
              valueListenable: AudioController.instance.listenable,
              builder: (context, info, _) {
                final mine = info.jobId == _jobId;
                final playing = mine && info.state == AudioState.playing;
                return IconButton.filled(
                  tooltip: playing
                      ? AppStrings.t('pause_audio')
                      : AppStrings.t('play_audio'),
                  onPressed: _toggleAudio,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
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