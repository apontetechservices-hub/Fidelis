import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One saint of the Lives of the Saints library: a fixed feast of the
/// 1962 Roman calendar with a short English life (public-domain sources).
class SaintLibraryEntry {
  final int month;
  final int day;
  final String name;
  final String life;
  final String source;

  const SaintLibraryEntry({
    required this.month,
    required this.day,
    required this.name,
    required this.life,
    required this.source,
  });
}

/// Loads and caches the Lives of the Saints from assets.
/// The JSON is parsed once per app run; screens read from memory.
/// Saint lives stay English (public-domain EN sources) in both languages.
class SaintsLibraryService {
  SaintsLibraryService._();

  static List<SaintLibraryEntry>? _entries;

  static Future<List<SaintLibraryEntry>> _load() async {
    final cached = _entries;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/saints/saints_lives.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final parsed = list
        .map((e) => SaintLibraryEntry(
              month: e['month'] as int,
              day: e['day'] as int,
              name: e['name'] as String,
              life: e['life'] as String,
              source: e['source'] as String,
            ))
        .toList()
      ..sort((a, b) {
        final byMonth = a.month.compareTo(b.month);
        return byMonth != 0 ? byMonth : a.day.compareTo(b.day);
      });
    _entries = parsed;
    return parsed;
  }

  /// All entries in calendar order (month, then feast day).
  static Future<List<SaintLibraryEntry>> all() => _load();

  /// Entries of one month, in feast-day order.
  static Future<List<SaintLibraryEntry>> byMonth(int month) async =>
      (await _load()).where((e) => e.month == month).toList();

  /// Entry for a fixed feast date of the 1962 calendar, or null.
  static Future<SaintLibraryEntry?> today(int month, int day) async {
    for (final entry in await _load()) {
      if (entry.month == month && entry.day == day) return entry;
    }
    return null;
  }

  /// Case-insensitive search by saint name.
  static Future<List<SaintLibraryEntry>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return (await _load())
        .where((e) => e.name.toLowerCase().contains(q))
        .toList();
  }

  /// Number of saints in the library.
  static Future<int> entryCount() async => (await _load()).length;
}
