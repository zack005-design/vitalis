import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/health/health_connect_client.dart';
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import '../design_system/swipe_to_delete_row.dart';
import '../food/food_search_sheet.dart';
import '../more/edit_profile_sheet.dart';
import 'water_history_sheet.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _quickAddWater(WidgetRef ref, int amountMl) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final db = ref.read(appDatabaseProvider);
    await db.insertWaterLog(
      WaterLogsCompanion(
        amountMl: drift.Value(amountMl),
        timestamp: drift.Value(now),
      ),
    );
    // Background sync to Health Connect
    HealthConnectClient().writeWaterLog(amountMl, now).ignore();
  }

  Future<void> _deleteMeal(WidgetRef ref, Meal meal) async {
    HapticFeedback.mediumImpact();
    final db = ref.read(appDatabaseProvider);
    await db.deleteMeal(meal.id);
  }

  Future<void> _restoreMeal(WidgetRef ref, Meal meal) async {
    final db = ref.read(appDatabaseProvider);
    await db.restoreMeal(meal);
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalCaloriesLogged = ref.watch(totalCaloriesTodayProvider);
    final totalWaterLogged = ref.watch(totalWaterMlTodayProvider);
    final mealsAsync = ref.watch(todayMealsProvider);
    final lastSleep = ref.watch(lastSleepEntryProvider);
    final targetCalories = ref.watch(calorieTargetProvider);
    final targetWaterMl = ref.watch(waterTargetProvider);

    final calorieRatio = (totalCaloriesLogged / targetCalories).clamp(0.0, 1.0);
    final waterRatio = (totalWaterLogged / targetWaterMl).clamp(0.0, 1.0);

    // Compute macro totals from logged meals
    final meals = mealsAsync.value ?? [];
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    for (final m in meals) {
      totalProtein += m.proteinG ?? 0;
      totalCarbs += m.carbsG ?? 0;
      totalFat += m.fatG ?? 0;
    }

    // Target macros (estimated 30% Protein, 45% Carbs, 25% Fat)
    final targetProtein = ((targetCalories * 0.30) / 4).roundToDouble();
    final targetCarbs = ((targetCalories * 0.45) / 4).roundToDouble();
    final targetFat = ((targetCalories * 0.25) / 9).roundToDouble();

    final balanceScore = ref.watch(dailyBalanceScoreProvider);

    final dateFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return AppScaffold(
      title: "Today",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => EditProfileSheet.show(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 22,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Subtitle
          Text(
            dateFormatted,
            style: AppTypography.subhead(isDark).copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Active Energy & Macros Hero Card (Replaced Big Circular Gauge)
          GlassContainer(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.calorieAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "ACTIVE ENERGY",
                              style: TextStyle(
                                fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "$totalCaloriesLogged",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "/ $targetCalories kcal",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.calorieAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.calorieAccent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Energy Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: calorieRatio,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.calorieAccent),
                  ),
                ),
                const SizedBox(height: 20),

                const Divider(height: 1, color: Color(0x1FFFFFFF)),
                const SizedBox(height: 18),

                // Horizontal Macros Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Macronutrients",
                      style: AppTypography.subhead(isDark).copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      "${(totalProtein + totalCarbs + totalFat).toInt()}g Total",
                      style: AppTypography.footnote(isDark),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _macroProgressBar("Protein", totalProtein, targetProtein, AppColors.proteinAccent, isDark),
                const SizedBox(height: 10),
                _macroProgressBar("Carbs", totalCarbs, targetCarbs, AppColors.carbsAccent, isDark),
                const SizedBox(height: 10),
                _macroProgressBar("Fat", totalFat, targetFat, AppColors.fatAccent, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2-Column Bento: Hydration + Sleep
          Row(
            children: [
              // Hydration Card (Replaced clunky gauge with compact quick-add)
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  onTap: () => WaterHistorySheet.show(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop_rounded, color: AppColors.waterAccent, size: 18),
                              const SizedBox(width: 6),
                              Text("Water", style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text(
                            "${(totalWaterLogged / 1000).toStringAsFixed(1)}L",
                            style: TextStyle(
                              color: AppColors.waterAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Goal: ${(targetWaterMl / 1000).toStringAsFixed(1)}L",
                        style: AppTypography.footnote(isDark),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: waterRatio,
                          minHeight: 6,
                          backgroundColor: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.waterAccent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _quickWaterPill(ref, "+250", 250, isDark),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _quickWaterPill(ref, "+500", 500, isDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Sleep Card
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.nightlight_round, color: AppColors.sleepAccent, size: 18),
                          const SizedBox(width: 6),
                          Text("Sleep", style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (lastSleep != null) ...[
                        Text(
                          _formatDuration(lastSleep.durationMinutes),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastSleep.bedtime != null && lastSleep.wakeTime != null
                              ? "${DateFormat.jm().format(lastSleep.bedtime!)} - ${DateFormat.jm().format(lastSleep.wakeTime!)}"
                              : "Last recorded session",
                          style: AppTypography.footnote(isDark),
                        ),
                      ] else ...[
                        Text(
                          "--",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("No sleep logged", style: AppTypography.footnote(isDark)),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sleepAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bedtime_outlined, color: AppColors.sleepAccent, size: 14),
                            const SizedBox(width: 6),
                            Text("Goal 8h", style: TextStyle(color: AppColors.sleepAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance Score Pill Card (Stitch Spec)
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BALANCE SCORE",
                      style: TextStyle(
                        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          "$balanceScore",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "/100",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.spa_rounded, color: AppColors.primaryBlue, size: 24),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Today's Meals Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Logged Meals",
                style: AppTypography.headline(isDark).copyWith(fontSize: 18),
              ),
              Text(
                "${meals.length} items",
                style: AppTypography.labelSm(isDark),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meals List with Stitch Pill Rows
          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error loading meals: $err")),
            data: (mealList) {
              if (mealList.isEmpty) {
                return GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.restaurant_outlined, color: AppColors.darkTextMuted, size: 36),
                        const SizedBox(height: 8),
                        Text("No meals logged yet today", style: AppTypography.bodyMd(isDark)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mealList.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meal = mealList[index];
                  return SwipeToDeleteRow(
                    itemKey: ValueKey(meal.id),
                    title: meal.name,
                    onDelete: () => _deleteMeal(ref, meal),
                    onUndo: () => _restoreMeal(ref, meal),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.calorieAccent.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: AppColors.calorieAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "P: ${meal.proteinG?.toStringAsFixed(0) ?? '0'}g • C: ${meal.carbsG?.toStringAsFixed(0) ?? '0'}g • F: ${meal.fatG?.toStringAsFixed(0) ?? '0'}g",
                                  style: AppTypography.footnote(isDark),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${meal.calories} kcal",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.calorieAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),

          // Dashed Log Meal Button (Matching Stitch Mockup)
          GestureDetector(
            onTap: () => FoodSearchSheet.show(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x33171F33) : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0x44FFFFFF) : const Color(0x44000000),
                  style: BorderStyle.solid,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: isDark ? Colors.white : AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    "Log Meal",
                    style: TextStyle(
                      fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80), // Adequate bottom spacing above navigation shell
        ],
      ),
    );
  }

  Widget _quickWaterPill(WidgetRef ref, String label, int amountMl, bool isDark) {
    return GestureDetector(
      onTap: () => _quickAddWater(ref, amountMl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            "$label ml",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.waterAccent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _macroProgressBar(String label, double currentG, double targetG, Color color, bool isDark) {
    final ratio = targetG > 0 ? (currentG / targetG).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            Text(
              "${currentG.toInt()}g / ${targetG.toInt()}g",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightTextPrimary),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
