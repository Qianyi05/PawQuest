import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pawquest/services/forum_service.dart';
import 'package:provider/provider.dart';
import 'package:pawquest/providers/theme_provider.dart';
import 'package:pawquest/theme/app_palette.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_name.dart';
import 'user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final String authorName;
  final String content;
  final Timestamp timestamp;
  final String? authorId;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.authorId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  AppPalette p = AppPalette.all.first;

  final TextEditingController _commentController = TextEditingController();
  final ForumService _forum = ForumService();

  String? _replyingToId;
  String? _replyingToName;
  String? _replyingToAuthorId;
  String? _replyingRootId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _openProfile(String? uid) {
    if (uid != null && uid.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: uid)),
      );
    }
  }

  void _startReply({
    required String commentId,
    required String name,
    required String authorId,
    required String rootId,
  }) {
    setState(() {
      _replyingToId = commentId;
      _replyingToName = name;
      _replyingToAuthorId = authorId;
      _replyingRootId = rootId;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyingToName = null;
      _replyingToAuthorId = null;
      _replyingRootId = null;
    });
  }

  Future<void> _send() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || FirebaseAuth.instance.currentUser == null) return;
    await _forum.addComment(
      widget.postId,
      text,
      parentId: _replyingToId,
      parentAuthorId: _replyingToAuthorId,
      parentName: _replyingToName,
      rootId: _replyingRootId,
    );
    _commentController.clear();
    _cancelReply();
  }

  Future<void> _confirmDelete(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete this comment?'),
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
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    p = context.watch<ThemeProvider>().palette;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('Post Detail',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: p.accent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _originalPost(user),
          // ---------------- Comments ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: p.primary));
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 44, color: p.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text('No comments yet',
                            style: TextStyle(
                                color: p.text.withValues(alpha: 0.7))),
                        Text('Be the first to say something!',
                            style: TextStyle(
                                fontSize: 12,
                                color: p.text.withValues(alpha: 0.5))),
                      ],
                    ),
                  );
                }

                final topLevel = <QueryDocumentSnapshot>[];
                final repliesByRoot =
                    <String, List<QueryDocumentSnapshot>>{};
                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final parentId = data['parentId'] as String?;
                  if (parentId == null) {
                    topLevel.add(d);
                  } else {
                    final root = (data['rootId'] as String?) ?? parentId;
                    repliesByRoot.putIfAbsent(root, () => []).add(d);
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: topLevel.length,
                  itemBuilder: (context, index) {
                    final root = topLevel[index];
                    final replies = repliesByRoot[root.id] ?? const [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildComment(root, user,
                              isReply: false, rootId: root.id),
                          for (final reply in replies)
                            _buildComment(reply, user,
                                isReply: true, rootId: root.id),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---------------- Reply banner ----------------
          if (_replyingToId != null)
            Container(
              width: double.infinity,
              color: p.accent.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded, size: 16, color: p.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingToName ?? ''}',
                      style: TextStyle(
                          fontSize: 13,
                          color: p.text,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 18, color: p.text),
                  ),
                ],
              ),
            ),

          // ---------------- Input bar ----------------
          _inputBar(user),
        ],
      ),
    );
  }

  Widget _originalPost(User? user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _openProfile(widget.authorId),
                child: UserAvatar(
                  userId: widget.authorId,
                  fallbackName: widget.authorName,
                  radius: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _openProfile(widget.authorId),
                  child: UserName(
                    userId: widget.authorId,
                    fallback: widget.authorName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: p.text,
                        fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                widget.timestamp.toDate().toString().substring(0, 16),
                style: TextStyle(
                    color: p.text.withValues(alpha: 0.45), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(widget.content,
              style: TextStyle(
                  color: p.text, fontSize: 15, height: 1.4)),
          const SizedBox(height: 12),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .snapshots(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>?;
              final liked =
                  data != null && ForumService.isLikedBy(data, user?.uid);
              final likes =
                  data != null ? ForumService.likeCount(data) : 0;
              return Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked ? Colors.redAccent : p.textMuted,
                      size: 22,
                    ),
                    onPressed: user == null
                        ? null
                        : () => _forum.togglePostLike(widget.postId),
                  ),
                  const SizedBox(width: 6),
                  Text('$likes',
                      style: TextStyle(
                          color: p.text, fontWeight: FontWeight.w600)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _inputBar(User? user) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: TextStyle(color: p.text),
                decoration: InputDecoration(
                  hintText: _replyingToId == null
                      ? 'Start a conversation...'
                      : 'Write a reply...',
                  hintStyle:
                      TextStyle(color: p.text.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: p.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: p.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _send,
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(
    QueryDocumentSnapshot doc,
    User? user, {
    required bool isReply,
    required String rootId,
  }) {
    final comment = doc.data() as Map<String, dynamic>;
    final authorName = comment['authorName'] ?? 'Unknown User';
    final replyToName = comment['replyToName'] as String?;
    final isAuthor = user != null && user.uid == comment['authorId'];
    final ts = comment['timestamp'];
    final timeLabel =
        ts is Timestamp ? ts.toDate().toString().substring(5, 16) : '';

    return Container(
      margin: EdgeInsets.only(left: isReply ? 16 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: isReply
          ? const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFE0C9A6), width: 2),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openProfile(comment['authorId'] as String?),
            child: UserAvatar(
              userId: comment['authorId'] as String?,
              fallbackName: authorName,
              radius: isReply ? 12 : 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: UserName(
                        userId: comment['authorId'] as String?,
                        fallback: authorName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: p.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeLabel,
                          style: TextStyle(
                              color: p.text.withValues(alpha: 0.4),
                              fontSize: 12),
                        ),
                        if (isAuthor)
                          InkWell(
                            onTap: () => _confirmDelete(doc.id),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.delete_outline,
                                  size: 16,
                                  color: p.text.withValues(alpha: 0.4)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (isReply &&
                    replyToName != null &&
                    replyToName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '↳ $replyToName',
                      style:
                          TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(comment['content'] ?? '',
                    style: TextStyle(color: p.text, height: 1.35)),
                if (user != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _startReply(
                        commentId: doc.id,
                        name: authorName,
                        authorId: comment['authorId'] ?? '',
                        rootId: rootId,
                      ),
                      child: Text('Reply',
                          style: TextStyle(
                              fontSize: 13,
                              color: p.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}