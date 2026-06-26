import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralizes all forum-related Firestore writes (likes, and later
/// notifications). Keeping this logic out of the widgets makes the UI
/// declarative and the data rules easy to reason about.
class ForumService {
  ForumService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// Whether [postData] is currently liked by the signed-in user.
  bool isLikedBy(Map<String, dynamic> postData, String? uid) {
    if (uid == null) return false;
    final likedBy = List<String>.from(postData['likedBy'] ?? const []);
    return likedBy.contains(uid);
  }

  /// Reads the like count defensively (old posts may not have the field yet).
  int likeCount(Map<String, dynamic> postData) {
    final raw = postData['likes'];
    if (raw is int) return raw;
    return List<String>.from(postData['likedBy'] ?? const []).length;
  }

  /// Toggles the current user's like on a post inside a transaction so the
  /// count can never drift. `likes` is derived from `likedBy.length`, which
  /// also self-heals any historical inconsistency.
  ///
  /// Returns the new liked state (true = now liked), or null if not signed in.
  Future<bool?> togglePostLike(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final postRef = _db.collection('posts').doc(postId);

    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(postRef);
      if (!snap.exists) return false;

      final data = snap.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? const []);
      final alreadyLiked = likedBy.contains(uid);

      if (alreadyLiked) {
        likedBy.remove(uid);
      } else {
        likedBy.add(uid);
      }

      tx.update(postRef, {
        'likedBy': likedBy,
        'likes': likedBy.length,
      });

      return !alreadyLiked;
    });
  }
}
