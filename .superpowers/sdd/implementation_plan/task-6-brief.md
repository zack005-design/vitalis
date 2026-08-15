# Task 6: Sleep Timestamp Bug

## Overview
Fix sleep timestamp calculating into the future.

## Specific Requirements
1. In lib/ui/sleep/log_sleep_sheet.dart:
   - Fix the logic that calculates the ed and wake DateTime objects.
   - Currently, if the current time is morning and bedtime is evening (e.g., > 18:00), ed is set to today (which is in the future), and wake is shifted to tomorrow.
   - The correct logic: if the user logs sleep in the morning for a bedtime in the evening, the bedtime should be anchored to yesterday's date.
