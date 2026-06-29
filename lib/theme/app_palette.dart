import 'package:flutter/material.dart';

/// An immutable named colour palette used across the app.
class AppPalette {
  final String id;
  final String name;
  final Color background; // scaffold background
  final Color surface; // cards
  final Color primary; // main accent: buttons, selected nav, icons
  final Color accent; // secondary accent: app bars, chips
  final Color text; // primary text
  final Color textMuted; // secondary text
  final Color danger; // destructive (logout)

  const AppPalette({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.text,
    required this.textMuted,
    this.danger = const Color(0xFFE0795C),
  });

  static const List<AppPalette> all = [
    AppPalette(
      id: 'pudding',
      name: 'Pudding',
      background: Color(0xFFFFF6EB),
      surface: Colors.white,
      primary: Color(0xFFF77F42),
      accent: Color(0xFFF8D66D),
      text: Color(0xFF6B4F3A),
      textMuted: Color(0xFF9C7B53),
    ),
    AppPalette(
      id: 'citrus',
      name: 'Citrus',
      background: Color(0xFFF6FBEC),
      surface: Colors.white,
      primary: Color(0xFF7BB661),
      accent: Color(0xFFE7D94C),
      text: Color(0xFF49603A),
      textMuted: Color(0xFF89A06C),
    ),
    AppPalette(
      id: 'ocean',
      name: 'Ocean',
      background: Color(0xFFEFF6FB),
      surface: Colors.white,
      primary: Color(0xFF3F9AC4),
      accent: Color(0xFF8ECAE6),
      text: Color(0xFF2C4A5A),
      textMuted: Color(0xFF6C8A9A),
    ),
    AppPalette(
      id: 'matcha',
      name: 'Matcha',
      background: Color(0xFFF1F5EC),
      surface: Colors.white,
      primary: Color(0xFF5C8A57),
      accent: Color(0xFFA9C99A),
      text: Color(0xFF3A4A36),
      textMuted: Color(0xFF7A8A70),
    ),
    AppPalette(
      id: 'grape',
      name: 'Grape',
      background: Color(0xFFF6F2FA),
      surface: Colors.white,
      primary: Color(0xFF9B7EC4),
      accent: Color(0xFFCBB6E6),
      text: Color(0xFF463A57),
      textMuted: Color(0xFF8B7AA0),
    ),
    AppPalette(
      id: 'sakura',
      name: 'Sakura',
      background: Color(0xFFFDF1F3),
      surface: Colors.white,
      primary: Color(0xFFE48BA0),
      accent: Color(0xFFF4C2CE),
      text: Color(0xFF6A4750),
      textMuted: Color(0xFFB08A93),
    ),
  ];

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => all.first);
}
