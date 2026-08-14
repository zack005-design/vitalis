import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import '../design_system/swipe_to_delete_row.dart';
import 'add_custom_food_sheet.dart';
import 'food_search_sheet.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mealsAsync = ref.watch(todayMealsProvider);
    final totalCalories = ref.watch(totalCaloriesTodayProvider);

    return AppScaffold(
      title: "Food",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Bar (Stitch UI Spec)
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () => FoodSearchSheet.show(context),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Search meals...",
                    style: AppTypography.bodyMd(isDark).copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
                const Icon(Icons.mic_rounded, color: AppColors.lightTextMuted),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Today's Total Calories Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today",
                style: AppTypography.headlineMd(isDark),
              ),
              Text(
                "$totalCalories kcal total",
                style: AppTypography.bodyMd(isDark).copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logged Meals List grouped by Meal Categories
          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error: $err")),
            data: (meals) {
              if (meals.isEmpty) {
                // Initial Default Kerala / South Indian Meal Examples (Matching Stitch Spec)
                return Column(
                  children: [
                    _buildMealSection(
                      context,
                      isDark: isDark,
                      title: "Breakfast",
                      mealName: "Masala Dosa",
                      calories: 350,
                      protein: 8.0,
                      carbs: 55.0,
                      fat: 12.0,
                    ),
                    const SizedBox(height: 16),
                    _buildMealSection(
                      context,
                      isDark: isDark,
                      title: "Lunch",
                      mealName: "Kerala Fish Curry & Boiled Rice",
                      calories: 420,
                      protein: 24.0,
                      carbs: 48.0,
                      fat: 14.0,
                    ),
                    const SizedBox(height: 16),
                    _buildMealSection(
                      context,
                      isDark: isDark,
                      title: "Snacks",
                      mealName: "Pazham Pori (Banana Fritters)",
                      calories: 180,
                      protein: 2.5,
                      carbs: 32.0,
                      fat: 6.0,
                    ),
                  ],
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  return SwipeToDeleteRow(
                    itemKey: ValueKey(meal.id),
                    title: meal.name,
                    onDelete: () {
                      final db = ref.read(appDatabaseProvider);
                      db.deleteMeal(meal.id);
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  meal.name,
                                  style: AppTypography.headline(isDark).copyWith(fontSize: 17),
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
                                    onPressed: () {
                                      final db = ref.read(appDatabaseProvider);
                                      db.deleteMeal(meal.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                _macroColumn("Protein", "${meal.proteinG ?? 0}g", isDark),
                                const SizedBox(width: 24),
                                _macroColumn("Carbs", "${meal.carbsG ?? 0}g", isDark),
                                const SizedBox(width: 24),
                                _macroColumn("Fat", "${meal.fatG ?? 0}g", isDark),
                              ],
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
          const SizedBox(height: 24),

          // Add Custom Food Glass Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_rounded, color: AppColors.primaryBlue),
              label: Text(
                "Add Custom Food",
                style: AppTypography.bodyMd(isDark).copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => AddCustomFoodSheet.show(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String mealName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyLg(isDark).copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mealName,
                    style: AppTypography.headline(isDark).copyWith(fontSize: 17),
                  ),
                  Text(
                    "$calories kcal",
                    style: AppTypography.bodyMd(isDark).copyWith(
                      color: AppColors.calorieAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _macroColumn("Protein", "${protein}g", isDark),
                    const SizedBox(width: 24),
                    _macroColumn("Carbs", "${carbs}g", isDark),
                    const SizedBox(width: 24),
                    _macroColumn("Fat", "${fat}g", isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _macroColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSm(isDark)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
