import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:calorie_sleep_tracker/data/health/health_connect_client.dart';

class FakeHealth extends Health {
  bool configureCalled = false;
  MealType? capturedMealType;
  DateTime? capturedStartTime;
  DateTime? capturedEndTime;
  double? capturedCaloriesConsumed;
  double? capturedProtein;
  double? capturedCarbohydrates;
  double? capturedFatTotal;
  String? capturedName;

  @override
  Future<void> configure() async {
    configureCalled = true;
  }

  @override
  Future<bool> writeMeal({
    required MealType mealType,
    required DateTime startTime,
    required DateTime endTime,
    String? clientRecordId,
    double? clientRecordVersion,
    double? caloriesConsumed,
    double? carbohydrates,
    double? protein,
    double? fatTotal,
    String? name,
    double? caffeine,
    double? vitaminA,
    double? b1Thiamin,
    double? b2Riboflavin,
    double? b3Niacin,
    double? b5PantothenicAcid,
    double? b6Pyridoxine,
    double? b7Biotin,
    double? b9Folate,
    double? b12Cobalamin,
    double? vitaminC,
    double? vitaminD,
    double? vitaminE,
    double? vitaminK,
    double? calcium,
    double? cholesterol,
    double? chloride,
    double? chromium,
    double? copper,
    double? fatUnsaturated,
    double? fatMonounsaturated,
    double? fatPolyunsaturated,
    double? fatSaturated,
    double? fatTransMonoenoic,
    double? fiber,
    double? iodine,
    double? iron,
    double? magnesium,
    double? manganese,
    double? molybdenum,
    double? phosphorus,
    double? potassium,
    double? selenium,
    double? sodium,
    double? sugar,
    double? water,
    double? zinc,
    RecordingMethod recordingMethod = RecordingMethod.automatic,
  }) async {
    capturedMealType = mealType;
    capturedStartTime = startTime;
    capturedEndTime = endTime;
    capturedCaloriesConsumed = caloriesConsumed;
    capturedProtein = protein;
    capturedCarbohydrates = carbohydrates;
    capturedFatTotal = fatTotal;
    capturedName = name;
    return true;
  }
}

class FakeHealthError extends Health {
  @override
  Future<void> configure() async {}

  @override
  Future<void> installHealthConnect() async {
    throw Exception('Simulated install error');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HealthConnectClient - Macronutrients', () {
    test('writeMealNutrition passes protein, carbs, and fat to health.writeMeal', () async {
      final fakeHealth = FakeHealth();
      final client = HealthConnectClient(health: fakeHealth);

      final timestamp = DateTime(2026, 8, 15, 12, 30);
      final result = await client.writeMealNutrition(
        calories: 520,
        proteinG: 32.5,
        carbsG: 65.0,
        fatG: 14.2,
        timestamp: timestamp,
        name: 'Chicken and Rice',
        mealType: MealType.LUNCH,
      );

      expect(result, isTrue);
      expect(fakeHealth.configureCalled, isTrue);
      expect(fakeHealth.capturedCaloriesConsumed, equals(520.0));
      expect(fakeHealth.capturedProtein, equals(32.5));
      expect(fakeHealth.capturedCarbohydrates, equals(65.0));
      expect(fakeHealth.capturedFatTotal, equals(14.2));
      expect(fakeHealth.capturedStartTime, equals(timestamp));
      expect(fakeHealth.capturedEndTime, equals(timestamp));
      expect(fakeHealth.capturedMealType, equals(MealType.LUNCH));
      expect(fakeHealth.capturedName, equals('Chicken and Rice'));
    });

    test('writeMealNutrition handles null macronutrients gracefully', () async {
      final fakeHealth = FakeHealth();
      final client = HealthConnectClient(health: fakeHealth);

      final timestamp = DateTime(2026, 8, 15, 19, 0);
      final result = await client.writeMealNutrition(
        calories: 250,
        timestamp: timestamp,
      );

      expect(result, isTrue);
      expect(fakeHealth.capturedCaloriesConsumed, equals(250.0));
      expect(fakeHealth.capturedProtein, isNull);
      expect(fakeHealth.capturedCarbohydrates, isNull);
      expect(fakeHealth.capturedFatTotal, isNull);
      expect(fakeHealth.capturedMealType, equals(MealType.UNKNOWN));
      expect(fakeHealth.capturedName, isNull);
    });

    test('installHealthConnect exposes errors instead of swallowing', () async {
      final fakeErrorHealth = FakeHealthError();
      final client = HealthConnectClient(health: fakeErrorHealth);

      expect(
        () => client.installHealthConnect(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
