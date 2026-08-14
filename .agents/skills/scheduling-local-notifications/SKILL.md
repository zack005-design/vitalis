---
name: scheduling-local-notifications
description: Configures flutter_local_notifications for offline Android reminders (water intake, meal logging, evening sleep wind-down prompts). Use when implementing local reminders, notification channels, or offline alarms in Flutter.
---

# Scheduling Local Notifications

## When to use this skill
- Adding optional offline local reminders for water intake or meal logging.
- Configuring Android notification channels (`AndroidManifest.xml` & Flutter startup).
- Scheduling recurring daily alarms without cloud services.

## Workflow Checklist
- [ ] Declare `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` in `AndroidManifest.xml`.
- [ ] Declare `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>` (if exact alarms are needed).
- [ ] Initialize `FlutterLocalNotificationsPlugin` in `main.dart`.
- [ ] Define notification channels (e.g. `water_reminders`, `sleep_reminders`).

## Code Pattern: Local Notification Helper

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
  }

  Future<void> showWaterReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminders',
      'Water Reminders',
      channelDescription: 'Reminders to log daily hydration intake',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      101,
      'Time to Hydrate 💧',
      'Log your latest water glass to stay on track today.',
      details,
    );
  }
}
```
