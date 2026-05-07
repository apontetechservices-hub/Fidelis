import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NovenaProgress {
  final String novenaId;
  final DateTime startDate;
  final int currentDay; // 1-9, 0 = not started
  final Set<int> completedDays;
  final bool notificationEnabled;
  final int notificationHour;
  final int notificationMinute;

  NovenaProgress({
    required this.novenaId,
    required this.startDate,
    required this.currentDay,
    required this.completedDays,
    this.notificationEnabled = false,
    this.notificationHour = 8,
    this.notificationMinute = 0,
  });

  bool get isComplete => completedDays.length >= 9;
  double get progressPercent => completedDays.length / 9;

  Map<String, dynamic> toJson() => {
    'novenaId': novenaId,
    'startDate': startDate.toIso8601String(),
    'currentDay': currentDay,
    'completedDays': completedDays.toList(),
    'notificationEnabled': notificationEnabled,
    'notificationHour': notificationHour,
    'notificationMinute': notificationMinute,
  };

  factory NovenaProgress.fromJson(Map<String, dynamic> json) => NovenaProgress(
    novenaId: json['novenaId'],
    startDate: DateTime.parse(json['startDate']),
    currentDay: json['currentDay'],
    completedDays: (json['completedDays'] as List).cast<int>().toSet(),
    notificationEnabled: json['notificationEnabled'] ?? false,
    notificationHour: json['notificationHour'] ?? 8,
    notificationMinute: json['notificationMinute'] ?? 0,
  );
}

class NovenaStorage {
  static const _key = 'novena_progress';

  static Future<Map<String, NovenaProgress>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, NovenaProgress.fromJson(v as Map<String, dynamic>)));
  }

  static Future<void> saveAll(Map<String, NovenaProgress> data) async {
    final prefs = await SharedPreferences.getInstance();
    final map = data.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<void> save(NovenaProgress progress) async {
    final all = await loadAll();
    all[progress.novenaId] = progress;
    await saveAll(all);
  }

  static Future<void> remove(String novenaId) async {
    final all = await loadAll();
    all.remove(novenaId);
    await saveAll(all);
  }
}