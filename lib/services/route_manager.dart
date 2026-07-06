import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

typedef CityUnlockedCallback = void Function(String cityName, String? badgeUrl);

class RouteManager {
  static final RouteManager _instance = RouteManager._internal();

  factory RouteManager() => _instance;

  RouteManager._internal();

  CityUnlockedCallback? _onCityUnlocked;

  void setOnCityUnlockedCallback(CityUnlockedCallback callback) {
    _onCityUnlocked = callback;
  }

  /// Loads every city unlocked by the current user's step total.
  Future<List<Map<String, dynamic>>> loadUnlockedCities(
      int currentSteps) async {
    final configJson = await rootBundle.loadString('assets/config/cities.json');
    final configuredCities =
        (jsonDecode(configJson) as List).cast<Map<String, dynamic>>();
    final positionsByName = {
      for (final city in configuredCities) city['name'] as String: city,
    };

    final snapshot = await FirebaseFirestore.instance
        .collection('cities')
        .orderBy('order')
        .get();

    final List<Map<String, dynamic>> unlocked = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['stepRequired'] <= currentSteps) {
        final configured = positionsByName[data['name']];
        if (configured == null) continue;
        unlocked.add({
          'name': data['name'],
          'stepRequired': data['stepRequired'],
          'badge': data['badge'],
          'order': data['order'],
          'mapX': configured['mapX'],
          'mapY': configured['mapY'],
        });
      }
    }

    return unlocked;
  }

  /// Checks the next city threshold and triggers at most one unlock.
  Future<void> checkAndUnlockCities(int currentSteps) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('cities')
        .orderBy('order')
        .get();

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final userDoc = await userRef.get();
    final int unlockedOrder = userDoc.data()?['currentCityOrder'] ?? -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final int cityOrder = data['order'];
      final int stepRequired = data['stepRequired'];

      if (cityOrder == unlockedOrder + 1 && currentSteps >= stepRequired) {
        // Unlock the newly reached city.
        await userRef.set(
          {'currentCityOrder': cityOrder},
          SetOptions(merge: true),
        );
        if (_onCityUnlocked != null) {
          _onCityUnlocked!(data['name'], data['badge']);
        }
        break;
      }
    }
  }
}
