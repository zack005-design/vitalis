import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import '../design_system/segmented_control.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedRange = '7d';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: "Insights",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            width: 140,
            child: SegmentedControl<String>(
              options: const {'7d': '7d', '30d': '30d', '90d': '90d'},
              selectedValue: _selectedRange,
              onValueChanged: (val) => setState(() => _selectedRange = val),
            ),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Recovery & Balance Insight Card (Stitch Spec)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Weekly Insight Summary",
                        style: AppTypography.headline(isDark).copyWith(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Your calorie intake consistency improved by 14% this week. Optimal sleep duration on Thursday directly correlated with lower late-night cravings.",
                  style: AppTypography.bodyMd(isDark).copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Recommendation: Maintain 2.0L water goal tomorrow",
                        style: AppTypography.labelSm(isDark).copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Metabolic Trends",
            style: AppTypography.headlineMd(isDark),
          ),
          const SizedBox(height: 10),

          // Calorie Trend Graph Card (Interactive fl_chart BarChart)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Calorie Intake (kcal)", style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w600)),
                    Text("Avg 1,920 kcal", style: AppTypography.labelSm(isDark).copyWith(color: AppColors.calorieAccent)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 150,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ["M", "T", "W", "T", "F", "S", "S"];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Text(
                                  days[value.toInt()],
                                  style: AppTypography.labelSm(isDark),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        _makeBarGroup(0, 1850, isDark),
                        _makeBarGroup(1, 2100, isDark),
                        _makeBarGroup(2, 1650, isDark),
                        _makeBarGroup(3, 2200, isDark),
                        _makeBarGroup(4, 1950, isDark),
                        _makeBarGroup(5, 2300, isDark),
                        _makeBarGroup(6, 1800, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hydration Trend Graph Card (Interactive fl_chart LineChart)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Hydration (ml)", style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w600)),
                    Text("Avg 2,100 ml", style: AppTypography.labelSm(isDark).copyWith(color: AppColors.waterAccent)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 140,
                  child: LineChart(
                    LineChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ["M", "T", "W", "T", "F", "S", "S"];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Text(days[value.toInt()], style: AppTypography.labelSm(isDark));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 1500),
                            FlSpot(1, 1800),
                            FlSpot(2, 2200),
                            FlSpot(3, 2000),
                            FlSpot(4, 2500),
                            FlSpot(5, 2100),
                            FlSpot(6, 1900),
                          ],
                          isCurved: true,
                          color: AppColors.waterAccent,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.waterAccent.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60), // Adequate bottom spacing above navigation shell
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.calorieAccent,
          width: 14,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}
