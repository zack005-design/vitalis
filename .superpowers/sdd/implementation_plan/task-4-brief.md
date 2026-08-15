# Task 4: History Queries N+1 loop

## Overview
Fix the N+1 query loop in history providers by adding grouped queries to app_database.

## Specific Requirements
1. In lib/data/local/app_database.dart:
   - Add a method to efficiently aggregate meals by date. For example: Future<List<Map<String, dynamic>>> getDailyCaloriesForDateRange(DateTime start, DateTime end).
   - Add a method to aggregate water logs by date.
   - Use Drift's custom queries or expression features to GROUP BY strftime('%Y-%m-%d', timestamp) (or Drift's datetime modifiers) so the database returns one row per day with the SUM of calories or mountMl.
2. In lib/domain/food/food_providers.dart:
   - Refactor calorieHistoryProvider and waterHistoryProvider to call these new single aggregation queries instead of looping sequentially for N days.
   - The providers must still return a List<double> of length days, where each element is the sum for that specific day index. Map the grouped SQL results back into this array appropriately.
