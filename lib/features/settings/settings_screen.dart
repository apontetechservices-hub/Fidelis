import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../config/app_strings.dart';
import '../../services/notification_service.dart';
import '../../app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _missal = '1962'; // '1962' or 'novus_ordo'
  // Notification settings
  bool _massReminder = false;
  TimeOfDay _massTime = const TimeOfDay(hour: 7, minute: 0);
  bool _rosaryReminder = false;
  TimeOfDay _rosaryTime = const TimeOfDay(hour: 18, minute: 0);
  bool _chapletReminder = false;
  TimeOfDay _chapletTime = const TimeOfDay(hour: 15, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _missal = prefs.getString('missal') ?? '1962';
      _massReminder = prefs.getBool('mass_reminder') ?? false;
      _rosaryReminder = prefs.getBool('rosary_reminder') ?? false;
      _chapletReminder = prefs.getBool('chaplet_reminder') ?? false;
      _massTime = TimeOfDay(
        hour: prefs.getInt('mass_hour') ?? 7,
        minute: prefs.getInt('mass_minute') ?? 0,
      );
      _rosaryTime = TimeOfDay(
        hour: prefs.getInt('rosary_hour') ?? 18,
        minute: prefs.getInt('rosary_minute') ?? 0,
      );
      _chapletTime = TimeOfDay(
        hour: prefs.getInt('chaplet_hour') ?? 15,
        minute: prefs.getInt('chaplet_minute') ?? 0,
      );
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  void _scheduleMassReminder() {
    NotificationService.scheduleMassReminder(hour: _massTime.hour, minute: _massTime.minute);
  }

  void _scheduleRosaryReminder() {
    NotificationService.scheduleRosaryReminder(hour: _rosaryTime.hour, minute: _rosaryTime.minute);
  }

  void _scheduleChapletReminder() {
    NotificationService.scheduleChapletReminder(hour: _chapletTime.hour, minute: _chapletTime.minute);
  }

  void _cancelMassReminder() {
    NotificationService.cancelNotification(1);
  }

  void _cancelRosaryReminder() {
    NotificationService.cancelNotification(2);
  }

  void _cancelChapletReminder() {
    NotificationService.cancelNotification(3);
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final current = AppStrings.locale;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.t('app_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in AppStrings.languages)
              ListTile(
                title: Text(l.$2),
                leading: current == l.$1
                    ? const Icon(Icons.check, color: FidelisTheme.gold)
                    : null,
                onTap: () => Navigator.pop(context, l.$1),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != current) {
      await AppStrings.setLanguage(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('title_settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Appearance
          _sectionHeader(AppStrings.t('section_appearance')),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(AppStrings.t('dark_mode')),
                  subtitle: Text(AppStrings.t('reduce_eye_strain')),
                  value: _darkMode,
                  onChanged: (val) {
                    setState(() => _darkMode = val);
                    _saveSetting('dark_mode', _darkMode);
                    FidelisApp.of(context)?.setDarkMode(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Language
          _sectionHeader(AppStrings.t('app_language')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppStrings.t('app_language')),
              subtitle: Text(
                AppStrings.languages
                        .firstWhere((l) => l.$1 == AppStrings.locale,
                            orElse: () => ('en', 'English'))
                        .$2 +
                    ' — ' +
                    AppStrings.t('language_changed_note'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(context),
            ),
          ),

          const SizedBox(height: 24),

          // Liturgical Settings
          _sectionHeader(AppStrings.t('liturgical_data')),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(AppStrings.t('daily_readings_missal')),
                  subtitle: Text(
                    _missal == '1962'
                        ? AppStrings.t('traditional_1962_missal')
                        : AppStrings.t('novus_ordo_missal'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMissalPicker(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications
          _sectionHeader(AppStrings.t('section_notifications')),
          Card(
            child: Column(
              children: [
                // Daily Mass
                SwitchListTile(
                  title: Text(AppStrings.t('daily_mass_reminder')),
                  subtitle: Text('${AppStrings.t('remind_me_at')} ${_massTime.format(context)}'),
                  value: _massReminder,
                  onChanged: (val) {
                    setState(() => _massReminder = val);
                    _saveSetting('mass_reminder', val);
                    if (val) {
                      _scheduleMassReminder();
                    } else {
                      _cancelMassReminder();
                    }
                  },
                ),
                if (_massReminder)
                  ListTile(
                    title: Text(AppStrings.t('mass_reminder_time')),
                    trailing: Text(_massTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _massTime,
                      );
                      if (time != null) {
                        setState(() => _massTime = time);
                        _saveSetting('mass_hour', time.hour);
                        _saveSetting('mass_minute', time.minute);
                        _scheduleMassReminder();
                      }
                    },
                  ),

                const Divider(height: 1),

                // Daily Rosary
                SwitchListTile(
                  title: Text(AppStrings.t('daily_rosary_reminder')),
                  subtitle: Text('${AppStrings.t('remind_me_at')} ${_rosaryTime.format(context)}'),
                  value: _rosaryReminder,
                  onChanged: (val) {
                    setState(() => _rosaryReminder = val);
                    _saveSetting('rosary_reminder', val);
                    if (val) {
                      _scheduleRosaryReminder();
                    } else {
                      _cancelRosaryReminder();
                    }
                  },
                ),
                if (_rosaryReminder)
                  ListTile(
                    title: Text(AppStrings.t('rosary_reminder_time')),
                    trailing: Text(_rosaryTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _rosaryTime,
                      );
                      if (time != null) {
                        setState(() => _rosaryTime = time);
                        _saveSetting('rosary_hour', time.hour);
                        _saveSetting('rosary_minute', time.minute);
                        _scheduleRosaryReminder();
                      }
                    },
                  ),

                const Divider(height: 1),

                // Divine Mercy Chaplet
                SwitchListTile(
                  title: Text(AppStrings.t('divine_mercy_chaplet')),
                  subtitle: Text('${AppStrings.t('remind_me_at')} ${_chapletTime.format(context)} (${AppStrings.t('hour_of_mercy')})'),
                  value: _chapletReminder,
                  onChanged: (val) {
                    setState(() => _chapletReminder = val);
                    _saveSetting('chaplet_reminder', val);
                    if (val) {
                      _scheduleChapletReminder();
                    } else {
                      _cancelChapletReminder();
                    }
                  },
                ),
                if (_chapletReminder)
                  ListTile(
                    title: Text(AppStrings.t('chaplet_reminder_time')),
                    trailing: Text(_chapletTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _chapletTime,
                      );
                      if (time != null) {
                        setState(() => _chapletTime = time);
                        _saveSetting('chaplet_hour', time.hour);
                        _saveSetting('chaplet_minute', time.minute);
                        _scheduleChapletReminder();
                      }
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About
          _sectionHeader(AppStrings.t('about')),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Fidelis'),
                  subtitle: Text(AppStrings.t('traditional_catholic_app')),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(AppStrings.t('liturgical_data')),
                  subtitle: Text(
                    '1962 Missal: Missale Meum (MIT)\n'
                    'Novus Ordo: USCCB (bible.usccb.org)',
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () async {
                    final uri = Uri.parse('https://www.missalemeum.com');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(AppStrings.t('no_ads')),
                  subtitle: Text(AppStrings.t('prayer_is_sacred')),
                  leading: const Icon(Icons.block, color: FidelisTheme.deepRed),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _showMissalPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppStrings.t('select_missal'),
                style: TextStyle(
                  color: FidelisTheme.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history_edu, color: FidelisTheme.gold),
              title: Text(AppStrings.t('traditional_1962_missal')),
              subtitle: Text(AppStrings.t('tridentine_mass')),
              trailing: _missal == '1962' ? const Icon(Icons.check, color: FidelisTheme.gold) : null,
              onTap: () => Navigator.pop(context, '1962'),
            ),
            ListTile(
              leading: const Icon(Icons.church, color: Color(0xFF1565C0)),
              title: const Text('Novus Ordo (Current Roman Missal)'),
              subtitle: const Text('Ordinary Form — USCCB readings'),
              trailing: _missal == 'novus_ordo' ? const Icon(Icons.check, color: Color(0xFF1565C0)) : null,
              onTap: () => Navigator.pop(context, 'novus_ordo'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null && result != _missal) {
      setState(() => _missal = result);
      _saveSetting('missal', result);
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: FidelisTheme.gold,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}