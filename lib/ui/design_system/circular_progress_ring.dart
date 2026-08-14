import 'dart:math';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Stitch Vitality Glass concentric progress ring bento component.
class BentoConcentricRings extends StatelessWidget {
  final double calorieProgress; // 0.0 to 1.0
  final double waterProgress;   // 0.0 to 1.0
  final int caloriesLogged;
  final int waterMlLogged;
  final int waterTargetMl;

  const BentoConcentricRings({
    super.key,
    required this.calorieProgress,
    required this.waterProgress,
    required this.caloriesLogged,
    required this.waterMlLogged,
    required this.waterTargetMl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlassSurface : AppColors.lightGlassSurface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SVG / CustomPaint Concentric Rings
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _ConcentricRingPainter(
                    calorieProgress: calorieProgress.clamp(0.0, 1.0),
                    waterProgress: waterProgress.clamp(0.0, 1.0),
                  ),
                ),
                // Center Display Text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$caloriesLogged",
                      style: AppTypography.displayRing(isDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "KCAL",
                      style: AppTypography.labelSm(isDark).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend below rings
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Calories", AppColors.calorieAccent, isDark),
              const SizedBox(width: 24),
              _buildLegendItem("Water", AppColors.waterAccent, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.labelSm(isDark),
        ),
      ],
    );
  }
}

class _ConcentricRingPainter extends CustomPainter {
  final double calorieProgress;
  final double waterProgress;

  _ConcentricRingPainter({
    required this.calorieProgress,
    required this.waterProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;

    // Outer Calories Track (Radius 85)
    final calorieTrackPaint = Paint()
      ..color = AppColors.calorieAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, 80, calorieTrackPaint);

    // Outer Calories Progress
    final calorieProgressPaint = Paint()
      ..color = AppColors.calorieAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 80),
      -pi / 2,
      2 * pi * calorieProgress,
      false,
      calorieProgressPaint,
    );

    // Inner Water Track (Radius 62)
    final waterTrackPaint = Paint()
      ..color = AppColors.waterAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, 60, waterTrackPaint);

    // Inner Water Progress
    final waterProgressPaint = Paint()
      ..color = AppColors.waterAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 60),
      -pi / 2,
      2 * pi * waterProgress,
      false,
      waterProgressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConcentricRingPainter oldDelegate) {
    return oldDelegate.calorieProgress != calorieProgress ||
        oldDelegate.waterProgress != waterProgress;
  }
}
