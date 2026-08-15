# Task 7: Validation UI and Water Target UI

## Overview
Fix silent validation failure for custom foods, and fix hardcoded water target.

## Specific Requirements
1. In lib/ui/food/add_custom_food_sheet.dart:
   - In the uild method, conditionally render Text(_proteinError), Text(_carbsError), and Text(_fatError) in red below their respective macro input fields.
2. In lib/ui/today/water_history_sheet.dart:
   - Replace the hardcoded / 2.0L string with a dynamic target computed from ef.watch(waterTargetProvider).
   - Display the target in liters with one decimal place.
