import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/config/app_strings.dart';
import 'package:fidelis/services/bible_service.dart';

/// Spanish (Torres Amat) chapter boundaries: the bundled Spanish text
/// divides 19 books into MORE chapters than the English counts in
/// books.json declare, so every chapter-count consumer must use the
/// count of the text in the CURRENTLY SELECTED language.
///
/// These tests mirror test/bible_navigation_test.dart in Spanish:
/// the expected counts are derived here by counting the chapters present
/// in the bundled sp_bible.json itself (never hand-typed), and the audit
/// asserts books.json's `chapters_es` matches that count EXACTLY, in both
/// directions, for all 73 books.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppStrings.setLanguage('es');
  });

  /// Chapters present in the bundled Spanish text, per book key: the count
  /// of integer chapter keys, verified contiguous 1..N.
  Future<Map<String, int>> bundledSpanishCounts() async {
    final raw = await rootBundle.loadString('assets/bible/sp_bible.json');
    final spanish = jsonDecode(raw) as Map<String, dynamic>;
    final counts = <String, int>{};
    spanish.forEach((key, bookData) {
      final chapterKeys = (bookData as Map<String, dynamic>).keys
          .where((k) => int.tryParse(k) != null)
          .toList();
      final numbers = chapterKeys.map(int.parse).toList()..sort();
      expect(numbers, List.generate(chapterKeys.length, (i) => i + 1),
          reason: '$key: Spanish chapter keys not contiguous 1..N');
      counts[key] = chapterKeys.length;
    });
    return counts;
  }

  group('audit: declared Spanish counts match the bundled text', () {
    test('every book declares EXACTLY the chapters its Spanish text has '
        '(both directions: no more, no fewer)', () async {
      final books = await BibleService.books();
      final bundled = await bundledSpanishCounts();
      expect(books.length, 73);
      expect(bundled.length, 73);
      for (final book in books) {
        final present = bundled[book.key];
        expect(present, isNotNull,
            reason: '${book.key}: no Spanish text for a declared book');
        // Both directions at once: declared == present means the declared
        // count is neither MORE (Next would walk into empty chapters) nor
        // FEWER (Next would hand off to the next book early) than the text.
        expect(book.chaptersEs, present,
            reason:
                '${book.key}: books.json declares ${book.chaptersEs} Spanish '
                'chapters but the bundled Torres Amat text has $present');
      }
    });

    test('every Spanish chapter the count declares has verses in the text',
        () async {
      final books = await BibleService.books();
      for (final book in books) {
        for (var ch = 1; ch <= book.chaptersInTextLang; ch++) {
          final verses = await BibleService.chapter(book, ch);
          expect(verses, isNotEmpty,
              reason:
                  '${book.key} $ch: declared ${book.chaptersInTextLang} '
                  'Spanish chapters but the verse text has none for this chapter');
        }
      }
    });

    test('English counts still match the English text exactly (regression guard)',
        () async {
      await AppStrings.setLanguage('en');
      final books = await BibleService.books();
      final raw = await rootBundle.loadString('assets/bible/dr_bible.json');
      final english = jsonDecode(raw) as Map<String, dynamic>;
      for (final book in books) {
        final present = (english[book.key] as Map<String, dynamic>)
            .keys
            .where((k) => int.tryParse(k) != null)
            .length;
        expect(book.chapters, present,
            reason:
                '${book.key}: books.json declares ${book.chapters} English '
                'chapters but dr_bible.json has $present');
      }
    });
  });

  group('Next across every book-to-book transition (Spanish)', () {
    test('every boundary lands on chapter 1 of the expected next book',
        () async {
      final books = await BibleService.books();
      final bundled = await bundledSpanishCounts();
      final firstNt = books.indexWhere((b) => b.testament == 'NT');
      for (var i = 0; i < books.length - 1; i++) {
        final book = books[i];
        final trueLast = bundled[book.key]!;
        // The book's TRUE final chapter (per the bundled text) is inside the
        // book, and the chapter after it is chapter 1 of the next book.
        final atLast = await BibleService.nextChapter(book, trueLast);
        expect(atLast, isNotNull,
            reason: '${book.key} $trueLast → null (Next disabled)');
        expect(atLast!.$1.key, books[i + 1].key,
            reason: '${book.key} $trueLast → ${atLast.$1.key} '
                'instead of ${books[i + 1].key}');
        expect(atLast.$2, 1);
        expect(atLast.$1.testament == 'NT', i + 1 >= firstNt,
            reason: '${book.key} jumped to the wrong testament');
        // One before the true final chapter stays inside the book.
        if (trueLast > 1) {
          final before = await BibleService.nextChapter(book, trueLast - 1);
          expect(before!.$1.key, book.key,
              reason: '${book.key} ${trueLast - 1} left its book early');
          expect(before.$2, trueLast);
        }
      }
    });

    test('within a book, Next lands on the next chapter (all Spanish chapters)',
        () async {
      final books = await BibleService.books();
      final bundled = await bundledSpanishCounts();
      for (final book in books) {
        final count = bundled[book.key]!;
        for (var ch = 1; ch < count; ch++) {
          final next = await BibleService.nextChapter(book, ch);
          expect(next, isNotNull);
          expect(next!.$1.key, book.key,
              reason: '${book.key} $ch left its book');
          expect(next.$2, ch + 1);
        }
      }
    });

    test('last chapter of Apocalypse (Spanish): Next is a no-op (null)',
        () async {
      final books = await BibleService.books();
      final bundled = await bundledSpanishCounts();
      final apocalypse = books.last;
      expect(apocalypse.key, 'Apocalypse');
      final next =
          await BibleService.nextChapter(apocalypse, bundled['Apocalypse']!);
      expect(next, isNull);
    });

    test('Previous mirrors Next: Genesis 1 is null, Matthew 1 enters '
        '2 Machabees at its Spanish last chapter', () async {
      final books = await BibleService.books();
      final bundled = await bundledSpanishCounts();
      expect(await BibleService.previousChapter(books.first, 1), isNull);
      final prev = await BibleService.previousChapter(books[46], 1); // Matthew
      expect(prev, isNotNull);
      expect(prev!.$1.key, '2 Machabees');
      expect(prev.$2, bundled['2 Machabees'], // 15 in Spanish, 14 in English
          reason: 'Previous must enter the previous book at its Spanish '
              'last chapter, not the English count');
    });

    test('within a book, Previous lands on the preceding chapter '
        '(all Spanish chapters)', () async {
      final books = await BibleService.books();
      final bundled = await bundledSpanishCounts();
      for (final book in books) {
        final count = bundled[book.key]!;
        for (var ch = 2; ch <= count; ch++) {
          final prev = await BibleService.previousChapter(book, ch);
          expect(prev, isNotNull);
          expect(prev!.$1.key, book.key,
              reason: '${book.key} $ch left its book');
          expect(prev.$2, ch - 1);
        }
      }
    });
  });

  group('per-language counts are actually per-language', () {
    test('English and Spanish chapter counts are unified (v1.4.77 rebuild)',
        () async {
      // The English text was rebuilt to the standard Douay-Rheims chapter
      // divisions — the same divisions the Spanish Torres Amat text already
      // used — so no book divides differently between the languages any
      // more. The per-language count plumbing stays (chaptersFor), but the
      // two languages now always agree.
      final books = await BibleService.books();
      final diverging = books.where((b) => b.chaptersEs != b.chapters).toList();
      expect(diverging, isEmpty,
          reason: 'books whose English and Spanish chapter counts still '
              'differ: ${diverging.map((b) => b.key).toList()}');
    });

    test('chaptersFor follows the selected language; counts are unified',
        () async {
      final books = await BibleService.books();
      final job = books.firstWhere((b) => b.key == 'Job');
      expect(job.chapters, 42); // English count, rebuilt to the standard DR
      expect(job.chaptersEs, 42); // Spanish count, from the bundled text
      await AppStrings.setLanguage('en');
      expect(job.chaptersInTextLang, 42);
      await AppStrings.setLanguage('es');
      expect(job.chaptersInTextLang, 42);
    });
  });
}
