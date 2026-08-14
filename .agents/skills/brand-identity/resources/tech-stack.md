# Preferred Tech Stack & Implementation Rules

When generating code or UI components for this brand, you **MUST** strictly adhere to the following technology choices.

## Core Stack
* **Framework:** Flutter (Dart, Android target primary)
* **State Management:** `flutter_riverpod` (Riverpod 2.x/3.x)
* **Local Database:** `drift` (SQLite wrapper with reactive streams)
* **Health Data:** `health` package (Android Health Connect integration)
* **Charts:** `fl_chart`
* **Typography:** `google_fonts` (Inter)
* **Design System:** Custom iOS-inspired frosted glass system (`AppScaffold`, `GlassContainer`, `AppButton`, `AppTextField`, `CircularProgressRing`, `BottomSheetModal`, `SwipeToDeleteRow`)

## Implementation Guidelines

### 1. Flutter UI & Styling
* Use predefined design system components from `lib/ui/design_system/` rather than bare default Material widgets (`Scaffold`, `AppBar`, `ListTile`).
* **Dark & Light Mode:** Support dual themes automatically based on device system brightness.
* **Opacity API:** Use `.withValues(alpha: 0.x)` instead of deprecated `.withOpacity(...)`.
* **Ink Splashes:** Always wrap `ListTile` or clickable elements inside `Material(color: Colors.transparent, child: ...)` when nested inside decorated containers.

### 2. Single Source of Truth
* **Sleep & Activity:** Read from Health Connect via `HealthConnectRepository`.
* **Meals & Water:** Write to local Drift SQLite database (`meals`, `water_logs`), then write back to Health Connect (`NutritionRecord`, `HydrationRecord`) asynchronously.

### 3. Forbidden Patterns
* Do NOT use paid APIs, cloud backends, or subscriptions.
* Do NOT hardcode colors or opacity values; reference `AppColors` and `design-tokens.json`.
* Do NOT put heavy DB calls or sync logic directly inside UI build methods; use Riverpod providers and repository classes.
