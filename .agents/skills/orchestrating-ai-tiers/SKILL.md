---
name: orchestrating-ai-tiers
description: Manages runtime tier selection across Tier A (rule-based Dart templates), Tier B (TFLite NPU formula scoring), and Tier C (Gemini Nano capability-gated LLM narration). Use when implementing AI insights, daily balance scoring, or LLM fallback coordination in Flutter.
---

# Orchestrating AI Tiers

## When to use this skill
- Implementing Insights tab engines (`TierAEngine`, `TierCEngine`).
- Implementing Today tab Daily Balance Score calculation (`TierBEngine`).
- Coordinating runtime capability detection (`AiCoordinator`).

## AI Tier Architecture Summary

| Tier | Role | Capability Requirement | Primary Target Status |
|---|---|---|---|
| **Tier A** | Pure Math Rules & Templated Insights | None (Pure Dart) | ✅ Always Available (Fallback Baseline) |
| **Tier B** | Daily Balance Score (Formula or TFLite) | Any Android / NPU NNAPI Delegate | ✅ Available (MediaTek Dimensity APU / NPU) |
| **Tier C** | On-Device NPU Narration & Insights | MediaTek APU / Android NNAPI / On-Device AI | ✅ Available (100% Offline, Zero Cloud Limits) |

## Code Pattern: AI Coordinator Gateway

```dart
enum AiTier { tierA, tierB, tierC }

class AiCoordinator {
  final bool isGeminiNanoAvailable;

  AiCoordinator({this.isGeminiNanoAvailable = false});

  String getDailyInsightText({
    required String templateInsight,
    required String? llmInsight,
  }) {
    if (isGeminiNanoAvailable && llmInsight != null && llmInsight.isNotEmpty) {
      return llmInsight;
    }
    return templateInsight; // Seamless Tier A fallback
  }

  int computeBalanceScore({
    required double sleepHours,
    required double sleepTarget,
    required int caloriesLogged,
    required int calorieTarget,
    required int waterMlLogged,
    required int waterTargetMl,
  }) {
    // Tier B Formula: Normalized weighted adherence
    final sleepScore = (sleepHours / sleepTarget).clamp(0.0, 1.0) * 35;
    final calorieScore = (1.0 - ((caloriesLogged - calorieTarget).abs() / calorieTarget)).clamp(0.0, 1.0) * 35;
    final waterScore = (waterMlLogged / waterTargetMl).clamp(0.0, 1.0) * 30;

    return (sleepScore + calorieScore + waterScore).round().clamp(0, 100);
  }
}
```
