import 'package:drift/drift.dart' as drift;
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

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(context: context, initialTime: _bedtime);
    if (picked != null) setState(() => _bedtime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(context: context, initialTime: _wakeTime);
    if (picked != null) setState(() => _wakeTime = picked);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
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

        // Time Pickers Row
        Row(
          children: [
            Expanded(
              child: _timePicker(
                label: "Bedtime",
                icon: Icons.bedtime_outlined,
                time: _bedtime,
                color: AppColors.sleepAccent,
                isDark: isDark,
                onTap: _pickBedtime,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _timePicker(
                label: "Wake Time",
                icon: Icons.wb_sunny_rounded,
                time: _wakeTime,
                color: AppColors.calorieAccent,
                isDark: isDark,
                onTap: _pickWakeTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Optional Note
        Text("Notes (optional)", style: AppTypography.subhead(isDark).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
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
        const SizedBox(height: 24),

        AppButton(
          label: _isSaving ? "Saving..." : "Save Sleep Session",
          icon: Icons.check_rounded,
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }

  Widget _timePicker({
    required String label,
    required IconData icon,
    required TimeOfDay time,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.footnote(isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time.format(context),
            style: AppTypography.title2(isDark).copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
