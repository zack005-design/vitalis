import 'package:health/health.dart';

class HealthConnectClient {
  final Health _health;

  HealthConnectClient({Health? health}) : _health = health ?? Health();

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WATER,
    HealthDataType.NUTRITION,
    HealthDataType.STEPS,
  ];

  /// Request Health Connect permissions on Android
  Future<bool> requestPermissions() async {
    try {
      final hasPermission = await _health.hasPermissions(_dataTypes);
      if (hasPermission == true) return true;

      return await _health.requestAuthorization(_dataTypes);
    } catch (_) {
      return false;
    }
  }

  /// Fetch last night's sleep sessions
  Future<List<HealthDataPoint>> fetchSleepSessions(DateTime now) async {
    final start = now.subtract(const Duration(hours: 24));
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: [HealthDataType.SLEEP_SESSION],
      );
      return points;
    } catch (_) {
      return [];
    }
  }

  /// Fetch total hydration logged in Health Connect today (in ml)
  Future<int> fetchTodayWaterMl(DateTime now) async {
    final start = DateTime(now.year, now.month, now.day);
    try {
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
    } catch (_) {
      return 0;
    }
  }

  /// Write water log to Health Connect
  Future<bool> writeWaterLog(int amountMl, DateTime timestamp) async {
    try {
      return await _health.writeHealthData(
        value: (amountMl / 1000.0),
        type: HealthDataType.WATER,
        startTime: timestamp,
        endTime: timestamp,
        unit: HealthDataUnit.LITER,
      );
    } catch (_) {
      return false;
    }
  }
}
