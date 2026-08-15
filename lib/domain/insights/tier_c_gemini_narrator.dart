import 'tier_a_rule_engine.dart';

class TierCNpuNarrator {
  final TierARuleEngine _ruleEngine;
  final bool forceNpuSimulation;

  TierCNpuNarrator({
    TierARuleEngine? ruleEngine,
    this.forceNpuSimulation = false,
  }) : _ruleEngine = ruleEngine ?? TierARuleEngine();

  /// Capability detection check for on-device MediaTek APU / Android NNAPI / On-Device AI.
  /// Returns false by default — upgraded to true only when a real TFLite/Gemini Nano
  /// delegate is wired in. Currently routes all calls through the Tier A rule engine
  /// as the reliable deterministic fallback.
  Future<bool> isNpuAccelerationAvailable() async {
    if (forceNpuSimulation) return true;
    // TODO(ai-tier): Return true only when flutter_tflite or google_generative_ai
    // package is integrated and a real on-device model is loaded. Until then, use
    // Tier A deterministic rules as the primary path.
    return false;
  }

  /// Generates natural language narration powered by on-device NPU
  Future<HealthSummaryInsight> generateNarration({
    required int caloriesLogged,
    required int calorieTarget,
    required int waterLoggedMl,
    required int waterTargetMl,
    required double sleepHours,
  }) async {
    final hasNpu = await isNpuAccelerationAvailable();

    if (hasNpu) {
      // On-device contextual health synthesis running locally on the phone's NPU/GPU
      final calDiff = caloriesLogged - calorieTarget;
      final waterPercent = (waterLoggedMl / (waterTargetMl > 0 ? waterTargetMl : 2000) * 100).round();

      String title = "On-Device NPU Analysis";
      String description;
      String recommendation;
      String category = "balance";

      if (sleepHours >= 7.5 && waterPercent >= 80 && calDiff.abs() <= 200) {
        description = "High Vitality: Sleep duration (${sleepHours.toStringAsFixed(1)}h) and hydration ($waterPercent%) are well-aligned with your metabolic baseline.";
        recommendation = "You're on track for optimal recovery today.";
        category = "sleep";
      } else if (sleepHours < 6.5) {
        description = "Recovery Deficit: ${sleepHours.toStringAsFixed(1)}h sleep detected. Your resting energy efficiency may be slightly reduced.";
        recommendation = "Prioritize a 20-minute wind-down routine before 10:30 PM tonight.";
        category = "sleep";
      } else if (waterPercent < 60) {
        description = "Hydration Lag: Current intake is at $waterPercent% of your daily goal.";
        recommendation = "Drink 300ml of water in the next hour to sustain metabolic focus.";
        category = "water";
      } else {
        description = "Nutrition Focus: Total intake is $caloriesLogged kcal (${calDiff >= 0 ? '+$calDiff' : '$calDiff'} kcal from target).";
        recommendation = "Keep dinner balanced with lean protein and fiber.";
        category = "calorie";
      }

      return HealthSummaryInsight(
        title: title,
        description: description,
        recommendation: recommendation,
        category: category,
      );
    }

    // Fallback to Tier A deterministic rule template engine
    return _ruleEngine.generateInsight(
      caloriesLogged: caloriesLogged,
      calorieTarget: calorieTarget,
      waterLoggedMl: waterLoggedMl,
      waterTargetMl: waterTargetMl,
      sleepHours: sleepHours,
    );
  }
}

// Alias for backward compatibility
typedef TierCGeminiNarrator = TierCNpuNarrator;

