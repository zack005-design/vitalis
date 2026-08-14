import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/app_typography.dart';
import '../design_system/glass_container.dart';
import '../design_system/segmented_control.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _selectedRange = '7d';

  int get _days {
    switch (_selectedRange) {
      case '30d': return 30;
      case '90d': return 90;
      default: return 7;
    }
  }

  String _buildInsightText(List<double> calories, List<double> waterMl, double calTarget, double waterTarget) {
    if (calories.isEmpty) return "Start logging meals and water to see personalized insights here!";

    final avgCal = calories.fold(0.0, (a, b) => a + b) / calories.length;
    final avgWater = waterMl.fold(0.0, (a, b) => a + b) / waterMl.length;
    final calPct = (avgCal / calTarget * 100).round();
    final waterPct = (avgWater / waterTarget * 100).round();

    final parts = <String>[];
    if (calPct >= 90 && calPct <= 110) {
      parts.add("Your calorie intake is on target ($calPct% of goal).");
    } else if (calPct < 90) {
      parts.add("You're averaging $calPct% of your calorie goal — try not to skip meals.");
    } else {
      parts.add("Calorie intake is ${calPct - 100}% above target — consider smaller portions.");
    }

    if (waterPct >= 100) {
      parts.add("Great hydration! You're averaging $waterPct% of your water goal.");
    } else {
      final targetL = (waterTarget / 1000).toStringAsFixed(1);
      parts.add("Hydration needs improvement — averaging $waterPct% of ${targetL}L goal.");
    }

    return parts.join(" ");
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final calorieDataAsync = ref.watch(calorieHistoryProvider(_days));
    final waterDataAsync = ref.watch(waterHistoryProvider(_days));
    final targetCal = ref.watch(calorieTargetProvider).toDouble();
    final targetWater = ref.watch(waterTargetProvider).toDouble();

    return AppScaffold(
      title: "Insights",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            width: 150,
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
          // AI Recovery & Balance Insight Card
          calorieDataAsync.when(
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox.shrink(),
            data: (calories) => waterDataAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (water) => GlassContainer(
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
                          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue, size: 20),
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
                      _buildInsightText(calories, water, targetCal, targetWater),
                      style: AppTypography.bodyMd(isDark).copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Recommendation: Maintain your 2.0L water goal and log meals consistently.",
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
            ),
          ),
          const SizedBox(height: 20),

          Text("Metabolic Trends", style: AppTypography.headlineMd(isDark)),
          const SizedBox(height: 10),

          // Calorie Trend Graph Card
          calorieDataAsync.when(
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox.shrink(),
            data: (calories) {
              final maxY = calories.isEmpty ? 3000.0 : (calories.reduce((a, b) => a > b ? a : b) * 1.2).clamp(1000.0, 5000.0);
              final avgCal = calories.isEmpty ? 0.0 : calories.fold(0.0, (a, b) => a + b) / calories.length;

              return GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Calorie Intake (kcal)", style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w600)),
                        Text("Avg ${avgCal.round()} kcal", style: AppTypography.labelSm(isDark).copyWith(color: AppColors.calorieAccent)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 150,
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
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
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < calories.length) {
                                    return Text(_dayLabel(idx, calories.length), style: AppTypography.labelSm(isDark));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          barGroups: calories.asMap().entries.map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [BarChartRodData(
                              toY: e.value,
                              color: AppColors.calorieAccent,
                              width: (300 / (calories.length + 1)).clamp(6.0, 22.0),
                              borderRadius: BorderRadius.circular(6),
                            )],
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Hydration Trend Graph Card
          waterDataAsync.when(
            loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox.shrink(),
            data: (water) {
              final maxY = water.isEmpty ? 3000.0 : (water.reduce((a, b) => a > b ? a : b) * 1.2).clamp(500.0, 4000.0);
              final avgWater = water.isEmpty ? 0.0 : water.fold(0.0, (a, b) => a + b) / water.length;

              return GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Hydration (ml)", style: AppTypography.bodyMd(isDark).copyWith(fontWeight: FontWeight.w600)),
                        Text("Avg ${avgWater.round()} ml", style: AppTypography.labelSm(isDark).copyWith(color: AppColors.waterAccent)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 140,
                      child: water.every((v) => v == 0)
                          ? Center(child: Text("No water data yet", style: AppTypography.bodyMd(isDark)))
                          : LineChart(
                              LineChartData(
                                maxY: maxY,
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
                                        final idx = value.toInt();
                                        if (idx >= 0 && idx < water.length) {
                                          return Text(_dayLabel(idx, water.length), style: AppTypography.labelSm(isDark));
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: water.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                                    isCurved: true,
                                    color: AppColors.waterAccent,
                                    barWidth: 3,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(show: true, color: AppColors.waterAccent.withValues(alpha: 0.15)),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  String _dayLabel(int index, int total) {
    if (total <= 7) {
      const days = ["M", "T", "W", "T", "F", "S", "S"];
      return days[index % 7];
    }
    return "${index + 1}";
  }
}
