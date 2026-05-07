import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for fetching 1962 Roman Missal data from the Missale Meum API.
/// Free, MIT-licensed API: https://www.missalemeum.com
class MissalService {
  /// On web, route through same-origin proxy (unified server on port 8080)
  /// to avoid CORS issues. On native, hit the API directly.
  static String get _baseUrl =>
      kIsWeb ? '' : 'https://www.missalemeum.com';
  static const String _apiVersion = 'v5';
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

  /// HTTP GET with timeout and retries with backoff.
  static Future<http.Response> _getWithRetry(Uri url) async {
    Exception? lastException;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await http.get(url).timeout(_timeout);
        if (response.statusCode == 200) return response;
        if (response.statusCode >= 500 && attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }
        throw Exception('API returned status ${response.statusCode}');
      } on TimeoutException {
        lastException = TimeoutException('Connection timed out');
        if (attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt < _maxRetries - 1) {
          await _backoff(attempt);
          continue;
        }
      }
    }
    throw lastException ?? Exception('API failed after $_maxRetries retries');
  }

  static Future<void> _backoff(int attempt) async {
    await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
  }

  /// Fetch the liturgical calendar for a given year.
  static Future<List<CalendarDay>> getCalendar(int year, {String lang = 'en'}) async {
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/$lang/api/$_apiVersion/calendar/$year'),
    );
    final List<dynamic> json = jsonDecode(response.body);
    return json.map((e) => CalendarDay.fromJson(e)).toList();
  }

  /// Fetch the Mass propers for a specific date.
  static Future<List<Proper>> getProper(DateTime date, {String lang = 'en'}) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _getWithRetry(
      Uri.parse('$_baseUrl/$lang/api/$_apiVersion/proper/$dateStr'),
    );
    final List<dynamic> json = jsonDecode(response.body);
    return json.map((e) => Proper.fromJson(e)).toList();
  }

  /// Get the liturgical color name from code.
  static String colorName(String code) {
    switch (code) {
      case 'w': return 'White';
      case 'r': return 'Red';
      case 'g': return 'Green';
      case 'v': return 'Violet';
      case 'p': return 'Rose';
      case 'b': return 'Black';
      default: return 'White';
    }
  }

  /// Get the liturgical color as a Color value.
  static int colorValue(String code) {
    switch (code) {
      case 'w': return 0xFFFFFFFF;
      case 'r': return 0xFFCC0000;
      case 'g': return 0xFF006600;
      case 'v': return 0xFF6600CC;
      case 'p': return 0xFFFF66CC;
      case 'b': return 0xFF000000;
      default: return 0xFFFFFFFF;
    }
  }
}

/// A single day in the liturgical calendar.
class CalendarDay {
  final String title;
  final List<String> tags;
  final List<String> colors;
  final int rank;
  final String id;
  final List<String> commemorations;

  CalendarDay({
    required this.title,
    required this.tags,
    required this.colors,
    required this.rank,
    required this.id,
    required this.commemorations,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      title: json['title'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      colors: List<String>.from(json['colors'] ?? ['w']),
      rank: json['rank'] ?? 4,
      id: json['id'] ?? '',
      commemorations: List<String>.from(
        (json['commemorations'] ?? []).map((c) => c is String ? c : c['title'] ?? ''),
      ),
    );
  }

  String get primaryColor => colors.isNotEmpty ? colors.first : 'w';
  String get colorName => MissalService.colorName(primaryColor);

  Map<String, dynamic> toJson() => {
    'title': title, 'tags': tags, 'colors': colors, 'rank': rank, 'id': id,
    'commemorations': commemorations,
  };
}

/// The full propers for a Mass (one or more celebrations on a day).
class Proper {
  final ProperInfo info;
  final List<ProperSection> sections;

  Proper({required this.info, required this.sections});

  factory Proper.fromJson(Map<String, dynamic> json) {
    return Proper(
      info: ProperInfo.fromJson(json['info'] ?? {}),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((s) => ProperSection.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'info': info.toJson(),
    'sections': sections.map((s) => s.toJson()).toList(),
  };
}

/// Metadata about the proper (title, rank, colors, date).
class ProperInfo {
  final String id;
  final String title;
  final List<String> tags;
  final List<String> colors;
  final String date;
  final int rank;
  final String description;
  final List<ProperCommemoration> commemorations;

  ProperInfo({
    required this.id,
    required this.title,
    required this.tags,
    required this.colors,
    required this.date,
    required this.rank,
    required this.description,
    required this.commemorations,
  });

  factory ProperInfo.fromJson(Map<String, dynamic> json) {
    return ProperInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      colors: List<String>.from(json['colors'] ?? ['w']),
      date: json['date'] ?? '',
      rank: json['rank'] ?? 4,
      description: json['description'] ?? '',
      commemorations: (json['commemorations'] as List<dynamic>? ?? [])
          .map((c) => ProperCommemoration.fromJson(c))
          .toList(),
    );
  }

  String get primaryColor => colors.isNotEmpty ? colors.first : 'w';

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'tags': tags, 'colors': colors, 'date': date,
    'rank': rank, 'description': description,
    'commemorations': commemorations.map((c) => c.toJson()).toList(),
  };
}

/// A commemoration within a proper.
class ProperCommemoration {
  final String id;
  final String title;

  ProperCommemoration({required this.id, required this.title});

  factory ProperCommemoration.fromJson(dynamic json) {
    if (json is String) {
      return ProperCommemoration(id: '', title: json);
    }
    final map = json as Map<String, dynamic>;
    return ProperCommemoration(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}

/// A section of the Mass proper (e.g., Introit, Collect, Epistle, Gospel).
class ProperSection {
  final String id;
  final String label;
  final List<List<String>> body; // [0] = English, [1] = Latin

  ProperSection({required this.id, required this.label, required this.body});

  factory ProperSection.fromJson(Map<String, dynamic> json) {
    return ProperSection(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      body: (json['body'] as List<dynamic>? ?? [])
          .map((pair) => (pair as List<dynamic>).map((e) => e.toString()).toList())
          .toList(),
    );
  }

  /// Get English text (first item in each pair).
  String get english => body.map((pair) => pair.isNotEmpty ? pair[0] : '').join('\n\n');

  /// Get Latin text (second item in each pair).
  String get latin => body.map((pair) => pair.length > 1 ? pair[1] : '').join('\n\n');

  bool get hasLatin => body.any((pair) => pair.length > 1 && pair[1].isNotEmpty);

  Map<String, dynamic> toJson() => {
    'id': id, 'label': label, 'body': body,
  };
}