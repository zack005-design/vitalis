# Task 5: Midnight Rollover & Sleep Range

## Overview
Fix streams holding onto stale dates across midnight, and hook up the 30d sleep range selector.

## Specific Requirements
1. In lib/domain/food/food_providers.dart:
   - Refactor 	odayMealsProvider and 	odayWaterLogsProvider (or their underlying streams) so that if the app is left open across midnight, they don't continue querying yesterday's boundaries. A simple approach is using Stream.periodic to force a rebuild at midnight, or invalidating the provider.
   - Modify ecentSleepLogsProvider to accept an int limit parameter.
2. In lib/ui/sleep/sleep_screen.dart:
   - Map the _selectedRange value to integer limits (7, 30) and watch the new parameterized ecentSleepLogsProvider.
   - Update the Hero display to show the last night's actual duration (lastEntry?.durationMinutes) instead of the average, and adjust the label accordingly.
