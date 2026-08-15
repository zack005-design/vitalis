# Task 3: Health Connect Macros & Notification Scheduling

## Overview
Fix macronutrient data loss in Health Connect and fix immediate notification firing instead of scheduling.

## Specific Requirements
1. In `lib/data/health/health_connect_client.dart`:
   - In `writeMealNutrition`, pass the `proteinG`, `carbsG`, and `fatG` variables into the health data package instead of dropping them, so Health Connect receives macronutrient metrics alongside calories.
2. In `lib/services/notification_service.dart`:
   - In `initialize()`, call `tz.initializeTimeZones()` (import `package:timezone/data/latest_all.dart` as `tz`).
   - In `scheduleSleepWindDownPrompt()`, replace `_notificationsPlugin.show(...)` with `_notificationsPlugin.zonedSchedule(...)` to properly schedule the reminder for the evening hours (e.g., 9:30 PM) relative to the user's timezone.
