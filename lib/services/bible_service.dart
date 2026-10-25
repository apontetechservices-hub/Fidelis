import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_strings.dart';

/// One book of the Douay-Rheims Bible.
class BibleBook {
  final String key;
  final String name;
  final String testament; // 'OT' | 'NT'
  final int order;
  final int chapters;

  const BibleBook({
    required this.key,
    required this.name,
    required this.testament,
    required this.order,
    required this.chapters,
  });
}

/// One verse of a chapter.
class BibleVerse {
  final int number;
  final String text;
  const BibleVerse(this.number, this.text);
}

/// Loads and caches the Douay-Rheims Bible from assets.
/// Both JSON files are parsed once per app run; screens read from memory.
class BibleService {
  BibleService._();

  static Map<String, dynamic>? _bible;
  static List<BibleBook>? _books;

  static Future<Map<String, dynamic>> _loadBible() async {
    final cached = _bible;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/bible/dr_bible.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    _bible = parsed;
    return parsed;
  }

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
            ))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    _books = parsed;
    return parsed;
  }

  /// Display name of a book in the active app language.
  /// Verse text stays English (Douay-Rheims) in both languages.
  static String bookName(BibleBook book) {
    if (!AppStrings.isSpanish) return book.name;
    return _spanishNames[book.key] ?? book.name;
  }

  /// Verses of one chapter, in verse order. Asterisk markup stripped.
  static Future<List<BibleVerse>> chapter(BibleBook book, int chapter) async {
    final bible = await _loadBible();
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
  static Future<(BibleBook, int)?> lastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString('bible_last_book');
      final chapter = prefs.getInt('bible_last_chapter');
      if (key == null || chapter == null) return null;
      final all = await books();
      for (final book in all) {
        if (book.key == key) {
          if (chapter >= 1 && chapter <= book.chapters) return (book, chapter);
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