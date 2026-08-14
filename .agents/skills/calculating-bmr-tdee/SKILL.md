---
name: calculating-bmr-tdee
description: Calculates Basal Metabolic Rate (BMR) and Total Daily Energy Expenditure (TDEE) using the Mifflin-St Jeor equation to suggest non-destructive daily calorie targets. Use when implementing profile management, target suggestions, or metabolic metrics in Flutter.
---

# Calculating BMR & TDEE

## When to use this skill
- Suggesting auto-computed daily calorie targets based on user age, height, weight, gender, and activity level.
- Updating target calculations in the Profile & Goals screen.

## Mathematical Model (Mifflin-St Jeor Equation)

$$\text{BMR} = 10 \times \text{weight (kg)} + 6.25 \times \text{height (cm)} - 5 \times \text{age (years)} + s$$

Where $s$:
- Male: $+5$
- Female: $-161$
- Unspecified / Neutral: $-78$ (average midpoint)

### Activity Multipliers (TDEE)
- **Sedentary** (little or no exercise): $\text{BMR} \times 1.2$
- **Lightly Active** (light exercise 1–3 days/week): $\text{BMR} \times 1.375$
- **Moderately Active** (moderate exercise 3–5 days/week): $\text{BMR} \times 1.55$
- **Active** (hard exercise 6–7 days/week): $\text{BMR} \times 1.725$
- **Very Active** (very hard exercise & physical job): $\text{BMR} \times 1.9$

## Code Pattern: BMR & TDEE Calculator (Pure Dart)

```dart
enum ActivityLevel { sedentary, light, moderate, active, veryActive }
enum Gender { male, female, unspecified }

class BmrTdeeCalculator {
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    Gender gender = Gender.unspecified,
  }) {
    int s;
    switch (gender) {
      case Gender.male: s = 5; break;
      case Gender.female: s = -161; break;
      case Gender.unspecified: s = -78; break;
    }
    return (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears) + s;
  }

  static int calculateTdee({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    Gender gender = Gender.unspecified,
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
      case ActivityLevel.sedentary: multiplier = 1.2; break;
      case ActivityLevel.light: multiplier = 1.375; break;
      case ActivityLevel.moderate: multiplier = 1.55; break;
      case ActivityLevel.active: multiplier = 1.725; break;
      case ActivityLevel.veryActive: multiplier = 1.9; break;
    }

    return (bmr * multiplier).round();
  }
}
```

## Rules
- **Non-Destructive Principle**: Suggested calorie targets must only be presented as a recommendation; **never** silently overwrite a manually configured user target in `user_targets`.
