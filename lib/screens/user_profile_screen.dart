import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/theme/app_palette.dart';
import 'package:pawquest/widgets/user_avatar.dart';
import 'package:pawquest/services/follow_service.dart';

/// Public profile for any user: avatar, name, city/age, bio, follow button,
/// follower/following counts, and their public posts.
class UserProfileScreen extends StatelessWidget {
  final String userId;

  UserProfileScreen({super.key, required this.userId});

  final FollowService _follow = FollowService();

  bool get _isSelf => FirebaseAuth.instance.currentUser?.uid == userId;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load profile:\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textMuted)),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: p.primary));
          }
          final data = snap.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(
              child: Text('This user has no profile yet.',
                  style: TextStyle(color: p.textMuted)),
            );
          }
          final nickname = data['nickname'] ?? 'Unnamed';
          final bio = data['bio'] as String?;
          final city = data['city'] as String?;
          final age = data['age'] as int?;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: [
              _header(context, p, nickname, bio, city, age),
              const SizedBox(height: 24),
              Text(
                'Posts',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: p.text),
              ),
              const SizedBox(height: 12),
              _posts(p),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, AppPalette p, String nickname,
      String? bio, String? city, int? age) {
    final chips = <Widget>[];
    if (city != null && city.isNotEmpty) {
      chips.add(_chip(p, Icons.location_city_rounded, city));
    }
    if (age != null) {
      chips.add(_chip(p, Icons.cake_rounded, '$age'));
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          UserAvatar(userId: userId, fallbackName: nickname, radius: 46),
          const SizedBox(height: 14),
          Text(
            nickname,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: p.text),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: chips,
            ),
          ],
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: p.text.withValues(alpha: 0.75),
                  height: 1.4),
            ),
          ],
          const SizedBox(height: 18),
          _statsRow(p),
          if (!_isSelf) ...[
            const SizedBox(height: 16),
            _followButton(p),
          ],
        ],
      ),
    );
  }

  Widget _statsRow(AppPalette p) {
    Widget stat(Stream<int> stream, String label) {
      return Column(
        children: [
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snap) => Text(
              '${snap.data ?? 0}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: p.text),
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: p.textMuted)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        stat(_follow.followerCount(userId), 'Followers'),
        Container(
          width: 1,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          color: p.text.withValues(alpha: 0.12),
        ),
        stat(_follow.followingCount(userId), 'Following'),
      ],
    );
  }

  Widget _followButton(AppPalette p) {
    return StreamBuilder<bool>(
      stream: _follow.isFollowing(userId),
      builder: (context, snap) {
        final following = snap.data ?? false;
        return SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () => _follow.toggleFollow(userId),
            icon: Icon(
              following ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
              size: 18,
            ),
            label: Text(following ? 'Following' : 'Follow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: following ? p.surface : p.primary,
              foregroundColor: following ? p.text : Colors.white,
              elevation: 0,
              side: following
                  ? BorderSide(color: p.text.withValues(alpha: 0.2))
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(AppPalette p, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: p.primary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: p.text,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _posts(AppPalette p) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: p.primary)),
          );
        }
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['timestamp'];
            final tb = (b.data() as Map<String, dynamic>)['timestamp'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            return 0;
          });
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('No posts yet',
                  style: TextStyle(color: p.textMuted)),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final ts = d['timestamp'];
            final timeLabel = ts is Timestamp
                ? ts.toDate().toString().substring(0, 16)
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['content'] ?? '',
                      style: TextStyle(
                          fontSize: 15, color: p.text, height: 1.35)),
                  const SizedBox(height: 8),
                  Text(timeLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: p.text.withValues(alpha: 0.45))),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}