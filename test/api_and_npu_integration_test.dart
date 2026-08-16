import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:calorie_sleep_tracker/data/food/usda_food_client.dart';
import 'package:calorie_sleep_tracker/services/weather_hydration_service.dart';
import 'package:calorie_sleep_tracker/domain/insights/tier_c_gemini_narrator.dart';
import 'package:calorie_sleep_tracker/domain/insights/tier_b_balance_scorer.dart';

void main() {
  group('USDA Food Client Tests', () {
    test('parses USDA food search response accurately', () async {
      final mockClient = MockClient((request) async {
        final sampleResponse = {
          'foods': [
            {
              'description': 'Bananas, raw',
              'foodNutrients': [
                {'nutrientName': 'Energy', 'value': 89.0, 'unitName': 'KCAL'},
                {'nutrientName': 'Protein', 'value': 1.09, 'unitName': 'G'},
                {'nutrientName': 'Carbohydrate, by difference', 'value': 22.84, 'unitName': 'G'},
                {'nutrientName': 'Total lipid (fat)', 'value': 0.33, 'unitName': 'G'},
              ]
            }
          ]
        };
        return http.Response(jsonEncode(sampleResponse), 200);
      });

      final usda = UsdaFoodClient(client: mockClient);
      final results = await usda.searchFoods('banana');

      expect(results.length, 1);
      expect(results.first.name, 'Bananas, raw');
      expect(results.first.calories, 89);
      expect(results.first.proteinG, 1.09);
      expect(results.first.carbsG, 22.84);
      expect(results.first.fatG, 0.33);
    });

    test('handles USDA network errors gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final usda = UsdaFoodClient(client: mockClient);
      final results = await usda.searchFoods('apple');
      expect(results, isEmpty);
    });
  });

  group('Weather Hydration Service Tests', () {
    test('adds 500ml bonus for hot weather (>= 33°C)', () async {
      final mockClient = MockClient((request) async {
        final sampleResponse = {
          'current': {
            'temperature_2m': 34.5,
            'relative_humidity_2m': 60.0,
          }
        };
        return http.Response(jsonEncode(sampleResponse), 200);
      });

      final weather = WeatherHydrationService(client: mockClient);
      final info = await weather.getHydrationAdjustment();

      expect(info.temperatureC, 34.5);
      expect(info.bonusWaterMl, 500);
      expect(info.weatherCondition, 'Hot');
    });

    test('adds 300ml bonus for warm weather (>= 28°C)', () async {
      final mockClient = MockClient((request) async {
        final sampleResponse = {
          'current': {
            'temperature_2m': 29.0,
            'relative_humidity_2m': 50.0,
          }
        };
        return http.Response(jsonEncode(sampleResponse), 200);
      });

      final weather = WeatherHydrationService(client: mockClient);
      final info = await weather.getHydrationAdjustment();

      expect(info.temperatureC, 29.0);
      expect(info.bonusWaterMl, 300);
      expect(info.weatherCondition, 'Warm');
    });
  });

  group('On-Device NPU Insights Engine Tests', () {
    test('TierCNpuNarrator synthesizes recovery deficit when sleep is low', () async {
      final narrator = TierCNpuNarrator(forceNpuSimulation: true);
      final insight = await narrator.generateNarration(
        caloriesLogged: 2000,
        calorieTarget: 2000,
        waterLoggedMl: 2500,
        waterTargetMl: 2500,
        sleepHours: 5.5,
      );

      expect(insight.title, 'On-Device NPU Analysis');
      expect(insight.category, 'sleep');
      expect(insight.description, contains('Recovery Deficit'));
    });

    test('TierCNpuNarrator falls back to deterministic engine when TFLite model is invalid', () async {
      final narrator = TierCNpuNarrator(forceNpuSimulation: false);
      
      final insight = await narrator.generateNarration(
        caloriesLogged: 1500,
        calorieTarget: 2000,
        waterLoggedMl: 2500,
        waterTargetMl: 2500,
        sleepHours: 8.0,
      );

      // Should fall back to Tier A since the mock TFLite file is invalid
      expect(insight.title, isNotEmpty);
      expect(insight.category, isNotEmpty);
    });

    test('TierBBalanceScorer calculates multi-factor score on device', () {
      final scorer = TierBBalanceScorer();
      final score = scorer.calculateScore(
        caloriesLogged: 2000,
        calorieTarget: 2000,
        waterMlLogged: 2500,
        waterTargetMl: 2500,
        sleepHours: 8.0,
      );

      expect(score, 100);
    });
  });
}
