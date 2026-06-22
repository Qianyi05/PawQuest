import 'package:flutter/material.dart';

import '../models/daily_quest_model.dart';
import '../models/weather_model.dart';
import '../services/daily_quest_service.dart';
import '../services/weather_service.dart';

class DailyQuestProvider with ChangeNotifier {
  final DailyQuestService _dailyQuestService;
  final WeatherService _weatherService;

  DailyQuestProvider({
    DailyQuestService? dailyQuestService,
    WeatherService? weatherService,
  })  : _dailyQuestService = dailyQuestService ?? DailyQuestService(),
        _weatherService = weatherService ?? WeatherService();

  DailyQuestModel? _quest;
  WeatherModel? _weather;
  bool _isLoading = false;
  String? _errorMessage;

  DailyQuestModel? get quest => _quest;
  WeatherModel? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadTodayQuest(int currentSteps) async {
    _setLoading(true);
    try {
      WeatherModel? weather;
      String? weatherError;

      try {
        weather = await _weatherService.fetchCurrentWeather();
      } catch (error) {
        weatherError = error.toString();
      }

      _weather = weather;
      _quest = await _dailyQuestService.getOrCreateTodayQuest(
        currentSteps: currentSteps,
        weather: weather,
      );
      _errorMessage = weatherError;
    } catch (error) {
      _quest = _dailyQuestService.buildDefaultQuest(
        currentSteps: currentSteps,
      );
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh(int currentSteps) async {
    await loadTodayQuest(currentSteps);
  }

  Future<void> syncSteps(int currentSteps) async {
    try {
      _quest = await _dailyQuestService.updateTodayProgress(
        currentSteps,
        existingQuest: _quest,
      );
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
