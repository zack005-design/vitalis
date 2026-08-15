import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/profile/profile_provider.dart';
import '../../domain/food/food_providers.dart';
import '../../domain/profile/bmr_calculator.dart';
import '../design_system/app_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_field.dart';
import '../design_system/app_typography.dart';
import '../design_system/bottom_sheet_modal.dart';
import '../design_system/glass_container.dart';
import '../design_system/segmented_control.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return BottomSheetModal.show(
      context: context,
      title: "Edit Profile & Goals",
      child: const EditProfileSheet(),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  late String _sex;
  late String _activityLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _heightController = TextEditingController(text: profile.height.toStringAsFixed(0));
    _weightController = TextEditingController(text: profile.weight.toStringAsFixed(0));
    _sex = profile.sex;
    _activityLevel = profile.activityLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  int get _calculatedTdee {
    final age = int.tryParse(_ageController.text) ?? 28;
    final height = double.tryParse(_heightController.text) ?? 175;
    final weight = double.tryParse(_weightController.text) ?? 72;

    return BmrTdeeCalculator.calculateTdee(
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      gender: BmrTdeeCalculator.parseGender(_sex),
      activityLevel: BmrTdeeCalculator.parseActivityLevel(_activityLevel),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final tdee = _calculatedTdee;
    final age = int.tryParse(_ageController.text) ?? 28;
    final height = double.tryParse(_heightController.text) ?? 175;
    final weight = double.tryParse(_weightController.text) ?? 72;

    await ref.read(userProfileProvider.notifier).updateProfile(
      name: _nameController.text.trim(),
      age: age,
      height: height,
      weight: weight,
      sex: _sex,
      activityLevel: _activityLevel,
    );
    await ref.read(calorieTargetProvider.notifier).setTarget(tdee);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated! Target set to $tdee kcal/day')),
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
          // Profile Photo Header
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Profile Details",
                  style: AppTypography.labelSm(isDark).copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary Inputs Card
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: "Name",
                  placeholder: "Full Name",
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                Text(
                  "Biological Sex",
                  style: AppTypography.labelSm(isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedControl<String>(
                  selectedValue: _sex,
                  options: const {
                    "Male": "Male",
                    "Female": "Female",
                  },
                  onValueChanged: (val) {
                    setState(() => _sex = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: "Age (yrs)",
                        placeholder: "28",
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.cake_outlined,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: "Height (cm)",
                        placeholder: "175",
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.height_rounded,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: "Weight (kg)",
                  placeholder: "72",
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.scale_outlined,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Activity Level Selector
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Activity Level",
                  style: AppTypography.labelSm(isDark).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _activityLevel,
                  dropdownColor: isDark ? const Color(0xFF171F33) : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.directions_run_rounded, color: AppColors.primaryBlue),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Sedentary", child: Text("Sedentary (Little/no exercise)")),
                    DropdownMenuItem(value: "Light", child: Text("Light (1-3 days/week)")),
                    DropdownMenuItem(value: "Moderate", child: Text("Moderate (4-5 days/week)")),
                    DropdownMenuItem(value: "Active", child: Text("Active (Daily exercise)")),
                    DropdownMenuItem(value: "Very Active", child: Text("Very Active (Intense daily)")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _activityLevel = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.calorieAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.calorieAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Calculated TDEE Target: $_calculatedTdee kcal/day",
                          style: AppTypography.bodyMd(isDark).copyWith(
                            color: AppColors.calorieAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          AppButton(
            label: "Update Profile & Goals",
            icon: Icons.check_circle_rounded,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
