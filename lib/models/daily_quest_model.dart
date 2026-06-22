import 'package:cloud_firestore/cloud_firestore.dart';

class DailyQuestModel {
  final String date;
  final int goalSteps;
  final int currentSteps;
  final bool completed;
  final bool rewardClaimed;
  final String questTitle;
  final String questDescription;
  final String weatherMain;
  final double temperature;
  final String locationName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const DailyQuestModel({
    required this.date,
    required this.goalSteps,
    required this.currentSteps,
    required this.completed,
    required this.rewardClaimed,
    required this.questTitle,
    required this.questDescription,
    required this.weatherMain,
    required this.temperature,
    required this.locationName,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyQuestModel.fromFirestore(Map<String, dynamic> data) {
    return DailyQuestModel(
      date: data['date']?.toString() ?? '',
      goalSteps: (data['goalSteps'] as num?)?.toInt() ?? 4000,
      currentSteps: (data['currentSteps'] as num?)?.toInt() ?? 0,
      completed: data['completed'] == true,
      rewardClaimed: data['rewardClaimed'] == true,
      questTitle: data['questTitle']?.toString() ?? 'Daily Walk',
      questDescription:
          data['questDescription']?.toString() ?? 'Complete 4000 steps today.',
      weatherMain: data['weatherMain']?.toString() ?? 'Default',
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0,
      locationName: data['locationName']?.toString() ?? 'Current location',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore({bool includeCreatedAt = true}) {
    return {
      'date': date,
      'goalSteps': goalSteps,
      'currentSteps': currentSteps,
      'completed': completed,
      'rewardClaimed': rewardClaimed,
      'questTitle': questTitle,
      'questDescription': questDescription,
      'weatherMain': weatherMain,
      'temperature': temperature,
      'locationName': locationName,
      if (includeCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DailyQuestModel copyWith({
    int? currentSteps,
    bool? completed,
  }) {
    return DailyQuestModel(
      date: date,
      goalSteps: goalSteps,
      currentSteps: currentSteps ?? this.currentSteps,
      completed: completed ?? this.completed,
      rewardClaimed: rewardClaimed,
      questTitle: questTitle,
      questDescription: questDescription,
      weatherMain: weatherMain,
      temperature: temperature,
      locationName: locationName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
