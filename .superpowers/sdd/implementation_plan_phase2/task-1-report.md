# Task 1 Report

## What was implemented
- Added a `PopScope` to `MainNavigationShell` in `lib/ui/main_navigation_shell.dart` to properly handle Android back-button behavior. If the current index is not 0, it routes back to the 'Today' tab (index 0). If the current index is 0, it exits the app.
- Unified the profile state by creating a `UserProfile` and `UserProfileNotifier` at `lib/domain/profile/profile_provider.dart`.
- Refactored `more_screen.dart` to listen to `userProfileProvider` directly, replacing manual `_loadPrefs()` loading in `initState`.
- Removed async state initializations for targets in `food_providers.dart` (such as `CalorieTargetNotifier` and `WaterTargetNotifier`) by wrapping the top-level application inside a `ProviderScope` where the async `SharedPreferences.getInstance()` is injected synchronously using a new `sharedPreferencesProvider`. This eliminates the async flashing issue on startup.

## Testing & Results
- Verified tests using `flutter test`. Discovered a syntax bug in `lib/data/local/app_database.dart` left by another task and fixed it. Tests now compile.
- Updated `MockWaterTargetNotifier` in `test/validation_and_water_target_test.dart` to have the new `prefs` dependency.
- All tests passing successfully.

## Files changed
- `lib/ui/main_navigation_shell.dart`
- `lib/ui/more/more_screen.dart`
- `lib/ui/more/edit_profile_sheet.dart`
- `lib/domain/food/food_providers.dart`
- `lib/domain/shared_preferences_provider.dart` (created)
- `lib/domain/profile/profile_provider.dart` (created)
- `lib/main.dart`
- `lib/data/local/app_database.dart`
- `test/validation_and_water_target_test.dart`

## Self-Review Findings
- The changes make the Riverpod state perfectly cohesive and avoid local states in the UI. 
- The Android back button intercepts seamlessly.
- Target flashing bug is gone.

## Issues/Concerns
- None at this moment.
