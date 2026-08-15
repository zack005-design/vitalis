# Task 5 Report: Midnight Rollover & Sleep Range

## What Was Implemented
1. **Midnight Rollover for Today Stream Providers** (`lib/domain/food/food_providers.dart`):
   - Added `_setupMidnightRollover(Ref ref, DateTime todayStart)` which schedules a `Timer` targeting the next midnight boundary (plus 200ms safety buffer) to call `ref.invalidateSelf()`.
   - Added a periodic 1-minute fallback check (`Timer.periodic`) in case the device slept across midnight or the system clock was updated.
   - Refactored `todayMealsProvider` and `todayWaterLogsProvider` to use `_setupMidnightRollover` with `todayStart`, preventing stale date boundaries from persisting across midnight when the app stays open.
   - Disposed all rollover timers on provider teardown (`ref.onDispose`).

2. **Parameterized Sleep Query Provider** (`lib/domain/food/food_providers.dart`):
   - Refactored `recentSleepLogsProvider` to be a `StreamProvider.family<List<SleepNote>, int>`, accepting an integer limit (e.g. 7 or 30).

3. **Sleep Screen Range Mapping & Hero Updates** (`lib/ui/sleep/sleep_screen.dart`):
   - Mapped `_selectedRange` values (`'7d'`, `'30d'`) to integer limits (7, 30) passed to `recentSleepLogsProvider(_limit)`.
   - Updated the Sleep Duration Hero header to display the actual duration of the last recorded night (`lastEntry?.durationMinutes`) instead of the multi-day average.
   - Updated the Hero subtitle label dynamically (`"Last Night • Goal 8h"` when recorded, or `"No sleep recorded • Goal 8h"` when empty).
   - Updated the Sleep Trend chart to support horizontal scrolling via `SingleChildScrollView` when the 30d range is selected.

4. **Automated Unit & Widget Tests** (`test/midnight_rollover_and_sleep_range_test.dart`):
   - Verified that `todayMealsProvider` and `todayWaterLogsProvider` query the current day's data and update reactive totals.
   - Verified `recentSleepLogsProvider` returns the exact limit requested (7 vs 30).
   - Verified `SleepScreen` widget rendering: empty state, last night actual duration in the Hero, and dynamic 7d / 30d SegmentedControl range toggles.

## What Was Tested and Results
- **Unit & Widget Tests**: `flutter test test/midnight_rollover_and_sleep_range_test.dart` (5 passed, 0 failed).
- **Full Test Suite**: `flutter test` (17 passed, 0 failed).
- **Static Analysis**: `flutter analyze` (0 issues found).

## Files Changed
- `lib/domain/food/food_providers.dart`: Added `_setupMidnightRollover`, updated `todayMealsProvider`, `todayWaterLogsProvider`, and parameterized `recentSleepLogsProvider.family`.
- `lib/ui/sleep/sleep_screen.dart`: Mapped range selection to provider query limit, updated Hero to use `lastEntry?.durationMinutes`, and enabled 30d trend scrolling.
- `lib/data/local/app_database.g.dart`: Generated database code.
- `test/midnight_rollover_and_sleep_range_test.dart`: Added unit and widget test coverage for rollover, parameterized sleep queries, and UI behavior.

## Self-Review Findings
- All requirements from `task-5-brief.md` have been met.
- No unused imports or lint warnings.
- Clean separation between Hero metric (last night actual) and Trend card (average across range).

## Issues or Concerns
- None.
