import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/food/food_search_repository.dart';
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_field.dart';
import '../design_system/app_typography.dart';
import '../design_system/bottom_sheet_modal.dart';
import '../design_system/glass_container.dart';
import 'add_custom_food_sheet.dart';

class FoodSearchSheet extends ConsumerStatefulWidget {
  const FoodSearchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return BottomSheetModal.show(
      context: context,
      title: "Log Food",
      child: const FoodSearchSheet(),
    );
  }

  @override
  ConsumerState<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<FoodSearchSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logMeal(FoodSearchResult item) async {
    final db = ref.read(appDatabaseProvider);
    await db.insertMeal(
      MealsCompanion(
        timestamp: drift.Value(DateTime.now()),
        name: drift.Value(item.name),
        calories: drift.Value(item.calories),
        proteinG: drift.Value(item.proteinG),
        carbsG: drift.Value(item.carbsG),
        fatG: drift.Value(item.fatG),
        source: drift.Value(item.source.name),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged "${item.name}" (${item.calories} kcal)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchResultsAsync = ref.watch(foodSearchResultsProvider);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        AppTextField(
          label: "",
          placeholder: "Search Kerala dishes, packaged foods...",
          controller: _searchController,
          prefixIcon: Icons.search_rounded,
          autofocus: true,
          onChanged: (val) {
            ref.read(foodSearchQueryProvider.notifier).state = val;
          },
        ),
        const SizedBox(height: 10),

        // Custom Food Shortcut Trigger
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Search Results",
              style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Create Custom Dish"),
              onPressed: () {
                Navigator.of(context).pop();
                AddCustomFoodSheet.show(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Tiered Results List (Safely expanded inside bounded height)
        Expanded(
          child: searchResultsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text("Error loading food items", style: AppTypography.footnote(isDark)),
            ),
            data: (results) {
              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text("No matching dishes found", style: AppTypography.subhead(isDark)),
                      const SizedBox(height: 4),
                      TextButton(
                        child: const Text("Add as Custom Dish"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          AddCustomFoodSheet.show(context);
                        },
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = results[index];
                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    onTap: () => _logMeal(item),
                    child: Row(
                      children: [
                        _buildSourceBadge(item.source),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTypography.headline(isDark).copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${item.servingDescription} • P: ${item.proteinG ?? 0}g  C: ${item.carbsG ?? 0}g  F: ${item.fatG ?? 0}g",
                                style: AppTypography.footnote(isDark),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${item.calories} kcal",
                          style: AppTypography.subhead(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.calorieAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSourceBadge(FoodSearchSource source) {
    IconData icon;
    Color color;

    switch (source) {
      case FoodSearchSource.custom:
      case FoodSearchSource.history:
        icon = Icons.history_rounded;
        color = AppColors.scoreAccent;
        break;
      case FoodSearchSource.indbLocal:
        icon = Icons.offline_pin_rounded;
        color = AppColors.waterAccent;
        break;
      case FoodSearchSource.openFoodFacts:
        icon = Icons.qr_code_scanner_rounded;
        color = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
