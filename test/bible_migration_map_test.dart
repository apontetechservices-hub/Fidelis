import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fidelis/config/app_strings.dart';
import 'package:fidelis/services/bible_address_migration.dart';
import 'package:fidelis/services/bible_service.dart';

/// Guards the v1.4.77 Bible data fix + address migration:
///
/// The English text (dr_bible.json) was rebuilt to the standard Douay-Rheims
/// chapter divisions (64 whole chapters + 3 individually missing verses
/// restored from drbo.org, 16 merged verse pairs un-merged, 2 chapter-
/// argument headings removed, every verse renumbered 1..N within its
/// chapter). The stored last-reading position (the app's only persisted
/// Bible address) migrates through assets/bible/migration_map.json.
///
/// The fixtures in test/fixtures/bible_migration_fixtures.json are sampled
/// pre-fix addresses (affected AND unaffected books) whose post-migration
/// verse text was verified identical during the rebuild audit — this test
/// re-proves them against the SHIPPED data, so any future data or map edit
/// that breaks a reader's position fails here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<Map<String, dynamic>> loadFixtures() async {
    final raw = File('test/fixtures/bible_migration_fixtures.json')
        .readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loadBible() async {
    final raw = await rootBundle.loadString('assets/bible/dr_bible.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loadMap() async {
    final raw =
        await rootBundle.loadString('assets/bible/migration_map.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  group('shipped English text structure', () {
    test('73 books, every verse keyed 1..N within its chapter, 35,804 verses',
        () async {
      final bible = await loadBible();
      expect(bible.length, 73);
      var total = 0;
      bible.forEach((book, chapters) {
        (chapters as Map<String, dynamic>).forEach((ch, verses) {
          final keys = (verses as Map<String, dynamic>).keys
              .map(int.parse)
              .toList()
            ..sort();
          expect(keys, List.generate(keys.length, (i) => i + 1),
              reason: '$book $ch: verse keys not contiguous 1..N');
          total += keys.length;
        });
      });
      expect(total, 35804);
    });

    test('the restored verses are present (spot checks)', () async {
      final bible = await loadBible();
      // The app strips the file's asterisk markup at display; assert on the
      // displayed text.
      String display(String t) => t.replaceAll('*', '');
      // Ruth 2 and 3 were entirely missing; Ruth 4:1 is the old Ruth 2:44.
      expect(display(bible['Ruth']['4']['1']),
          startsWith('Then Booz went up to the gate'));
      expect(display(bible['Ruth']['2']['1']),
          startsWith('Now her husband Elimelech had a kinsman'));
      expect(display(bible['Ruth']['3']['1']),
          startsWith('After she was returned to her mother in law'));
      // Genesis 40:9 was individually missing.
      expect(display(bible['Genesis']['40']['9']),
          startsWith('The chief butler first told his dream'));
      // Isaias 5:7 was individually missing.
      expect(display(bible['Isaias']['5']['7']),
          startsWith('For the vineyard of the Lord of hosts'));
      // The two typos are fixed.
      expect(bible['Genesis']['40']['7'], isNot(contains('oountenance')));
      expect(bible['Genesis']['40']['7'], contains('countenance'));
      final ecclus17 = bible['Ecclesiasticus']['17'].values
          .whereType<String>()
          .join(' ');
      expect(ecclus17, isNot(contains('sun of man')));
      expect(ecclus17, contains('son of man'));
      // The chapter-argument headings are gone from the verse list.
      expect(display(bible['Deuteronomy']['34']['1']),
          startsWith('Then Moses went up'));
      expect(display(bible['Psalms']['129']['1']),
          startsWith('Out of the depths'));
    });
  });

  group('migration map', () {
    test('covers exactly the 19 rebuilt books; every mapped chapter is '
        'within the book\'s declared count', () async {
      final map = await loadMap();
      final books = await BibleService.books();
      final byKey = {for (final b in books) b.key: b};
      // The 19 books whose English chapter divisions changed.
      const rebuilt = {
        'Numbers', 'Josue', 'Judges', 'Ruth', '2 Kings',
        '1 Paralipomenon', 'Nehemias', 'Judith', 'Esther', 'Job',
        'Ecclesiasticus', 'Jeremias', 'Ezechiel', 'Osee', 'Amos',
        'Micheas', 'Zacharias', '2 Machabees', '1 Corinthians',
      };
      expect(map.keys.toSet(), rebuilt);
      map.forEach((book, chapters) {
        final declared = byKey[book]!.chapters;
        (chapters as Map<String, dynamic>).forEach((oldCh, newCh) {
          expect(newCh, inInclusiveRange(1, declared),
              reason: '$book: old chapter $oldCh maps to $newCh, '
                  'outside 1..$declared');
          expect(int.parse(oldCh), inInclusiveRange(1, declared),
              reason: '$book: map key $oldCh outside the old chapter range');
        });
      });
    });

    test('every mapped (book, old chapter) lands on the same first-verse '
        'text the old chapter showed (chapter fixtures)', () async {
      final map = await loadMap();
      final bible = await loadBible();
      final fixtures = await loadFixtures();
      for (final f in fixtures['chapter'] as List) {
        final book = f['book'] as String;
        final oldCh = f['old_ch'] as int;
        final newCh = f['new_ch'] as int;
        final mapped = map[book]?['$oldCh'] ?? oldCh;
        expect(mapped, newCh,
            reason: '$book: map sends old chapter $oldCh to $mapped, '
                'audit-verified target is $newCh');
        final chapter = bible[book]['$newCh'] as Map<String, dynamic>;
        final keys = chapter.keys.map(int.parse).toList()..sort();
        final first = chapter['${keys.first}'];
        expect(first, f['first_verse_text'],
            reason: '$book: old chapter $oldCh migrated to $newCh but the '
                'first verse text changed');
      }
    });

    test('sampled verse addresses land on the identical verse text '
        '(verse fixtures)', () async {
      final map = await loadMap();
      final bible = await loadBible();
      final fixtures = await loadFixtures();
      for (final f in fixtures['verse'] as List) {
        final book = f['book'] as String;
        final oldCh = (f['old'] as List)[0] as int;
        final oldV = (f['old'] as List)[1] as int;
        final newCh = (f['new'] as List)[0] as int;
        final newV = (f['new'] as List)[1] as int;
        // Chapter-level: the shipped map must agree with the audited target.
        final mappedCh = map[book]?['$oldCh'] ?? oldCh;
        expect(mappedCh, newCh,
            reason: '$book: map sends old chapter $oldCh to $mappedCh, '
                'audit-verified target is $newCh');
        expect(bible[book]['$newCh']['$newV'], f['text'],
            reason: '$book: old $oldCh:$oldV should land on $newCh:$newV '
                'with identical text');
      }
    });
  });

  group('BibleAddressMigration', () {
    test('remaps a stored English position through the map (one-time, '
        'flag-guarded)', () async {
      await AppStrings.setLanguage('en');
      SharedPreferences.setMockInitialValues({
        'bible_last_book': 'Ruth',
        'bible_last_chapter': 2,
      });
      await BibleAddressMigration.apply();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('bible_last_chapter'), 4);
      expect(prefs.getBool('bible_addr_migration_v77'), isTrue);
      // Second run: the flag prevents re-migration (the position is now in
      // the new numbering; re-applying would be a no-op anyway because the
      // map's keys are old chapters, but the flag makes it explicit).
      await prefs.setInt('bible_last_chapter', 1);
      await BibleAddressMigration.apply();
      expect(prefs.getInt('bible_last_chapter'), 1);
    });

    test('leaves unaffected-book positions untouched', () async {
      await AppStrings.setLanguage('en');
      SharedPreferences.setMockInitialValues({
        'bible_last_book': 'Genesis',
        'bible_last_chapter': 40,
      });
      await BibleAddressMigration.apply();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('bible_last_chapter'), 40);
    });

    test('Spanish-saved positions are already in the standard numbering '
        'and are not remapped', () async {
      // The migration gates on the app language (AppStrings.isSpanish): a
      // Spanish-saved position is already in the standard numbering.
      SharedPreferences.setMockInitialValues({
        'app_language': 'es',
        'bible_last_book': 'Job',
        'bible_last_chapter': 5,
      });
      await AppStrings.load();
      await BibleAddressMigration.apply();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('bible_last_chapter'), 5);
    });

    test('corrupt stored chapter (out of the old range) is left untouched',
        () async {
      await AppStrings.setLanguage('en');
      SharedPreferences.setMockInitialValues({
        'bible_last_book': 'Job',
        'bible_last_chapter': 25, // old Job had 19 chapters
      });
      await BibleAddressMigration.apply();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('bible_last_chapter'), 25);
    });
  });
}
