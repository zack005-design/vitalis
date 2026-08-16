import 'package:drift/drift.dart' as drift;
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../local/app_database.dart';

class HealthConnectClient {
  final Health _health;
  bool _configured = false;

  HealthConnectClient({Health? health}) : _health = health ?? Health();

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WATER,
    HealthDataType.NUTRITION,
    HealthDataType.STEPS,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
  ];

  Future<void> _ensureConfigured() async {
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }
  }

  /// Request Health Connect permissions on Android
  Future<bool> requestPermissions() async {
    try {
      await _ensureConfigured();
      final hasPermission = await _health.hasPermissions(_dataTypes, permissions: _permissions);
      if (hasPermission == true) return true;

      final granted = await _health.requestAuthorization(_dataTypes, permissions: _permissions);
      return granted;
    } catch (e, st) {
      debugPrint('HealthConnect error (requestPermissions): $e\n$st');
      rethrow;
    }
  }

  /// Check if Health Connect is installed or prompt install
  Future<void> installHealthConnect() async {
    try {
      final uri = Uri.parse("market://details?id=com.google.android.apps.healthdata");
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
      } else {
        await _health.installHealthConnect();
      }
    } catch (e, st) {
      debugPrint('HealthConnect error (installHealthConnect): $e\n$st');
      rethrow;
    }
  }

  /// Fetch last night's sleep sessions (queries last 48 hours to reliably catch overnight sessions)
  Future<List<HealthDataPoint>> fetchSleepSessions(DateTime now) async {
    try {
      await _ensureConfigured();
      final start = now.subtract(const Duration(hours: 48));
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.SLEEP_SESSION],
      );
      return points;
    } catch (e, st) {
      debugPrint('HealthConnect error (fetchSleepSessions): $e\n$st');
      rethrow;
    }
  }

  /// Fetch total hydration logged in Health Connect today (in ml)
  Future<int> fetchTodayWaterMl(DateTime now) async {
    try {
      await _ensureConfigured();
      final start = DateTime(now.year, now.month, now.day);
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.WATER],
      );
      double totalLiters = 0;
      for (final p in points) {
        if (p.value is NumericHealthValue) {
          totalLiters += (p.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      return (totalLiters * 1000).round();
    } catch (e, st) {
      debugPrint('HealthConnect error (fetchTodayWaterMl): $e\n$st');
      rethrow;
    }
  }

  /// Write water log to Health Connect
  Future<bool> writeWaterLog(int amountMl, DateTime timestamp) async {
    try {
      await _ensureConfigured();
      return await _health.writeHealthData(
        value: (amountMl / 1000.0),
        type: HealthDataType.WATER,
        startTime: timestamp,
        endTime: timestamp,
        unit: HealthDataUnit.LITER,
      );
    } catch (e, st) {
      debugPrint('HealthConnect error (writeWaterLog): $e\n$st');
      rethrow;
    }
  }

  /// Write sleep session to Health Connect
  Future<bool> writeSleepSession({required DateTime start, required DateTime end}) async {
    try {
      await _ensureConfigured();
      final durationHours = end.difference(start).inMinutes / 60.0;
      return await _health.writeHealthData(
        value: durationHours,
        type: HealthDataType.SLEEP_SESSION,
        startTime: start,
        endTime: end,
        unit: HealthDataUnit.HOUR,
      );
    } catch (e, st) {
      debugPrint('HealthConnect error (writeSleepSession): $e\n$st');
      rethrow;
    }
  }

  /// Write meal nutrition to Health Connect
  Future<bool> writeMealNutrition({
    required int calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    required DateTime timestamp,
    MealType mealType = MealType.UNKNOWN,
    String? name,
  }) async {
    try {
      await _ensureConfigured();
      return await _health.writeMeal(
        mealType: mealType,
        startTime: timestamp,
        endTime: timestamp,
        caloriesConsumed: calories.toDouble(),
        protein: proteinG,
        carbohydrates: carbsG,
        fatTotal: fatG,
        name: name,
      );
    } catch (e, st) {
      debugPrint('HealthConnect error (writeMealNutrition): $e\n$st');
      rethrow;
    }
  }

  /// Two-way sync: Pulls external data from Health Connect into local database
  Future<void> syncFromHealthConnect(AppDatabase db) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();

      // 1. Sync external sleep
      final sleepPoints = await fetchSleepSessions(now);
      for (final p in sleepPoints) {
        final durationMin = p.dateTo.difference(p.dateFrom).inMinutes;
        if (durationMin > 0) {
          final existing = await db.getSleepNotesForDateRange(
            p.dateFrom.subtract(const Duration(hours: 1)),
            p.dateTo.add(const Duration(hours: 1)),
          );
          if (existing.isEmpty) {
            await db.insertSleepNote(
              SleepNotesCompanion(
                date: drift.Value(p.dateFrom),
                bedtime: drift.Value(p.dateFrom),
                wakeTime: drift.Value(p.dateTo),
                durationMinutes: drift.Value(durationMin),
                noteText: const drift.Value("Synced from Google Health"),
                createdAt: drift.Value(now),
              ),
            );
          }
        }
      }
    } catch (e, st) {
      debugPrint('HealthConnect error (syncFromHealthConnect): $e\n$st');
      rethrow;
    }
  }
}
