# Task 1: Core Navigation & Architecture

**Goal:** Resolve app lifecycle, routing, and state fragmentation issues.

**Specific Requirements:**
1. **Navigation:** Modify lib/ui/main_navigation_shell.dart. Wrap the main body/shell in a PopScope to handle the Android back-button correctly. If the user is not on the 'Today' tab (index 0), pressing back should navigate them to the 'Today' tab rather than exiting the app. If they are on the 'Today' tab, allow the app to exit.
2. **Profile State Fragmentation:** 
   - lib/ui/more/more_screen.dart currently loads profile data manually via SharedPreferences in initState. This means it doesn't stay in sync if the profile is updated elsewhere.
   - Refactor more_screen.dart to read the profile name and details from a Riverpod provider (e.g., userProfileProvider or similar, check ood_providers.dart or profile_providers.dart).
   - Ensure the UI reactively updates without needing a manual _loadPrefs() call.
3. **Async Notifier Race:**
   - In lib/domain/food/food_providers.dart, fix the CalorieTargetNotifier and WaterTargetNotifier race conditions where they flash default values (2200 and 2.0L) on startup before SharedPreferences loads.
   - Hint: Use SharedPreferencesProvider if available, or initialize the synchronous preferences earlier in the app lifecycle so providers can read them synchronously on first build, OR make the target providers async (e.g. AsyncValue<int>) and handle the loading state in the UI.

**Testing:**
- Run all widget tests.
- Add/update tests to ensure the back button behavior and profile sync work.
