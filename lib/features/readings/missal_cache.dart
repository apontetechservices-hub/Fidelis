import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'missal_service.dart';
import 'usccb_service.dart';

/// Local SQLite cache for Missal API data.
/// Stores calendar and proper data so the app works offline.
class MissalCache {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'fidelis_missal.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE calendar (
            year INTEGER PRIMARY KEY,
            data TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE propers (
            date TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE usccb_readings (
            date TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            fetched_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS usccb_readings (
              date TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              fetched_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  // --- Calendar ---

  /// Get calendar data. Returns null only if no data exists at all.
  static Future<List<CalendarDay>?> getCalendar(int year) async {
    final db = await database;
    final rows = await db.query('calendar', where: 'year = ?', whereArgs: [year]);
    if (rows.isEmpty) return null;

    final data = rows.first['data'] as String;
    final List<dynamic> json = jsonDecode(data) as List<dynamic>;
    return json.map((e) => CalendarDay.fromJson(e)).toList();
  }

  static Future<void> saveCalendar(int year, List<CalendarDay> days) async {
    final db = await database;
    final data = jsonEncode(days.map((d) => d.toJson()).toList());
    await db.insert(
      'calendar',
      {'year': year, 'data': data, 'fetched_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Propers (1962) ---

  /// Get proper data. Returns null only if no data exists at all.
  static Future<List<Proper>?> getProper(String dateStr) async {
    final db = await database;
    final rows = await db.query('propers', where: 'date = ?', whereArgs: [dateStr]);
    if (rows.isEmpty) return null;

    final data = rows.first['data'] as String;
    final List<dynamic> json = jsonDecode(data) as List<dynamic>;
    return json.map((e) => Proper.fromJson(e)).toList();
  }

  /// Check if proper data is fresh (within 7 days).
  static bool _isProperFresh(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return false;
    final fetchedAt = rows.first['fetched_at'] as int;
    return DateTime.now().millisecondsSinceEpoch - fetchedAt < 7 * 24 * 3600 * 1000;
  }

  /// Check if a proper exists and is fresh in cache.
  static Future<bool> isProperFresh(String dateStr) async {
    final db = await database;
    final rows = await db.query('propers', where: 'date = ?', whereArgs: [dateStr]);
    return _isProperFresh(rows);
  }

  static Future<void> saveProper(String dateStr, List<Proper> propers) async {
    final db = await database;
    final data = jsonEncode(propers.map((p) => p.toJson()).toList());
    await db.insert(
      'propers',
      {'date': dateStr, 'data': data, 'fetched_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- USCCB Readings (Novus Ordo) ---

  /// Get USCCB readings from cache.
  static Future<UsccbReadings?> getUsccbReadings(String dateStr) async {
    final db = await database;
    final rows = await db.query('usccb_readings', where: 'date = ?', whereArgs: [dateStr]);
    if (rows.isEmpty) return null;

    final data = rows.first['data'] as String;
    return UsccbReadings.fromJson(jsonDecode(data));
  }

  static Future<void> saveUsccbReadings(String dateStr, UsccbReadings readings) async {
    final db = await database;
    final data = jsonEncode(readings.toJson());
    await db.insert(
      'usccb_readings',
      {'date': dateStr, 'data': data, 'fetched_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Preload ---

  /// Preload data for the next N days (for offline access).
  /// If [missal] is '1962', loads traditional propers;
  /// if 'novus_ordo', loads USCCB readings.
  static Future<void> preloadDays(int days, {String missal = '1962'}) async {
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      try {
        if (missal == 'novus_ordo') {
          final cached = await getUsccbReadings(dateStr);
          if (cached != null) continue;
          final readings = await UsccbService.getReadings(date);
          await saveUsccbReadings(dateStr, readings);
        } else {
          if (await isProperFresh(dateStr)) continue;
          final propers = await MissalService.getProper(date);
          await saveProper(dateStr, propers);
        }
      } catch (_) {
        // Skip on failure, will try again next time
      }
    }
  }
}