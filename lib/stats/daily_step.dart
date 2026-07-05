import 'package:cloud_firestore/cloud_firestore.dart';

/// One calendar day of step data, normalised from a
/// `users/{uid}/step_history/{date}` document.
///
/// The stored `date` key is `YYYY-MM-DD` (see StepProvider._todayDateKey),
/// which sorts lexicographically the same as chronologically.
class DailyStep {
  final DateTime date; // normalised to midnight (date-only)
  final int steps; // steps taken that day (the doc's `daily` field)

  const DailyStep({required this.date, required this.steps});

  /// The `YYYY-MM-DD` key used by Firestore.
  String get key =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Parse a Firestore history document. Falls back to the document id when
  /// the `date` field is missing, and to 0 steps for malformed data — the
  /// dashboard must never crash on a bad row (NFR3).
  factory DailyStep.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final raw = (data['date'] as String?) ?? doc.id;
    return DailyStep(
      date: _parseKey(raw),
      steps: (data['daily'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime _parseKey(String key) {
    final parts = key.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
    // Unparseable key: place it at the epoch so it sorts out of the way.
    return DateTime(1970);
  }

  DailyStep copyWith({DateTime? date, int? steps}) =>
      DailyStep(date: date ?? this.date, steps: steps ?? this.steps);
}
