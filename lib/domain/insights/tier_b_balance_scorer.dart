import 'dart:math';

class TierBBalanceScorer {
  /// Computes Daily Balance Score (0 - 100) based on weighted health vectors:
  /// - Calorie Target Adherence: 40%
  /// - Water Intake Target: 30%
  /// - Sleep Duration & Quality: 30%
  int calculateScore({
    required int caloriesLogged,
    required int calorieTarget,
    required int waterMlLogged,
    required int waterTargetMl,
    required double sleepHours,
    double targetSleepHours = 8.0,
  }) {
    if (calorieTarget <= 0 || waterTargetMl <= 0) return 75;

    // 1. Calorie Sub-Score (40 pts)
    final calDiffRatio = (caloriesLogged - calorieTarget).abs() / calorieTarget;
    final calorieSubScore = max(0.0, 40.0 * (1.0 - calDiffRatio * 1.2));

    // 2. Water Sub-Score (30 pts)
    final waterRatio = (waterMlLogged / waterTargetMl).clamp(0.0, 1.2);
    final waterSubScore = min(30.0, waterRatio * 30.0);

    // 3. Sleep Sub-Score (30 pts)
    final sleepRatio = (sleepHours / targetSleepHours).clamp(0.0, 1.2);
    final sleepSubScore = min(30.0, sleepRatio * 30.0);

    final totalScore = (calorieSubScore + waterSubScore + sleepSubScore).round();
    return totalScore.clamp(0, 100);
  }
}
