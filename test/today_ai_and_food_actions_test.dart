import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_sleep_tracker/domain/food/food_providers.dart';
import 'package:calorie_sleep_tracker/domain/insights/tier_a_rule_engine.dart';
import 'package:calorie_sleep_tracker/domain/shared_preferences_provider.dart';
import 'package:calorie_sleep_tracker/ui/today/today_screen.dart';
import 'package:calorie_sleep_tracker/ui/food/food_screen.dart';
import 'package:calorie_sleep_tracker/ui/food/food_search_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TodayScreen AI Vitality Card Tests', () {
    testWidgets('Renders AI Vitality Coach Card with dynamic narrative', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeInsight = const HealthSummaryInsight(
        title: "Optimal Metabolic Alignment",
        description: "All 3 vitality markers (Calories, Water, Sleep) are within target ranges today.",
        recommendation: "Maintain this consistent rhythm for improved metabolic efficiency.",
        category: "balance",
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            dailyHealthInsightProvider.overrideWith((ref) => fakeInsight),
          ],
          child: const MaterialApp(
            home: TodayScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("AI VITALITY COACH"), findsOneWidget);
      expect(find.text("Optimal Metabolic Alignment"), findsOneWidget);
      expect(find.text("Maintain this consistent rhythm for improved metabolic efficiency."), findsOneWidget);
    });
  });

  group('Food Quick Actions and Search Provider Tests', () {
    testWidgets('FoodScreen renders 4 action tiles: My Meals, Favorites, Quick Add, Custom Dish', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: FoodScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("My Meals"), findsOneWidget);
      expect(find.text("Favorites"), findsOneWidget);
      expect(find.text("Quick Add"), findsOneWidget);
      expect(find.text("Custom Dish"), findsOneWidget);
    });

    testWidgets('FoodSearchSheet renders category filter chips and empty states', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            foodSearchResultsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: FoodSearchSheet(initialCategory: 'Favorites'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Favorites"), findsWidgets);
      expect(find.text("No favorite foods yet"), findsOneWidget);
    });
  });
}
