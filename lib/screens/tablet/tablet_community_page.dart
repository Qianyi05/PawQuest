import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_palette.dart';
import '../new_post_screen.dart';
import '../post_detail_screen.dart';

class TabletCommunityPage extends StatefulWidget {
  const TabletCommunityPage({super.key});

  @override
  State<TabletCommunityPage> createState() => _TabletCommunityPageState();
}

class _TabletCommunityPageState extends State<TabletCommunityPage> {
  String? _selectedPostId;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().palette;

    return Scaffold(
      backgroundColor: p.background,
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Image.asset(
                    'assets/images/title/talk.png',
                    height: 82,
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.contain,
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewPostScreen()),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New post'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load posts.'));
                  }
                  if (!snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(color: p.primary));
                  }

                  final posts = snapshot.data!.docs;
                  if (posts.isEmpty) {
                    return const Center(child: Text('No posts yet.'));
                  }

                  // Do not use firstWhere(orElse:) here. Firestore's list has
                  // an internal _JsonQueryDocumentSnapshot runtime subtype,
                  // which makes the orElse callback fail a runtime type check.
                  var selected = posts.first;
                  for (final post in posts) {
                    if (post.id == _selectedPostId) {
                      selected = post;
                      break;
                    }
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 350,
                        child: _PostList(
                          posts: posts,
                          selectedId: selected.id,
                          p: p,
                          onSelected: (id) {
                            setState(() => _selectedPostId = id);
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: PostDetailScreen(
                            key: ValueKey(selected.id),
                            postId: selected.id,
                            authorName:
                                selected.data()['authorName'] ?? 'Anonymous',
                            content: selected.data()['content'] ?? '',
                            timestamp: selected.data()['timestamp'] is Timestamp
                                ? selected.data()['timestamp'] as Timestamp
                                : Timestamp.now(),
                            authorId: selected.data()['authorId'] as String?,
                            imageUrl: selected.data()['imageUrl'] as String?,
                            embedded: true,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  const _PostList({
    required this.posts,
    required this.selectedId,
    required this.p,
    required this.onSelected,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> posts;
  final String selectedId;
  final AppPalette p;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 14,
          endIndent: 14,
          color: p.textMuted.withValues(alpha: 0.15),
        ),
        itemBuilder: (context, index) {
          final post = posts[index];
          final data = post.data();
          final imageUrl = data['imageUrl'] as String?;
          final selected = post.id == selectedId;

          return ListTile(
            selected: selected,
            selectedTileColor: p.accent.withValues(alpha: 0.28),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackIcon(p),
                    ),
                  )
                : _fallbackIcon(p),
            title: Text(
              data['authorName'] ?? 'Anonymous',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.text,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              data['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textMuted),
            ),
            onTap: () => onSelected(post.id),
          );
        },
      ),
    );
  }

  Widget _fallbackIcon(AppPalette p) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.article_outlined, color: p.primary),
    );
  }
}
