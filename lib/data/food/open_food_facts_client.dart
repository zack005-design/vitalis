import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodItem {
  final String name;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String servingDescription;

  const OpenFoodItem({
    required this.name,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.servingDescription,
  });
}

class OpenFoodFactsClient {
  final http.Client _client;
  final bool _ownsClient;

  OpenFoodFactsClient({http.Client? client}) 
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<List<OpenFoodItem>> searchPackagedFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=15',
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'VitalityTracker/1.0 (contact@example.com)',
        },
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List? ?? [];

        return products.map((p) {
          final nutriments = p['nutriments'] as Map<String, dynamic>? ?? {};
          final kcal = (nutriments['energy-kcal_100g'] as num?)?.toInt() ??
              (nutriments['energy-kcal'] as num?)?.toInt() ?? 0;

          return OpenFoodItem(
            name: (p['product_name'] as String?) ?? 'Packaged Item',
            calories: kcal,
            proteinG: (nutriments['proteins_100g'] as num?)?.toDouble(),
            carbsG: (nutriments['carbohydrates_100g'] as num?)?.toDouble(),
            fatG: (nutriments['fat_100g'] as num?)?.toDouble(),
            servingDescription: (p['serving_size'] as String?) ?? '100g',
          );
        }).where((item) => item.calories > 0).toList();
      }
    } catch (_) {
      // Offline fallback: return empty list without throwing UI exceptions
    }
    return [];
  }
}
