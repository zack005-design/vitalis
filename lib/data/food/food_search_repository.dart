import 'indb_food_loader.dart';
import 'open_food_facts_client.dart';
import '../local/app_database.dart';

enum FoodSearchSource { history, custom, indbLocal, openFoodFacts }

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
  final AppDatabase db;

  FoodSearchRepository({
    IndbFoodLoader? indbLoader,
    OpenFoodFactsClient? openFoodClient,
    required this.db,
  })  : _indbLoader = indbLoader ?? IndbFoodLoader(),
        _openFoodClient = openFoodClient ?? OpenFoodFactsClient();

  /// Tiered resolution: History/Custom -> Local INDB -> Open Food Facts
  Future<List<FoodSearchResult>> search(String query) async {
    final results = <FoodSearchResult>[];
    final cleanQuery = query.trim().toLowerCase();

    // Step 1: User History & Custom Foods
    final customFoods = await db.searchCustomFoods(query);
    for (final cf in customFoods) {
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

    // Step 2: Bundled INDB Dataset (South Indian / Kerala)
    final indbItems = await _indbLoader.searchLocalDataset(query);
    for (final item in indbItems) {
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
    }

    return results;
  }
}
