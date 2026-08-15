import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:calorie_sleep_tracker/data/local/app_database.dart';
import 'package:calorie_sleep_tracker/domain/food/food_providers.dart';
import 'package:calorie_sleep_tracker/ui/sleep/sleep_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Midnight Rollover & Food Providers', () {
    test('todayMealsProvider and todayWaterLogsProvider stream today entries', () async {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 8, 30);
      final yesterday = todayStart.subtract(const Duration(days: 1));

      // Insert meal for today and yesterday
      await db.insertMeal(MealsCompanion.insert(
        timestamp: todayStart,
        name: 'Breakfast Omelette',
        calories: 350,
      ));
      await db.insertMeal(MealsCompanion.insert(
        timestamp: yesterday,
        name: 'Yesterday Dinner',
        calories: 600,
      ));

      // Insert water log for today and yesterday
      await db.insertWaterLog(WaterLogsCompanion.insert(
        timestamp: todayStart,
        amountMl: 500,
      ));
      await db.insertWaterLog(WaterLogsCompanion.insert(
        timestamp: yesterday,
        amountMl: 750,
      ));

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      // Read today meals
      final meals = await container.read(todayMealsProvider.future);
      expect(meals.length, equals(1));
      expect(meals.first.name, equals('Breakfast Omelette'));
      expect(container.read(totalCaloriesTodayProvider), equals(350));

      // Read today water logs
      final waterLogs = await container.read(todayWaterLogsProvider.future);
      expect(waterLogs.length, equals(1));
      expect(waterLogs.first.amountMl, equals(500));
      expect(container.read(totalWaterMlTodayProvider), equals(500));
    });
  });

  group('Recent Sleep Logs Provider - Parameterized Limit', () {
    test('recentSleepLogsProvider respects 7 and 30 limit parameters', () async {
      final now = DateTime.now();

      // Insert 15 sleep notes
      for (int i = 0; i < 15; i++) {
        final date = now.subtract(Duration(days: i));
        await db.insertSleepNote(SleepNotesCompanion.insert(
          date: date,
          bedtime: Value(date.subtract(const Duration(hours: 8))),
          wakeTime: Value(date),
          durationMinutes: const Value(480),
          ratingStars: const Value(4),
          noteText: Value('Night $i'),
          createdAt: date,
        ));
      }

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final sleepLogs7 = await container.read(recentSleepLogsProvider(7).future);
      expect(sleepLogs7.length, equals(7));

      final sleepLogs30 = await container.read(recentSleepLogsProvider(30).future);
      expect(sleepLogs30.length, equals(15));
    });
  });

  group('SleepScreen UI Widget Tests', () {
    testWidgets('Displays 0h 0m and "No sleep recorded" when there are no sleep sessions', (tester) async {
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
            home: SleepScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsNWidgets(2)); // 0 h, 0 m
      expect(find.text('h '), findsOneWidget);
      expect(find.text('m'), findsOneWidget);
      expect(find.text('No sleep recorded • Goal 8h'), findsOneWidget);
      expect(find.text('No sleep sessions recorded'), findsOneWidget);
    });

    testWidgets('Displays last night actual duration in hero instead of average', (tester) async {
      final now = DateTime.now();

      // Insert 2 sleep notes:
      // Night 0 (most recent): 7 hours 15 mins (435 mins)
      // Night 1 (previous): 9 hours (540 mins)
      // Average would be (435 + 540) / 2 = 487 mins (8h 7m)
      // Hero MUST show 7h 15m (last night actual), Sleep Trend Avg shows 8h 7m
      await db.insertSleepNote(SleepNotesCompanion.insert(
        date: now.subtract(const Duration(days: 1)),
        bedtime: Value(now.subtract(const Duration(days: 1, hours: 9))),
        wakeTime: Value(now.subtract(const Duration(days: 1))),
        durationMinutes: const Value(540),
        ratingStars: const Value(4),
        createdAt: now.subtract(const Duration(days: 1)),
      ));

      await db.insertSleepNote(SleepNotesCompanion.insert(
        date: now,
        bedtime: Value(now.subtract(const Duration(hours: 7, minutes: 15))),
        wakeTime: Value(now),
        durationMinutes: const Value(435),
        ratingStars: const Value(5),
        createdAt: now,
      ));

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
            home: SleepScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hero should show 7h 15m
      expect(find.text('7'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Last Night • Goal 8h'), findsOneWidget);

      // Trend Card should display Avg 8h 7m
      expect(find.text('Avg 8h 7m'), findsOneWidget);
    });

    testWidgets('Toggling range selector between 7d and 30d updates the view', (tester) async {
      final now = DateTime.now();

      for (int i = 0; i < 10; i++) {
        final date = now.subtract(Duration(days: i));
        await db.insertSleepNote(SleepNotesCompanion.insert(
          date: date,
          bedtime: Value(date.subtract(const Duration(hours: 8))),
          wakeTime: Value(date),
          durationMinutes: const Value(480),
          ratingStars: const Value(4),
          createdAt: date,
        ));
      }

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
            home: SleepScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find 30d segment toggle and tap it
      final segment30d = find.text('30d');
      expect(segment30d, findsOneWidget);

      await tester.tap(segment30d);
      await tester.pumpAndSettle();

      // Verify that the view settled and shows 30d data
      expect(find.text('Sleep Trend'), findsOneWidget);
      expect(find.text('Avg 8h 0m'), findsOneWidget);
    });
  });
}
