import 'indb_food_loader.dart';
import 'open_food_facts_client.dart';
import 'usda_food_client.dart';
import '../local/app_database.dart';

enum FoodSearchSource { history, favorite, custom, indbLocal, openFoodFacts, usda }

class FoodSearchResult {
  final String name;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String servingDescription;
  final FoodSearchSource source;

  const FoodSearchResult({
    required this.name,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.servingDescription,
    required this.source,
  });
}

class FoodSearchRepository {
  final IndbFoodLoader _indbLoader;
  final OpenFoodFactsClient _openFoodClient;
  final UsdaFoodClient _usdaClient;
  final AppDatabase db;

  FoodSearchRepository({
    IndbFoodLoader? indbLoader,
    OpenFoodFactsClient? openFoodClient,
    UsdaFoodClient? usdaClient,
    required this.db,
  })  : _indbLoader = indbLoader ?? IndbFoodLoader(),
        _openFoodClient = openFoodClient ?? OpenFoodFactsClient(),
        _usdaClient = usdaClient ?? UsdaFoodClient();

  /// Tiered resolution: History -> Favorites -> Custom -> Local INDB -> Open Food Facts -> USDA FoodData
  Future<List<FoodSearchResult>> search(String query) async {
    final results = <FoodSearchResult>[];
    final cleanQuery = query.trim().toLowerCase();

    // Step 0: User History
    final allMeals = await db.getAllMeals();
    final seen = <String>{};
    for (final m in allMeals.reversed) {
      if (cleanQuery.isEmpty || m.name.toLowerCase().contains(cleanQuery)) {
        if (seen.add(m.name)) {
          results.add(FoodSearchResult(
            name: m.name,
            calories: m.calories,
            proteinG: m.proteinG,
            carbsG: m.carbsG,
            fatG: m.fatG,
            servingDescription: "1 serving",
            source: FoodSearchSource.history,
          ));
        }
      }
    }

    // Step 0.5: Favorites
    final favorites = await db.getAllFavoriteFoods();
    for (final fav in favorites) {
      if (cleanQuery.isEmpty || fav.name.toLowerCase().contains(cleanQuery)) {
        // avoid exact duplicates from history
        if (seen.add(fav.name)) {
          results.add(FoodSearchResult(
            name: fav.name,
            calories: fav.calories,
            proteinG: fav.proteinG,
            carbsG: fav.carbsG,
            fatG: fav.fatG,
            servingDescription: fav.servingDescription,
            source: FoodSearchSource.favorite,
          ));
        }
      }
    }

    // Step 1: User History & Custom Foods
    final customFoods = await db.searchCustomFoods(query);
    for (final cf in customFoods) {
      if (seen.add(cf.name)) {
        results.add(FoodSearchResult(
          name: cf.name,
          calories: cf.caloriesPerServing,
          proteinG: cf.proteinG,
          carbsG: cf.carbsG,
          fatG: cf.fatG,
          servingDescription: cf.servingDescription,
          source: FoodSearchSource.custom,
        ));
      }
    }

    // Step 2: Bundled INDB Dataset (South Indian / Kerala)
    final indbItems = await _indbLoader.searchLocalDataset(query);
    for (final item in indbItems) {
      if (seen.add(item.name)) {
        results.add(FoodSearchResult(
          name: item.name,
          calories: item.calories,
          proteinG: item.proteinG,
          carbsG: item.carbsG,
          fatG: item.fatG,
          servingDescription: item.servingDescription,
          source: FoodSearchSource.indbLocal,
        ));
      }
    }

    // Step 3: Open Food Facts API (if query is non-empty)
    if (cleanQuery.isNotEmpty) {
      final offItems = await _openFoodClient.searchPackagedFoods(query);
      for (final off in offItems) {
        results.add(FoodSearchResult(
          name: off.name,
          calories: off.calories,
          proteinG: off.proteinG,
          carbsG: off.carbsG,
          fatG: off.fatG,
          servingDescription: off.servingDescription,
          source: FoodSearchSource.openFoodFacts,
        ));
      }

      // Step 4: USDA FoodData Central API (generic & raw foods)
      final usdaItems = await _usdaClient.searchFoods(query);
      for (final u in usdaItems) {
        results.add(FoodSearchResult(
          name: u.name,
          calories: u.calories,
          proteinG: u.proteinG,
          carbsG: u.carbsG,
          fatG: u.fatG,
          servingDescription: u.servingDescription,
          source: FoodSearchSource.usda,
        ));
      }
    }

    return results;
  }

  void dispose() {
    _openFoodClient.dispose();
  }
}

