import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings: initSettings);
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule a recurring hourly water reminder notification
  Future<void> scheduleHourlyWaterReminders() async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminders_channel',
      'Water Reminders',
      channelDescription: 'Hourly reminders to log water intake',
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
  Future<void> scheduleSleepWindDownPrompt() async {
    const androidDetails = AndroidNotificationDetails(
      'sleep_reminders_channel',
      'Sleep Reminders',
      channelDescription: 'Offline prompts to log sleep & wind down',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 99,
      title: 'Evening Wind-Down',
      body: "Ready for rest? Take a moment to log your evening meals & notes.",
      notificationDetails: details,
    );
  }
}
