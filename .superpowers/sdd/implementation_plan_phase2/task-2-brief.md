# Task 2: UI Foundation & Rendering Performance

**Goal:** Fix layout crashes, font issues, and GPU compositing performance.

**Specific Requirements:**
1. **AppScaffold Scrolling Fix:** Modify lib/ui/design_system/app_scaffold.dart. The ody is currently always wrapped in a SliverToBoxAdapter inside a CustomScrollView, which causes unbounded height errors if the body itself is a scrollable widget (like a ListView or another CustomScrollView). Conditionally wrap the body or restructure it so nested scrollables work safely without layout exceptions.
2. **Font Registration:** JetBrains Mono is missing from pubspec.yaml but used in code (glass_time_picker.dart, segmented_control.dart). Add it to pubspec.yaml (you might need to fetch the font file or rely on google_fonts if that's standard for the project). Wait, the project already uses google_fonts for Inter. Update pp_typography.dart to use GoogleFonts.jetbrainsMono or register the asset properly if it exists locally. Note: The audit says "GoogleFonts called dynamically every build" - optimize this by registering 	extTheme properly in main.dart or standardizing it in pp_typography.dart so it isn't rebuilt dynamically.
3. **CircularProgressRing NaN/Infinity Guard:** In lib/ui/design_system/circular_progress_ring.dart, guard against NaN or Infinity sweep angles when calculating progress = current / target (which crashes if 	arget is 0). If 	arget is 0, progress should be 0. Also wrap the CustomPaint widget inside a RepaintBoundary to prevent unnecessary repaints.
4. **GlassContainer Performance:** In lib/ui/design_system/glass_container.dart, add a boolean enableBlur flag (defaulting to 	rue). If alse, skip the BackdropFilter to improve scrolling performance for long lists.

**Testing:**
- Verify tests pass.
- Write a quick test to ensure CircularProgressRing handles target = 0 without throwing an exception.
