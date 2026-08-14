import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import '../design_system/segmented_control.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  String _selectedRange = '7d';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: "Sleep",
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {},
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last 7 Days Header + Range Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Last 7 Days",
                    style: AppTypography.subhead(isDark),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "7h 42m",
                        style: AppTypography.headlineLg(isDark),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "avg",
                        style: AppTypography.bodyMd(isDark),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 110,
                child: SegmentedControl<String>(
                  options: const {'7d': '7d', '30d': '30d'},
                  selectedValue: _selectedRange,
                  onValueChanged: (val) => setState(() => _selectedRange = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sleep History Bar Chart Container (Stitch UI Spec)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSleepBar("Mon", 0.75, isDark),
                  _buildSleepBar("Tue", 0.85, isDark),
                  _buildSleepBar("Wed", 0.60, isDark),
                  _buildSleepBar("Thu", 0.90, isDark),
                  _buildSleepBar("Fri", 0.70, isDark),
                  _buildSleepBar("Sat", 0.95, isDark),
                  _buildSleepBar("Sun", 0.80, isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Last Night's Stages",
            style: AppTypography.headlineMd(isDark),
          ),
          const SizedBox(height: 10),

          // Sleep Stage Breakdown Cards
          GlassContainer(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildStageRow("Deep Sleep", "1h 45m", "23%", AppColors.sleepAccent, isDark),
                const Divider(height: 24),
                _buildStageRow("Light Sleep", "4h 12m", "55%", AppColors.waterAccent, isDark),
                const Divider(height: 24),
                _buildStageRow("REM Sleep", "1h 27m", "19%", AppColors.calorieAccent, isDark),
                const Divider(height: 24),
                _buildStageRow("Awake", "18m", "3%", Colors.amber, isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subjective Sleep Note Card
          GlassContainer(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sleepAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.sleepAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Subjective Sleep Note",
                        style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Felt well rested after evening wind-down",
                        style: AppTypography.footnote(isDark),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
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
            const SizedBox(width: 8),
            Text(percentage, style: AppTypography.labelSm(isDark)),
          ],
        ),
      ],
    );
  }
}
