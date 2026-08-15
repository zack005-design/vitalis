import 'dart:convert';
import 'package:http/http.dart' as http;

class UsdaFoodItem {
  final String name;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String servingDescription;

  const UsdaFoodItem({
    required this.name,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.servingDescription,
  });
}

class UsdaFoodClient {
  final http.Client _client;
  final String apiKey;

  UsdaFoodClient({
    http.Client? client,
    this.apiKey = 'DEMO_KEY',
  }) : _client = client ?? http.Client();

  /// Search foods in USDA FoodData Central
  Future<List<UsdaFoodItem>> searchFoods(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final uri = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search?query=${Uri.encodeComponent(clean)}&pageSize=15&api_key=$apiKey',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foods = data['foods'] as List? ?? [];
        final items = <UsdaFoodItem>[];

        for (final food in foods) {
          final description = food['description']?.toString() ?? 'Generic Food';
          final nutrients = food['foodNutrients'] as List? ?? [];

          int calories = 0;
          double? protein;
          double? carbs;
          double? fat;

          for (final n in nutrients) {
            final nutrientName = n['nutrientName']?.toString().toLowerCase() ?? '';
            final value = (n['value'] as num?)?.toDouble() ?? 0.0;

            if (nutrientName.contains('energy') && (nutrientName.contains('kcal') || n['unitName'] == 'KCAL')) {
              calories = value.round();
            } else if (nutrientName.contains('protein')) {
              protein = value;
            } else if (nutrientName.contains('carbohydrate')) {
              carbs = value;
            } else if (nutrientName.contains('total lipid') || nutrientName == 'fat') {
              fat = value;
            }
          }

          items.add(UsdaFoodItem(
            name: description,
            calories: calories,
            proteinG: protein,
            carbsG: carbs,
            fatG: fat,
            servingDescription: '100g standard serving',
          ));
        }

        return items;
      }
    } catch (_) {
      // Graceful offline fallback
    }
    return [];
  }
}
