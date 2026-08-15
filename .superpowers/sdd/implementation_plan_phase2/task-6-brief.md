# Task 6: Accessibility (a11y) & Polish

**Goal:** Ensure the app is fully accessible to screen readers, meets WCAG contrast ratios, and has usable touch targets.

**Specific Requirements:**
1. **Contrast Issues:** In lib/ui/design_system/app_colors.dart, adjust darkTextMuted (currently Color(0xFF64748B)) and lightTextMuted (currently Color(0xFF94A3B8)) slightly to ensure they meet WCAG 4.5:1 text contrast ratios against their respective background colors (dark/light mode surfaces). Use slightly lighter/darker grey respectively.
2. **Semantics:**
   - In lib/ui/main_navigation_shell.dart, wrap the NavigationBar destinations in Semantics widgets to ensure the active/inactive state and tab labels are cleanly read by VoiceOver/TalkBack.
   - In lib/ui/design_system/segmented_control.dart, add Semantics(button: true, label: ...) around the tappable segments.
3. **Touch Targets:** In lib/ui/food/food_screen.dart, the macro breakdown chips or custom food cards might have small tap targets. Ensure any GestureDetector or InkWell used for interaction has at least a 44x44 or 48x48 logical pixel tap area, wrapping them in Padding or SizedBox if necessary.

**Testing:**
- Verify flutter tests pass.
