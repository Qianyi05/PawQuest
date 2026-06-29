import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_palette.dart';

/// Holds the active colour palette, persisted per user in their Firestore doc
/// (`theme` field). Loads automatically on sign-in and resets on sign-out.
class ThemeProvider extends ChangeNotifier {
  AppPalette _palette = AppPalette.all.first;
  AppPalette get palette => _palette;
  String get currentId => _palette.id;

  ThemeProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        load();
      } else {
        _palette = AppPalette.all.first;
        notifyListeners();
      }
    });
  }

  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final id = doc.data()?['theme'] as String?;
      if (id != null) {
        _palette = AppPalette.byId(id);
        notifyListeners();
      }
    } catch (_) {
      // ignore: keep default palette on failure
    }
  }

  Future<void> setPalette(String id) async {
    _palette = AppPalette.byId(id);
    notifyListeners();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'theme': id}, SetOptions(merge: true));
    } catch (_) {
      // ignore: selection still applies in-session
    }
  }
}
