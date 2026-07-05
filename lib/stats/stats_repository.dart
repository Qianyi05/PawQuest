import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'daily_step.dart';

/// Reads the signed-in user's `step_history` sub-collection and turns it into
/// a list of [DailyStep]s for the aggregation layer. This is the only piece of
/// the stats feature that touches Firebase, keeping [StepStats] pure.
class StatsRepository {
  StatsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? _historyRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('step_history');
  }

  /// A one-shot load. Optionally bounded to the last [lastDays] days to keep
  /// reads cheap for the shorter ranges. Pass null to load everything (needed
  /// for lifetime totals and all-time records).
  Future<List<DailyStep>> load({int? lastDays}) async {
    final ref = _historyRef();
    if (ref == null) return const [];

    Query<Map<String, dynamic>> query = ref;
    if (lastDays != null) {
      final from = DateTime.now().subtract(Duration(days: lastDays));
      final key =
          '${from.year}-${_two(from.month)}-${_two(from.day)}';
      // `date` is a sortable YYYY-MM-DD string, so a range filter works.
      query = ref.where('date', isGreaterThanOrEqualTo: key);
    }

    final snap = await query.get();
    return snap.docs.map(DailyStep.fromDoc).toList();
  }

  /// A live stream — the dashboard updates as new steps are written.
  Stream<List<DailyStep>> watch() {
    final ref = _historyRef();
    if (ref == null) return Stream.value(const []);
    return ref.snapshots().map(
          (snap) => snap.docs.map(DailyStep.fromDoc).toList(),
        );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
