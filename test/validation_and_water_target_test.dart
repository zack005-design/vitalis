import 'package:calorie_sleep_tracker/data/local/app_database.dart';
import 'package:calorie_sleep_tracker/domain/food/food_providers.dart';
import 'package:calorie_sleep_tracker/ui/food/add_custom_food_sheet.dart';
import 'package:calorie_sleep_tracker/ui/today/water_history_sheet.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_sleep_tracker/domain/shared_preferences_provider.dart';

class MockWaterTargetNotifier extends StateNotifier<int> implements WaterTargetNotifier {
  @override
  late final SharedPreferences prefs;

  MockWaterTargetNotifier(super.state);

  @override
  Future<void> setTarget(int target) async {
    state = target;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AddCustomFoodSheet Macro Validation UI', () {
    testWidgets('Displays macro validation errors in red when invalid values are entered', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AddCustomFoodSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no error texts are present
      expect(find.text('Name is required'), findsNothing);
      expect(find.text('Enter a number > 0'), findsNothing);
      expect(find.text('Enter 0–500g'), findsNothing);

      // Enter valid name and calories, but invalid macros (>500)
      final textFields = find.byType(TextField);
      // Food Name (index 0)
      await tester.enterText(textFields.at(0), 'Protein Shake');
      // Serving Size (index 1)
      // Calories (index 2)
      await tester.enterText(textFields.at(2), '300');
      // Protein (index 3)
      await tester.enterText(textFields.at(3), '600');
      // Carbs (index 4)
      await tester.enterText(textFields.at(4), '999');
      // Fat (index 5)
      await tester.enterText(textFields.at(5), '501');

      await tester.pumpAndSettle();

      // Tap Save to Library button to trigger validation
      final saveButton = find.text('Save to Library');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Error messages for macros should now be visible
      expect(find.text('Enter 0–500g'), findsNWidgets(3));

      // Check text color is red
      final errorWidgets = tester.widgetList<Text>(find.text('Enter 0–500g'));
      for (final textWidget in errorWidgets) {
        expect(textWidget.style?.color, equals(Colors.red));
      }

      // Now fix the macro values to valid ones
      await tester.enterText(textFields.at(3), '30');
      await tester.enterText(textFields.at(4), '20');
      await tester.enterText(textFields.at(5), '5');
      await tester.pumpAndSettle();

      // Tap Save to Library again
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Error messages should be gone
      expect(find.text('Enter 0–500g'), findsNothing);

      // Verify custom food was stored in database
      final customFoods = await db.select(db.customFoods).get();
      expect(customFoods.length, equals(1));
      expect(customFoods.first.name, equals('Protein Shake'));
      expect(customFoods.first.caloriesPerServing, equals(300));
      expect(customFoods.first.proteinG, equals(30.0));
      expect(customFoods.first.carbsG, equals(20.0));
      expect(customFoods.first.fatG, equals(5.0));
    });

    testWidgets('Displays required name and calorie errors when empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AddCustomFoodSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save to Library with empty fields
      final saveButton = find.text('Save to Library');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Enter a number > 0'), findsOneWidget);
    });
  });

  group('WaterHistorySheet Dynamic Target UI', () {
    testWidgets('Displays dynamic water target from waterTargetProvider (default 2000ml -> 2.0L)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            todayWaterLogsProvider.overrideWith((ref) => Stream.value([])),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WaterHistorySheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0.0L / 2.0L'), findsOneWidget);
    });

    testWidgets('Displays dynamic custom water target (2500ml -> 2.5L)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            todayWaterLogsProvider.overrideWith((ref) => Stream.value([])),
            waterTargetProvider.overrideWith((ref) => MockWaterTargetNotifier(2500)),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WaterHistorySheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0.0L / 2.5L'), findsOneWidget);
    });

    testWidgets('Displays dynamic custom water target (3200ml -> 3.2L) and reflects logged water', (tester) async {
      final now = DateTime.now();
      final sampleLog = WaterLog(
        id: 1,
        amountMl: 750,
        timestamp: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            todayWaterLogsProvider.overrideWith((ref) => Stream.value([sampleLog])),
            waterTargetProvider.overrideWith((ref) => MockWaterTargetNotifier(3200)),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WaterHistorySheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 750ml -> 0.8L (due to toStringAsFixed(1)) / 3.2L
      expect(find.text('0.8L / 3.2L'), findsOneWidget);
      expect(find.text('750 ml'), findsOneWidget);
    });
  });
}
