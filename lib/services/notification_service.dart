import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  NotificationService({FlutterLocalNotificationsPlugin? notificationsPlugin})
      : _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Fallback if platform channel is not available (e.g. unit tests)
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings: initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a recurring hourly water reminder notification (7AM–10PM only)
  Future<void> scheduleHourlyWaterReminders() async {
    // Cancel any existing water reminders before rescheduling
    await _notificationsPlugin.cancel(id: 0);

    final now = tz.TZDateTime.now(tz.local);
    final hour = now.hour;

    // Only schedule if within quiet hours window (7AM to 10PM)
    if (hour >= 7 && hour < 22) {
      const androidDetails = AndroidNotificationDetails(
        'water_reminders_channel',
        'Water Reminders',
        channelDescription: 'Hourly reminders to log water intake (7AM–10PM only)',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.periodicallyShow(
        id: 0,
        title: '💧 Hydration Reminder',
        body: 'Time to drink 250ml of water to hit your daily goal!',
        repeatInterval: RepeatInterval.hourly,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      // Also schedule the evening sleep wind-down (9:30 PM by default)
      await scheduleSleepWindDownPrompt();
    }
  }

  /// Reschedule water reminders — call at app startup and at 7AM each day
  Future<void> rescheduleWaterRemindersIfNeeded() async {
    final now = tz.TZDateTime.now(tz.local);
    final hour = now.hour;
    // Cancel outside quiet hours, start inside
    if (hour >= 7 && hour < 22) {
      await scheduleHourlyWaterReminders();
    } else {
      await _notificationsPlugin.cancel(id: 0);
    }
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Schedule a one-time water reminder (legacy)
  Future<void> scheduleWaterReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminders_channel',
      'Water Reminders',
      channelDescription: 'Offline reminders to log water intake',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Schedule evening sleep wind-down reminder
  Future<void> scheduleSleepWindDownPrompt({
    int hour = 21,
    int minute = 30,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sleep_reminders_channel',
      'Sleep Reminders',
      channelDescription: 'Offline prompts to log sleep & wind down',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: 99,
      title: 'Evening Wind-Down',
      body: "Ready for rest? Take a moment to log your evening meals & notes.",
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
