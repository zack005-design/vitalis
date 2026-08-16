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
  /// Evaluates user metrics using an advanced deterministic rule template engine
  HealthSummaryInsight generateInsight({
    required int caloriesLogged,
    required int calorieTarget,
    required int waterLoggedMl,
    required int waterTargetMl,
    required double sleepHours,
    required DateTime currentTime,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) {
    final calorieRatio = calorieTarget > 0 ? caloriesLogged / calorieTarget : 0.0;
    final waterRatio = waterTargetMl > 0 ? waterLoggedMl / waterTargetMl : 0.0;
    final hour = currentTime.hour;

    final isMorning = hour >= 5 && hour < 12;
    final isAfternoon = hour >= 12 && hour < 17;
    final isEvening = hour >= 17 && hour <= 23;

    final isDehydratedForTime = (isMorning && waterRatio < 0.15) ||
        (isAfternoon && waterRatio < 0.5) ||
        (isEvening && waterRatio < 0.75);

    final isLowProtein = proteinG < ((calorieTarget * 0.20) / 4); // under 20% protein
    final isHighCarb = carbsG > ((calorieTarget * 0.55) / 4); // over 55% carbs
    final calorieDeficit = calorieTarget - caloriesLogged;

    // 1. Morning Specific: Poor Sleep & No Hydration
    if (isMorning && sleepHours < 6.0 && waterRatio < 0.15) {
      return const HealthSummaryInsight(
        title: "Morning Recovery Lag",
        description: "You had a short night and haven't hydrated yet. Sleep debt increases cortisol, which accelerates dehydration.",
        recommendation: "Drink 500ml of water before your first meal to jumpstart your metabolism.",
        category: "sleep",
      );
    }

    // 2. Morning Specific: Great Sleep & Good Hydration
    if (isMorning && sleepHours >= 7.5 && waterRatio >= 0.2) {
      return HealthSummaryInsight(
        title: "Strong Morning Start",
        description: "Excellent recovery last night (${sleepHours.toStringAsFixed(1)}h) paired with early hydration.",
        recommendation: "Capitalize on this energy peak with a protein-rich breakfast.",
        category: "balance",
      );
    }

    // 3. Afternoon: High Carb Crash Risk
    if (isAfternoon && isHighCarb && isLowProtein) {
      return const HealthSummaryInsight(
        title: "Energy Crash Risk",
        description: "Your logged meals are carb-heavy with low protein, which often leads to an afternoon energy dip.",
        recommendation: "Opt for a protein-based snack (like Greek yogurt or almonds) to stabilize blood sugar.",
        category: "calorie",
      );
    }

    // 4. Afternoon: Dehydration Warning
    if (isAfternoon && isDehydratedForTime) {
      return HealthSummaryInsight(
        title: "Afternoon Hydration Dip",
        description: "You're halfway through the day but only at ${(waterRatio * 100).toInt()}% of your water goal. This can cause brain fog.",
        recommendation: "Keep a water bottle visible. Drink 2 glasses in the next 2 hours.",
        category: "water",
      );
    }

    // 5. Evening: High Calorie Deficit
    if (isEvening && calorieRatio < 0.6) {
      return HealthSummaryInsight(
        title: "Significant Calorie Deficit",
        description: "You still have $calorieDeficit kcal remaining for the day. Under-eating can disrupt tonight's sleep architecture.",
        recommendation: "Have a balanced, moderate dinner to ensure your body repairs overnight.",
        category: "calorie",
      );
    }

    // 6. Evening: Near Target & Wind Down
    if (isEvening && calorieRatio >= 0.85 && calorieRatio <= 1.05 && waterRatio >= 0.8) {
      return const HealthSummaryInsight(
        title: "Evening Metabolic Balance",
        description: "Your daily nutrition and hydration are right on target. Your body is primed for optimal rest.",
        recommendation: "Avoid heavy eating now. Focus on a digital wind-down routine 1 hour before bed.",
        category: "balance",
      );
    }

    // 7. General: Excellent Protein Intake
    if (!isLowProtein && proteinG > 30 && calorieRatio < 1.05) {
      return HealthSummaryInsight(
        title: "Strong Protein Alignment",
        description: "You've logged ${proteinG.toInt()}g of protein, supporting muscle maintenance and keeping you satiated.",
        recommendation: "Great job! Keep matching protein with fiber to maintain steady energy.",
        category: "calorie",
      );
    }

    // 8. General: High Hydration Offsetting Low Sleep
    if (sleepHours < 6.0 && waterRatio >= 0.8) {
      return HealthSummaryInsight(
        title: "Hydration Mitigating Sleep Debt",
        description: "Your ${(waterLoggedMl / 1000).toStringAsFixed(1)}L water intake today is buffering the cognitive fatigue from getting less than 6h sleep.",
        recommendation: "Aim for a 30-minute earlier bedtime tonight to complete recovery.",
        category: "balance",
      );
    }

    // 9. General: Optimal Alignment
    if (calorieRatio >= 0.85 && calorieRatio <= 1.05 && waterRatio >= 0.85 && sleepHours >= 7.0) {
      return const HealthSummaryInsight(
        title: "Total Vitality Alignment",
        description: "All 3 core markers (Calories, Water, Sleep) are in their ideal target zones.",
        recommendation: "Maintain this consistent rhythm. Consistency is the foundation of metabolic efficiency.",
        category: "balance",
      );
    }

    // 10. General: Late Night Snacking Risk
    if (hour >= 21 && calorieRatio > 1.1) {
      return HealthSummaryInsight(
        title: "Calorie Surplus Detected",
        description: "You are ${(caloriesLogged - calorieTarget)} kcal over target late in the evening.",
        recommendation: "Late-night digestion can impair deep sleep. Try to stop eating 2-3 hours before bed tomorrow.",
        category: "calorie",
      );
    }

    // 11. Catch-all: Very low data
    if (caloriesLogged == 0 && waterLoggedMl == 0 && sleepHours == 8.0) {
      return const HealthSummaryInsight(
        title: "Blank Canvas",
        description: "You haven't logged any data for today yet.",
        recommendation: "Start by logging your morning glass of water or your first meal.",
        category: "balance",
      );
    }

    // 12. General fallback
    return HealthSummaryInsight(
      title: "Daily Vitality Overview",
      description: "Logged $caloriesLogged kcal (${proteinG.toInt()}g P) and ${(waterLoggedMl / 1000).toStringAsFixed(1)}L water. Sleep: ${sleepHours.toStringAsFixed(1)}h.",
      recommendation: "Keep logging consistently to unlock more precise metabolic patterns.",
      category: "balance",
    );
  }
}
