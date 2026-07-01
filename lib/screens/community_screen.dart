import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/services/forum_service.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/theme/app_palette.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';
import 'new_post_screen.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_name.dart';

class CommunityScreen extends StatelessWidget {
  CommunityScreen({super.key});

  final ForumService _forum = ForumService();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Image.asset(
              "assets/images/title/talk.png",
              height: 104,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: p.primary));
                  }

                  final posts = snapshot.data?.docs ?? [];

                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 48, color: p.text.withValues(alpha: 0.4)),
                          const SizedBox(height: 10),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                                color: p.text,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Be the first to share something!',
                            style: TextStyle(
                                color: p.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 110),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final doc = posts[index];
                      final postData = doc.data() as Map<String, dynamic>;
                      return _PostCard(
                        postId: doc.id,
                        postData: postData,
                        currentUid: currentUser?.uid,
                        forum: _forum,
                        p: p,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: p.primary,
          elevation: 3,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          onPressed: () => _showPostDialog(context, p),
        ),
      ),
    );
  }

  void _showPostDialog(BuildContext context, AppPalette p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewPostScreen()),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.postId,
    required this.postData,
    required this.currentUid,
    required this.forum,
    required this.p,
  });

  final String postId;
  final Map<String, dynamic> postData;
  final String? currentUid;
  final ForumService forum;
  final AppPalette p;

  void _openProfile(BuildContext context) {
    final aid = postData['authorId'] as String?;
    if (aid != null && aid.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: aid)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthor = currentUid != null && currentUid == postData['authorId'];
    final liked = ForumService.isLikedBy(postData, currentUid);
    final likes = ForumService.likeCount(postData);
    final author = postData['authorName'] ?? 'Anonymous user';
    final ts = postData['timestamp'];
    final timeLabel =
        ts is Timestamp ? ts.toDate().toString().substring(0, 16) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                postId: postId,
                authorName: author,
                content: postData['content'] ?? '',
                timestamp: ts is Timestamp ? ts : Timestamp.now(),
                authorId: postData['authorId'] as String?,
                imageUrl: postData['imageUrl'] as String?,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: UserAvatar(
                        userId: postData['authorId'] as String?,
                        fallbackName: author,
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openProfile(context),
                        child: UserName(
                          userId: postData['authorId'] as String?,
                          fallback: author,
                          style: TextStyle(
                            fontSize: 15,
                            color: p.text,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: p.text.withValues(alpha: 0.45)),
                    ),
                    if (isAuthor)
                      InkWell(
                        onTap: () => _confirmDelete(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.delete_outline,
                              size: 20,
                              color: p.text.withValues(alpha: 0.4)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if ((postData['content'] ?? '').toString().isNotEmpty)
                  Text(
                    postData['content'] ?? '',
                    style: TextStyle(fontSize: 15, color: p.text, height: 1.35),
                  ),
                if (postData['imageUrl'] != null &&
                    (postData['imageUrl'] as String).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      postData['imageUrl'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 180,
                          alignment: Alignment.center,
                          color: p.background,
                          child: CircularProgressIndicator(
                              color: p.primary, strokeWidth: 2),
                        );
                      },
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.redAccent : Colors.grey,
                        size: 22,
                      ),
                      onPressed: currentUid == null
                          ? null
                          : () => forum.togglePostLike(postId),
                    ),
                    const SizedBox(width: 4),
                    Text('$likes',
                        style: TextStyle(fontSize: 13, color: p.text)),
                    const SizedBox(width: 16),
                    Icon(Icons.mode_comment_outlined,
                        size: 18, color: p.text.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text('Reply',
                        style: TextStyle(
                            fontSize: 13,
                            color: p.text.withValues(alpha: 0.55))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Do you really want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    }
  }
}