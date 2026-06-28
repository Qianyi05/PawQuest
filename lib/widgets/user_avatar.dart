import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shows a user's current avatar (uploaded photo if any, otherwise their cat
/// character), resolved live from their user doc. Falls back to the first
/// letter of [fallbackName].
///
/// Results are cached per session so a list of posts doesn't trigger a read
/// per rebuild.
class UserAvatar extends StatelessWidget {
  final String? userId;
  final String? fallbackName;
  final double radius;

  const UserAvatar({
    super.key,
    required this.userId,
    this.fallbackName,
    this.radius = 16,
  });

  static const Color _yellow = Color(0xFFF8D66D);
  static const Color _brown = Color(0xFF6B4F3A);

  static final Map<String, Future<Map<String, dynamic>?>> _cache = {};

  Future<Map<String, dynamic>?> _load(String uid) {
    return _cache.putIfAbsent(uid, () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        return doc.data();
      } catch (_) {
        return null;
      }
    });
  }

  Widget _circle(ImageProvider? img, String letter) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _yellow.withValues(alpha: 0.4),
      backgroundImage: img,
      child: img == null
          ? Text(
              letter,
              style: TextStyle(
                color: _brown,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.85,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = userId;
    final letter = (fallbackName != null && fallbackName!.isNotEmpty)
        ? fallbackName![0].toUpperCase()
        : '?';
    if (uid == null || uid.isEmpty) return _circle(null, letter);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _load(uid),
      builder: (context, snap) {
        final data = snap.data;
        final avatarUrl = data?['avatarUrl'] as String?;
        final cat = data?['cat'] as String?;
        ImageProvider? img;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          img = NetworkImage(avatarUrl);
        } else if (cat != null && cat.isNotEmpty) {
          img = AssetImage('assets/images/cats_profile/$cat.jpeg');
        }
        return _circle(img, letter);
      },
    );
  }
}
