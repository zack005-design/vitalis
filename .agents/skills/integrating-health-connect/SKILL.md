---
name: integrating-health-connect
description: Handles reading and writing health metrics (sleep sessions, hydration, nutrition records, activity steps, weight) via Android Health Connect in Flutter. Use when implementing health data sync, configuring Android permissions, or reconciling local database records with Health Connect.
---

# Integrating Health Connect in Flutter

## When to use this skill
- Adding or modifying Health Connect data sync (sleep, nutrition, hydration, steps, weight).
- Configuring Android permissions and `AndroidManifest.xml` intent filters for Health Connect.
- Reconciling local database records with external health data sources.

## Health Connect Permission Checklist
- [ ] Declare `<uses-permission android:name="android.permission.health.READ_SLEEP"/>` and write permissions in `android/app/src/main/AndroidManifest.xml`.
- [ ] Declare `<uses-permission android:name="android.permission.health.READ_HYDRATION"/>` and `WRITE_HYDRATION`.
- [ ] Declare `<uses-permission android:name="android.permission.health.READ_NUTRITION"/>` and `WRITE_NUTRITION`.
- [ ] Add the Health Connect `ACTION_SHOW_PERMISSIONS_RATIONALE` activity intent filter inside `.MainActivity`.
- [ ] Verify `minSdkVersion` is 26 or higher in `android/app/build.gradle`.

## Reconciliation & Authoritative Rules
- **Sleep & Activity**: Health Connect is authoritative. Always read from `HealthConnectRepository`. Local notes are supplementary.
- **Meals & Water**: Local SQLite is authoritative. Write back to Health Connect (`NutritionRecord`, `HydrationRecord`) asynchronously and track `health_connect_synced` status flags.

## Code Pattern: Unified Health Connect Client

```dart
import 'package:health/health.dart';

class HealthConnectRepository {
  final Health _health = Health();

  static const List<HealthDataType> readTypes = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_CALORIES_BURNED,
  ];

  static const List<HealthDataAccess> permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ_WRITE,
  ];

  Future<bool> requestPermissions() async {
    try {
      final granted = await _health.requestAuthorization(readTypes);
      return granted;
    } catch (e) {
      return false;
    }
  }

  Future<List<HealthDataPoint>> fetchSleepSessions(DateTime start, DateTime end) async {
    return await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [HealthDataType.SLEEP_SESSION],
    );
  }

  Future<bool> writeWaterLog(int amountMl, DateTime timestamp) async {
    return await _health.writeHealthData(
      value: amountMl.toDouble(),
      type: HealthDataType.WATER,
      startTime: timestamp,
      endTime: timestamp,
      unit: HealthDataUnit.MILLILITER,
    );
  }
}
```

## Validation & Error Handling
1. Call `_health.hasPermissions(...)` before attempting batch sync.
2. If Health Connect app is missing or revoked on older Android devices, prompt the user gracefully with `HealthConnectRepository.installHealthConnect()`.
3. Wrap write routines in try/catch blocks; failure to sync to Health Connect should **never** prevent local SQLite database saves.
