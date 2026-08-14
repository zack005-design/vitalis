---
name: stitching-ui-components
description: Guides component composition, widget stitching, layout integration, and provider bindings to assemble cohesive screens from atomic design tokens in Flutter. Use when stitching components into composite layouts, assembling dashboard widgets, or linking Riverpod state to UI design system wrappers.
---

# Stitching UI Components in Flutter

## When to use this skill
- Stitching atomic design system widgets (`GlassContainer`, `AppButton`, `CircularProgressRing`, `SwipeToDeleteRow`) into composite feature screens.
- Assembling dashboard layouts (e.g. Today screen, Insights screen) with responsive vertical & horizontal spacing.
- Connecting Riverpod state providers to stitched component hierarchies without causing rebuild cascades or layout overflow errors.

## Core Stitching Principles

### 1. Atomic Composition
- **Atoms**: `AppColors`, `AppTypography`, `AppButton`, `AppTextField`.
- **Molecules**: `CircularProgressRing`, `SegmentedControl`, `SwipeToDeleteRow`.
- **Organisms**: `BottomSheetModal`, `FoodSearchSheet`, Today Dashboard Cards.
- **Pages**: `TodayScreen`, `FoodScreen`, `SleepScreen`, `InsightsScreen`, `MoreScreen`.

### 2. Layout Stitching Rules
- **No Direct Material Defaults**: Never stitch raw `Scaffold`, `AppBar`, or `ListTile` directly into screens—always wrap with `AppScaffold`, `GlassContainer`, and transparent `Material` wrappers.
- **Flexibility & Overflow Safety**: Wrap variable-length list children inside `SingleChildScrollView` or `CustomScrollView` + `SliverToBoxAdapter` to prevent pixel overflow errors when keyboard or bottom sheets open.
- **State Binding**: Pass primitives or model objects to stitched presenter widgets; consume Riverpod state at the screen boundary.

## Code Pattern: Component Stitching Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/app_scaffold.dart';
import '../design_system/glass_container.dart';
import '../design_system/app_typography.dart';
import '../design_system/app_button.dart';

class StitchedFeatureCard extends ConsumerWidget {
  final String title;
  final String metricText;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTapAction;

  const StitchedFeatureCard({
    super.key,
    required this.title,
    required this.metricText,
    required this.icon,
    required this.accentColor,
    required this.onTapAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      onTap: onTapAction,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subhead(isDark)),
                const SizedBox(height: 2),
                Text(
                  metricText,
                  style: AppTypography.title2(isDark).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          AppButton(
            label: "Action",
            isFullWidth: false,
            onPressed: onTapAction,
          ),
        ],
      ),
    );
  }
}
```

## Checklist for Stitching New Screens
- [ ] Ensure all parent containers use `AppScaffold` for uniform ambient glows and safe area padding.
- [ ] Check dark & light theme rendering using `Theme.of(context).brightness`.
- [ ] Verify haptic feedback (`HapticFeedback.lightImpact()`) on interactive component taps.
- [ ] Confirm `flutter analyze` passes with 0 issues after stitching components together.
