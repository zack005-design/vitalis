import 'dart:math';
import 'package:calorie_sleep_tracker/data/local/app_database.dart';
import 'package:calorie_sleep_tracker/domain/food/food_providers.dart';
import 'package:calorie_sleep_tracker/domain/shared_preferences_provider.dart';
import 'package:calorie_sleep_tracker/ui/design_system/app_colors.dart';
import 'package:calorie_sleep_tracker/ui/design_system/segmented_control.dart';
import 'package:calorie_sleep_tracker/ui/main_navigation_shell.dart';
import 'package:calorie_sleep_tracker/ui/food/food_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper to compute WCAG 2.1 contrast ratio between two colors using Flutter's computeLuminance.
double _contrastRatio(Color c1, Color c2) {
  final l1 = c1.computeLuminance();
  final l2 = c2.computeLuminance();
  final lighter = max(l1, l2);
  final darker = min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
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

  group('WCAG Contrast Ratios (AppColors)', () {
    test('lightTextMuted meets WCAG AA 4.5:1 ratio against light backgrounds', () {
      final ratioAgainstBg = _contrastRatio(AppColors.lightTextMuted, AppColors.lightBackground);
      final ratioAgainstSurface = _contrastRatio(AppColors.lightTextMuted, AppColors.lightSurface);

      expect(ratioAgainstBg, greaterThanOrEqualTo(4.5),
          reason: 'lightTextMuted vs lightBackground must achieve >= 4.5:1 contrast');
      expect(ratioAgainstSurface, greaterThanOrEqualTo(4.5),
          reason: 'lightTextMuted vs lightSurface must achieve >= 4.5:1 contrast');
    });

    test('darkTextMuted meets WCAG AA 4.5:1 ratio against dark surfaces', () {
      final ratioAgainstBg = _contrastRatio(AppColors.darkTextMuted, AppColors.darkBackground);
      final ratioAgainstSurface = _contrastRatio(AppColors.darkTextMuted, AppColors.darkSurface);
      final ratioAgainstSurfaceHighest = _contrastRatio(AppColors.darkTextMuted, AppColors.darkSurfaceHighest);

      expect(ratioAgainstBg, greaterThanOrEqualTo(4.5),
          reason: 'darkTextMuted vs darkBackground must achieve >= 4.5:1 contrast');
      expect(ratioAgainstSurface, greaterThanOrEqualTo(4.5),
          reason: 'darkTextMuted vs darkSurface must achieve >= 4.5:1 contrast');
      expect(ratioAgainstSurfaceHighest, greaterThanOrEqualTo(4.5),
          reason: 'darkTextMuted vs darkSurfaceHighest must achieve >= 4.5:1 contrast');
    });
  });

  group('MainNavigationShell Semantics & Touch Targets', () {
    testWidgets('Renders accessible semantics for all navigation items', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: MainNavigationShell(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify all 5 tab semantics exist
      for (final label in ['Today', 'Sleep', 'Insights', 'Food', 'More']) {
        final semanticsFinder = find.byWidgetPredicate((widget) {
          if (widget is Semantics) {
            return widget.properties.label == label && widget.properties.button == true;
          }
          return false;
        });
        expect(semanticsFinder, findsOneWidget, reason: 'Tab "$label" must have Semantics(button: true, label: "$label")');
      }

      // Today tab should be selected initially
      final todaySemantics = tester.widget<Semantics>(find.byWidgetPredicate((widget) {
        return widget is Semantics && widget.properties.label == 'Today';
      }));
      expect(todaySemantics.properties.selected, isTrue);

      final foodSemantics = tester.widget<Semantics>(find.byWidgetPredicate((widget) {
        return widget is Semantics && widget.properties.label == 'Food';
      }));
      expect(foodSemantics.properties.selected, isFalse);

      // Tap the Food tab
      await tester.tap(find.byWidgetPredicate((widget) {
        return widget is Semantics && widget.properties.label == 'Food';
      }));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now Food tab should be selected
      final foodSemanticsAfterTap = tester.widget<Semantics>(find.byWidgetPredicate((widget) {
        return widget is Semantics && widget.properties.label == 'Food';
      }));
      expect(foodSemanticsAfterTap.properties.selected, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('SegmentedControl Semantics', () {
    testWidgets('Renders Semantics buttons and responds to taps', (tester) async {
      String selected = '7d';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SegmentedControl<String>(
                options: const {'7d': '7D', '30d': '30D', '90d': '90D'},
                selectedValue: selected,
                onValueChanged: (val) {
                  setState(() => selected = val);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check semantics buttons exist
      for (final label in ['7D', '30D', '90D']) {
        final semFinder = find.byWidgetPredicate((w) {
          return w is Semantics && w.properties.label == label && w.properties.button == true;
        });
        expect(semFinder, findsOneWidget);
      }

      // Initial selected state
      final sel7d = tester.widget<Semantics>(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '7D'));
      expect(sel7d.properties.selected, isTrue);

      final sel30d = tester.widget<Semantics>(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '30D'));
      expect(sel30d.properties.selected, isFalse);

      // Tap 30D
      await tester.tap(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '30D'));
      await tester.pumpAndSettle();

      expect(selected, '30d');
      final sel30dAfter = tester.widget<Semantics>(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == '30D'));
      expect(sel30dAfter.properties.selected, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('FoodScreen Accessibility & Action Tiles', () {
    testWidgets('Renders search bar and action tiles with accessible semantics', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: FoodScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Search Bar semantics
      final searchSemantics = find.byWidgetPredicate((w) {
        return w is Semantics && w.properties.label == 'Search foods, meals, or dishes' && w.properties.button == true;
      });
      expect(searchSemantics, findsOneWidget);

      // Action Tiles semantics
      for (final tileLabel in ['My Meals', 'Favorites', 'Quick Add', 'Custom Dish']) {
        final tileSemantics = find.byWidgetPredicate((w) {
          return w is Semantics && w.properties.label == tileLabel && w.properties.button == true;
        });
        expect(tileSemantics, findsOneWidget, reason: 'Action tile "$tileLabel" must have Semantics(button: true, label: "$tileLabel")');
      }

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
