import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../data/food/food_search_repository.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
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
        builder: (ctx, setLocalState) {
          final totalEnergy = (item.calories * servings).round();
          final protein = ((item.proteinG ?? 0) * servings);
          final carbs = ((item.carbsG ?? 0) * servings);
          final fat = ((item.fatG ?? 0) * servings);

          return Dialog(
            backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top close button & Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 32),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: AppColors.calorieAccent, size: 28),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.of(ctx).pop(null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.servingDescription,
                    style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Serving Size Label & Chips
                  Text(
                    "SERVING SIZE",
                    style: TextStyle(
                      fontFamily: "JetBrains Mono",
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: options.map((opt) {
                      final isSel = servings == opt;
                      return ChoiceChip(
                        label: Text("${opt}x"),
                        selected: isSel,
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: (_) => setLocalState(() => servings = opt),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Energy & Macro Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B1326) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Energy",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "$totalEnergy",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "kcal",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0x1FFFFFFF)),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _macroPill("PROTEIN", "${protein.toStringAsFixed(1)}g", AppColors.proteinAccent, isDark),
                            _macroPill("CARBS", "${carbs.toStringAsFixed(1)}g", AppColors.carbsAccent, isDark),
                            _macroPill("FAT", "${fat.toStringAsFixed(1)}g", AppColors.fatAccent, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Log Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        "Log ${servings}x serving",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(servings),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (confirmed != null) {
      await _logMeal(item, confirmed);
    }
  }

  Widget _macroPill(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: "JetBrains Mono",
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _logMeal(FoodSearchResult item, [double servings = 1.0]) async {
    HapticFeedback.mediumImpact();
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search TextField
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171F33) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.lightTextPrimary),
                  decoration: InputDecoration(
                    hintText: "Search Kerala dishes, foods...",
                    hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => ref.read(foodSearchQueryProvider.notifier).state = val,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(foodSearchQueryProvider.notifier).state = '';
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Custom Dish Action Trigger
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Foods Library",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryBlue),
              label: const Text("Custom Dish", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                AddCustomFoodSheet.show(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Search Results List
        SizedBox(
          height: 380,
          child: searchResultsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text("Error: $err")),
            data: (results) {
              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 40, color: AppColors.darkTextMuted),
                      const SizedBox(height: 8),
                      Text("No food items found", style: AppTypography.bodyMd(isDark)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = results[index];
                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${item.servingDescription} • P: ${item.proteinG?.toStringAsFixed(0) ?? '0'}g  C: ${item.carbsG?.toStringAsFixed(0) ?? '0'}g  F: ${item.fatG?.toStringAsFixed(0) ?? '0'}g",
                                style: AppTypography.footnote(isDark),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${item.calories} kcal",
                          style: const TextStyle(
                            fontSize: 15,
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
    String label;
    Color color;

    switch (source) {
      case FoodSearchSource.history:
        label = "Recent";
        color = AppColors.scoreAccent;
        break;
      case FoodSearchSource.custom:
        label = "Custom";
        color = AppColors.waterAccent;
        break;
      case FoodSearchSource.indbLocal:
        label = "INDB";
        color = AppColors.calorieAccent;
        break;
      case FoodSearchSource.openFoodFacts:
        label = "OFF";
        color = const Color(0xFFAF52DE);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
