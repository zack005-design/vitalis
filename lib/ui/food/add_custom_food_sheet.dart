import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_field.dart';
import '../design_system/app_typography.dart';
import '../design_system/bottom_sheet_modal.dart';
import '../design_system/glass_container.dart';

class AddCustomFoodSheet extends ConsumerStatefulWidget {
  const AddCustomFoodSheet({super.key});

  static Future<void> show(BuildContext context) {
    return BottomSheetModal.show(
      context: context,
      title: "Create Food",
      child: const AddCustomFoodSheet(),
    );
  }

  @override
  ConsumerState<AddCustomFoodSheet> createState() => _AddCustomFoodSheetState();
}

class _AddCustomFoodSheetState extends ConsumerState<AddCustomFoodSheet> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _servingController = TextEditingController(text: "1 serving");
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _servingController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomFood() async {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());

    if (name.isEmpty || calories == null || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid dish name and calorie count.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final db = ref.read(appDatabaseProvider);
    await db.insertCustomFood(
      CustomFoodsCompanion(
        name: drift.Value(name),
        caloriesPerServing: drift.Value(calories),
        servingDescription: drift.Value(_servingController.text.trim()),
        proteinG: drift.Value(double.tryParse(_proteinController.text.trim())),
        carbsG: drift.Value(double.tryParse(_carbsController.text.trim())),
        fatG: drift.Value(double.tryParse(_fatController.text.trim())),
        createdAt: drift.Value(DateTime.now()),
      ),
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "$name" to Custom Dish Library!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Details Card
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                AppTextField(
                  label: "Food Name",
                  placeholder: "e.g., Avocado Toast / Kerala Fish Curry",
                  controller: _nameController,
                  autofocus: true,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: "Serving Size",
                        placeholder: "e.g., 1 slice / 1 plate",
                        controller: _servingController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: "Calories (kcal)",
                        placeholder: "0",
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Macronutrients Card (Stitch UI Spec with icon boxes)
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Macronutrients",
                      style: AppTypography.headline(isDark).copyWith(fontSize: 17),
                    ),
                    Text("Optional", style: AppTypography.labelSm(isDark)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Protein Box
                    Expanded(
                      child: _buildMacroInputBox(
                        label: "Protein",
                        icon: Icons.fitness_center_rounded,
                        iconColor: AppColors.waterAccent,
                        controller: _proteinController,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Carbs Box
                    Expanded(
                      child: _buildMacroInputBox(
                        label: "Carbs",
                        icon: Icons.grain_rounded,
                        iconColor: const Color(0xFFC64F00),
                        controller: _carbsController,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Fat Box
                    Expanded(
                      child: _buildMacroInputBox(
                        label: "Fat",
                        icon: Icons.water_drop_rounded,
                        iconColor: AppColors.calorieAccent,
                        controller: _fatController,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          AppButton(
            label: "Save to Library",
            icon: Icons.check_circle_rounded,
            isLoading: _isSaving,
            onPressed: _saveCustomFood,
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
