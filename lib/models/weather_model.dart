class WeatherModel {
  final String weatherMain;
  final String description;
  final double temperature;
  final String locationName;
  final double latitude;
  final double longitude;

  const WeatherModel({
    required this.weatherMain,
    required this.description,
    required this.temperature,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  factory WeatherModel.fromJson(
    Map<String, dynamic> json, {
    required double latitude,
    required double longitude,
  }) {
    final weatherList = json['weather'] as List?;
    final weather = weatherList == null || weatherList.isEmpty
        ? null
        : weatherList.first as Map<String, dynamic>?;
    final main = json['main'] as Map<String, dynamic>?;

    return WeatherModel(
      weatherMain: weather?['main']?.toString() ?? 'Unknown',
      description: weather?['description']?.toString() ?? 'No description',
      temperature: (main?['temp'] as num?)?.toDouble() ?? 0,
      locationName: json['name']?.toString() ?? 'Current location',
      latitude: latitude,
      longitude: longitude,
    );
  }

  String get walkingAdvice {
    if (temperature >= 30) {
      return 'It is hot. Drink water and avoid walking at noon.';
    }
    if (temperature <= 5) {
      return 'It is cold. Keep warm and choose a safe route.';
    }

    switch (weatherMain) {
      case 'Clear':
      case 'Clouds':
        return 'Good walking weather. An outdoor walk is a nice choice today.';
      case 'Rain':
      case 'Drizzle':
      case 'Thunderstorm':
        return 'Rainy weather. Indoor steps are safer today.';
      case 'Snow':
        return 'Snowy weather. Walk carefully and avoid slippery areas.';
      case 'Mist':
      case 'Fog':
      case 'Haze':
      case 'Smoke':
      case 'Dust':
        return 'Visibility or air quality is not ideal. Walk carefully.';
      default:
        return 'Complete a steady daily walk at your own pace.';
    }
  }
}
