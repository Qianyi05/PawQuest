import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles follow / unfollow and follower/following counts.
///
/// Data model (mirrored writes for easy counting):
///   users/{me}/following/{targetUid}   = { timestamp }
///   users/{target}/followers/{me}      = { timestamp }
class FollowService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Live "am I following [targetUid]?" stream.
  Stream<bool> isFollowing(String targetUid) {
    final me = _uid;
    if (me == null) return Stream.value(false);
    return _db
        .collection('users')
        .doc(me)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Live follower count for [uid].
  Stream<int> followerCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Live following count for [uid].
  Stream<int> followingCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Toggle follow state for [targetUid]. No-op if not logged in or self.
  Future<void> toggleFollow(String targetUid) async {
    final me = _uid;
    if (me == null || me == targetUid) return;

    final myFollowing =
        _db.collection('users').doc(me).collection('following').doc(targetUid);
    final theirFollowers =
        _db.collection('users').doc(targetUid).collection('followers').doc(me);

    final existing = await myFollowing.get();
    final batch = _db.batch();
    if (existing.exists) {
      batch.delete(myFollowing);
      batch.delete(theirFollowers);
    } else {
      final now = FieldValue.serverTimestamp();
      batch.set(myFollowing, {'timestamp': now});
      batch.set(theirFollowers, {'timestamp': now});
    }
    await batch.commit();
  }
}