# Task 1 Report

## What was implemented
- Added a `PopScope` to `MainNavigationShell` in `lib/ui/main_navigation_shell.dart` to properly handle Android back-button behavior. If the current index is not 0, it routes back to the 'Today' tab (index 0). If the current index is 0, it exits the app.
- Unified the profile state by creating a `UserProfile` model and `UserProfileNotifier` at `lib/domain/profile/profile_provider.dart`.
- Refactored `more_screen.dart` and `edit_profile_sheet.dart` to listen to and mutate `userProfileProvider` directly, eliminating manual `_loadPrefs()` loading in `initState` and removing bypassed direct `SharedPreferences.getInstance()` calls.
- Injected `SharedPreferences` synchronously via `sharedPreferencesProvider` at the root `ProviderScope`, avoiding target flashing on startup across all notifiers (`CalorieTargetNotifier`, `WaterTargetNotifier`, `UserProfileNotifier`).

## Review 1 Feedback & Fixes Applied

1. **Compilation error in `test/female_bmr_and_design_system_test.dart`:**
   - Removed the duplicate `final prefs = await SharedPreferences.getInstance();` variable declaration on line 61.

2. **Async race condition in `more_screen.dart` toggles:**
   - Removed un-awaited local `_saveAiNarration` and `_saveReminders` helper methods.
   - Wired the switches directly to `UserProfileNotifier` methods (`await ref.read(userProfileProvider.notifier).setAiNarration(val)` and `await ref.read(userProfileProvider.notifier).setReminders(val)`), safely handling local notification rescheduling in try-catch.

3. **Fragile state mutation in `UserProfileNotifier`:**
   - Added `copyWith` to `UserProfile`.
   - Exposed atomic mutating persistence methods on `UserProfileNotifier`:
     - `Future<void> updateProfile({String? name, int? age, double? height, double? weight, String? activityLevel, String? sex})`
     - `Future<void> setAiNarration(bool value)`
     - `Future<void> setReminders(bool value)`
     - `void reload()`

4. **Bypassing `sharedPreferencesProvider` in UI:**
   - Refactored `EditProfileSheet` (`lib/ui/more/edit_profile_sheet.dart`) to read initial state from `ref.read(userProfileProvider)` and save changes atomically using `ref.read(userProfileProvider.notifier).updateProfile(...)` and `ref.read(calorieTargetProvider.notifier).setTarget(...)`.
   - Removed direct `SharedPreferences.getInstance()` invocations across `more_screen.dart` and `edit_profile_sheet.dart`.

5. **Missing test coverage for PopScope and Profile sync:**
   - Created `test/pop_scope_and_profile_sync_test.dart` containing 9 comprehensive unit & widget tests covering:
     - `UserProfileNotifier` default values, `updateProfile` field persistence, `setAiNarration`, `setReminders`, and `reload`.
     - `MainNavigationShell` PopScope widget navigation (intercepting back press from non-zero tabs to tab 0, and allowing app pop at tab 0).
     - `MoreScreen` reactive profile display and atomic state updates on profile modification.
     - `MoreScreen` toggle handling without race conditions.
     - `EditProfileSheet` updating both `UserProfileNotifier` and `CalorieTargetNotifier`.

## Testing & Verification Results
- Executed `flutter test test/pop_scope_and_profile_sync_test.dart` (9/9 tests passed).
- Executed full test suite `flutter test` (48/48 tests passed).

## Files changed
- `lib/ui/main_navigation_shell.dart`
- `lib/ui/more/more_screen.dart`
- `lib/ui/more/edit_profile_sheet.dart`
- `lib/domain/food/food_providers.dart`
- `lib/domain/shared_preferences_provider.dart`
- `lib/domain/profile/profile_provider.dart`
- `lib/main.dart`
- `lib/data/local/app_database.dart`
- `test/female_bmr_and_design_system_test.dart`
- `test/pop_scope_and_profile_sync_test.dart` (created)
- `test/validation_and_water_target_test.dart`
