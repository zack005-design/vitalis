---
name: designing-health-charts
description: Guides creation of interactive health trend charts (fl_chart), range toggles (7d/30d/90d), tooltip formatting, and visual analytics in Flutter. Use when building charts, graphing calorie/sleep trends, or styling fl_chart components.
---

# Designing Health Charts in Flutter

## When to use this skill
- Building line or bar charts for Calories, Water, or Sleep trends.
- Integrating range switching toggles (7d, 30d, 90d) with `SegmentedControl`.
- Styling `fl_chart` components with custom gradients, touch tooltips, and grid lines matching the obsidian glass design system.

## Workflow Checklist
- [ ] Group date-indexed database logs into daily totals for the selected timeframe.
- [ ] Map timeframes to fixed date ranges (`Duration(days: 7)`, `30`, `90`).
- [ ] Format Y-axis labels with human-readable units (e.g. `2.2k` for 2200 kcal, `8h` for sleep).
- [ ] Apply smooth line curves (`isCurved: true`) and gradient fills below the curve.
- [ ] Add haptic feedback on `LineTouchData` touch callbacks.

## Code Pattern: CalTrack fl_chart Line Chart

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

Widget buildHealthTrendChart({
  required List<FlSpot> spots,
  required Color accentColor,
  required bool isDark,
}) {
  return LineChart(
    LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 3.5,
          color: accentColor,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: accentColor.withValues(alpha: 0.15),
          ),
        ),
      ],
    ),
  );
}
```
