import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherDay {
  final DateTime date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;

  const WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
  });

  String get description {
    if (weatherCode == 0) return 'Sunny';
    if (weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode <= 48) return 'Cloudy / Fog';
    if (weatherCode <= 67) return 'Rain';
    if (weatherCode <= 77) return 'Snow';
    if (weatherCode <= 82) return 'Showers';
    return 'Thunderstorm';
  }

  IconData get icon {
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode <= 3) return Icons.cloud_queue;
    if (weatherCode <= 48) return Icons.cloud;
    if (weatherCode <= 67) return Icons.water_drop;
    if (weatherCode <= 77) return Icons.ac_unit;
    if (weatherCode <= 82) return Icons.grain;
    return Icons.thunderstorm;
  }

  Color get color {
    if (weatherCode == 0) return const Color(0xFFFF9800);
    if (weatherCode <= 3) return const Color(0xFF90A4AE);
    if (weatherCode <= 48) return const Color(0xFF78909C);
    if (weatherCode <= 67) return const Color(0xFF42A5F5);
    if (weatherCode <= 77) return const Color(0xFF80DEEA);
    if (weatherCode <= 82) return const Color(0xFF4FC3F7);
    return const Color(0xFF7E57C2);
  }

  String get tempRange => '${tempMin.round()}° / ${tempMax.round()}°F';
}

/// Tracks whether the current weather data reflects the user's actual location.
/// `false` = no location permission or geolocation failed, weather is unavailable.
final weatherLocationAvailableProvider = StateProvider<bool>((ref) => true);

final weatherProvider = FutureProvider<Map<DateTime, WeatherDay>>((ref) async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // No location permission — don't guess a city. Return empty so the UI
      // can surface "Enable location for weather" instead of showing NYC.
      ref.read(weatherLocationAvailableProvider.notifier).state = false;
      return <DateTime, WeatherDay>{};
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    ref.read(weatherLocationAvailableProvider.notifier).state = true;
    return _fetchWeather(position.latitude, position.longitude);
  } catch (_) {
    // Geolocation failed (browser blocked, no GPS, etc.) — don't fabricate weather.
    ref.read(weatherLocationAvailableProvider.notifier).state = false;
    return <DateTime, WeatherDay>{};
  }
});

Future<Map<DateTime, WeatherDay>> _fetchWeather(
    double lat, double lon) async {
  final uri = Uri.parse(
    'https://api.open-meteo.com/v1/forecast'
    '?latitude=$lat&longitude=$lon'
    '&daily=weather_code,temperature_2m_max,temperature_2m_min'
    '&temperature_unit=fahrenheit'
    '&timezone=auto&forecast_days=16',
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) return {};

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final daily = data['daily'] as Map<String, dynamic>;
  final dates  = (daily['time']           as List).cast<String>();
  final codes  = (daily['weather_code']   as List).cast<int>();
  final maxT   = (daily['temperature_2m_max'] as List).map((v) => (v as num).toDouble()).toList();
  final minT   = (daily['temperature_2m_min'] as List).map((v) => (v as num).toDouble()).toList();

  final result = <DateTime, WeatherDay>{};
  for (int i = 0; i < dates.length; i++) {
    final d = DateTime.parse(dates[i]);
    final key = DateTime(d.year, d.month, d.day);
    result[key] = WeatherDay(
      date: key,
      weatherCode: codes[i],
      tempMax: maxT[i],
      tempMin: minT[i],
    );
  }
  return result;
}
