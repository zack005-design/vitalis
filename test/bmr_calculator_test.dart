import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_sleep_tracker/domain/profile/bmr_calculator.dart';

void main() {
  group('BmrTdeeCalculator Unit Tests', () {
    test('calculateBmr for Male (+5 constant)', () {
      // 70kg, 175cm, 25 years old male
      // BMR = 10*70 + 6.25*175 - 5*25 + 5 = 700 + 1093.75 - 125 + 5 = 1673.75
      final bmr = BmrTdeeCalculator.calculateBmr(
        weightKg: 70,
        heightCm: 175,
        ageYears: 25,
        gender: Gender.male,
      );
      expect(bmr, equals(1673.75));
    });

    test('calculateBmr for Female (-161 constant)', () {
      // 60kg, 165cm, 28 years old female
      // BMR = 10*60 + 6.25*165 - 5*28 - 161 = 600 + 1031.25 - 140 - 161 = 1330.25
      final bmr = BmrTdeeCalculator.calculateBmr(
        weightKg: 60,
        heightCm: 165,
        ageYears: 28,
        gender: Gender.female,
      );
      expect(bmr, equals(1330.25));
    });

    test('calculateBmr for Unspecified (-78 constant)', () {
      // 70kg, 170cm, 30 years old unspecified
      // BMR = 10*70 + 6.25*170 - 5*30 - 78 = 700 + 1062.5 - 150 - 78 = 1534.5
      final bmr = BmrTdeeCalculator.calculateBmr(
        weightKg: 70,
        heightCm: 170,
        ageYears: 30,
        gender: Gender.unspecified,
      );
      expect(bmr, equals(1534.5));
    });

    test('calculateTdee with all activity multipliers', () {
      // Female 60kg, 165cm, 28yo -> BMR = 1330.25
      // Sedentary (1.2): 1330.25 * 1.2 = 1596.3 -> 1596
      expect(
        BmrTdeeCalculator.calculateTdee(
          weightKg: 60,
          heightCm: 165,
          ageYears: 28,
          gender: Gender.female,
          activityLevel: ActivityLevel.sedentary,
        ),
        equals(1596),
      );

      // Light (1.375): 1330.25 * 1.375 = 1829.09375 -> 1829
      expect(
        BmrTdeeCalculator.calculateTdee(
          weightKg: 60,
          heightCm: 165,
          ageYears: 28,
          gender: Gender.female,
          activityLevel: ActivityLevel.light,
        ),
        equals(1829),
      );

      // Moderate (1.55): 1330.25 * 1.55 = 2061.8875 -> 2062
      expect(
        BmrTdeeCalculator.calculateTdee(
          weightKg: 60,
          heightCm: 165,
          ageYears: 28,
          gender: Gender.female,
          activityLevel: ActivityLevel.moderate,
        ),
        equals(2062),
      );

      // Active (1.725): 1330.25 * 1.725 = 2294.68125 -> 2295
      expect(
        BmrTdeeCalculator.calculateTdee(
          weightKg: 60,
          heightCm: 165,
          ageYears: 28,
          gender: Gender.female,
          activityLevel: ActivityLevel.active,
        ),
        equals(2295),
      );

      // Very Active (1.9): 1330.25 * 1.9 = 2527.475 -> 2527
      expect(
        BmrTdeeCalculator.calculateTdee(
          weightKg: 60,
          heightCm: 165,
          ageYears: 28,
          gender: Gender.female,
          activityLevel: ActivityLevel.veryActive,
        ),
        equals(2527),
      );
    });

    test('Helper parsers handle various string formats', () {
      expect(BmrTdeeCalculator.parseGender('female'), equals(Gender.female));
      expect(BmrTdeeCalculator.parseGender('Female'), equals(Gender.female));
      expect(BmrTdeeCalculator.parseGender('MALE'), equals(Gender.male));
      expect(BmrTdeeCalculator.parseGender('unknown'), equals(Gender.male));

      expect(BmrTdeeCalculator.parseActivityLevel('Sedentary'), equals(ActivityLevel.sedentary));
      expect(BmrTdeeCalculator.parseActivityLevel('Light'), equals(ActivityLevel.light));
      expect(BmrTdeeCalculator.parseActivityLevel('Moderate'), equals(ActivityLevel.moderate));
      expect(BmrTdeeCalculator.parseActivityLevel('Active'), equals(ActivityLevel.active));
      expect(BmrTdeeCalculator.parseActivityLevel('Very Active'), equals(ActivityLevel.veryActive));
    });
  });
}
