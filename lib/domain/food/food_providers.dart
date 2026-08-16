import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_database.dart';
import '../../data/food/food_search_repository.dart';
import '../insights/tier_a_rule_engine.dart';
import '../insights/tier_b_balance_scorer.dart';
import '../insights/tier_c_gemini_narrator.dart';
import '../shared_preferences_provider.dart';

// Database Singleton Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Food Search Repository Provider
final foodSearchRepositoryProvider = Provider<FoodSearchRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = FoodSearchRepository(db: db);
  ref.onDispose(() => repo.dispose());
  return repo;
});

void _setupMidnightRollover(Ref ref, DateTime todayStart) {
  final now = DateTime.now();
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final delay = nextMidnight.difference(now) + const Duration(milliseconds: 200);
  final timer = Timer(delay, () {
    ref.invalidateSelf();
  });

  final periodicTimer = Timer.periodic(const Duration(minutes: 1), (_) {
    final currentNow = DateTime.now();
    if (currentNow.day != todayStart.day ||
        currentNow.month != todayStart.month ||
        currentNow.year != todayStart.year) {
      ref.invalidateSelf();
    }
  });

  ref.onDispose(() {
    timer.cancel();
    periodicTimer.cancel();
  });
}

// Today Meals Stream Provider
final todayMealsProvider = StreamProvider<List<Meal>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  _setupMidnightRollover(ref, todayStart);
  return db.watchTodayMeals(todayStart);
});

// Favorite Foods Stream Provider
final favoriteFoodsProvider = StreamProvider<List<FavoriteFood>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchFavoriteFoods();
});

// Today Water Logs Stream Provider
final todayWaterLogsProvider = StreamProvider<List<WaterLog>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  _setupMidnightRollover(ref, todayStart);
  return db.watchTodayWaterLogs(todayStart);
});

// Nutrition Summary (Calories & Macros) for Reactive Dashboard
class NutritionSummary {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  const NutritionSummary({this.calories = 0, this.protein = 0, this.carbs = 0, this.fat = 0});
}

final todaysNutritionSummaryProvider = Provider<NutritionSummary>((ref) {
  final mealsAsync = ref.watch(todayMealsProvider);
  final meals = mealsAsync.valueOrNull ?? [];
  int cal = 0;
  double p = 0;
  double c = 0;
  double f = 0;
  for (final m in meals) {
    cal += m.calories;
    p += m.proteinG ?? 0;
    c += m.carbsG ?? 0;
    f += m.fatG ?? 0;
  }
  return NutritionSummary(calories: cal, protein: p, carbs: c, fat: f);
});

// Total Calories Logged Today
final totalCaloriesTodayProvider = Provider<int>((ref) {
  return ref.watch(todaysNutritionSummaryProvider).calories;
});

// Total Water Logged Today (in ml)
final totalWaterMlTodayProvider = Provider<int>((ref) {
  final waterLogsAsync = ref.watch(todayWaterLogsProvider);
  return waterLogsAsync.valueOrNull?.fold<int>(0, (sum, log) => sum + log.amountMl) ?? 0;
});

// Food Search Query State Provider
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

// Food Search Results Provider — 300ms debounce prevents a query per keystroke
final foodSearchResultsProvider = FutureProvider<List<FoodSearchResult>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  if (query.trim().isEmpty) return const [];

  // Debounce: wait 300ms after the last keystroke before firing the search
  final completer = Completer<void>();
  final timer = Timer(const Duration(milliseconds: 300), completer.complete);
  ref.onDispose(() {
    timer.cancel();
    if (!completer.isCompleted) completer.complete();
  });
  await completer.future;

  // Re-check if the provider was disposed/rebuilt during the debounce window
  final repo = ref.read(foodSearchRepositoryProvider);
  return repo.search(query);
});

// Sleep Logs Stream Provider
final sleepLogsProvider = StreamProvider<List<SleepNote>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSleepNotes();
});

// Last sleep entry (most recent)
final lastSleepEntryProvider = Provider<SleepNote?>((ref) {
  final logs = ref.watch(sleepLogsProvider);
  return logs.maybeWhen(data: (list) => list.isNotEmpty ? list.first : null, orElse: () => null);
});

// Sleep logs for bar chart (parameterized limit, e.g. 7 or 30 entries)
final recentSleepLogsProvider = StreamProvider.family<List<SleepNote>, int>((ref, limit) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchLastNSleepNotes(limit);
});

List<double> _buildHistoryArray(List<Map<String, dynamic>> grouped, int days, DateTime now) {
  final dateToTotal = {
    for (final row in grouped)
      row['date'] as String: ((row['total'] as num?)?.toDouble() ?? 0.0)
  };

  final List<double> result = [];
  for (int i = days - 1; i >= 0; i--) {
    final dayStart = DateTime(now.year, now.month, now.day - i);
    final dateStr = dayStart.toIso8601String().substring(0, 10);
    result.add(dateToTotal[dateStr] ?? 0.0);
  }
  return result;
}

// Calorie history for insights charts — last N days, per day total
final calorieHistoryProvider = StreamProvider.family<List<double>, int>((ref, days) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startDay = DateTime(now.year, now.month, now.day - (days - 1));
  final endDay = DateTime(now.year, now.month, now.day + 1);

  return db.watchDailyCaloriesForDateRange(startDay, endDay).map((grouped) {
    return _buildHistoryArray(grouped, days, now);
  });
});

// Water history for insights charts — last N days, per day total in ml
final waterHistoryProvider = StreamProvider.family<List<double>, int>((ref, days) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startDay = DateTime(now.year, now.month, now.day - (days - 1));
  final endDay = DateTime(now.year, now.month, now.day + 1);

  return db.watchDailyWaterForDateRange(startDay, endDay).map((grouped) {
    return _buildHistoryArray(grouped, days, now);
  });
});

class DailyMacros {
  final double protein;
  final double carbs;
  final double fat;
  const DailyMacros({this.protein = 0, this.carbs = 0, this.fat = 0});
}

// Macro history for insights charts — last N days, per day totals
// Uses a single batched DB query instead of N individual queries for performance.
final macroHistoryProvider = StreamProvider.family<List<DailyMacros>, int>((ref, days) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startDay = DateTime(now.year, now.month, now.day - (days - 1));
  final endDay = DateTime(now.year, now.month, now.day + 1);

  return db.watchMealsForDateRange(startDay, endDay).map((allMeals) {
    // Group by date string (YYYY-MM-DD) in Dart
    final Map<String, DailyMacros> byDate = {};
    for (final m in allMeals) {
      final dateKey = m.timestamp.toIso8601String().substring(0, 10);
      final existing = byDate[dateKey] ?? const DailyMacros();
      byDate[dateKey] = DailyMacros(
        protein: existing.protein + (m.proteinG ?? 0),
        carbs: existing.carbs + (m.carbsG ?? 0),
        fat: existing.fat + (m.fatG ?? 0),
      );
    }

    // Build ordered result array — one entry per day, oldest to newest
    final List<DailyMacros> result = [];
    for (int i = days - 1; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day - i);
      final dateKey = dayStart.toIso8601String().substring(0, 10);
      result.add(byDate[dateKey] ?? const DailyMacros());
    }
    return result;
  });
});

// Sleep history for insights charts — last N days, per day total in hours.
// Uses a single batched DB query instead of N individual queries for performance.
final sleepHistoryProvider = StreamProvider.family<List<double>, int>((ref, days) {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startDay = DateTime(now.year, now.month, now.day - (days - 1));
  final endDay = DateTime(now.year, now.month, now.day + 1);

  return db.watchSleepNotesForDateRange(startDay, endDay).map((allSleep) {
    // Group by date string in Dart
    final Map<String, int> minutesByDate = {};
    for (final s in allSleep) {
      final dateKey = s.date.toIso8601String().substring(0, 10);
      minutesByDate[dateKey] = (minutesByDate[dateKey] ?? 0) + s.durationMinutes;
    }

    // Build ordered result array — one entry per day
    final List<double> result = [];
    for (int i = days - 1; i >= 0; i--) {
      final dayStart = DateTime(now.year, now.month, now.day - i);
      final dateKey = dayStart.toIso8601String().substring(0, 10);
      result.add((minutesByDate[dateKey] ?? 0) / 60.0);
    }
    return result;
  });
});

// Dynamic User Calorie Target Provider (Mifflin-St Jeor / Profile-linked)
class CalorieTargetNotifier extends StateNotifier<int> {
  final SharedPreferences prefs;

  CalorieTargetNotifier(this.prefs) : super(prefs.getInt('target_calories') ?? 2200);

  Future<void> setTarget(int target) async {
    state = target;
    await prefs.setInt('target_calories', target);
  }
}

final calorieTargetProvider = StateNotifierProvider<CalorieTargetNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CalorieTargetNotifier(prefs);
});

// Dynamic User Water Target Provider (in ml)
class WaterTargetNotifier extends StateNotifier<int> {
  final SharedPreferences prefs;

  WaterTargetNotifier(this.prefs) : super(prefs.getInt('target_water_ml') ?? 2000);

  Future<void> setTarget(int target) async {
    state = target;
    await prefs.setInt('target_water_ml', target);
  }
}

final waterTargetProvider = StateNotifierProvider<WaterTargetNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WaterTargetNotifier(prefs);
});

// Tier B Daily Balance Score Provider
final dailyBalanceScoreProvider = Provider<int>((ref) {
  final caloriesLogged = ref.watch(totalCaloriesTodayProvider);
  final calorieTarget = ref.watch(calorieTargetProvider);
  final waterLogged = ref.watch(totalWaterMlTodayProvider);
  final waterTarget = ref.watch(waterTargetProvider);
  final lastSleep = ref.watch(lastSleepEntryProvider);
  final sleepHours = lastSleep != null ? lastSleep.durationMinutes / 60.0 : 8.0;

  return TierBBalanceScorer().calculateScore(
    caloriesLogged: caloriesLogged,
    calorieTarget: calorieTarget,
    waterMlLogged: waterLogged,
    waterTargetMl: waterTarget,
    sleepHours: sleepHours,
    currentTime: DateTime.now(),
  );
});

// Tier A / C Daily Health Insight Provider
final dailyHealthInsightProvider = FutureProvider<HealthSummaryInsight>((ref) async {
  final caloriesLogged = ref.watch(totalCaloriesTodayProvider);
  final calorieTarget = ref.watch(calorieTargetProvider);
  final waterLogged = ref.watch(totalWaterMlTodayProvider);
  final waterTarget = ref.watch(waterTargetProvider);
  final lastSleep = ref.watch(lastSleepEntryProvider);
  final sleepHours = lastSleep != null ? lastSleep.durationMinutes / 60.0 : 8.0;

  return TierCGeminiNarrator().generateNarration(
    caloriesLogged: caloriesLogged,
    calorieTarget: calorieTarget,
    waterLoggedMl: waterLogged,
    waterTargetMl: waterTarget,
    sleepHours: sleepHours,
  );
});
