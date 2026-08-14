import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/circular_progress_ring.dart';
import '../design_system/glass_container.dart';
import '../design_system/swipe_to_delete_row.dart';
import '../food/food_search_sheet.dart';
import 'water_history_sheet.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _quickAddWater(WidgetRef ref, int amountMl) async {
    final db = ref.read(appDatabaseProvider);
    await db.insertWaterLog(
      WaterLogsCompanion(
        amountMl: drift.Value(amountMl),
        timestamp: drift.Value(DateTime.now()),
      ),
    );
  }

  Future<void> _deleteMeal(WidgetRef ref, int id) async {
    final db = ref.read(appDatabaseProvider);
    await db.deleteMeal(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalCaloriesLogged = ref.watch(totalCaloriesTodayProvider);
    final totalWaterLogged = ref.watch(totalWaterMlTodayProvider);
    final mealsAsync = ref.watch(todayMealsProvider);

    const targetCalories = 2200;
    const targetWaterMl = 2000;

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

    return AppScaffold(
      title: "Today",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak & Vitality Banner Badge
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.calorieAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text("🔥", style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "4-Day Vitality Streak!",
                        style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Consistent logging boosts energy balance prediction accuracy.",
                        style: AppTypography.footnote(isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bento Concentric Rings Card (Calories + Water Dual Ring)
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                BentoConcentricRings(
                  calorieProgress: calorieRatio,
                  waterProgress: waterRatio,
                  caloriesLogged: totalCaloriesLogged,
                  waterMlLogged: totalWaterLogged,
                  waterTargetMl: targetWaterMl,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendItem("Calories", "${(calorieRatio * 100).toInt()}%", AppColors.calorieAccent, isDark),
                    const SizedBox(width: 32),
                    _legendItem("Water", "${(totalWaterLogged / 1000).toStringAsFixed(1)}L", AppColors.waterAccent, isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2-Column Bento Grid: Sleep Card + Balance Score Card
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.nightlight_round, color: AppColors.sleepAccent, size: 20),
                          const SizedBox(width: 8),
                          Text("Sleep", style: AppTypography.subhead(isDark)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "7h 24m",
                        style: AppTypography.title2(isDark).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Light sleep optimal",
                        style: AppTypography.footnote(isDark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.balance_rounded, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text("Balance Score", style: AppTypography.subhead(isDark)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "88 /100",
                        style: AppTypography.title2(isDark).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Hydration balance high",
                        style: AppTypography.footnote(isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Macro Breakdown Glass Card
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Macronutrients Breakdown", style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _macroProgressBar("Protein", totalProtein, 140, AppColors.calorieAccent, isDark),
                const SizedBox(height: 10),
                _macroProgressBar("Carbohydrates", totalCarbs, 250, AppColors.waterAccent, isDark),
                const SizedBox(height: 10),
                _macroProgressBar("Healthy Fats", totalFat, 65, AppColors.warning, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Water Quick Log Trigger Bar
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onTap: () => WaterHistorySheet.show(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.waterAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: AppColors.waterAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hydration Tracker",
                        style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${(totalWaterLogged / 1000).toStringAsFixed(1)}L / 2.0L logged",
                        style: AppTypography.footnote(isDark),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    foregroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                    ),
                  ),
                  onPressed: () => _quickAddWater(ref, 250),
                  child: const Text("+250ml", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.waterAccent,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _quickAddWater(ref, 500),
                  child: const Text("+500ml", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Log Food Action Button
          AppButton(
            label: "Log Food",
            icon: Icons.restaurant_rounded,
            onPressed: () => FoodSearchSheet.show(context),
          ),
          const SizedBox(height: 24),

          // Today's Logged Meals Section with Deletion Support
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Meals", style: AppTypography.headline(isDark)),
              Text("${meals.length} items logged", style: AppTypography.footnote(isDark)),
            ],
          ),
          const SizedBox(height: 10),

          if (meals.isEmpty)
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text("No meals logged today yet. Tap 'Log Food' above!", style: AppTypography.bodyMd(isDark)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return SwipeToDeleteRow(
                  itemKey: ValueKey(meal.id),
                  title: meal.name,
                  onDelete: () => _deleteMeal(ref, meal.id),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                style: AppTypography.headline(isDark).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "P: ${meal.proteinG ?? 0}g  C: ${meal.carbsG ?? 0}g  F: ${meal.fatG ?? 0}g",
                                style: AppTypography.footnote(isDark),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "${meal.calories} kcal",
                              style: AppTypography.bodyMd(isDark).copyWith(
                                color: AppColors.calorieAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.destructive, size: 20),
                              onPressed: () => _deleteMeal(ref, meal.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          "$label ($value)",
          style: AppTypography.footnote(isDark).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _macroProgressBar(String label, double currentG, double targetG, Color color, bool isDark) {
    final ratio = (currentG / targetG).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.footnote(isDark)),
            Text("${currentG.toInt()}g / ${targetG.toInt()}g", style: AppTypography.footnote(isDark).copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
