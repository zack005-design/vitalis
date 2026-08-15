# Task 6 Implementation Report: Sleep Timestamp Bug

## Summary of Implementation
Fixed the sleep timestamp calculation bug where logging sleep in the morning incorrectly assigned the bedtime to today (in the future) and pushed wake time to tomorrow.

### Details
- Extracted and implemented `calculateSleepRange(TimeOfDay bedtime, TimeOfDay wakeTime, {DateTime? now})` returning a `SleepRange(DateTime bed, DateTime wake)` record model.
- If `wake.isBefore(bed)` (overnight sleep crossing midnight, e.g. bedtime 22:30, wake 06:30), bedtime is properly anchored to yesterday's date (`bed.subtract(Duration(days: 1))`), ensuring bedtime and wake time both reflect the past completed sleep session without future timestamps.
- If `bed.isAfter(now)` (same-day nap logged prior to the current time, e.g. logging yesterday's afternoon nap in the morning), both `bed` and `wake` are shifted back by one day.
- Updated `LogSleepSheet._durationMinutes` and `LogSleepSheet._save` to use `calculateSleepRange`, accurately persisting `bedtime` (yesterday), `wakeTime` (today), `durationMinutes`, and syncing the past session range to Health Connect.

## Files Changed
- `lib/ui/sleep/log_sleep_sheet.dart`: Added `SleepRange`, `calculateSleepRange()`, and updated `LogSleepSheet._durationMinutes` & `_save()`.
- `test/sleep_timestamp_test.dart`: Added comprehensive unit and widget tests for timestamp calculation, edge cases, and sheet persistence.

## Verification and Test Results
- Ran full test suite via `flutter test`.
- All 24 tests passed (6 unit tests in `calculateSleepRange`, 1 integration test in `LogSleepSheet`, and all 17 existing tests).
- Verified:
  1. Overnight sleep in the morning anchors bedtime to yesterday (22:30 -> yesterday 22:30, 06:30 -> today 06:30).
  2. Overnight sleep in the evening anchors bedtime to yesterday and wake to today.
  3. Post-midnight bedtime logged in morning preserves same-day timestamps (01:30 -> 07:30).
  4. Afternoon naps logged after wake time preserve same-day timestamps.
  5. Afternoon naps logged next morning shift back by 1 day.
  6. Month and year boundary rollovers work seamlessly (e.g. Jan 1 morning log anchors bedtime to Dec 31).
  7. Widget tests verify correct UI duration display ("8h 0m") and valid database insertion.

## Self-Review Findings
- No lint errors or regressions.
- Pure function `calculateSleepRange` allows deterministic unit testing with injectable `now` parameter.
- Health Connect sync receives accurate historical timestamps instead of future dates.

## Concerns
- None.
