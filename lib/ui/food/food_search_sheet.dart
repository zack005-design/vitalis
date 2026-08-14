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

  Future<void> _showServingPicker(FoodSearchResult item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double servings = 1.0;
    final List<double> options = [0.5, 1.0, 1.5, 2.0, 3.0];

    final confirmed = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.servingDescription, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 16),
              // Serving count selector chips
              Wrap(
                spacing: 8,
                children: options.map((opt) => ChoiceChip(
                  label: Text("${opt}x"),
                  selected: servings == opt,
                  selectedColor: AppColors.primaryBlue,
                  onSelected: (_) => setLocalState(() => servings = opt),
                )).toList(),
              ),
              const SizedBox(height: 16),
              // Live calorie/macro preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statPill("Cal", "${(item.calories * servings).round()} kcal"),
                    _statPill("P", "${((item.proteinG ?? 0) * servings).toStringAsFixed(1)}g"),
                    _statPill("C", "${((item.carbsG ?? 0) * servings).toStringAsFixed(1)}g"),
                    _statPill("F", "${((item.fatG ?? 0) * servings).toStringAsFixed(1)}g"),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(servings),
              child: Text("Log ${servings}x serving"),
            ),
          ],
        ),
      ),
    );

    if (confirmed != null) {
      await _logMeal(item, confirmed);
    }
  }

  Widget _statPill(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
  }

  Future<void> _logMeal(FoodSearchResult item, [double servings = 1.0]) async {
    final db = ref.read(appDatabaseProvider);
    await db.insertMeal(
      MealsCompanion(
        timestamp: drift.Value(DateTime.now()),
        name: drift.Value(item.name),
        calories: drift.Value((item.calories * servings).round()),
        proteinG: drift.Value(item.proteinG != null ? item.proteinG! * servings : null),
        carbsG: drift.Value(item.carbsG != null ? item.carbsG! * servings : null),
        fatG: drift.Value(item.fatG != null ? item.fatG! * servings : null),
        source: drift.Value(item.source.name),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged "${item.name}" (${(item.calories * servings).round()} kcal)'),
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
                    onTap: () => _showServingPicker(item),
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
