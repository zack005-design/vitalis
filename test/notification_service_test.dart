import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:calorie_sleep_tracker/services/notification_service.dart';

class FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  bool initializeCalled = false;
  InitializationSettings? capturedSettings;

  int? capturedZonedId;
  String? capturedZonedTitle;
  String? capturedZonedBody;
  tz.TZDateTime? capturedZonedScheduledDate;
  NotificationDetails? capturedZonedNotificationDetails;
  AndroidScheduleMode? capturedZonedScheduleMode;
  DateTimeComponents? capturedZonedMatchDateTimeComponents;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback? onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalled = true;
    capturedSettings = settings;
    return true;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    capturedZonedId = id;
    capturedZonedTitle = title;
    capturedZonedBody = body;
    capturedZonedScheduledDate = scheduledDate;
    capturedZonedNotificationDetails = notificationDetails;
    capturedZonedScheduleMode = androidScheduleMode;
    capturedZonedMatchDateTimeComponents = matchDateTimeComponents;
  }

  @override
  Future<void> periodicallyShow({
    required int id,
    String? title,
    String? body,
    required RepeatInterval repeatInterval,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
  }) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  T? resolvePlatformSpecificImplementation<
      T extends FlutterLocalNotificationsPlatform>() {
    return null;
  }
}

void main() {
  group('NotificationService - Initialization and Scheduling', () {
    test('initialize() initializes timezone database and plugin', () async {
      final fakePlugin = FakeFlutterLocalNotificationsPlugin();
      final service = NotificationService(notificationsPlugin: fakePlugin);

      await service.initialize();

      expect(fakePlugin.initializeCalled, isTrue);
      expect(fakePlugin.capturedSettings, isNotNull);
      // Verify timezones are initialized and accessible
      expect(tz.timeZoneDatabase.locations, isNotEmpty);
    });

    test('scheduleSleepWindDownPrompt() uses zonedSchedule for evening time with daily repeat', () async {
      final fakePlugin = FakeFlutterLocalNotificationsPlugin();
      final service = NotificationService(notificationsPlugin: fakePlugin);
      await service.initialize();

      await service.scheduleSleepWindDownPrompt(hour: 21, minute: 30);

      expect(fakePlugin.capturedZonedId, equals(99));
      expect(fakePlugin.capturedZonedTitle, equals('Evening Wind-Down'));
      expect(
        fakePlugin.capturedZonedBody,
        equals('Ready for rest? Take a moment to log your evening meals & notes.'),
      );
      expect(fakePlugin.capturedZonedScheduledDate, isNotNull);
      expect(fakePlugin.capturedZonedScheduledDate!.hour, equals(21));
      expect(fakePlugin.capturedZonedScheduledDate!.minute, equals(30));
      expect(
        fakePlugin.capturedZonedMatchDateTimeComponents,
        equals(DateTimeComponents.time),
      );
      expect(
        fakePlugin.capturedZonedScheduleMode,
        equals(AndroidScheduleMode.inexactAllowWhileIdle),
      );
    });
  });
}
