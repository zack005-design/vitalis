import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_sleep_tracker/data/local/app_database.dart';
import 'package:calorie_sleep_tracker/domain/food/food_providers.dart';
import 'package:calorie_sleep_tracker/ui/sleep/log_sleep_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('calculateSleepRange Unit Tests', () {
    test('Overnight sleep logged in the morning anchors bedtime to yesterday', () {
      final now = DateTime(2026, 8, 15, 8, 0); // 8:00 AM on Aug 15
      const bedtime = TimeOfDay(hour: 22, minute: 30); // 10:30 PM
      const wakeTime = TimeOfDay(hour: 6, minute: 30); // 6:30 AM

      final range = calculateSleepRange(bedtime, wakeTime, now: now);

      expect(range.bed, equals(DateTime(2026, 8, 14, 22, 30)));
      expect(range.wake, equals(DateTime(2026, 8, 15, 6, 30)));
      expect(range.durationMinutes, equals(480));
      expect(range.bed.isBefore(now), isTrue);
      expect(range.wake.isBefore(now), isTrue);
    });

    test('Overnight sleep logged in the evening anchors bedtime to yesterday and wake to today', () {
      final now = DateTime(2026, 8, 15, 20, 0); // 8:00 PM on Aug 15
      const bedtime = TimeOfDay(hour: 23, minute: 0); // 11:00 PM
      const wakeTime = TimeOfDay(hour: 7, minute: 0); // 7:00 AM

      final range = calculateSleepRange(bedtime, wakeTime, now: now);

      expect(range.bed, equals(DateTime(2026, 8, 14, 23, 0)));
      expect(range.wake, equals(DateTime(2026, 8, 15, 7, 0)));
      expect(range.durationMinutes, equals(480));
      expect(range.bed.isBefore(now), isTrue);
      expect(range.wake.isBefore(now), isTrue);
    });

    test('Post-midnight bedtime logged in morning keeps both timestamps on today', () {
      final now = DateTime(2026, 8, 15, 9, 0); // 9:00 AM on Aug 15
      const bedtime = TimeOfDay(hour: 1, minute: 30); // 1:30 AM
      const wakeTime = TimeOfDay(hour: 7, minute: 30); // 7:30 AM

      final range = calculateSleepRange(bedtime, wakeTime, now: now);

      expect(range.bed, equals(DateTime(2026, 8, 15, 1, 30)));
      expect(range.wake, equals(DateTime(2026, 8, 15, 7, 30)));
      expect(range.durationMinutes, equals(360));
      expect(range.bed.isBefore(now), isTrue);
      expect(range.wake.isBefore(now), isTrue);
    });

    test('Afternoon nap logged after wake time keeps both timestamps on today', () {
      final now = DateTime(2026, 8, 15, 17, 0); // 5:00 PM on Aug 15
      const bedtime = TimeOfDay(hour: 14, minute: 0); // 2:00 PM
      const wakeTime = TimeOfDay(hour: 15, minute: 30); // 3:30 PM

      final range = calculateSleepRange(bedtime, wakeTime, now: now);

      expect(range.bed, equals(DateTime(2026, 8, 15, 14, 0)));
      expect(range.wake, equals(DateTime(2026, 8, 15, 15, 30)));
      expect(range.durationMinutes, equals(90));
      expect(range.bed.isBefore(now), isTrue);
      expect(range.wake.isBefore(now), isTrue);
    });

    test('Afternoon nap logged in morning shifts both timestamps to yesterday', () {
      final now = DateTime(2026, 8, 15, 8, 0); // 8:00 AM on Aug 15
      const bedtime = TimeOfDay(hour: 14, minute: 0); // 2:00 PM
      const wakeTime = TimeOfDay(hour: 15, minute: 30); // 3:30 PM

      final range = calculateSleepRange(bedtime, wakeTime, now: now);

      expect(range.bed, equals(DateTime(2026, 8, 14, 14, 0)));
      expect(range.wake, equals(DateTime(2026, 8, 14, 15, 30)));
      expect(range.durationMinutes, equals(90));
      expect(range.bed.isBefore(now), isTrue);
      expect(range.wake.isBefore(now), isTrue);
    });

    test('Month/Year boundary: Jan 1 morning log anchors bedtime to Dec 31 previous year', () {
      final now = DateTime(2026, 1, 1, 8, 0); // 8:00 AM on Jan 1, 2026
      const bedtime = TimeOfDay(hour: 23, minute: 0); // 11:00 PM
      const wakeTime = TimeOfDay(hour: 7, minute: 0); // 7:00 AM

      final range = calculateSleepRange(bedtime, wakeTime, now: now);

      expect(range.bed, equals(DateTime(2025, 12, 31, 23, 0)));
      expect(range.wake, equals(DateTime(2026, 1, 1, 7, 0)));
      expect(range.durationMinutes, equals(480));
    });
  });

  group('LogSleepSheet Widget & Integration Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Displays 8h 0m duration banner by default and saves valid sleep record to database', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: LogSleepSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check default duration
      expect(find.text('8h 0m'), findsOneWidget);
      expect(find.text('Total sleep duration'), findsOneWidget);

      // Enter optional notes
      final noteField = find.byType(TextField);
      expect(noteField, findsOneWidget);
      await tester.enterText(noteField, 'Felt energized and well-rested');
      await tester.pump();

      // Tap Save Sleep Session button
      final saveButton = find.text('Save Sleep Session');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify database contents
      final notes = await db.getAllSleepNotes();
      expect(notes.length, equals(1));
      final saved = notes.first;

      expect(saved.durationMinutes, equals(480));
      expect(saved.noteText, equals('Felt energized and well-rested'));
      expect(saved.bedtime, isNotNull);
      expect(saved.wakeTime, isNotNull);
      expect(saved.wakeTime!.isAfter(saved.bedtime!), isTrue);
      expect(saved.wakeTime!.difference(saved.bedtime!).inMinutes, equals(480));
    });
  });
}
