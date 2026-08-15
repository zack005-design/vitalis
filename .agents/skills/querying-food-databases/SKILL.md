---
name: querying-food-databases
description: Handles tiered food database resolution across local INDB datasets (ICMR-NIN Kerala/South Indian dishes), Open Food Facts REST API lookups, and custom food CRUD operations. Use when implementing food search, barcode scanning, or custom dish creation in Flutter.
---

# Querying Food Databases

## When to use this skill
- Implementing food search in the Food tab.
- Querying the local bundled ICMR-NIN INDB JSON asset (offline).
- Fetching packaged product nutrition from Open Food Facts REST API (online fallback).
- Creating and storing reusable custom dishes in SQLite (`custom_foods`).

## Resolution Cascade Precedence
1. **User History & Custom Foods** (`meals`, `custom_foods` in Drift SQLite)
2. **Bundled INDB Dataset Asset** (`assets/data/indb_kerala_foods.json`)
3. **Open Food Facts API** (`https://world.openfoodfacts.org/api/v2/search`)
4. **USDA FoodData Central API** (`https://api.nal.usda.gov/fdc/v1/foods/search`)
5. **Manual Entry** (Fallback form)

## Open Food Facts REST Client Pattern

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsClient {
  final http.Client _client;
  OpenFoodFactsClient({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> searchPackagedFoods(String query) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=20',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List? ?? [];
        return products.map((p) => {
          'name': p['product_name'] ?? 'Unknown Product',
          'calories': (p['nutriments']?['energy-kcal_100g'] as num?)?.toInt() ?? 0,
          'protein_g': (p['nutriments']?['proteins_100g'] as num?)?.toDouble(),
          'carbs_g': (p['nutriments']?['carbohydrates_100g'] as num?)?.toDouble(),
          'fat_g': (p['nutriments']?['fat_100g'] as num?)?.toDouble(),
          'source': 'open_food_facts',
        }).toList();
      }
    } catch (_) {
      // Offline fallback: return empty list without throwing UI exceptions
    }
    return [];
  }
}
```
