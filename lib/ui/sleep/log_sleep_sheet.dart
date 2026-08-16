import 'package:drift/drift.dart' as drift;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/health/health_connect_client.dart';
import '../../data/local/app_database.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';
import '../design_system/bottom_sheet_modal.dart';
import '../design_system/glass_container.dart';
import 'active_sleep_tracker_screen.dart';

class SleepRange {
  final DateTime bed;
  final DateTime wake;

  const SleepRange({required this.bed, required this.wake});

  int get durationMinutes => wake.difference(bed).inMinutes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepRange &&
          runtimeType == other.runtimeType &&
          bed == other.bed &&
          wake == other.wake;

  @override
  int get hashCode => bed.hashCode ^ wake.hashCode;

  @override
  String toString() => 'SleepRange(bed: $bed, wake: $wake)';
}

/// Calculates [SleepRange] (bed and wake [DateTime]s) given [bedtime] and [wakeTime].
///
/// If bedtime is in the evening and wake time is in the morning (overnight sleep),
/// bedtime is anchored to yesterday's date so it does not calculate into the future.
/// If bedtime is later today than [now] (e.g., logging yesterday's nap in the morning),
/// both timestamps are shifted to yesterday.
SleepRange calculateSleepRange(TimeOfDay bedtime, TimeOfDay wakeTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  var bed = DateTime(current.year, current.month, current.day, bedtime.hour, bedtime.minute);
  var wake = DateTime(current.year, current.month, current.day, wakeTime.hour, wakeTime.minute);

  if (wake.isBefore(bed)) {
    // Bedtime was yesterday (overnight sleep crossing midnight)
    bed = bed.subtract(const Duration(days: 1));
  } else if (bed.isAfter(current)) {
    // Bedtime is currently in the future today (e.g. logging yesterday's nap)
    bed = bed.subtract(const Duration(days: 1));
    wake = wake.subtract(const Duration(days: 1));
  }

  return SleepRange(bed: bed, wake: wake);
}

class LogSleepSheet extends ConsumerStatefulWidget {
  const LogSleepSheet({super.key});

  static Future<void> show(BuildContext context) {
    return BottomSheetModal.show(
      context: context,
      title: "Log Sleep",
      child: const LogSleepSheet(),
    );
  }

  @override
  ConsumerState<LogSleepSheet> createState() => _LogSleepSheetState();
}

class _LogSleepSheetState extends ConsumerState<LogSleepSheet> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _durationMinutes {
    return calculateSleepRange(_bedtime, _wakeTime).durationMinutes;
  }

  String get _durationLabel {
    final minutes = _durationMinutes;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  Future<void> _pickTime({
    required String title,
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    TimeOfDay tempTime = initialTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await BottomSheetModal.show(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 216,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: AppTypography.title2(isDark).copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(2020, 1, 1, initialTime.hour, initialTime.minute),
                onDateTimeChanged: (DateTime newDateTime) {
                  tempTime = TimeOfDay.fromDateTime(newDateTime);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: "Confirm",
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );

    onPicked(tempTime);
  }

  Future<void> _pickBedtime() async {
    await _pickTime(
      title: "Set Bedtime",
      initialTime: _bedtime,
      onPicked: (time) {
        if (mounted) setState(() => _bedtime = time);
      },
    );
  }

  Future<void> _pickWakeTime() async {
    await _pickTime(
      title: "Set Wake Time",
      initialTime: _wakeTime,
      onPicked: (time) {
        if (mounted) setState(() => _wakeTime = time);
      },
    );
  }

  Future<void> _autoFillFromHealthConnect() async {
    setState(() => _isSaving = true);
    try {
      final client = HealthConnectClient();
      
      final hasPerms = await client.requestPermissions();
      if (!hasPerms) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied for Health Connect')),
          );
        }
        return;
      }
      
      final sessions = await client.fetchSleepSessions(DateTime.now());
      if (sessions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recent sleep sessions found in Health Connect')),
          );
        }
        return;
      }
      
      // Pick the most recent sleep session
      final latest = sessions.reduce((a, b) => a.dateTo.isAfter(b.dateTo) ? a : b);
      if (mounted) {
        setState(() {
          _bedtime = TimeOfDay.fromDateTime(latest.dateFrom);
          _wakeTime = TimeOfDay.fromDateTime(latest.dateTo);
          _noteController.text = "Auto-filled from Health Connect";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Auto-filled sleep: ${_bedtime.format(context)} – ${_wakeTime.format(context)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Health Connect sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now();
      final range = calculateSleepRange(_bedtime, _wakeTime, now: now);
      final bed = range.bed;
      final wake = range.wake;

      await db.insertSleepNote(
        SleepNotesCompanion(
          date: drift.Value(wake),
          bedtime: drift.Value(bed),
          wakeTime: drift.Value(wake),
          durationMinutes: drift.Value(range.durationMinutes),
          noteText: drift.Value(_noteController.text.trim()),
          createdAt: drift.Value(now),
        ),
      );

      // Background sync to Health Connect
      HealthConnectClient().writeSleepSession(start: bed, end: wake).ignore();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep logged: $_durationLabel'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log sleep: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Duration Summary Banner
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bedtime_rounded, color: AppColors.sleepAccent, size: 28),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _durationLabel,
                      style: AppTypography.headlineLg(isDark).copyWith(
                        color: AppColors.sleepAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Total sleep duration", style: AppTypography.footnote(isDark)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grouped Time Pickers
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.bedtime_outlined, color: AppColors.sleepAccent),
                    title: Text("Bedtime", style: AppTypography.bodyMd(isDark)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _bedtime.format(context),
                          style: AppTypography.bodyMd(isDark).copyWith(color: AppColors.sleepAccent, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                      ],
                    ),
                    onTap: _pickBedtime,
                  ),
                  Divider(height: 1, indent: 48, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.wb_sunny_rounded, color: AppColors.calorieAccent),
                    title: Text("Wake Time", style: AppTypography.bodyMd(isDark)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _wakeTime.format(context),
                          style: AppTypography.bodyMd(isDark).copyWith(color: AppColors.calorieAccent, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                      ],
                    ),
                    onTap: _pickWakeTime,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Notes
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              "Notes (optional)",
              style: AppTypography.subhead(isDark).copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "E.g. Felt rested, had vivid dreams...",
                hintStyle: AppTypography.footnote(isDark),
                border: InputBorder.none,
              ),
              style: AppTypography.bodyMd(isDark),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Tools Group
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.sensors_rounded, color: AppColors.primaryBlue),
                    title: Text(
                      "Sensor Tracking",
                      style: AppTypography.bodyMd(isDark),
                    ),
                    trailing: Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                    onTap: _isSaving ? null : () {
                      final nav = Navigator.of(context, rootNavigator: true);
                      Navigator.of(context).pop();
                      nav.push(
                        MaterialPageRoute(builder: (_) => const ActiveSleepTrackerScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 48, endIndent: 16, color: isDark ? Colors.white12 : Colors.black12),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.sync_rounded, color: AppColors.primaryBlue),
                    title: Text(
                      "Sync with Health Connect",
                      style: AppTypography.bodyMd(isDark),
                    ),
                    trailing: _isSaving
                        ? const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.white54 : Colors.black54),
                    onTap: _isSaving ? null : _autoFillFromHealthConnect,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          AppButton(
            label: _isSaving ? "Saving..." : "Save Sleep Session",
            icon: Icons.check_rounded,
            onPressed: _isSaving ? null : _save,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}
