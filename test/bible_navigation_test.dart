import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/services/bible_service.dart';

/// The owner's boundary check: stepping Next across EVERY book-to-book
/// transition in canonical order (Genesis → Exodus → … → Apocalypse) must
/// land on chapter 1 of the EXPECTED next book; within a book, Next lands
/// on the next chapter; and Next on the last chapter of Apocalypse
/// (Revelation) is a no-op.
///
/// Regression for the random book jumps at book boundaries: books.json
/// restarts `order` at 1 for the NT, and the old `order`-only sort
/// interleaved OT and NT books sharing an order value (Dart's sort is
/// unstable), so the index-based neighbour lookup jumped across testaments
/// (Genesis 50 → Matthew 1, Apocalypse 22 → Jeremias 1). The fix orders the
/// list as the picker presents it — OT block first, then NT block — and the
/// neighbour lookup stays index-based on that ordered list.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('canonical book order', () {
    test('73 books, OT block first then NT block, orders ascending', () async {
      final books = await BibleService.books();
      expect(books.length, 73);
      expect(books.first.key, 'Genesis');
      expect(books.last.key, 'Apocalypse');
      // Testament blocks: every OT book precedes every NT book.
      final firstNt = books.indexWhere((b) => b.testament == 'NT');
      expect(firstNt, 46);
      for (var i = 0; i < books.length; i++) {
        expect(books[i].testament == 'NT', i >= firstNt,
            reason: 'testament block violated at index $i: ${books[i].key}');
      }
      // Orders ascend within each block.
      for (var i = 1; i < firstNt; i++) {
        expect(books[i].order, greaterThan(books[i - 1].order),
            reason: 'OT order regression at ${books[i].key}');
      }
      for (var i = firstNt + 1; i < books.length; i++) {
        expect(books[i].order, greaterThan(books[i - 1].order),
            reason: 'NT order regression at ${books[i].key}');
      }
    });
  });

  group('Next across every book-to-book transition (canonical order)', () {
    test('every boundary lands on chapter 1 of the expected next book',
        () async {
      final books = await BibleService.books();
      final firstNt = books.indexWhere((b) => b.testament == 'NT');
      for (var i = 0; i < books.length - 1; i++) {
        final book = books[i];
        final next = await BibleService.nextChapter(book, book.chapters);
        expect(next, isNotNull,
            reason: '${book.key} ${book.chapters} → null (Next disabled)');
        expect(next!.$1.key, books[i + 1].key,
            reason:
                '${book.key} ${book.chapters} → ${next.$1.key} instead of ${books[i + 1].key}');
        expect(next.$2, 1);
        expect(next.$1.testament == 'NT', i + 1 >= firstNt,
            reason: '${book.key} jumped to the wrong testament');
      }
    });

    test('within a book, Next lands on the next chapter', () async {
      final books = await BibleService.books();
      for (final book in books) {
        for (var ch = 1; ch < book.chapters; ch++) {
          final next = await BibleService.nextChapter(book, ch);
          expect(next, isNotNull);
          expect(next!.$1.key, book.key,
              reason: '${book.key} $ch left its book');
          expect(next.$2, ch + 1);
        }
      }
    });

    test('last chapter of Apocalypse: Next is a no-op (null)', () async {
      final books = await BibleService.books();
      final apocalypse = books.last;
      expect(apocalypse.key, 'Apocalypse');
      final next =
          await BibleService.nextChapter(apocalypse, apocalypse.chapters);
      expect(next, isNull);
    });

    test('Previous mirrors Next: Genesis 1 is null, Matthew 1 enters 2 Machabees',
        () async {
      final books = await BibleService.books();
      expect(await BibleService.previousChapter(books.first, 1), isNull);
      final prev = await BibleService.previousChapter(books[46], 1); // Matthew
      expect(prev, isNotNull);
      expect(prev!.$1.key, '2 Machabees');
      expect(prev.$2, 14); // 2 Machabees chapter count per books.json
    });
  });

  group('chapter counts match the verse text', () {
    // English (Douay-Rheims): books.json's `chapters` counts are exact for
    // the English text, and they are what the English boundary conditions
    // use. The Spanish Torres Amat text divides 19 books into more
    // chapters — it has its own per-language count (`chapters_es`) and its
    // own boundary tests in test/bible_spanish_boundaries_test.dart.
    test('every book declares the chapters its English verse text has',
        () async {
      final books = await BibleService.books();
      for (final book in books) {
        for (var ch = 1; ch <= book.chapters; ch++) {
          final verses = await BibleService.chapter(book, ch);
          expect(verses, isNotEmpty,
              reason:
                  '${book.key} $ch: books.json declares ${book.chapters} chapters but the verse text has none for this chapter');
        }
      }
    });
  });
}
