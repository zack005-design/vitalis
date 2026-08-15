import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_database.dart';
import '../../data/food/food_search_repository.dart';
import '../insights/tier_a_rule_engine.dart';
import '../insights/tier_b_balance_scorer.dart';
import '../insights/tier_c_gemini_narrator.dart';

// Database Singleton Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Food Search Repository Provider
final foodSearchRepositoryProvider = Provider<FoodSearchRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FoodSearchRepository(db: db);
});

// Today Meals Stream Provider
final todayMealsProvider = StreamProvider<List<Meal>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTodayMeals(DateTime.now());
});

// Today Water Logs Stream Provider
final todayWaterLogsProvider = StreamProvider<List<WaterLog>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTodayWaterLogs(DateTime.now());
});

// Total Calories Logged Today
final totalCaloriesTodayProvider = Provider<int>((ref) {
  final mealsAsync = ref.watch(todayMealsProvider);
  return mealsAsync.maybeWhen(
    data: (meals) => meals.fold<int>(0, (sum, meal) => sum + meal.calories),
    orElse: () => 0,
  );
});

// Total Water Logged Today (in ml)
final totalWaterMlTodayProvider = Provider<int>((ref) {
  final waterLogsAsync = ref.watch(todayWaterLogsProvider);
  return waterLogsAsync.maybeWhen(
    data: (logs) => logs.fold<int>(0, (sum, log) => sum + log.amountMl),
    orElse: () => 0,
  );
});

// Food Search Query State Provider
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

// Food Search Results Provider
final foodSearchResultsProvider = FutureProvider<List<FoodSearchResult>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  final repo = ref.watch(foodSearchRepositoryProvider);
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

// Sleep logs for bar chart (last 7 entries)
final recentSleepLogsProvider = StreamProvider<List<SleepNote>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchLastNSleepNotes(7);
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
final calorieHistoryProvider = FutureProvider.family<List<double>, int>((ref, days) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startDay = DateTime(now.year, now.month, now.day - (days - 1));
  final endDay = DateTime(now.year, now.month, now.day + 1);

  final grouped = await db.getDailyCaloriesForDateRange(startDay, endDay);
  return _buildHistoryArray(grouped, days, now);
});

// Water history for insights charts — last N days, per day total in ml
final waterHistoryProvider = FutureProvider.family<List<double>, int>((ref, days) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final startDay = DateTime(now.year, now.month, now.day - (days - 1));
  final endDay = DateTime(now.year, now.month, now.day + 1);

  final grouped = await db.getDailyWaterForDateRange(startDay, endDay);
  return _buildHistoryArray(grouped, days, now);
});

class DailyMacros {
  final double protein;
  final double carbs;
  final double fat;
  const DailyMacros({this.protein = 0, this.carbs = 0, this.fat = 0});
}

// Macro history for insights charts — last N days, per day totals
final macroHistoryProvider = FutureProvider.family<List<DailyMacros>, int>((ref, days) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final List<DailyMacros> result = [];
  for (int i = days - 1; i >= 0; i--) {
    final dayStart = DateTime(now.year, now.month, now.day - i);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final mealList = await db.getMealsForDateRange(dayStart, dayEnd);
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final m in mealList) {
      protein += m.proteinG ?? 0;
      carbs += m.carbsG ?? 0;
      fat += m.fatG ?? 0;
    }
    result.add(DailyMacros(protein: protein, carbs: carbs, fat: fat));
  }
  return result;
});

// Sleep history for insights charts — last N days, per day total in hours
final sleepHistoryProvider = FutureProvider.family<List<double>, int>((ref, days) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final List<double> result = [];
  for (int i = days - 1; i >= 0; i--) {
    final dayStart = DateTime(now.year, now.month, now.day - i);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final sleepList = await db.getSleepNotesForDateRange(dayStart, dayEnd);
    final totalMin = sleepList.fold<int>(0, (s, n) => s + n.durationMinutes);
    result.add(totalMin / 60.0);
  }
  return result;
});

// Dynamic User Calorie Target Provider (Mifflin-St Jeor / Profile-linked)
class CalorieTargetNotifier extends StateNotifier<int> {
  CalorieTargetNotifier() : super(2200) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('target_calories') ?? 2200;
  }

  Future<void> setTarget(int target) async {
    state = target;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_calories', target);
  }
}

final calorieTargetProvider = StateNotifierProvider<CalorieTargetNotifier, int>((ref) {
  return CalorieTargetNotifier();
});

// Dynamic User Water Target Provider (in ml)
class WaterTargetNotifier extends StateNotifier<int> {
  WaterTargetNotifier() : super(2000) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt('target_water_ml') ?? 2000;
  }

  Future<void> setTarget(int target) async {
    state = target;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_water_ml', target);
  }
}

final waterTargetProvider = StateNotifierProvider<WaterTargetNotifier, int>((ref) {
  return WaterTargetNotifier();
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
