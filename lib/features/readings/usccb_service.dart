import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for fetching Novus Ordo (current Roman Missal) daily readings
/// from the USCCB website.
///
/// On web, routes through local CORS proxy at localhost:8766.
/// On native, hits USCCB directly.
class UsccbService {
  /// On web, route through same-origin proxy (unified server on port 8080)
  /// to avoid CORS issues. On native, hit USCCB directly.
  static String get _baseUrl =>
      kIsWeb ? '/usccb' : 'https://bible.usccb.org';
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
        throw Exception('USCCB API returned status ${response.statusCode}');
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
    throw lastException ?? Exception('USCCB API failed after $_maxRetries retries');
  }

  static Future<void> _backoff(int attempt) async {
    await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
  }

  /// Fetch Novus Ordo readings for a given date.
  static Future<UsccbReadings> getReadings(DateTime date) async {
    final dateStr =
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}'
        '${(date.year % 100).toString().padLeft(2, '0')}';
    final url = Uri.parse('$_baseUrl/bible/readings/$dateStr.cfm.md');
    final response = await _getWithRetry(url);
    return _parseMarkdown(response.body);
  }

  /// Parse the USCCB markdown into structured readings.
  static UsccbReadings _parseMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String title = '';
    int? lectionary;
    final sections = <UsccbSection>[];

    String? currentLabel;
    String? currentRef;
    final currentLines = <String>[];

    void flushSection() {
      if (currentLabel != null) {
        sections.add(UsccbSection(
          label: currentLabel!,
          reference: currentRef ?? '',
          text: currentLines.join('\n').trim(),
        ));
        currentLabel = null;
        currentRef = null;
        currentLines.clear();
      }
    }

    for (final line in lines) {
      final trimmed = line.trim();

      // Title line: "## Monday of the Fourth Week of Easter"
      if (trimmed.startsWith('## ') && !trimmed.startsWith('## Get')) {
        flushSection();
        title = trimmed.substring(3).trim();
        // Remove "Lectionary: NNN" if appended
        final lectionaryMatch = RegExp(r'Lectionary:\s*(\d+)').firstMatch(title);
        if (lectionaryMatch != null) {
          lectionary = int.tryParse(lectionaryMatch.group(1) ?? '');
          title = title.substring(0, lectionaryMatch.start).trim();
        }
        continue;
      }

      // Standalone "Lectionary: NNN"
      final lectionaryLine = RegExp(r'^Lectionary:\s*(\d+)').firstMatch(trimmed);
      if (lectionaryLine != null) {
        lectionary ??= int.tryParse(lectionaryLine.group(1) ?? '');
        continue;
      }

      // Section header: "### Reading 1", "### Responsorial Psalm", etc.
      if (trimmed.startsWith('### ')) {
        flushSection();
        currentLabel = trimmed.substring(4).trim();
        continue;
      }

      // Reference line: "[Acts 11:1-18](...)"
      final refMatch = RegExp(r'^\s*\[([^\]]+)\]\(<[^>]+>\)').firstMatch(line);
      if (refMatch != null && currentLabel != null && currentLines.isEmpty) {
        currentRef = refMatch.group(1)?.trim();
        continue;
      }

      // Skip navigation links, links, empty lines at section boundaries
      if (trimmed.startsWith('- [') && currentLabel == null) continue;
      if (trimmed.startsWith('- [')) continue; // Any navigation link
      if (trimmed.startsWith('LISTEN') || trimmed.startsWith('VIEW')) continue;
      if (trimmed.startsWith('En Español') || trimmed.startsWith('View Calendar')) continue;
      if (trimmed.startsWith('Get Daily Readings')) continue;
      if (trimmed.startsWith('I Agree') || trimmed.startsWith('SUBSCRIBE')) continue;
      if (trimmed.startsWith('Privacy Policy') || trimmed.startsWith('Terms')) continue;
      if (trimmed.startsWith('Lectionary for Mass')) continue;
      if (trimmed.startsWith('# Daily Readings')) continue;
      if (trimmed.startsWith('## Get')) continue;
      if (trimmed.startsWith('## ')) continue; // Any remaining H2 headers after the main title
      // Skip USCCB copyright/footer blocks
      if (trimmed.startsWith('Confraternity') || trimmed.startsWith('International Committee')) continue;
      if (trimmed.startsWith('Neither this work') || trimmed.startsWith('subscri')) continue;
      if (trimmed.startsWith('Every Morning')) continue;
      if (trimmed.contains('usccb.org')) continue; // Any URL line
      if (trimmed.startsWith('SUBSCRIBE') || trimmed.startsWith('Email')) continue;

      // Stop collecting after last real section — footer detection
      // If we already have a Gospel section and hit non-section content, we're done
      if (sections.any((s) => s.label.toLowerCase() == 'gospel') &&
          currentLabel == null &&
          trimmed.isNotEmpty &&
          !trimmed.startsWith('### ')) {
        break;
      }

      // Skip empty lines only when we don't have an active section
      if (trimmed.isEmpty && currentLabel == null) continue;

      // Collect content lines for current section
      if (currentLabel != null && trimmed.isNotEmpty) {
        currentLines.add(trimmed);
      }
    }
    flushSection();

    return UsccbReadings(
      title: title,
      lectionary: lectionary,
      sections: sections,
      date: DateTime.now(), // Will be overridden by caller
    );
  }
}

/// Parsed Novus Ordo readings for a day.
class UsccbReadings {
  final String title;
  final int? lectionary;
  final List<UsccbSection> sections;
  final DateTime date;

  UsccbReadings({
    required this.title,
    this.lectionary,
    required this.sections,
    required this.date,
  });

  /// Get the liturgical color based on the feast title
  /// (Novus Ordo colors — best effort from title keywords)
  String get liturgicalColorCode {
    final lower = title.toLowerCase();
    if (lower.contains('palm') || lower.contains('passion') || lower.contains('holy week')) return 'r';
    if (lower.contains('pentecost') || lower.contains('martyr') || lower.contains('holy cross')) return 'r';
    if (lower.contains('ash') || lower.contains('lent') || lower.contains('advent')) return 'v';
    if (lower.contains('good friday')) return 'r';
    if (lower.contains('easter') || lower.contains('christmas') || lower.contains('nativity')) return 'w';
    if (lower.contains('ascension') || lower.contains('assumption') || lower.contains('all saints')) return 'w';
    if (lower.contains('ordinary')) return 'g';
    // Default to green for Ordinary Time
    return 'g';
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'lectionary': lectionary,
    'sections': sections.map((s) => s.toJson()).toList(),
    'date': date.toIso8601String(),
  };

  factory UsccbReadings.fromJson(Map<String, dynamic> json) {
    return UsccbReadings(
      title: json['title'] ?? '',
      lectionary: json['lectionary'],
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((s) => UsccbSection.fromJson(s))
          .toList(),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }
}

/// A single reading section (e.g., "Reading 1", "Responsorial Psalm", "Gospel").
class UsccbSection {
  final String label;
  final String reference;
  final String text;

  UsccbSection({
    required this.label,
    required this.reference,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'reference': reference,
    'text': text,
  };

  factory UsccbSection.fromJson(Map<String, dynamic> json) {
    return UsccbSection(
      label: json['label'] ?? '',
      reference: json['reference'] ?? '',
      text: json['text'] ?? '',
    );
  }
}