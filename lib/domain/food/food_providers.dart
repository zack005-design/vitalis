import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_database.dart';
import '../../data/food/food_search_repository.dart';

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

// Custom Foods Stream Provider
final customFoodsProvider = StreamProvider<List<CustomFood>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCustomFoods();
});

// Total Logged Calories Today Provider
final totalCaloriesTodayProvider = Provider<int>((ref) {
  final mealsAsync = ref.watch(todayMealsProvider);
  return mealsAsync.maybeWhen(
    data: (meals) => meals.fold<int>(0, (sum, meal) => sum + meal.calories),
    orElse: () => 0,
  );
});

// Food Search Query State Provider
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

// Food Search Results Future Provider
final foodSearchResultsProvider = FutureProvider<List<FoodSearchResult>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  final repo = ref.watch(foodSearchRepositoryProvider);
  return repo.search(query);
});

// Today Water Logs Stream Provider
final todayWaterLogsProvider = StreamProvider<List<WaterLog>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchTodayWaterLogs(DateTime.now());
});

// Total Logged Water Today Provider (in ml)
final totalWaterMlTodayProvider = Provider<int>((ref) {
  final waterLogsAsync = ref.watch(todayWaterLogsProvider);
  return waterLogsAsync.maybeWhen(
    data: (logs) => logs.fold<int>(0, (sum, log) => sum + log.amountMl),
    orElse: () => 0,
  );
});

// Sleep Logs Stream Provider (last 30 entries)
final sleepLogsProvider = StreamProvider<List<SleepNote>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchLastNSleepNotes(30);
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

// Calorie history for insights charts — last N days, per day total
final calorieHistoryProvider = FutureProvider.family<List<double>, int>((ref, days) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final List<double> result = [];
  for (int i = days - 1; i >= 0; i--) {
    final dayStart = DateTime(now.year, now.month, now.day - i);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final mealList = await db.getMealsForDateRange(dayStart, dayEnd);
    final total = mealList.fold<int>(0, (s, m) => s + m.calories);
    result.add(total.toDouble());
  }
  return result;
});

// Water history for insights charts — last N days, per day total in ml
final waterHistoryProvider = FutureProvider.family<List<double>, int>((ref, days) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  final List<double> result = [];
  for (int i = days - 1; i >= 0; i--) {
    final dayStart = DateTime(now.year, now.month, now.day - i);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final waterList = await db.getWaterLogsForDateRange(dayStart, dayEnd);
    final total = waterList.fold<int>(0, (s, w) => s + w.amountMl);
    result.add(total.toDouble());
  }
  return result;
});

// Streak counter: consecutive days with ≥1 meal logged
final streakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final now = DateTime.now();
  int streak = 0;
  for (int i = 0; i <= 365; i++) {
    final dayStart = DateTime(now.year, now.month, now.day - i);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final mealList = await db.getMealsForDateRange(dayStart, dayEnd);
    if (mealList.isNotEmpty) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
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
