import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/export/json_backup_service.dart';
import '../../data/health/health_connect_client.dart';
import '../../domain/food/food_providers.dart';
import '../../services/notification_service.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import '../../domain/profile/profile_provider.dart';
import '../../data/debug/demo_data_injector.dart';
import 'edit_profile_sheet.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    final db = ref.read(appDatabaseProvider);
    final backupService = JsonBackupService(db: db);

    try {
      final file = await backupService.exportToJson();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup exported successfully to ${file.path.split('/').last}'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : "?";
    return "${parts[0][0]}${parts.last[0]}".toUpperCase();
  }

  Future<void> _importData() async {
    // Let the user pick a JSON backup file (file_picker v12 single-file API)
    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e')),
        );
      }
      return;
    }

    if (picked == null) {
      // User cancelled the picker — do nothing
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final bytes = await picked.readAsBytes();
      final jsonString = String.fromCharCodes(bytes);
      final db = ref.read(appDatabaseProvider);
      final backupService = JsonBackupService(db: db);
      final importedCount = await backupService.importFromJson(jsonString);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully restored $importedCount records from backup.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid backup file format: ${e.message}'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    }
  }

  void _showResetConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset All Data?", style: AppTypography.headline(isDark)),
        content: Text(
          "This will permanently delete all logged meals, water history, and sleep notes. This action cannot be undone.",
          style: AppTypography.bodyMd(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final db = ref.read(appDatabaseProvider);
              await db.delete(db.meals).go();
              await db.delete(db.waterLogs).go();
              await db.delete(db.sleepNotes).go();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Local database cleared successfully.'),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
                  ),
                );
              }
            },
            child: const Text("Delete All"),
          ),
        ],
      ),
    );
  }

  void _showDemoDataActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Inject Demo Data",
                  style: AppTypography.headline(isDark),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose how many days of randomized data to inject.",
                  style: AppTypography.bodyMd(isDark),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.calendar_view_week_rounded),
                  title: const Text("7 Days"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _injectDemoData(7);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_rounded),
                  title: const Text("30 Days"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _injectDemoData(30);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_view_month_rounded),
                  title: const Text("90 Days"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _injectDemoData(90);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _injectDemoData(int days) async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }
    try {
      final db = ref.read(appDatabaseProvider);
      final injector = DemoDataInjector(db);
      await injector.injectData(days);
      
      // Update UserProfile
      final random = math.Random();
      final names = ['Alex Johnson', 'Sam Smith', 'Jordan Lee', 'Taylor Doe', 'Riley Chen'];
      final randomName = names[random.nextInt(names.length)];
      final randomAge = 20 + random.nextInt(40);
      final randomHeight = 150.0 + random.nextInt(50);
      final randomWeight = 50.0 + random.nextInt(50);
      final randomSex = random.nextBool() ? 'Male' : 'Female';
      final activities = ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'];
      final randomActivity = activities[random.nextInt(activities.length)];

      await ref.read(userProfileProvider.notifier).updateProfile(
        name: randomName,
        age: randomAge,
        height: randomHeight,
        weight: randomWeight,
        sex: randomSex,
        activityLevel: randomActivity,
      );

      // Update Targets
      final randomCalorieTarget = 1500 + random.nextInt(1000);
      await ref.read(calorieTargetProvider.notifier).setTarget(randomCalorieTarget);

      final randomWaterTarget = 1500 + (random.nextInt(6) * 250);
      await ref.read(waterTargetProvider.notifier).setTarget(randomWaterTarget);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully injected $days days of demo data.'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to inject data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calorieTarget = ref.watch(calorieTargetProvider);
    final waterTarget = ref.watch(waterTargetProvider);
    final userProfile = ref.watch(userProfileProvider);
    
    final profileName = userProfile.name;
    final activityLevel = userProfile.activityLevel;
    final profileDetails = "${userProfile.sex} • ${userProfile.age} yrs • ${userProfile.height.toStringAsFixed(0)} cm • ${userProfile.weight.toStringAsFixed(0)} kg • ${userProfile.activityLevel}";
    final useAiNarration = userProfile.useAiNarration;
    final enableReminders = userProfile.enableReminders;

    return AppScaffold(
      title: "Settings",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card Header
          GlassContainer(
            padding: const EdgeInsets.all(18),
            onTap: () async {
              await EditProfileSheet.show(context);
            },
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.waterAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(profileName),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profileDetails,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text(
            "Metabolic Targets",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Group 1: Targets & Profile
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.track_changes_rounded,
                  iconBg: AppColors.calorieAccent,
                  title: "Calorie & Water Goals",
                  subtitle: "Daily Target: $calorieTarget kcal • ${(waterTarget / 1000).toStringAsFixed(1)}L",
                  onTap: () async {
                    await EditProfileSheet.show(context);
                  },
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.directions_run_rounded,
                  iconBg: AppColors.primaryBlue,
                  title: "Activity Level",
                  subtitle: "$activityLevel activity tier",
                  onTap: () async {
                    await EditProfileSheet.show(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text(
            "Sync & AI Intelligence",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Group 2: Integrations & AI
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.health_and_safety_rounded,
                  iconBg: const Color(0xFF34C759),
                  title: "Health Connect Grants",
                  subtitle: "Sleep sessions, Hydration & Nutrition sync",
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final client = HealthConnectClient();
                    final granted = await client.requestPermissions();
                    if (granted) {
                      final db = ref.read(appDatabaseProvider);
                      await client.syncFromHealthConnect(db);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Connected to Google Health Connect! Two-way sync complete.'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
                        ),
                      );
                    } else {
                      await client.installHealthConnect();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Please grant Health Connect permissions in Android Settings.'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(bottom: 80, left: 16, right: 16),
                        ),
                      );
                    }
                  },
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  isDark: isDark,
                  icon: Icons.auto_awesome_rounded,
                  iconBg: const Color(0xFFAF52DE),
                  title: "On-Device AI Insights",
                  subtitle: "Use Gemini Nano when available (Tier C)",
                  value: useAiNarration,
                  onChanged: (val) async {
                    await ref.read(userProfileProvider.notifier).setAiNarration(val);
                  },
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  isDark: isDark,
                  icon: Icons.notifications_active_rounded,
                  iconBg: const Color(0xFFFF9500),
                  title: "Offline Reminder Alarms",
                  subtitle: "Water logging & evening sleep wind-down",
                  value: enableReminders,
                  onChanged: (val) async {
                    await ref.read(userProfileProvider.notifier).setReminders(val);
                    try {
                      final svc = NotificationService();
                      if (val) {
                        await svc.scheduleHourlyWaterReminders();
                      } else {
                        await svc.cancelAllReminders();
                      }
                    } catch (e) {
                      debugPrint('Notification toggle error: $e');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text(
            "Privacy & Local Data",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Group 3: Data Management
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.ios_share_rounded,
                  iconBg: AppColors.waterAccent,
                  title: "Export Data (JSON)",
                  subtitle: "Save timestamped backup via OS Share Sheet",
                  isLoading: _isExporting,
                  onTap: _isExporting ? null : _exportData,
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.file_download_rounded,
                  iconBg: const Color(0xFF9C27B0),
                  title: "Restore from Backup",
                  subtitle: "Import local JSON data file",
                  onTap: _importData,
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.delete_forever_rounded,
                  iconBg: AppColors.destructive,
                  title: "Reset Local Data",
                  subtitle: "Purge all local meals, water, and notes",
                  isDestructive: true,
                  onTap: _showResetConfirmation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "Developer / Testing",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.science_rounded,
                  iconBg: const Color(0xFFFF5722),
                  title: "Inject Demo Data",
                  subtitle: "Add randomized meals, water, and sleep",
                  onTap: () {
                    _showDemoDataActionSheet(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Local-First Privacy Reassurance Card
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "100% Offline & Private",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "No accounts, no cloud sync, zero tracking. All health data remains strictly on your device.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Group 4: About / App Info
          GlassContainer(
            padding: EdgeInsets.zero,
            child: _buildSettingsTile(
              isDark: isDark,
              icon: Icons.info_outline_rounded,
              iconBg: const Color(0xFF607D8B),
              title: "About",
              subtitle: "Vitality Tracker v1.2.0",
              onTap: () {},
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconBg, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDestructive
                ? AppColors.destructive
                : (isDark ? Colors.white : AppColors.lightTextPrimary),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        trailing: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconBg, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: AppColors.primaryBlue,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 68,
      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
    );
  }
}
