# Task 8 Report: Female BMR & Design System Bugs

## What Was Implemented
1. **Biological Sex Selector & Female BMR Calculation:**
   - Created `BmrTdeeCalculator` in `lib/domain/profile/bmr_calculator.dart` implementing the Mifflin-St Jeor equation (+5 for males, -161 for females, -78 for unspecified) and activity multipliers (1.2 to 1.9).
   - Added Biological Sex segmented selector (Male / Female) to `EditProfileSheet` in `lib/ui/more/edit_profile_sheet.dart`, defaulting to Male for backward compatibility.
   - Wired live BMR/TDEE recomputation when toggling between Male and Female.
   - Saved and restored `profile_sex` / `profile_gender` in `SharedPreferences` and updated `calorieTargetProvider`.
   - Updated `MoreScreen` in `lib/ui/more/more_screen.dart` to display the user's sex in profile summary details.

2. **Design System - SwipeToDeleteRow Undo Callback:**
   - Added `final VoidCallback? onUndo` property to `SwipeToDeleteRow` in `lib/ui/design_system/swipe_to_delete_row.dart`.
   - Passed `onUndo` to the `SnackBarAction` onPressed handler (and only showing the action when `onUndo` is provided).

3. **Design System - BottomSheetModal Actions Rendering:**
   - Updated `BottomSheetModal` in `lib/ui/design_system/bottom_sheet_modal.dart` to render `actions` widgets inside the header row next to the close button.

## What Was Tested and Test Results
- **Unit Tests (`test/bmr_calculator_test.dart`):**
  - Verified BMR calculations for Male (+5), Female (-161), and Unspecified (-78).
  - Verified TDEE calculations across all 5 activity tiers (Sedentary, Light, Moderate, Active, Very Active).
  - Verified parsing helpers for gender and activity level strings.
- **Widget & Component Tests (`test/female_bmr_and_design_system_test.dart`):**
  - Verified `EditProfileSheet` biological sex selection defaults to Male, updates dynamically when Female is selected (2602 -> 2345 kcal/day), and saves to `SharedPreferences` + `calorieTargetProvider`.
  - Verified `EditProfileSheet` loads stored female sex from `SharedPreferences`.
  - Verified `SwipeToDeleteRow` triggers `onDelete` on dismiss and calls `onUndo` callback when the SnackBar Undo action is pressed.
  - Verified `BottomSheetModal` renders header `actions` widgets and handles action taps.
- **Full Test Suite:**
  - Ran `flutter test`: all 39 tests in the test suite passed with 0 failures.

## Files Changed
- `lib/domain/profile/bmr_calculator.dart` (new)
- `lib/ui/more/edit_profile_sheet.dart` (modified)
- `lib/ui/more/more_screen.dart` (modified)
- `lib/ui/design_system/swipe_to_delete_row.dart` (modified)
- `lib/ui/design_system/bottom_sheet_modal.dart` (modified)
- `test/bmr_calculator_test.dart` (new)
- `test/female_bmr_and_design_system_test.dart` (new)

## Self-Review Findings
- All Mifflin-St Jeor formula constants accurately reflect clinical guidelines (+5 for males, -161 for females).
- Backward compatibility is preserved: if no sex was previously stored in `SharedPreferences`, Male is defaulted without errors.
- Both `profile_sex` and `profile_gender` keys are written to `SharedPreferences` to ensure seamless interoperability.
- SnackBar only exposes the Undo action when `onUndo` is non-null.

## Issues or Concerns
- None.
