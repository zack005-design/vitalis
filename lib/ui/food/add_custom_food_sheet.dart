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
  String? _nameError;
  String? _caloriesError;
  String? _proteinError;
  String? _carbsError;
  String? _fatError;

  bool _validateFields() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final carbs = double.tryParse(_carbsController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());

    bool valid = true;
    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
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

      valid = _nameError == null && _caloriesError == null && _proteinError == null &&
              _carbsError == null && _fatError == null;
    });
    return valid;
  }

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
    if (!_validateFields()) return;

    final name = _nameController.text.trim();
    final calories = int.parse(_caloriesController.text.trim());

    setState(() => _isSaving = true);

    final db = ref.read(appDatabaseProvider);
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save food: $e')),
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
                if (_nameError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(_nameError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: "Calories (kcal)",
                            placeholder: "0",
                            controller: _caloriesController,
                            keyboardType: TextInputType.number,
                          ),
                          if (_caloriesError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Text(_caloriesError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),
                        ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Protein Box
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
                              child: Text(
                                _proteinError!,
                                style: const TextStyle(color: Colors.red, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Carbs Box
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
                              child: Text(
                                _carbsError!,
                                style: const TextStyle(color: Colors.red, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Fat Box
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
                              child: Text(
                                _fatError!,
                                style: const TextStyle(color: Colors.red, fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
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
