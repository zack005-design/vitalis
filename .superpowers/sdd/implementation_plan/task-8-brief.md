# Task 8: Female BMR & Design System Bugs

## Overview
Fix female BMR calculation and broken UI components in the design system.

## Specific Requirements
1. In lib/ui/more/edit_profile_sheet.dart:
   - Add a UI selector for Biological Sex (Male/Female). Default to Male for backward compatibility if the user hasn't selected it.
   - Update the BMR calculation to use - 161 for females, + 5 for males.
2. In lib/ui/design_system/swipe_to_delete_row.dart:
   - Add a inal VoidCallback? onUndo property to the widget.
   - Pass this callback to the SnackBar's "Undo" button.
3. In lib/ui/design_system/bottom_sheet_modal.dart:
   - The BottomSheetModal accepts a List<Widget>? actions, but they are ignored. Insert code to render them.
