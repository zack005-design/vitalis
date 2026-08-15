import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Reusable Stitch Vitality Glass card panel with BackdropFilter blur and subtle inner border.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurAmount;
  final Color? customBackgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.blurAmount = 20.0,
    this.customBackgroundColor,
    this.borderColor,
    this.onTap,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = customBackgroundColor ??
        (isDark ? AppColors.darkGlassSurface : AppColors.lightGlassSurface);

    final border = borderColor ??
        (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    Widget innerContainer = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    Widget content;
    if (enableBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: innerContainer,
        ),
      );
    } else {
      content = innerContainer;
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
