---
name: building-glassmorphism-ui
description: Guides creation of custom iOS-styled glassmorphism UI components, frosted glass overlays, shrinking large-title headers, and swipe gestures in Flutter. Use when modifying design tokens, creating glass panels, or fixing widget rendering issues.
---

# Building Glassmorphism UI in Flutter

## When to use this skill
- Creating frosted glass UI elements (`BackdropFilter` + `ImageFilter.blur`).
- Designing iOS-style obsidian dark mode or translucent light mode palettes.
- Implementing swipe-to-delete gesture rows or draggable translucent bottom sheets.
- Resolving Material ink splash or ListTile decorated box rendering issues.

## Best Practices & Performance Rules
- **GPU Overdraw Prevention**: Use `BackdropFilter` **only** for fixed header navigation bars, bottom tab bars, and top-level bottom sheet backdrops. Avoid placing live blurs inside scrolling list item delegates.
- **Opacity API**: Use `.withValues(alpha: 0.x)` instead of deprecated `.withOpacity(0.x)` in Flutter 3.27+.
- **ListTile Material Wrappers**: Always wrap `ListTile` in a transparent `Material` widget (`Material(color: Colors.transparent, child: ListTile(...))`) when placed inside a `DecoratedBox` or `GlassContainer` to ensure ink splash ripples render correctly.

## Code Pattern: Glass Container Template

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bg = isDark ? const Color(0x1F2C2D35) : const Color(0xB8FFFFFF);
    final border = isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1.0),
          ),
          child: child,
        ),
      ),
    );
  }
}
```
