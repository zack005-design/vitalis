import 'package:flutter_riverpod/flutter_riverpod.dart';
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
