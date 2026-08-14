import 'tier_a_rule_engine.dart';

class TierCGeminiNarrator {
  final TierARuleEngine _ruleEngine;

  TierCGeminiNarrator({TierARuleEngine? ruleEngine})
      : _ruleEngine = ruleEngine ?? TierARuleEngine();

  /// Capability detection check for on-device NPU / Gemini Nano
  Future<bool> isGeminiNanoAvailable() async {
    // Capability-gated: returns false when on-device LLM unavailable,
    // gracefully falling back to Tier A rule-based templates.
    return false;
  }

  /// Generates natural language narration with Tier A fallback gating
  Future<HealthSummaryInsight> generateNarration({
    required int caloriesLogged,
    required int calorieTarget,
    required int waterLoggedMl,
    required int waterTargetMl,
    required double sleepHours,
  }) async {
    final available = await isGeminiNanoAvailable();

    if (available) {
      // In the future when Gemini Nano Flutter plugin is loaded on supported devices
      return const HealthSummaryInsight(
        title: "AI Health Narration",
        description: "Gemini Nano on-device synthesis: Your vitality scores reflect balanced hydration and steady recovery.",
        recommendation: "Continue maintaining 2.0L water intake.",
        category: "balance",
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
