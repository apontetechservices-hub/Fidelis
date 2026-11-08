import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_strings.dart';

/// One book of the Bible. Chapter counts are PER-LANGUAGE: the English
/// Douay-Rheims text and the Spanish Torres Amat text divide 19 books into
/// different numbers of chapters, so every consumer — navigation (Next/
/// Previous end-of-book detection), the chapter picker, last-position
/// restore, and the count labels — reads [chaptersFor] / [chaptersInTextLang]
/// instead of the English [chapters] directly.
class BibleBook {
  final String key;
  final String name;
  final String testament; // 'OT' | 'NT'
  final int order;

  /// Chapters of the ENGLISH text (Douay-Rheims, dr_bible.json) — books.json's
  /// `chapters`. Also the fallback when a hand-constructed book (tests) has no
  /// Spanish count.
  final int chapters;

  /// Chapters of the SPANISH text (Torres Amat, sp_bible.json) — books.json's
  /// `chapters_es`, derived by counting the chapters present in the bundled
  /// Spanish text (tool/gen_spanish_chapter_counts.py; guarded by
  /// test/bible_spanish_boundaries_test.dart). Never hand-typed.
  final int? chaptersEs;

  const BibleBook({
    required this.key,
    required this.name,
    required this.testament,
    required this.order,
    required this.chapters,
    this.chaptersEs,
  });

  /// Chapter count of this book's text in [lang] ('en' | 'es') — the count of
  /// chapters the displayed text actually has.
  int chaptersFor(String lang) =>
      lang == 'es' ? (chaptersEs ?? chapters) : chapters;

  /// Chapter count in the language the app currently displays
  /// ([BibleService.textLang]).
  int get chaptersInTextLang => chaptersFor(BibleService.textLang);
}

/// One verse of a chapter.
class BibleVerse {
  final int number;
  final String text;
  const BibleVerse(this.number, this.text);
}

/// Loads and caches the Bible verse text per app language from assets:
/// 'en' → Douay-Rheims (dr_bible.json), 'es' → Torres Amat (sp_bible.json).
/// Each language's ~5 MB JSON is parsed lazily on first use — never both
/// eagerly — and kept in memory; screens read from memory.
class BibleService {
  BibleService._();

  static final Map<String, Map<String, dynamic>> _bibles = {};
  static List<BibleBook>? _books;

  /// Asset file holding the verse text for [lang] ('en' | 'es').
  static String _bibleAsset(String lang) =>
      lang == 'es' ? 'assets/bible/sp_bible.json' : 'assets/bible/dr_bible.json';

  static Future<Map<String, dynamic>> _loadBible(String lang) async {
    final cached = _bibles[lang];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_bibleAsset(lang));
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    _bibles[lang] = parsed;
    return parsed;
  }

  /// Language of the verse text the app currently displays: Spanish reads
  /// the Torres Amat text, English the Douay-Rheims.
  static String get textLang => AppStrings.isSpanish ? 'es' : 'en';

  /// All 73 books in canonical order.
  static Future<List<BibleBook>> books() async {
    final cached = _books;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/bible/books.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final list = (data['books'] as List).cast<Map<String, dynamic>>();
    final parsed = list
        .map((b) => BibleBook(
              key: b['key'] as String,
              name: b['name'] as String,
              testament: b['testament'] as String,
              order: b['order'] as int,
              chapters: b['chapters'] as int,
              chaptersEs: b['chapters_es'] as int?,
            ))
        .toList()
      ..sort((a, b) {
        // Canonical order: the whole Old Testament block first (orders
        // 1..46), then the New Testament block (orders 1..27) — exactly the
        // order the book picker presents. books.json restarts `order` at 1
        // for the NT, so sorting on `order` alone interleaves OT and NT
        // books sharing an order value (Dart's sort is unstable), and the
        // neighbour lookup jumped across testaments at book boundaries
        // (Genesis 50 → Matthew 1, Apocalypse 22 → Jeremias 1).
        final aBlock = a.testament == 'NT' ? 1 : 0;
        final bBlock = b.testament == 'NT' ? 1 : 0;
        if (aBlock != bBlock) return aBlock.compareTo(bBlock);
        return a.order.compareTo(b.order);
      });
    _books = parsed;
    return parsed;
  }

  /// Next chapter in reading order: the following chapter of [book], or —
  /// past the book's last chapter IN THE CURRENTLY DISPLAYED LANGUAGE —
  /// chapter 1 of the NEXT book in canonical order (index-based on the
  /// ordered [books] list). The Spanish Torres Amat text divides 19 books
  /// into more chapters than the English counts declare, so the end-of-book
  /// check must use the current language's count ([BibleBook
  /// .chaptersInTextLang]) — otherwise Spanish Next hands off to the next
  /// book early and the text's remaining chapters are never reached. Past
  /// the last chapter of Apocalypse (the final book) this returns null:
  /// Next is a no-op.
  static Future<(BibleBook, int)?> nextChapter(BibleBook book, int chapter) async {
    if (chapter < book.chaptersInTextLang) return (book, chapter + 1);
    final all = await books();
    final index = all.indexWhere((b) => b.key == book.key);
    if (index < 0 || index >= all.length - 1) return null;
    return (all[index + 1], 1);
  }

  /// Previous chapter in reading order: the preceding chapter of [book], or
  /// — before chapter 1 — the LAST chapter of the previous book in canonical
  /// order, in the currently displayed language. Before Genesis 1 this
  /// returns null.
  static Future<(BibleBook, int)?> previousChapter(BibleBook book, int chapter) async {
    if (chapter > 1) return (book, chapter - 1);
    final all = await books();
    final index = all.indexWhere((b) => b.key == book.key);
    if (index <= 0) return null;
    final prev = all[index - 1];
    return (prev, prev.chaptersInTextLang);
  }

  /// Display name of a book in the active app language.
  static String bookName(BibleBook book) {
    if (!AppStrings.isSpanish) return book.name;
    return _spanishNames[book.key] ?? book.name;
  }

  /// Verses of one chapter, in verse order, in the app's current language
  /// (Douay-Rheims for English, Torres Amat for Spanish). Asterisk markup
  /// stripped.
  static Future<List<BibleVerse>> chapter(BibleBook book, int chapter) async {
    final bible = await _loadBible(textLang);
    final bookData = bible[book.key] as Map<String, dynamic>?;
    if (bookData == null) return [];
    final ch = bookData['$chapter'] as Map<String, dynamic>?;
    if (ch == null) return [];
    final verses = <BibleVerse>[];
    for (final entry in ch.entries) {
      final number = int.tryParse(entry.key);
      if (number == null) continue;
      final text = (entry.value as String).replaceAll('*', '');
      verses.add(BibleVerse(number, text));
    }
    verses.sort((a, b) => a.number.compareTo(b.number));
    return verses;
  }

  /// Last-read position, remembered across sessions.
  static Future<void> savePosition(BibleBook book, int chapter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bible_last_book', book.key);
      await prefs.setInt('bible_last_chapter', chapter);
    } catch (_) {}
  }

  /// Returns the saved (book, chapter) or null when nothing was read yet.
  /// The chapter is validated against the CURRENTLY DISPLAYED language's
  /// count: a position saved past a language's count (the two languages
  /// divide 19 books differently) is out of range for that language's text.
  static Future<(BibleBook, int)?> lastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('bible_last_book');
      final chapter = prefs.getInt('bible_last_chapter');
      if (key == null || chapter == null) return null;
      final all = await books();
      for (final book in all) {
        if (book.key == key) {
          if (chapter >= 1 && chapter <= book.chaptersInTextLang) {
            return (book, chapter);
          }
          return null;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Standard Spanish Catholic book names, keyed by the Douay-Rheims
  /// book keys used in books.json / dr_bible.json.
  static const Map<String, String> _spanishNames = {
    // ---- Old Testament ----
    'Genesis': 'Génesis',
    'Exodus': 'Éxodo',
    'Leviticus': 'Levítico',
    'Numbers': 'Números',
    'Deuteronomy': 'Deuteronomio',
    'Josue': 'Josué',
    'Judges': 'Jueces',
    'Ruth': 'Rut',
    '1 Kings': '1 Samuel',
    '2 Kings': '2 Samuel',
    '3 Kings': '1 Reyes',
    '4 Kings': '2 Reyes',
    '1 Paralipomenon': '1 Crónicas',
    '2 Paralipomenon': '2 Crónicas',
    'Esdras': 'Esdras',
    'Nehemias': 'Nehemías',
    'Tobias': 'Tobías',
    'Judith': 'Judit',
    'Esther': 'Ester',
    'Job': 'Job',
    'Psalms': 'Salmos',
    'Proverbs': 'Proverbios',
    'Ecclesiastes': 'Eclesiastés',
    'Canticle of Canticles': 'Cantar de los Cantares',
    'Wisdom': 'Sabiduría',
    'Ecclesiasticus': 'Eclesiástico',
    'Isaias': 'Isaías',
    'Jeremias': 'Jeremías',
    'Lamentations': 'Lamentaciones',
    'Baruch': 'Baruc',
    'Ezechiel': 'Ezequiel',
    'Daniel': 'Daniel',
    'Osee': 'Oseas',
    'Joel': 'Joel',
    'Amos': 'Amós',
    'Abdias': 'Abdías',
    'Jonas': 'Jonás',
    'Micheas': 'Miqueas',
    'Nahum': 'Nahum',
    'Habacuc': 'Habacuc',
    'Sophonias': 'Sofonías',
    'Aggeus': 'Hageo',
    'Zacharias': 'Zacarías',
    'Malachias': 'Malaquías',
    '1 Machabees': '1 Macabeos',
    '2 Machabees': '2 Macabeos',
    // ---- New Testament ----
    'Matthew': 'San Mateo',
    'Mark': 'San Marcos',
    'Luke': 'San Lucas',
    'John': 'San Juan',
    'Acts': 'Hechos de los Apóstoles',
    'Romans': 'Romanos',
    '1 Corinthians': '1 Corintios',
    '2 Corinthians': '2 Corintios',
    'Galatians': 'Gálatas',
    'Ephesians': 'Efesios',
    'Philippians': 'Filipenses',
    'Colossians': 'Colosenses',
    '1 Thessalonians': '1 Tesalonicenses',
    '2 Thessalonians': '2 Tesalonicenses',
    '1 Timothy': '1 Timoteo',
    '2 Timothy': '2 Timoteo',
    'Titus': 'Tito',
    'Philemon': 'Filemón',
    'Hebrews': 'Hebreos',
    'James': 'Santiago',
    '1 Peter': '1 Pedro',
    '2 Peter': '2 Pedro',
    '1 John': '1 Juan',
    '2 John': '2 Juan',
    '3 John': '3 Juan',
    'Jude': 'Judas',
    'Apocalypse': 'Apocalipsis',
  };
}