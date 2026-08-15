import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  int get _limit => _selectedRange == '30d' ? 30 : 7;

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sleepLogsAsync = ref.watch(recentSleepLogsProvider(_limit));

    final logs = sleepLogsAsync.value ?? [];
    final avgMinutes = logs.isEmpty
        ? 0
        : logs.fold<int>(0, (s, e) => s + e.durationMinutes) ~/ logs.length;
    final lastEntry = logs.isNotEmpty ? logs.first : null;
    final lastDurationMinutes = lastEntry?.durationMinutes ?? 0;

    const maxMinutes = 480.0;
    final barData = logs.take(_limit).toList().reversed.toList();

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
          // Sleep Duration Hero Header (Stitch Mockup)
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      lastDurationMinutes > 0 ? "${lastDurationMinutes ~/ 60}" : "0",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      "h ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      lastDurationMinutes > 0 ? "${lastDurationMinutes % 60}" : "0",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      "m",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  lastEntry != null ? "Last Night • Goal 8h" : "No sleep recorded • Goal 8h",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Bedtime & Wake Time Cards
          Row(
            children: [
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bedtime_outlined, color: AppColors.sleepAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bedtime", style: AppTypography.footnote(isDark)),
                          const SizedBox(height: 2),
                          Text(
                            lastEntry?.bedtime != null
                                ? DateFormat.jm().format(lastEntry!.bedtime!)
                                : "--",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wb_sunny_rounded, color: AppColors.calorieAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Wake", style: AppTypography.footnote(isDark)),
                          const SizedBox(height: 2),
                          Text(
                            lastEntry?.wakeTime != null
                                ? DateFormat.jm().format(lastEntry!.wakeTime!)
                                : "--",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sleep Trend Card with Glowing Indigo Capsule Bars (Stitch Spec)
          GlassContainer(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sleep Trend",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      "Avg ${_formatDuration(avgMinutes)}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sleepAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 160,
                  child: barData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.nightlight_round, color: AppColors.sleepAccent, size: 36),
                              const SizedBox(height: 8),
                              Text("No sleep sessions recorded", style: AppTypography.bodyMd(isDark)),
                            ],
                          ),
                        )
                      : (_limit > 7
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: barData.asMap().entries.map((entry) {
                                  final log = entry.value;
                                  final ratio = (log.durationMinutes / maxMinutes).clamp(0.08, 1.0);
                                  final dayLabel = _dayLabel(log.date);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: _buildSleepBar(dayLabel, ratio, isDark, width: 16),
                                  );
                                }).toList(),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: barData.asMap().entries.map((entry) {
                                final log = entry.value;
                                final ratio = (log.durationMinutes / maxMinutes).clamp(0.08, 1.0);
                                final dayLabel = _dayLabel(log.date);
                                return _buildSleepBar(dayLabel, ratio, isDark, width: 24);
                              }).toList(),
                            )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Sleep Button
          AppButton(
            label: "Log Sleep Session",
            icon: Icons.add_rounded,
            onPressed: () => LogSleepSheet.show(context),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _dayLabel(DateTime dt) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return days[dt.weekday % 7];
  }

  Widget _buildSleepBar(String dayLabel, double heightPercent, bool isDark, {double width = 24}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width,
          height: 120 * heightPercent,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
            ),
            borderRadius: BorderRadius.circular(width / 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: width < 20 ? 10 : 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
