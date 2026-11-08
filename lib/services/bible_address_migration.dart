import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_strings.dart';

/// One-time migration of stored Bible addresses across the v1.4.77 data fix:
/// the English text (dr_bible.json) was rebuilt to the standard Douay-Rheims
/// chapter divisions — 64 whole chapters + 7 single verses restored, every
/// verse renumbered 1..N within its chapter — so a stored (book, chapter)
/// reference from the OLD English numbering must remap to keep pointing at
/// the same verse text.
///
/// Stored references audited 2026-11-08 (the only persisted Bible addresses
/// in the app):
///   - last-reading position / continue-reading: 'bible_last_book' +
///     'bible_last_chapter' (chapter-level; no verse is stored).
/// There are no bookmarks (the feature does not exist) and no stored audio
/// word-timing data (Bible word timing is synthesized at playback from the
/// same synthesis pass as the audio — lib/services/audio_controller.dart —
/// so it regenerates from the new text automatically).
///
/// Language gate: the stored position is language-agnostic (a single
/// (book, chapter) pair, saved from whichever language was displayed). The
/// Spanish text (sp_bible.json) ALREADY uses the standard divisions, so a
/// position saved under Spanish is already in the new numbering and must
/// NOT be remapped (remapping would move it to a different chapter). The
/// app's language at migration time is the best available signal of the
/// language the position was saved under (the position is rewritten on
/// every chapter load, so it tracks the reader's current language):
///   - English (or unset, the default): apply the old→new map.
///   - Spanish: leave the position untouched.
/// After this release the two languages share one numbering, so the
/// ambiguity dissolves for anything saved from now on.
///
/// Unmappable references: every old English chapter 1..N of the 19 rebuilt
/// books is present in the map, so a stored position can only be unmappable
/// if it is corrupt (a chapter the old text never had). Those are left
/// untouched — the pre-existing range validation in
/// [BibleService.lastPosition] already returns null for them (the
/// continue-reading card simply does not show; nothing is silently
/// rewritten into a wrong chapter).
class BibleAddressMigration {
  BibleAddressMigration._();

  /// Guard flag: the migration runs at most once per install.
  static const _flag = 'bible_addr_migration_v77';

  static Map<String, Map<String, int>>? _map;

  /// Applies the migration. Call once at startup, before any Bible screen
  /// can read the stored position. Never throws: a failure leaves the
  /// stored data untouched (and the flag unset, so the next launch
  /// retries).
  static Future<void> apply() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_flag) ?? false) return;
      // Spanish-saved positions are already in the standard numbering.
      if (!AppStrings.isSpanish) {
        final book = prefs.getString('bible_last_book');
        final chapter = prefs.getInt('bible_last_chapter');
        if (book != null && chapter != null) {
          final mapped = (await _loadMap())[book]?['$chapter'];
          if (mapped != null && mapped != chapter) {
            await prefs.setInt('bible_last_chapter', mapped);
          }
        }
      }
      await prefs.setBool(_flag, true);
    } catch (_) {}
  }

  /// The old→new chapter map for the 19 rebuilt books, from
  /// assets/bible/migration_map.json ({book: {old_chapter: new_chapter}}).
  /// Books and chapters absent from the map are unchanged (identity).
  static Future<Map<String, Map<String, int>>> _loadMap() async {
    final cached = _map;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/bible/migration_map.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    _map = parsed.map(
        (book, chapters) => MapEntry(book, (chapters as Map<String, dynamic>)
            .map((ch, newCh) => MapEntry(ch, newCh as int))));
    return _map!;
  }
}
