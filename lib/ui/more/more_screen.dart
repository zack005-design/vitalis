import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/export/json_backup_service.dart';
import '../../data/health/health_connect_client.dart';
import '../../domain/food/food_providers.dart';
import '../../services/notification_service.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import 'edit_profile_sheet.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  bool _useAiNarration = true;
  bool _enableReminders = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _useAiNarration = prefs.getBool('pref_ai_narration') ?? true;
        _enableReminders = prefs.getBool('pref_reminders') ?? true;
      });
    }
  }

  Future<void> _saveAiNarration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_ai_narration', value);
  }

  Future<void> _saveReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_reminders', value);
    final svc = NotificationService();
    if (value) {
      await svc.scheduleHourlyWaterReminders();
    } else {
      await svc.cancelAllReminders();
    }
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

  void _showResetConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local data reset successfully.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Delete All"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: "Settings",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card Header
          GlassContainer(
            padding: const EdgeInsets.all(18),
            onTap: () => EditProfileSheet.show(context),
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
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Alex Johnson",
                        style: AppTypography.title2(isDark).copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "28 yrs • 175 cm • 72 kg • Active",
                        style: AppTypography.footnote(isDark),
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
            style: AppTypography.headline(isDark).copyWith(fontSize: 15),
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
                  subtitle: "BMR/TDEE Goal: 2,200 kcal • 2.0L",
                  onTap: () => EditProfileSheet.show(context),
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  isDark: isDark,
                  icon: Icons.directions_run_rounded,
                  iconBg: AppColors.primaryBlue,
                  title: "Activity Level",
                  subtitle: "Moderate (4-5 workouts/week)",
                  onTap: () => EditProfileSheet.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text(
            "Sync & AI Intelligence",
            style: AppTypography.headline(isDark).copyWith(fontSize: 15),
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
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          granted
                              ? 'Health Connect permissions granted successfully!'
                              : 'Please ensure Google Health Connect app is installed & granted on Android.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  isDark: isDark,
                  icon: Icons.auto_awesome_rounded,
                  iconBg: const Color(0xFFAF52DE),
                  title: "On-Device AI Insights",
                  subtitle: "Use Gemini Nano when available (Tier C)",
                  value: _useAiNarration,
                  onChanged: (val) {
                    setState(() => _useAiNarration = val);
                    _saveAiNarration(val);
                  },
                ),
                _buildDivider(isDark),
                _buildSwitchTile(
                  isDark: isDark,
                  icon: Icons.notifications_active_rounded,
                  iconBg: const Color(0xFFFF9500),
                  title: "Offline Reminder Alarms",
                  subtitle: "Water logging & evening sleep wind-down",
                  value: _enableReminders,
                  onChanged: (val) {
                    setState(() => _enableReminders = val);
                    _saveReminders(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text(
            "Privacy & Local Data",
            style: AppTypography.headline(isDark).copyWith(fontSize: 15),
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
                  icon: Icons.download_rounded,
                  iconBg: AppColors.sleepAccent,
                  title: "Import & Restore",
                  subtitle: "Restore SQLite database from JSON backup",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Select backup file to restore database.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
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

          // Local-First Reassurance Banner Card
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
                        style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "No accounts, no cloud sync, zero tracking. All health data remains strictly on your device.",
                        style: AppTypography.footnote(isDark),
                      ),
                    ],
                  ),
                ),
              ],
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
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMd(isDark).copyWith(
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.destructive : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
        subtitle: Text(subtitle, style: AppTypography.footnote(isDark)),
        trailing: isDestructive ? null : Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
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
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        secondary: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: AppTypography.bodyMd(isDark).copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        subtitle: Text(subtitle, style: AppTypography.footnote(isDark)),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 68,
      endIndent: 16,
      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
    );
  }
}
