import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:calorie_sleep_tracker/data/food/open_food_facts_client.dart';

void main() {
  test('OpenFoodFactsClient adds User-Agent header and parses correctly', () async {
    final mockClient = MockClient((request) async {
      expect(request.headers['User-Agent'], 'VitalityTracker/1.0 (contact@example.com)');
      return http.Response(jsonEncode({
        'products': [
          {
            'product_name': 'Test Food',
            'nutriments': {
              'energy-kcal_100g': 100,
            }
          }
        ]
      }), 200);
    });

    final client = OpenFoodFactsClient(client: mockClient);
    final results = await client.searchPackagedFoods('test');

    expect(results.length, 1);
    expect(results.first.name, 'Test Food');
    expect(results.first.calories, 100);
  });
}
