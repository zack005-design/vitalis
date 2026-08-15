import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
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
      title: "Food & Nutrition",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Bar with Barcode Icon
          Semantics(
            button: true,
            label: "Search foods, meals, or dishes",
            child: GestureDetector(
              onTap: () => FoodSearchSheet.show(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF171F33) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Search foods, meals, or dishes...",
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 18,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4 Grid Action Tiles (Stitch Mockup)
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.restaurant_menu_rounded,
                  label: "My Meals",
                  color: AppColors.calorieAccent,
                  isDark: isDark,
                  onTap: () => FoodSearchSheet.show(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.star_rounded,
                  label: "Favorites",
                  color: Colors.amber,
                  isDark: isDark,
                  onTap: () => FoodSearchSheet.show(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.auto_awesome_rounded,
                  label: "Quick Add",
                  color: AppColors.primaryBlue,
                  isDark: isDark,
                  onTap: () => FoodSearchSheet.show(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.add_rounded,
                  label: "Custom Dish",
                  color: AppColors.waterAccent,
                  isDark: isDark,
                  onTap: () => AddCustomFoodSheet.show(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Logged Foods Today
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Logged Today",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                "$totalCalories kcal",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.calorieAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          mealsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error: $err")),
            data: (meals) {
              if (meals.isEmpty) {
                return GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.lunch_dining_rounded, color: AppColors.darkTextMuted, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          "No meals logged yet today.\nTap Search or Custom Dish to add one.",
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd(isDark),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.calorieAccent.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant_rounded, color: AppColors.calorieAccent, size: 20),
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
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.destructive, size: 20),
                          tooltip: "Delete ${meal.name}",
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final db = ref.read(appDatabaseProvider);
                            try {
                              await db.deleteMeal(meal.id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete meal: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171F33) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
