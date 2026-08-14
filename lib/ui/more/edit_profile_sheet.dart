import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_text_field.dart';
import '../design_system/app_typography.dart';
import '../design_system/bottom_sheet_modal.dart';
import '../design_system/glass_container.dart';

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
  final _nameController = TextEditingController(text: "Alex Johnson");
  final _ageController = TextEditingController(text: "28");
  final _heightController = TextEditingController(text: "175");
  final _weightController = TextEditingController(text: "72");

  String _activityLevel = "Moderate";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('profile_name') ?? "Alex Johnson";
        _ageController.text = (prefs.getInt('profile_age') ?? 28).toString();
        _heightController.text = (prefs.getDouble('profile_height') ?? 175.0).toStringAsFixed(0);
        _weightController.text = (prefs.getDouble('profile_weight') ?? 72.0).toStringAsFixed(0);
        _activityLevel = prefs.getString('profile_activity') ?? "Moderate";
      });
    }
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

    // Mifflin-St Jeor Formula
    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;

    double multiplier = 1.2;
    switch (_activityLevel) {
      case "Light":
        multiplier = 1.375;
        break;
      case "Moderate":
        multiplier = 1.55;
        break;
      case "Active":
        multiplier = 1.725;
        break;
      case "Very Active":
        multiplier = 1.9;
        break;
    }
    return (bmr * multiplier).round();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final tdee = _calculatedTdee;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setInt('profile_age', int.tryParse(_ageController.text) ?? 28);
    await prefs.setDouble('profile_height', double.tryParse(_heightController.text) ?? 175);
    await prefs.setDouble('profile_weight', double.tryParse(_weightController.text) ?? 72);
    await prefs.setString('profile_activity', _activityLevel);
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
              children: [
                AppTextField(
                  label: "Name",
                  placeholder: "Full Name",
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
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
