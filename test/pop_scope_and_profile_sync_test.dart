import 'package:calorie_sleep_tracker/data/local/app_database.dart';
import 'package:calorie_sleep_tracker/domain/food/food_providers.dart';
import 'package:calorie_sleep_tracker/domain/profile/profile_provider.dart';
import 'package:calorie_sleep_tracker/domain/shared_preferences_provider.dart';
import 'package:calorie_sleep_tracker/ui_legacy/more/edit_profile_sheet.dart';
import 'package:calorie_sleep_tracker/ui_v2/main_navigation_shell.dart';
import 'package:calorie_sleep_tracker/ui_v2/more/more_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('UserProfileNotifier Unit Tests', () {
    test('Loads default values when SharedPreferences is empty', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = UserProfileNotifier(prefs);

      expect(notifier.state.name, equals('Alex Johnson'));
      expect(notifier.state.age, equals(28));
      expect(notifier.state.height, equals(175.0));
      expect(notifier.state.weight, equals(72.0));
      expect(notifier.state.activityLevel, equals('Moderate'));
      expect(notifier.state.sex, equals('Male'));
      expect(notifier.state.useAiNarration, isTrue);
      expect(notifier.state.enableReminders, isTrue);
    });

    test('updateProfile updates state and persists all fields to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = UserProfileNotifier(prefs);

      await notifier.updateProfile(
        name: 'Jane Doe',
        age: 32,
        height: 168.0,
        weight: 64.0,
        activityLevel: 'Active',
        sex: 'Female',
      );

      expect(notifier.state.name, equals('Jane Doe'));
      expect(notifier.state.age, equals(32));
      expect(notifier.state.height, equals(168.0));
      expect(notifier.state.weight, equals(64.0));
      expect(notifier.state.activityLevel, equals('Active'));
      expect(notifier.state.sex, equals('Female'));

      expect(prefs.getString('profile_name'), equals('Jane Doe'));
      expect(prefs.getInt('profile_age'), equals(32));
      expect(prefs.getDouble('profile_height'), equals(168.0));
      expect(prefs.getDouble('profile_weight'), equals(64.0));
      expect(prefs.getString('profile_activity'), equals('Active'));
      expect(prefs.getString('profile_sex'), equals('Female'));
      expect(prefs.getString('profile_gender'), equals('Female'));
    });

    test('setAiNarration and setReminders update state and persist to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = UserProfileNotifier(prefs);

      await notifier.setAiNarration(false);
      expect(notifier.state.useAiNarration, isFalse);
      expect(prefs.getBool('pref_ai_narration'), isFalse);

      await notifier.setReminders(false);
      expect(notifier.state.enableReminders, isFalse);
      expect(prefs.getBool('pref_reminders'), isFalse);

      await notifier.setAiNarration(true);
      expect(notifier.state.useAiNarration, isTrue);
      expect(prefs.getBool('pref_ai_narration'), isTrue);
    });

    test('reload restores state modified in SharedPreferences externally', () async {
      final prefs = await SharedPreferences.getInstance();
      final notifier = UserProfileNotifier(prefs);

      await prefs.setString('profile_name', 'External Update');
      await prefs.setInt('profile_age', 40);
      notifier.reload();

      expect(notifier.state.name, equals('External Update'));
      expect(notifier.state.age, equals(40));
    });
  });

  group('MainNavigationShell PopScope Widget Tests', () {
    testWidgets('PopScope intercepts back button and navigates to Today tab (index 0) if on other tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();

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

      // Starts at index 0 (Today)
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);
      IndexedStack indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0));

      // Tap More tab (icon: person_rounded, index 4)
      final moreTab = find.byIcon(Icons.person_rounded).last;
      expect(moreTab, findsOneWidget);
      await tester.tap(moreTab);
      await tester.pump();

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(4));

      // Simulate Android back button press
      final popHandled = await tester.binding.handlePopRoute();
      await tester.pump();

      expect(popHandled, isTrue);

      // Verify returned to tab 0 (Today)
      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0));

      // Now switch to Sleep tab (icon: nightlight_round, index 1)
      final sleepTab = find.byIcon(Icons.bedtime_rounded).last;
      await tester.tap(sleepTab);
      await tester.pump();

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(1));

      // Simulate back press again
      await tester.binding.handlePopRoute();
      await tester.pump();

      // Verify returned to tab 0 again
      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('PopScope allows exit when at index 0 and intercepts when at other tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();

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

      final indexedStackFinder = find.byType(IndexedStack);
      IndexedStack indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0));

      // Switch to More tab (index 4)
      final moreTab = find.byIcon(Icons.person_rounded).last;
      await tester.tap(moreTab);
      await tester.pump();

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(4));

      // Pop while on tab 4 -> intercepts and returns true
      final intercepted = await tester.binding.handlePopRoute();
      await tester.pump();
      expect(intercepted, isTrue);

      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, equals(0));

      // Pop while on tab 0 -> allows exit (handlePopRoute returns false)
      final allowsExit = await tester.binding.handlePopRoute();
      await tester.pump();
      expect(allowsExit, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Profile and Target Sync Widget Tests', () {
    testWidgets('MoreScreen displays profile and reactively updates on profile modification', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'profile_name': 'Original Name',
        'profile_age': 25,
        'profile_height': 170.0,
        'profile_weight': 70.0,
        'profile_sex': 'Male',
        'profile_activity': 'Sedentary',
        'target_calories': 2000,
        'target_water_ml': 2500,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MoreScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Original Name'), findsOneWidget);
      expect(find.text('Male • 25 yrs • 170 cm • 70 kg • Sedentary'), findsOneWidget);
      expect(find.text('Daily Target: 2000 kcal • 2.5L'), findsOneWidget);

      // Mutate profile via provider directly to verify reactive UI sync
      await container.read(userProfileProvider.notifier).updateProfile(
        name: 'Updated Name',
        age: 26,
        sex: 'Female',
      );
      await tester.pump();

      expect(find.text('Updated Name'), findsOneWidget);
      expect(find.text('Female • 26 yrs • 170 cm • 70 kg • Sedentary'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Toggling AI Insights and Reminders in MoreScreen updates state without race condition', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'pref_ai_narration': true,
        'pref_reminders': true,
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: MoreScreen(),
          ),
        ),
      );
      await tester.pump();

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      // Toggle AI Narration switch
      await tester.tap(switches.first);
      await tester.pump();

      expect(container.read(userProfileProvider).useAiNarration, isFalse);
      expect(prefs.getBool('pref_ai_narration'), isFalse);

      // Toggle Reminders switch
      await tester.tap(switches.last);
      await tester.pump();

      expect(container.read(userProfileProvider).enableReminders, isFalse);
      expect(prefs.getBool('pref_reminders'), isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('EditProfileSheet saves changes to UserProfileNotifier and CalorieTargetNotifier', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Switch to Female
      await tester.tap(find.text('Female'));
      await tester.pump();

      // Tap save
      final saveBtn = find.text('Update Profile & Goals');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      // Verify UserProfile state updated
      expect(container.read(userProfileProvider).sex, equals('Female'));
      expect(prefs.getString('profile_sex'), equals('Female'));
      expect(prefs.getString('profile_gender'), equals('Female'));
      // Verify CalorieTarget state updated
      expect(container.read(calorieTargetProvider), equals(2345));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
