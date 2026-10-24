import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../config/app_strings.dart';

/// One rendered block of a Liturgy of the Hours hour.
class LotSection {
  final String type; // 'fixed' | 'antiphon_psalm' | 'hymn' | 'short_reading' | 'collect' | other API keys
  final String label;
  final String la;
  final String vernacular;

  const LotSection({required this.type, required this.label, required this.la, required this.vernacular});

  Map<String, dynamic> toJson() => {'type': type, 'label': label, 'la': la, 'vernacular': vernacular};

  factory LotSection.fromJson(Map<String, dynamic> j) => LotSection(
        type: j['type'] as String? ?? 'text',
        label: j['label'] as String? ?? '',
        la: j['la'] as String? ?? '',
        vernacular: j['vernacular'] as String? ?? '',
      );
}

/// An assembled hour (Lauds or Vespers) ready to render.
class LotHour {
  final String hourKey; // 'lauds' | 'vespers'
  final String title;
  final List<LotSection> sections;

  const LotHour({required this.hourKey, required this.title, required this.sections});

  Map<String, dynamic> toJson() => {
        'hourKey': hourKey,
        'title': title,
        'sections': sections.map((s) => s.toJson()).toList(),
      };

  factory LotHour.fromJson(Map<String, dynamic> j) => LotHour(
        hourKey: j['hourKey'] as String? ?? '',
        title: j['title'] as String? ?? '',
        sections: ((j['sections'] as List<dynamic>?) ?? [])
            .map((s) => LotSection.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// Assembles traditional (1962) Liturgy of the Hours hours from the bundled
/// psalter plus the CatéGPT free API (Divinum Officium texts, attribution required).
class LotService {
  static const String _apiBase = 'https://categpt.chat/api/v1/feast';
  static Database? _db;
  static bool _dbReady = false;
  static Map<String, dynamic>? _psalter;

  static Future<Database> get database async {
    if (_db != null && _dbReady) return _db!;
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(p.join(dbPath, 'fidelis_missal.db'), version: 3);
    await db.execute('CREATE TABLE IF NOT EXISTS hours_cache (id TEXT PRIMARY KEY, payload TEXT NOT NULL, fetched_at INTEGER NOT NULL)');
    _db = db;
    _dbReady = true;
    return db;
  }

  static Future<Map<String, dynamic>> _loadPsalter() async {
    if (_psalter != null) return _psalter!;
    final raw = await rootBundle.loadString('assets/breviary/psalter.json');
    _psalter = json.decode(raw) as Map<String, dynamic>;
    return _psalter!;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Public entry: assemble today's Lauds or Vespers.
  static Future<LotHour?> getHour(String hourKey, {DateTime? date}) async {
    final now = date ?? DateTime.now();
    final lang = AppStrings.isSpanish ? 'es' : 'en';
    final cacheId = '${_dateKey(now)}|$hourKey|$lang';

    try {
      final db = await database;
      final rows = await db.query('hours_cache', where: 'id = ?', whereArgs: [cacheId]);
      if (rows.isNotEmpty) {
        return LotHour.fromJson(json.decode(rows.first['payload'] as String) as Map<String, dynamic>);
      }
    } catch (_) {}

    try {
      final hour = await _assemble(hourKey, now, lang);
      if (hour != null) {
        try {
          final db = await database;
          await db.insert('hours_cache', {
            'id': cacheId,
            'payload': json.encode(hour.toJson()),
            'fetched_at': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (_) {}
        return hour;
      }
    } catch (_) {}

    return null;
  }

  static Future<LotHour?> _assemble(String hourKey, DateTime now, String lang) async {
    final psalter = await _loadPsalter();
    final dayKey = 'Day${now.weekday % 7}'; // Sunday=Day0
    final sectionName = hourKey == 'lauds' ? '$dayKey Laudes1' : '$dayKey Vespera';
    final assignmentsMap = (psalter['assignments'] as Map<String, dynamic>?) ?? {};
    final assignments = assignmentsMap[sectionName] as Map<String, dynamic>?;
    if (assignments == null) return null;
    final psalmList = ((assignments[lang] ?? assignments['la']) as List<dynamic>?) ?? [];
    if (psalmList.isEmpty) return null;

    final feast = await _fetchCategpt(now);
    final vom = feast?['vom'] as Map<String, dynamic>?;
    final offices = (vom?['offices'] as Map<String, dynamic>?) ?? {};
    final hourTexts = ((offices[hourKey] ?? []) as List<dynamic>? ?? []);

    final sections = <LotSection>[];

    sections.add(LotSection(
      type: 'fixed',
      label: AppStrings.t('lot_opening'),
      la: AppStrings.t('lot_opening_la'),
      vernacular: AppStrings.t('lot_opening_la'),
    ));

    for (final item in psalmList) {
      final n = (item['psalm'] as int).toString();
      final psalmTexts = ((psalter['psalms'] as Map<String, dynamic>?) ?? {})[n] as Map<String, dynamic>?;
      if (psalmTexts == null) continue;
      final antiphon = (item['antiphon'] as String? ?? '').trim();
      final laText = antiphon.isEmpty ? (psalmTexts['la'] as String? ?? '') : '$antiphon\n${psalmTexts['la'] ?? ''}';
      final vernText = antiphon.isEmpty
          ? (psalmTexts[lang] ?? psalmTexts['la'] ?? '')
          : '$antiphon\n${psalmTexts[lang] ?? psalmTexts['la'] ?? ''}';
      sections.add(LotSection(
        type: 'antiphon_psalm',
        label: '${AppStrings.t('lot_psalm')} $n',
        la: laText,
        vernacular: vernText as String,
      ));
    }

    for (final t in hourTexts) {
      final map = t as Map<String, dynamic>;
      final key = map['key'] as String? ?? 'text';
      if (key == 'te_deum') continue; // rendered separately later
      final label = map['label'] as String? ?? '';
      final text = _stripHtml(map['text'] as String? ?? '');
      final laText = _stripHtml(((map['source'] as Map<String, dynamic>?)?['text'] ?? '') as String);
      if (text.isEmpty && laText.isEmpty) continue;
      sections.add(LotSection(type: key, label: label, la: laText, vernacular: text));
    }

    sections.add(LotSection(
      type: 'fixed',
      label: AppStrings.t('lot_closing'),
      la: AppStrings.t('lot_closing_la'),
      vernacular: AppStrings.t('lot_closing_la'),
    ));

    final title = hourKey == 'lauds' ? AppStrings.t('lot_lauds') : AppStrings.t('lot_vespers');
    return LotHour(hourKey: hourKey, title: title, sections: sections);
  }

  static Future<Map<String, dynamic>?> _fetchCategpt(DateTime date) async {
    final locale = AppStrings.isSpanish ? 'es' : 'en';
    final url = '$_apiBase?date=${_dateKey(date)}&locale=$locale';
    final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) return null;
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  static String _stripHtml(String html) {
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>\s*<br\s*/?>'), '\n\n')
        .replaceAll(RegExp(r'</p>\s*<p[^>]*>'), '\n\n')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
    text = text.split('\n').map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim()).join('\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}