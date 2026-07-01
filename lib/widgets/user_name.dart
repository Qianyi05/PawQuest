import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shows a user's current nickname, resolved live from their Firestore user
/// doc so renaming updates everywhere (old posts included). Short-lived cache
/// like UserAvatar. Falls back to [fallback] while loading or on failure.
class UserName extends StatefulWidget {
  final String? userId;
  final String? fallback;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const UserName({
    super.key,
    required this.userId,
    this.fallback,
    this.style,
    this.maxLines,
    this.overflow,
  });

  static const Duration _ttl = Duration(minutes: 5);
  static final Map<String, _NameEntry> _cache = {};

  static void invalidate(String uid) => _cache.remove(uid);
  static void invalidateAll() => _cache.clear();

  static Future<String?> _load(String uid) async {
    final now = DateTime.now();
    final cached = _cache[uid];
    if (cached != null && now.difference(cached.fetchedAt) < _ttl) {
      return cached.name;
    }
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final name = (doc.data()?['nickname'] as String?)?.trim();
      _cache[uid] = _NameEntry(now, name);
      return name;
    } catch (_) {
      return cached?.name;
    }
  }

  @override
  State<UserName> createState() => _UserNameState();
}

class _NameEntry {
  final DateTime fetchedAt;
  final String? name;
  _NameEntry(this.fetchedAt, this.name);
}

class _UserNameState extends State<UserName> {
  late Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  @override
  void didUpdateWidget(UserName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _future = _resolve();
    }
  }

  Future<String?> _resolve() {
    final uid = widget.userId;
    if (uid == null || uid.isEmpty) return Future.value(null);
    return UserName._load(uid);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snap) {
        final resolved = (snap.data != null && snap.data!.isNotEmpty)
            ? snap.data!
            : (widget.fallback ?? 'Anonymous user');
        return Text(
          resolved,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}