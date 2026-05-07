import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static bool _initialized = false;

  // Channel IDs — using NEW IDs to bypass Android's cached channel settings
  static const _massChannelId = 'fidelis_mass_popup';
  static const _rosaryChannelId = 'fidelis_rosary_popup';
  static const _chapletChannelId = 'fidelis_chaplet_popup';

  // Notification IDs
  static const _massId = 1;
  static const _rosaryId = 2;
  static const _chapletId = 3;

  /// Initialize notifications and timezone data
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneInfo.identifier);
      tz.setLocalLocation(location);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationReceived(response);
      },
    );

    // Create notification channels with max importance for heads-up popups
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _massChannelId,
      'Mass Reminders',
      description: 'Daily reminder to prepare for Mass',
      importance: Importance.max,
      enableVibration: true,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _rosaryChannelId,
      'Rosary Reminders',
      description: 'Daily reminder to pray the Holy Rosary',
      importance: Importance.max,
      enableVibration: true,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _chapletChannelId,
      'Chaplet Reminders',
      description: 'Daily reminder to pray the Divine Mercy Chaplet',
      importance: Importance.max,
      enableVibration: true,
    ));

    // Request Android 13+ notification permission
    await androidPlugin?.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+)
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  /// Schedule daily Mass reminder
  static Future<void> scheduleMassReminder({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await initialize();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(id: _massId);
    if (!enabled) return;

    await plugin.zonedSchedule(
      id: _massId,
      title: 'Daily Mass',
      body: 'Prepare your heart for the Holy Sacrifice of the Mass.',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _massChannelId,
          'Mass Reminders',
          channelDescription: 'Daily reminder to prepare for Mass',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule daily rosary reminder
  static Future<void> scheduleRosaryReminder({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await initialize();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(id: _rosaryId);
    if (!enabled) return;

    await plugin.zonedSchedule(
      id: _rosaryId,
      title: 'Pray the Rosary',
      body: 'Our Lady awaits your daily rosary.',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _rosaryChannelId,
          'Rosary Reminders',
          channelDescription: 'Daily reminder to pray the Holy Rosary',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule Divine Mercy Chaplet reminder
  static Future<void> scheduleChapletReminder({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await initialize();
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(id: _chapletId);
    if (!enabled) return;

    await plugin.zonedSchedule(
      id: _chapletId,
      title: 'Divine Mercy Chaplet',
      body: 'It\'s the Hour of Mercy — pray the Chaplet.',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _chapletChannelId,
          'Chaplet Reminders',
          channelDescription: 'Daily reminder to pray the Divine Mercy Chaplet',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a novena daily reminder
  static Future<void> scheduleNovenaReminder({
    required int id,
    required String novenaTitle,
    required int day,
    required int hour,
    required int minute,
  }) async {
    await initialize();
    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.zonedSchedule(
      id: id,
      title: novenaTitle,
      body: 'Day $day of 9 — Continue your novena prayer.',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fidelis_novena',
          'Novena Reminders',
          channelDescription: 'Daily novena prayer reminders',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel a specific notification by id
  static Future<void> cancelNotification(int id) async {
    await initialize();
    await FlutterLocalNotificationsPlugin().cancel(id: id);
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAll() async {
    await initialize();
    await FlutterLocalNotificationsPlugin().cancelAll();
  }

  /// Get the next instance of a specific time (today or tomorrow if already passed)
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day, hour, minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Called when a notification is tapped
  static void _onNotificationReceived(NotificationResponse response) {
    // Notification tap handling — opens app via intent
  }
}