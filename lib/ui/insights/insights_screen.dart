import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/food/food_providers.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_scaffold.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final calorieDataAsync = ref.watch(calorieHistoryProvider(_days));
    final waterDataAsync = ref.watch(waterHistoryProvider(_days));
    final sleepDataAsync = ref.watch(sleepHistoryProvider(_days));
    final macroDataAsync = ref.watch(macroHistoryProvider(_days));

    return AppScaffold(
      title: "Metabolic Insights",
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: SizedBox(
            width: 150,
            child: SegmentedControl<String>(
              options: const {'7d': '7D', '30d': '30D', '90d': '90D'},
              selectedValue: _selectedRange,
              onValueChanged: (val) => setState(() => _selectedRange = val),
            ),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caloric Intake Card (Stitch Spec)
          calorieDataAsync.when(
            loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox(height: 100, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text("Failed to load")]))),
            data: (calories) {
              final avgCal = calories.isEmpty ? 0.0 : calories.fold(0.0, (a, b) => a + b) / calories.length;
              final maxVal = calories.isEmpty ? 3000.0 : (calories.reduce((a, b) => a > b ? a : b) * 1.25).clamp(1500.0, 5000.0);

              return GlassContainer(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Avg. Caloric Intake",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  avgCal.round().toString(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.calorieAccent,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "kcal/day",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.calorieAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant_rounded, color: AppColors.calorieAccent, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Capsule Bar Chart
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          maxY: maxVal,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxVal / 3,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
                              strokeWidth: 1,
                            ),
                          ),
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
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _dayLabel(idx, calories.length),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          barGroups: calories.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: AppColors.calorieAccent,
                                  width: (280 / (calories.length + 1)).clamp(8.0, 26.0),
                                  borderRadius: BorderRadius.circular(12),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxVal * 0.85,
                                    color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Macro Breakdown Line Chart
          macroDataAsync.when(
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox(height: 100, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text("Failed to load")]))),
            data: (macros) {
              final maxProtein = macros.isEmpty ? 100.0 : macros.map((m) => m.protein).reduce((a, b) => a > b ? a : b);
              final maxCarbs = macros.isEmpty ? 100.0 : macros.map((m) => m.carbs).reduce((a, b) => a > b ? a : b);
              final maxFat = macros.isEmpty ? 100.0 : macros.map((m) => m.fat).reduce((a, b) => a > b ? a : b);
              final maxVal = [maxProtein, maxCarbs, maxFat].reduce((a, b) => a > b ? a : b) * 1.25;

              return GlassContainer(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Macro Trends",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _macroLegend(isDark, "P", const Color(0xFFE57373)),
                                const SizedBox(width: 12),
                                _macroLegend(isDark, "C", const Color(0xFF64B5F6)),
                                const SizedBox(width: 12),
                                _macroLegend(isDark, "F", const Color(0xFFFFD54F)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF64B5F6).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF64B5F6), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 150,
                      child: LineChart(
                        LineChartData(
                          maxY: maxVal == 0 ? 100 : maxVal,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (maxVal == 0 ? 100 : maxVal) / 3,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < macros.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _dayLabel(idx, macros.length),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            _macroLineData(macros.map((m) => m.protein).toList(), const Color(0xFFE57373)),
                            _macroLineData(macros.map((m) => m.carbs).toList(), const Color(0xFF64B5F6)),
                            _macroLineData(macros.map((m) => m.fat).toList(), const Color(0xFFFFD54F)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Daily Hydration Line Chart (Stitch Spec)
          waterDataAsync.when(
            loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox(height: 100, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text("Failed to load")]))),
            data: (water) {
              final avgWater = water.isEmpty ? 0.0 : water.fold(0.0, (a, b) => a + b) / water.length;
              final maxVal = water.isEmpty ? 3000.0 : (water.reduce((a, b) => a > b ? a : b) * 1.25).clamp(1000.0, 4000.0);

              return GlassContainer(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Daily Hydration",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  (avgWater / 1000).toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.waterAccent,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Liters",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.waterAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: AppColors.waterAccent, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 150,
                      child: LineChart(
                        LineChartData(
                          maxY: maxVal,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxVal / 3,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
                              strokeWidth: 1,
                            ),
                          ),
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
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _dayLabel(idx, water.length),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    );
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
                              curveSmoothness: 0.35,
                              color: AppColors.waterAccent,
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                                  radius: 4.5,
                                  color: AppColors.waterAccent,
                                  strokeWidth: 2,
                                  strokeColor: isDark ? const Color(0xFF0B1326) : Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.waterAccent.withValues(alpha: 0.30),
                                    AppColors.waterAccent.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
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
          const SizedBox(height: 16),
          // Sleep Duration Bar Chart
          sleepDataAsync.when(
            loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => const SizedBox(height: 100, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text("Failed to load")]))),
            data: (sleepHours) {
              final avgSleep = sleepHours.isEmpty ? 0.0 : sleepHours.fold(0.0, (a, b) => a + b) / sleepHours.length;
              final maxVal = sleepHours.isEmpty ? 8.0 : (sleepHours.reduce((a, b) => a > b ? a : b) * 1.25).clamp(8.0, 14.0);

              return GlassContainer(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Avg. Sleep Duration",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  avgSleep.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFB39DDB),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "hours",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB39DDB).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.bedtime_rounded, color: Color(0xFFB39DDB), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          maxY: maxVal,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxVal / 3,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < sleepHours.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _dayLabel(idx, sleepHours.length),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          barGroups: sleepHours.asMap().entries.map((e) {
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: e.value,
                                  color: const Color(0xFFB39DDB),
                                  width: (280 / (sleepHours.length + 1)).clamp(8.0, 26.0),
                                  borderRadius: BorderRadius.circular(12),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxVal * 0.85,
                                    color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Optimal Recovery Window AI Card
          ref.watch(dailyHealthInsightProvider).when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox(height: 100, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text("Failed to load")]))),
            data: (insight) => GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          insight.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    insight.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222A3E) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tips_and_updates_rounded, size: 16, color: AppColors.calorieAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.recommendation,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
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

  Widget _macroLegend(bool isDark, String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      ],
    );
  }

  LineChartBarData _macroLineData(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }
}
