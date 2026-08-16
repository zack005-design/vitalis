import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart';
import '../../data/health/health_connect_client.dart';
import '../design_system/app_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_field.dart';
import '../design_system/app_typography.dart';
import '../design_system/bottom_sheet_modal.dart';
import '../design_system/glass_container.dart';

class QuickAddFoodSheet extends ConsumerStatefulWidget {
  const QuickAddFoodSheet({super.key});

  static Future<void> show(BuildContext context) {
    return BottomSheetModal.show(
      context: context,
      title: "Quick Add Calories",
      child: const QuickAddFoodSheet(),
    );
  }

  @override
  ConsumerState<QuickAddFoodSheet> createState() => _QuickAddFoodSheetState();
}

class _QuickAddFoodSheetState extends ConsumerState<QuickAddFoodSheet> {
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  bool _isSaving = false;
  String? _caloriesError;
  String? _proteinError;
  String? _carbsError;
  String? _fatError;

  bool _validateFields() {
    final calories = int.tryParse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());

    bool valid = true;
    setState(() {
      _caloriesError = (calories == null || calories <= 0)
          ? 'Enter a number > 0'
          : calories > 5000
              ? 'Max 5000 kcal'
              : null;
      _proteinError = (_proteinController.text.trim().isNotEmpty && (protein == null || protein < 0 || protein > 500))
          ? 'Enter 0–500g'
          : null;
      _carbsError = (_carbsController.text.trim().isNotEmpty && (carbs == null || carbs < 0 || carbs > 500))
          ? 'Enter 0–500g'
          : null;
      _fatError = (_fatController.text.trim().isNotEmpty && (fat == null || fat < 0 || fat > 500))
          ? 'Enter 0–500g'
          : null;

      valid = _caloriesError == null && _proteinError == null && _carbsError == null && _fatError == null;
    });
    return valid;
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveQuickAdd() async {
    if (!_validateFields()) return;

    final calories = int.parse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());

    setState(() => _isSaving = true);

    final db = ref.read(appDatabaseProvider);
    try {
      await db.insertMeal(
        MealsCompanion(
          timestamp: drift.Value(DateTime.now()),
          name: const drift.Value("Quick Add"),
          calories: drift.Value(calories),
          proteinG: drift.Value(protein),
          carbsG: drift.Value(carbs),
          fatG: drift.Value(fat),
          source: const drift.Value("custom"),
        ),
      );

      // Background sync to Health Connect
      HealthConnectClient().writeMealNutrition(
        calories: calories,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quick added $calories kcal!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save quick add: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                AppTextField(
                  label: "Calories (kcal)",
                  placeholder: "e.g. 250",
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
                if (_caloriesError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(_caloriesError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Macronutrients", style: AppTypography.headline(isDark).copyWith(fontSize: 17)),
                    Text("Optional", style: AppTypography.labelSm(isDark)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildMacroInputBox(
                            label: "Protein",
                            icon: Icons.fitness_center_rounded,
                            iconColor: AppColors.waterAccent,
                            controller: _proteinController,
                            isDark: isDark,
                          ),
                          if (_proteinError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_proteinError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          _buildMacroInputBox(
                            label: "Carbs",
                            icon: Icons.grain_rounded,
                            iconColor: const Color(0xFFC64F00),
                            controller: _carbsController,
                            isDark: isDark,
                          ),
                          if (_carbsError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_carbsError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          _buildMacroInputBox(
                            label: "Fat",
                            icon: Icons.water_drop_rounded,
                            iconColor: AppColors.calorieAccent,
                            controller: _fatController,
                            isDark: isDark,
                          ),
                          if (_fatError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_fatError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: "Log Calories",
            icon: Icons.add_circle_outline_rounded,
            isLoading: _isSaving,
            onPressed: _saveQuickAdd,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMacroInputBox({
    required String label,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: "0",
                  ),
                ),
              ),
              Text("g", style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
