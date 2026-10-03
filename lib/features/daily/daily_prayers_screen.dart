import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../services/notification_service.dart';
import '../prayers/prayers_screen.dart';
import '../chaplet/chaplet_list_screen.dart';

/// The daily prayer hub — the traditional rhythm of the Catholic day:
/// Morning Offering at dawn, the Angelus at 6 AM / noon / 6 PM, Night Prayer at night.
/// During the Easter Season the Angelus slots become the Regina Caeli, as tradition prescribes.
class DailyPrayersScreen extends StatefulWidget {
  const DailyPrayersScreen({super.key});

  @override
  State<DailyPrayersScreen> createState() => _DailyPrayersScreenState();

  /// True from Holy Saturday through Pentecost Sunday (the Regina Caeli season).
  static bool isEasterSeason(DateTime now) {
    final e = _easterSunday(now.year);
    final start = DateTime(now.year, e.month, e.day).subtract(const Duration(days: 1));
    final end = DateTime(now.year, e.month, e.day).add(const Duration(days: 50));
    return !now.isBefore(start) && now.isBefore(end);
  }

  /// Easter Sunday by the Anonymous Gregorian algorithm (computus).
  static DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }
}

class _DailyPrayersScreenState extends State<DailyPrayersScreen> {
  bool _reminder = false;
  final Map<String, bool> _done = {};
  late final String _dayKey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    _dayKey = 'dp_${now.year}$mm$dd';
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _reminder = prefs.getBool('angelus_reminder') ?? false;
      for (final p in _dayList()) {
        _done[p.$1] = prefs.getBool('$_dayKey${_slug(p.$1)}') ?? false;
      }
    });
  }

  Future<void> _toggleDone(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final v = !(_done[title] ?? false);
    setState(() => _done[title] = v);
    await prefs.setBool('$_dayKey${_slug(title)}', v);
  }

  Future<void> _setReminder(bool v) async {
    setState(() => _reminder = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('angelus_reminder', v);
    await NotificationService.scheduleAngelusReminders(enabled: v);
  }

  static String _slug(String t) =>
      '_${t.toLowerCase().replaceAll(RegExp('[^a-z]+'), '_')}';

  /// The day's prayers — the Angelus becomes the Regina Caeli in Eastertide.
  List<(String, IconData)> _dayList() {
    final easter = DailyPrayersScreen.isEasterSeason(DateTime.now());
    return [
      ('Morning Offering', Icons.wb_sunny),
      (
        easter ? 'Regina Caeli (Easter Angelus)' : 'The Angelus',
        easter ? Icons.celebration_outlined : Icons.church_outlined,
      ),
      ('Act of Contrition', Icons.favorite_border),
      ('Night Prayer', Icons.nightlight),
    ];
  }

  /// Time-aware suggestion for the current hour.
  (String title, String subtitle, IconData icon) _suggestion() {
    final now = DateTime.now();
    final h = now.hour;
    final easter = DailyPrayersScreen.isEasterSeason(now);
    final angelus = easter ? 'Regina Caeli (Easter Angelus)' : 'The Angelus';
    if (h >= 5 && h < 11) {
      return ('Morning Offering', 'Begin the day — offer everything to God', Icons.wb_sunny);
    }
    if (h >= 11 && h < 14) {
      return (angelus, 'Midday — the bell tolls for the Angelus', Icons.access_time_rounded);
    }
    if (h >= 15 && h < 16) {
      return ('Divine Mercy Chaplet', 'The Hour of Great Mercy — 3 PM', Icons.favorite);
    }
    if (h >= 17 && h < 20) {
      return (angelus, 'At the close of day', Icons.wb_twilight);
    }
    return ('Night Prayer', 'End the day in peace', Icons.nightlight);
  }

  void _openDevotion(String title) {
    if (title == 'Divine Mercy Chaplet') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChapletListScreen()),
      );
      return;
    }
    PrayersScreen.openPrayerByName(context, title);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = _suggestion();

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Prayers')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Time-aware suggestion
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openDevotion(s.$1),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF2A1A3C), const Color(0xFF1A2332)]
                        : [FidelisTheme.rosePink, FidelisTheme.lightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOW IS A GOOD TIME FOR',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? FidelisTheme.gold : Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(s.$3, color: FidelisTheme.gold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.$1,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.$2,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // The day's prayers
          Text(
            "The Day's Prayers",
            style: theme.textTheme.titleLarge?.copyWith(color: FidelisTheme.gold),
          ),
          const SizedBox(height: 8),
          for (final p in _dayList())
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(p.$2, color: isDark ? FidelisTheme.gold : FidelisTheme.deepRed),
                title: Text(p.$1, style: theme.textTheme.bodyLarge),
                onTap: () => _openDevotion(p.$1),
                trailing: Checkbox(
                  value: _done[p.$1] ?? false,
                  onChanged: (_) => _toggleDone(p.$1),
                  activeColor: FidelisTheme.gold,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Reminders
          Text(
            'Reminders',
            style: theme.textTheme.titleLarge?.copyWith(color: FidelisTheme.gold),
          ),
          SwitchListTile(
            title: const Text('Angelus reminders'),
            subtitle: const Text('6 AM · noon · 6 PM'),
            value: _reminder,
            onChanged: _setReminder,
            activeColor: FidelisTheme.gold,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "The Angelus commemorates the Incarnation — the Angel's announcement to Mary — "
              'and is traditionally prayed at 6 AM, noon, and 6 PM. '
              'During the Easter Season the app shows the Regina Caeli in its place.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}