import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_button.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import '../design_system/segmented_control.dart';
import 'log_sleep_sheet.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  String _selectedRange = '7d';


  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sleepLogsAsync = ref.watch(recentSleepLogsProvider);

    // Compute average from real data
    final logs = sleepLogsAsync.value ?? [];
    final avgMinutes = logs.isEmpty
        ? 0
        : logs.fold<int>(0, (s, e) => s + e.durationMinutes) ~/ logs.length;
    final lastEntry = logs.isNotEmpty ? logs.first : null;

    // Build bar chart heights from real data (normalised to max 8h = 480min)
    const maxMinutes = 480.0;
    final barData = logs.take(7).toList().reversed.toList();

    return AppScaffold(
      title: "Sleep",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizedBox(
            width: 120,
            child: SegmentedControl<String>(
              options: const {'7d': '7d', '30d': '30d'},
              selectedValue: _selectedRange,
              onValueChanged: (val) => setState(() => _selectedRange = val),
            ),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Average Sleep Header + Log Sleep Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Last ${_selectedRange == '7d' ? '7' : '30'} Days",
                    style: AppTypography.subhead(isDark),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avgMinutes > 0 ? _formatDuration(avgMinutes) : "--",
                        style: AppTypography.headlineLg(isDark),
                      ),
                      const SizedBox(width: 6),
                      Text("avg", style: AppTypography.bodyMd(isDark)),
                    ],
                  ),
                ],
              ),
              AppButton(
                label: "Log Sleep",
                icon: Icons.add_rounded,
                onPressed: () => LogSleepSheet.show(context),
                isFullWidth: false,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sleep Bar Chart
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 180,
              child: barData.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bedtime_outlined, color: AppColors.sleepAccent, size: 40),
                          const SizedBox(height: 8),
                          Text("No sleep sessions logged yet.", style: AppTypography.bodyMd(isDark)),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: barData.asMap().entries.map((entry) {
                        final log = entry.value;
                        final ratio = (log.durationMinutes / maxMinutes).clamp(0.0, 1.0);
                        final dayLabel = _dayLabel(log.date);
                        return _buildSleepBar(dayLabel, ratio, isDark);
                      }).toList(),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Last Night's Detail
          Text("Last Night", style: AppTypography.headlineMd(isDark)),
          const SizedBox(height: 10),

          if (lastEntry == null)
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "No sleep session logged yet.\nTap 'Log Sleep' to add your first entry.",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(isDark),
                ),
              ),
            )
          else
            GlassContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _buildStageRow(
                    "Duration",
                    _formatDuration(lastEntry.durationMinutes),
                    "${(lastEntry.durationMinutes / 60).toStringAsFixed(1)}h",
                    AppColors.sleepAccent,
                    isDark,
                  ),
                  if (lastEntry.bedtime != null) ...[
                    const Divider(height: 24),
                    _buildStageRow(
                      "Bedtime",
                      _formatTime(lastEntry.bedtime!),
                      "",
                      AppColors.primaryBlue,
                      isDark,
                    ),
                  ],
                  if (lastEntry.wakeTime != null) ...[
                    const Divider(height: 24),
                    _buildStageRow(
                      "Wake Time",
                      _formatTime(lastEntry.wakeTime!),
                      "",
                      AppColors.waterAccent,
                      isDark,
                    ),
                  ],
                  if (lastEntry.noteText.isNotEmpty) ...[
                    const Divider(height: 24),
                    _buildStageRow(
                      "Note",
                      lastEntry.noteText,
                      "",
                      AppColors.scoreAccent,
                      isDark,
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Subjective Note Card
          GlassContainer(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sleepAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppColors.sleepAccent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sleep Goal",
                        style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Aim for 7-9 hours of quality sleep per night for optimal recovery.",
                        style: AppTypography.footnote(isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _dayLabel(DateTime dt) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dt.weekday % 7];
  }

  Widget _buildSleepBar(String dayLabel, double heightPercent, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: 130 * heightPercent,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.sleepAccent, Color(0xFF8E8CE0)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(dayLabel, style: AppTypography.labelSm(isDark).copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildStageRow(String stageName, String duration, String percentage, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(stageName, style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
        Row(
          children: [
            Text(duration, style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.bold)),
            if (percentage.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(percentage, style: AppTypography.labelSm(isDark)),
            ],
          ],
        ),
      ],
    );
  }
}
