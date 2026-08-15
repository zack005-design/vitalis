import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherHydrationInfo {
  final double temperatureC;
  final double humidityPercent;
  final int bonusWaterMl;
  final String weatherCondition;

  const WeatherHydrationInfo({
    required this.temperatureC,
    required this.humidityPercent,
    required this.bonusWaterMl,
    required this.weatherCondition,
  });
}

class WeatherHydrationService {
  final http.Client _client;

  WeatherHydrationService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches weather from Open-Meteo (Free, No Auth) and calculates dynamic hydration offset
  Future<WeatherHydrationInfo> getHydrationAdjustment({
    double latitude = 9.9312, // Default: Kerala / Kochi
    double longitude = 76.2673,
  }) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,weather_code',
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'] ?? {};
        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
        final humidity = (current['relative_humidity_2m'] as num?)?.toDouble() ?? 65.0;

        int bonus = 0;
        String condition = 'Mild';

        if (temp >= 33.0) {
          bonus = 500;
          condition = 'Hot';
        } else if (temp >= 28.0) {
          bonus = 300;
          condition = 'Warm';
        } else if (temp >= 24.0 && humidity >= 70.0) {
          bonus = 200;
          condition = 'Humid';
        }

        return WeatherHydrationInfo(
          temperatureC: temp,
          humidityPercent: humidity,
          bonusWaterMl: bonus,
          weatherCondition: condition,
        );
      }
    } catch (_) {
      // Offline fallback: neutral baseline
    }

    return const WeatherHydrationInfo(
      temperatureC: 28.0,
      humidityPercent: 60.0,
      bonusWaterMl: 0,
      weatherCondition: 'Standard',
    );
  }
}
