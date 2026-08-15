enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum Gender { male, female, unspecified }

/// Mifflin-St Jeor equation calculator for BMR and TDEE.
class BmrTdeeCalculator {
  /// Calculates Basal Metabolic Rate (BMR) in kcal/day.
  /// Male: +5, Female: -161, Unspecified: -78 (midpoint average).
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    Gender gender = Gender.male,
  }) {
    int s;
    switch (gender) {
      case Gender.male:
        s = 5;
        break;
      case Gender.female:
        s = -161;
        break;
      case Gender.unspecified:
        s = -78;
        break;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) + s;
  }

  /// Calculates Total Daily Energy Expenditure (TDEE) based on activity level.
  static int calculateTdee({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    Gender gender = Gender.male,
    required ActivityLevel activityLevel,
  }) {
    final bmr = calculateBmr(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      gender: gender,
    );

    double multiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        multiplier = 1.2;
        break;
      case ActivityLevel.light:
        multiplier = 1.375;
        break;
      case ActivityLevel.moderate:
        multiplier = 1.55;
        break;
      case ActivityLevel.active:
        multiplier = 1.725;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.9;
        break;
    }

    return (bmr * multiplier).round();
  }

  /// Helper to convert string activity level to ActivityLevel enum.
  static ActivityLevel parseActivityLevel(String value) {
    switch (value.trim().toLowerCase()) {
      case "sedentary":
        return ActivityLevel.sedentary;
      case "light":
        return ActivityLevel.light;
      case "active":
        return ActivityLevel.active;
      case "very active":
      case "veryactive":
        return ActivityLevel.veryActive;
      case "moderate":
      default:
        return ActivityLevel.moderate;
    }
  }

  /// Helper to convert string sex/gender to Gender enum.
  static Gender parseGender(String value) {
    switch (value.trim().toLowerCase()) {
      case "female":
        return Gender.female;
      case "male":
        return Gender.male;
      default:
        return Gender.male;
    }
  }
}
