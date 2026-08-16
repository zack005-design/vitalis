import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// AppScaffold provides multi-layered diffuse ambient background glows, HyperOS safe area padding,
/// 120Hz/144Hz high refresh rate scroll physics, and sleek large-title headers.
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showLargeTitle;
  final bool isScrollable;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showLargeTitle = true,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Top-Right Diffuse Ambient Nutrition Glow (Aura for AMOLED)
          Positioned(
            top: -100,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.calorieAccent.withValues(alpha: isDark ? 0.18 : 0.10),
                      AppColors.calorieAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Middle-Left Diffuse Ambient Health Blue Glow
          Positioned(
            top: 200,
            left: -100,
            child: IgnorePointer(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.waterAccent.withValues(alpha: isDark ? 0.15 : 0.08),
                      AppColors.waterAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom-Right Diffuse Ambient Sleep Indigo Glow
          Positioned(
            bottom: 60,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.sleepAccent.withValues(alpha: isDark ? 0.14 : 0.06),
                      AppColors.sleepAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Scroll Content optimized for 120Hz/144Hz HyperOS displays
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                if (title != null && showLargeTitle)
                  SliverAppBar(
                    expandedHeight: 90.0,
                    floating: false,
                    pinned: false,
                    backgroundColor: bgColor,
                    elevation: 0,
                    flexibleSpace: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: FlexibleSpaceBar(
                          collapseMode: CollapseMode.parallax,
                          titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                          title: Text(
                            title!,
                            style: AppTypography.headline(isDark).copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    actions: actions,
                  )
                else if (title != null || actions != null)
                  SliverAppBar(
                    pinned: false,
                    title: title != null ? Text(
                      title!,
                      style: AppTypography.headline(isDark).copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ) : null,
                    backgroundColor: bgColor.withValues(alpha: 0.85),
                    elevation: 0,
                    actions: actions,
                  ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 96 + bottomInset),
                  sliver: SliverToBoxAdapter(child: body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
