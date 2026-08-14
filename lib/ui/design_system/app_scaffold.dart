import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// AppScaffold provides multi-layered ambient background glows, safe area handling, and large-title header shrink animations.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showLargeTitle;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showLargeTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          // Top-Right Ambient Coral Glow
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.calorieAccent.withValues(alpha: isDark ? 0.18 : 0.10),
              ),
            ),
          ),

          // Middle-Left Ambient Teal Glow
          Positioned(
            top: 180,
            left: -120,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.waterAccent.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
            ),
          ),

          // Bottom-Right Ambient Indigo Glow
          Positioned(
            bottom: 40,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sleepAccent.withValues(alpha: isDark ? 0.16 : 0.08),
              ),
            ),
          ),

          // Main Scroll Content / NestedScrollView with iOS Large Title
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (showLargeTitle)
                  SliverAppBar(
                    expandedHeight: 100.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: bgColor.withValues(alpha: 0.85),
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                      title: Text(
                        title,
                        style: AppTypography.headline(isDark).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    actions: actions,
                  )
                else
                  SliverAppBar(
                    pinned: true,
                    title: Text(title, style: AppTypography.headline(isDark)),
                    backgroundColor: bgColor.withValues(alpha: 0.85),
                    elevation: 0,
                    actions: actions,
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
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
