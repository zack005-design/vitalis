import 'package:calorie_sleep_tracker/domain/food/food_providers.dart';
import 'package:calorie_sleep_tracker/ui/design_system/bottom_sheet_modal.dart';
import 'package:calorie_sleep_tracker/ui/design_system/swipe_to_delete_row.dart';
import 'package:calorie_sleep_tracker/ui/more/edit_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_sleep_tracker/domain/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EditProfileSheet Biological Sex & Female BMR UI Tests', () {
    testWidgets('Defaults to Male, toggles to Female, and recomputes TDEE target live', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Biological Sex selector label and options exist
      expect(find.text('Biological Sex'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);

      // Default values: 28 yrs, 175 cm, 72 kg, Moderate (1.55)
      // Male BMR = 10*72 + 6.25*175 - 5*28 + 5 = 1678.75 -> TDEE = (1678.75 * 1.55).round() = 2602
      expect(find.text('Calculated TDEE Target: 2602 kcal/day'), findsOneWidget);

      // Tap "Female"
      final femaleOption = find.text('Female');
      await tester.tap(femaleOption);
      await tester.pumpAndSettle();

      // Female BMR = 10*72 + 6.25*175 - 5*28 - 161 = 1512.75 -> TDEE = (1512.75 * 1.55).round() = 2345
      expect(find.text('Calculated TDEE Target: 2345 kcal/day'), findsOneWidget);

      // Tap "Update Profile & Goals" button to save
      final saveButton = find.text('Update Profile & Goals');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify saved in SharedPreferences
      expect(prefs.getString('profile_sex'), equals('Female'));
      expect(prefs.getString('profile_gender'), equals('Female'));
      expect(prefs.getInt('target_calories'), equals(2345));
    });

    testWidgets('Loads stored Female sex from SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({
        'profile_name': 'Sarah Connor',
        'profile_age': 30,
        'profile_height': 165.0,
        'profile_weight': 60.0,
        'profile_sex': 'Female',
        'profile_activity': 'Active',
      });

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Female 60kg, 165cm, 30yo, Active (1.725)
      // BMR = 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
      // TDEE = (1320.25 * 1.725).round() = 2277
      expect(find.text('Calculated TDEE Target: 2277 kcal/day'), findsOneWidget);
    });
  });

  group('SwipeToDeleteRow Design System Component Tests', () {
    testWidgets('Triggers onDelete on swipe dismiss and triggers onUndo callback when undo action tapped', (tester) async {
      bool deleted = false;
      bool undid = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                SwipeToDeleteRow(
                  itemKey: const ValueKey('item-1'),
                  title: 'Apple',
                  onDelete: () {
                    deleted = true;
                  },
                  onUndo: () {
                    undid = true;
                  },
                  child: const ListTile(title: Text('Apple')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);

      // Swipe to delete (DismissDirection.endToStart)
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
      expect(find.text('Deleted "Apple"'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo in SnackBar
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(undid, isTrue);
    });

    testWidgets('Does not show SnackBar action if onUndo is null', (tester) async {
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                SwipeToDeleteRow(
                  itemKey: const ValueKey('item-2'),
                  title: 'Banana',
                  onDelete: () {
                    deleted = true;
                  },
                  child: const ListTile(title: Text('Banana')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
      expect(find.text('Deleted "Banana"'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });
  });

  group('BottomSheetModal Actions Rendering Tests', () {
    testWidgets('Renders action widgets in the header row when provided', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomSheetModal(
              title: 'Settings Modal',
              actions: [
                IconButton(
                  key: const Key('custom_action_btn'),
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    actionTapped = true;
                  },
                ),
              ],
              child: const Text('Modal Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings Modal'), findsOneWidget);
      expect(find.text('Modal Content'), findsOneWidget);
      expect(find.byKey(const Key('custom_action_btn')), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);

      // Tap custom action
      await tester.tap(find.byKey(const Key('custom_action_btn')));
      expect(actionTapped, isTrue);
    });
  });
}
