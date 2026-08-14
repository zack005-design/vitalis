class HealthSummaryInsight {
  final String title;
  final String description;
  final String recommendation;
  final String category; // 'calorie' | 'water' | 'sleep' | 'balance'

  const HealthSummaryInsight({
    required this.title,
    required this.description,
    required this.recommendation,
    required this.category,
  });
}

class TierARuleEngine {
  /// Evaluates user metrics using deterministic rule templates
  HealthSummaryInsight generateInsight({
    required int caloriesLogged,
    required int calorieTarget,
    required int waterLoggedMl,
    required int waterTargetMl,
    required double sleepHours,
  }) {
    final calorieRatio = calorieTarget > 0 ? caloriesLogged / calorieTarget : 0.0;
    final waterRatio = waterTargetMl > 0 ? waterLoggedMl / waterTargetMl : 0.0;

    // Rule 1: High hydration offsetting low sleep
    if (sleepHours < 6.0 && waterRatio >= 0.8) {
      return const HealthSummaryInsight(
        title: "Hydration Mitigating Sleep Debt",
        description: "Your 2.0L+ water intake today helped buffer cognitive fatigue from getting less than 6h sleep last night.",
        recommendation: "Aim for a 30-minute earlier bedtime tonight to complete recovery.",
        category: "balance",
      );
    }

    // Rule 2: Calorie deficit with optimal hydration
    if (calorieRatio >= 0.75 && calorieRatio <= 1.05 && waterRatio >= 0.8 && sleepHours >= 7.0) {
      return const HealthSummaryInsight(
        title: "Optimal Metabolic Alignment",
        description: "All 3 vitality markers (Calories, Water, Sleep) are within target ranges today.",
        recommendation: "Maintain this consistent rhythm for improved metabolic efficiency.",
        category: "balance",
      );
    }

    // Rule 3: Dehydration risk
    if (waterRatio < 0.4 && caloriesLogged > 1200) {
      return const HealthSummaryInsight(
        title: "Hydration Attention Required",
        description: "Water intake is currently below 40% of your daily 2.0L target.",
        recommendation: "Drink 500ml of water now to maintain hydration balance.",
        category: "water",
      );
    }

    // Rule 4: General default fallback template
    return HealthSummaryInsight(
      title: "Daily Balance Overview",
      description: "Logged $caloriesLogged kcal and ${waterLoggedMl}ml water with ${sleepHours.toStringAsFixed(1)}h sleep recorded.",
      recommendation: "Keep logging meals and water consistently to unlock detailed trends.",
      category: "balance",
    );
  }
}
