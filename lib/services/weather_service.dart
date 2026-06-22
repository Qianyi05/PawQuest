import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherModel> fetchCurrentWeather() async {
    final position = await _getCurrentPosition();
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

    if (apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw WeatherException(
        'OpenWeather API key is missing. Add it to your .env file.',
      );
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': position.latitude.toString(),
      'lon': position.longitude.toString(),
      'appid': apiKey,
      'units': 'metric',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw WeatherException('Weather request failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherModel.fromJson(
      json,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw WeatherException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw WeatherException('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw WeatherException(
        'Location permission is permanently denied. Enable it in Settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }
}

class WeatherException implements Exception {
  final String message;

  WeatherException(this.message);

  @override
  String toString() => message;
}
