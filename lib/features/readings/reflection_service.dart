import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Daily Gospel reflection from My Catholic Life! (catholic-daily-reflections.com)
/// RSS feed: https://catholic-daily-reflections.com/feed/
/// Permission: Free to use with attribution ("Source: mycatholic.life")
class DailyReflection {
  final String title;
  final String date;
  final String feastDay;
  final String gospelVerse;
  final String gospelText;
  final String reflection;
  final String prayer;
  final String link;
  final String audioUrl;

  const DailyReflection({
    required this.title,
    required this.date,
    required this.feastDay,
    required this.gospelVerse,
    required this.gospelText,
    required this.reflection,
    required this.prayer,
    required this.link,
    this.audioUrl = '',
  });
}

/// Service to fetch and cache daily Gospel reflections.
class ReflectionService {
  static const String _feedUrl = 'https://catholic-daily-reflections.com/feed/';
  static Database? _db;
  static bool _dbReady = false;

  static Future<Database> get database async {
    if (_db != null && _dbReady) return _db!;
    _db = await _initDb();
    _dbReady = true;
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dbPath, 'fidelis_missal.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reflections (
            date TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            feast_day TEXT NOT NULL,
            gospel_verse TEXT NOT NULL,
            gospel_text TEXT NOT NULL,
            reflection TEXT NOT NULL,
            prayer TEXT NOT NULL,
            link TEXT NOT NULL,
            audio_url TEXT DEFAULT '',
            fetched_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS reflections (
              date TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              feast_day TEXT NOT NULL,
              gospel_verse TEXT NOT NULL,
              gospel_text TEXT NOT NULL,
              reflection TEXT NOT NULL,
              prayer TEXT NOT NULL,
              link TEXT NOT NULL,
              audio_url TEXT DEFAULT '',
              fetched_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
    // Safety net
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reflections (
        date TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        feast_day TEXT NOT NULL,
        gospel_verse TEXT NOT NULL,
        gospel_text TEXT NOT NULL,
        reflection TEXT NOT NULL,
        prayer TEXT NOT NULL,
        link TEXT NOT NULL,
        audio_url TEXT DEFAULT '',
        fetched_at INTEGER NOT NULL
      )
    ''');
    return db;
  }

  static Future<DailyReflection?> getTodayReflection() async {
    final today = _dateKey(DateTime.now());

    try {
      final cached = await _getCached(today);
      if (cached != null) return cached;
    } catch (_) {}

    try {
      final reflection = await _fetchFromRss();
      if (reflection != null) {
        try { await _saveToCache(reflection); } catch (_) {}
        return reflection;
      }
    } catch (_) {
      try {
        final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
        return _getCached(yesterday);
      } catch (_) {}
    }

    return null;
  }

  static Future<DailyReflection?> _getCached(String date) async {
    final db = await database;
    final rows = await db.query('reflections', where: 'date = ?', whereArgs: [date]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return DailyReflection(
      title: row['title'] as String,
      date: row['date'] as String,
      feastDay: row['feast_day'] as String,
      gospelVerse: row['gospel_verse'] as String,
      gospelText: row['gospel_text'] as String,
      reflection: row['reflection'] as String,
      prayer: row['prayer'] as String,
      link: row['link'] as String,
      audioUrl: (row['audio_url'] as String?) ?? '',
    );
  }

  static Future<void> _saveToCache(DailyReflection reflection) async {
    final db = await database;
    await db.insert('reflections', {
      'date': reflection.date,
      'title': reflection.title,
      'feast_day': reflection.feastDay,
      'gospel_verse': reflection.gospelVerse,
      'gospel_text': reflection.gospelText,
      'reflection': reflection.reflection,
      'prayer': reflection.prayer,
      'link': reflection.link,
      'audio_url': reflection.audioUrl,
      'fetched_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static String _dateKey(DateTime dt) {
    final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static Future<DailyReflection?> _fetchFromRss() async {
    final response = await http.get(Uri.parse(_feedUrl)).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;

    final body = response.body;
    final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final titleRegex = RegExp(r'<title>(.*?)</title>', dotAll: false);
    final linkRegex = RegExp(r'<link>(.*?)</link>', dotAll: false);
    final contentRegex = RegExp(r'<content:encoded><!\[CDATA\[(.*?)\]\]></content:encoded>', dotAll: true);

    final items = <Map<String, String>>[];
    for (final match in itemRegex.allMatches(body)) {
      final item = match.group(1) ?? '';
      final title = titleRegex.firstMatch(item)?.group(1);
      final link = linkRegex.firstMatch(item)?.group(1);
      final content = contentRegex.firstMatch(item)?.group(1);
      if (title != null) {
        items.add({'title': title, 'link': link ?? '', 'content': content ?? ''});
      }
    }

    if (items.isEmpty) return null;
    final latest = items.first;
    return _parseReflectionContent(latest['content'] ?? '', latest['title'] ?? '', latest['link'] ?? '');
  }

  /// Parse the HTML content. Structure is:
  /// - <strong>Date</strong> (April 29, 2026)
  /// - <a>Feast day link</a> (Memorial of Saint...)
  /// - <strong>Gospel verse text</strong> (Jesus cried out and said...)
  /// - <p><span>Reflection paragraph 1</span></p>
  /// - <p><span>Reflection paragraph 2</span></p>
  /// - ...
  /// - <i><span>Closing prayer</span></i>
  static DailyReflection? _parseReflectionContent(String html, String title, String link) {
    if (html.isEmpty) return null;

    String date = '';
    String feastDay = '';
    String gospelVerse = '';
    String gospelText = '';
    String reflection = '';
    String prayer = '';
    String audioUrl = '';

    // 1. Date: first <strong> with a month name and year
    final dateMatch = RegExp(r'<strong>([^<]*?\d{1,2},\s*\d{4})</strong>', dotAll: true).firstMatch(html);
    if (dateMatch != null) date = dateMatch.group(1)?.trim() ?? '';

    // 2. Feast day: link to mycatholic.life/saints/
    final feastMatch = RegExp(r'<a[^>]*mycatholic\.life/saints/[^>]*>(.*?)</a>', dotAll: true).firstMatch(html);
    if (feastMatch != null) feastDay = _stripHtml(feastMatch.group(1) ?? '');

    // 3. Gospel verse reference: e.g. "John 12:44–46"
    final verseMatch = RegExp(r'(\d\s?\w+\s+\d+:\d+[–\-\u2013]\d+|\d\s?\w+\s+\d+:\d+)').firstMatch(html);
    if (verseMatch != null) gospelVerse = verseMatch.group(1)?.trim() ?? '';

    // 4. Gospel text: the long <strong> paragraph (the actual scripture quote)
    final boldSections = RegExp(r'<strong>(.*?)</strong>', dotAll: true).allMatches(html);
    for (final match in boldSections) {
      final text = _stripHtml(match.group(1) ?? '').trim();
      // Skip date lines (short, contain year)
      if (text.length < 40) continue;
      // This is the Gospel quote
      gospelText = text;
      break;
    }

    // 5. Reflection paragraphs: <p><span>...</span></p> blocks
    final paragraphs = RegExp(r'<p><span[^>]*>(.*?)</span></p>', dotAll: true).allMatches(html);
    final reflectionParts = <String>[];
    for (final match in paragraphs) {
      final text = _stripHtml(match.group(1) ?? '').trim();
      if (text.isEmpty) continue;
      // Skip navigation/link lines
      if (text.startsWith('Readings for') || text.startsWith('More Gospel') ||
          text.startsWith('Divine Mercy') || text.startsWith('All Saints') ||
          text.startsWith('Mass Reading') || text.contains('Easter Season Prayers')) {
        continue;
      }
      reflectionParts.add(text);
    }
    reflection = reflectionParts.join('\n\n');

    // 6. Closing prayer: found in <i><span>...</span></i> blocks
    final italicSections = RegExp(r'<i><span[^>]*>(.*?)</span></i>', dotAll: true).allMatches(html);
    for (final match in italicSections) {
      final text = _stripHtml(match.group(1) ?? '').trim();
      // Skip short link texts like "Readings for Today"
      if (text.length < 40) continue;
      prayer = text;
      break;
    }

    // 7. Audio URL (Spreaker)
    final audioMatch = RegExp(r'spreaker\.com/player\?episode_id=(\d+)').firstMatch(html);
    if (audioMatch != null) {
      audioUrl = 'https://www.spreaker.com/episode/${audioMatch.group(1)}';
    }

    // Fallbacks
    if (date.isEmpty) date = _dateKey(DateTime.now());
    // Don't fall back to full title for gospel verse — it's usually too long and overflows
    if (gospelVerse.isEmpty) {
      // Try extracting just the book/chapter from the title
      final titleVerseMatch = RegExp(r'(\d\s?\w+\s+\d+:\d+)').firstMatch(title);
      gospelVerse = titleVerseMatch?.group(1)?.trim() ?? '';
    }

    return DailyReflection(
      title: title,
      date: date,
      feastDay: feastDay,
      gospelVerse: gospelVerse,
      gospelText: gospelText,
      reflection: reflection,
      prayer: prayer,
      link: link,
      audioUrl: audioUrl,
    );
  }

  static String _stripHtml(String html) {
    var text = html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8216;', ''')
        .replaceAll('&#8217;', ''')
        .replaceAll('&#8220;', '\u201c')
        .replaceAll('&#8221;', '\u201d')
        .replaceAll('&quot;', '"')
        .trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }
}