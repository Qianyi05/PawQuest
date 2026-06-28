import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StepHistoryScreen extends StatelessWidget {
  const StepHistoryScreen({super.key});

  static const Color _cream = Color(0xFFFFF6EB);
  static const Color _yellow = Color(0xFFF8D66D);
  static const Color _orange = Color(0xFFF77F42);
  static const Color _brown = Color(0xFF6B4F3A);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in first")),
      );
    }

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('step_history')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text(
          'Step History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _yellow,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Oldest -> newest
          final docs = snapshot.data!.docs.reversed.toList();
          if (docs.isEmpty) {
            return _emptyState();
          }

          // ---- summary stats over all history ----
          int total = 0;
          int best = 0;
          String bestDate = '';
          final Map<String, int> dateSteps = {};
          for (final d in docs) {
            final daily = _daily(d);
            total += daily;
            final date = (d.data() as Map<String, dynamic>)['date'];
            if (date is String) dateSteps[date] = daily;
            if (daily > best) {
              best = daily;
              bestDate = date is String ? date : '';
            }
          }
          final activeDays = docs.length;
          final avg = activeDays == 0 ? 0 : (total / activeDays).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryGrid(
                total: total,
                avg: avg,
                best: best,
                bestDate: bestDate,
                days: activeDays,
                onActiveDaysTap: () => _openCalendar(context, dateSteps),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Last 7 days'),
              const SizedBox(height: 12),
              _chartCard(docs),
              const SizedBox(height: 24),
              _sectionTitle('Daily details'),
              const SizedBox(height: 12),
              // newest first in the list
              ...docs.reversed.map(_buildStepCard),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- helpers

  int _daily(QueryDocumentSnapshot doc) {
    final raw = (doc.data() as Map<String, dynamic>)['daily'];
    return raw is num ? raw.toInt() : 0;
  }

  String _comma(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _axisLabel(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}k'
          : '${k.toStringAsFixed(1)}k';
    }
    return v.toInt().toString();
  }

  /// A "nice" tick step (1/2/2.5/5 × 10^n) for ~5 ticks.
  double _niceStep(double maxVal, {int ticks = 5}) {
    if (maxVal <= 0) return 1000;
    final rough = maxVal / ticks;
    final mag = pow(10, (log(rough) / ln10).floor()).toDouble();
    final norm = rough / mag;
    double nice;
    if (norm <= 1) {
      nice = 1;
    } else if (norm <= 2) {
      nice = 2;
    } else if (norm <= 2.5) {
      nice = 2.5;
    } else if (norm <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * mag;
  }

  // ----------------------------------------------------------------- widgets

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _brown,
        ),
      );

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_walk_rounded,
              size: 56, color: _orange.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          const Text(
            'No steps recorded yet',
            style: TextStyle(fontSize: 16, color: _brown),
          ),
          const SizedBox(height: 4),
          Text(
            'Start walking and your history will appear here.',
            style: TextStyle(fontSize: 13, color: _brown.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int total,
    required int avg,
    required int best,
    required String bestDate,
    required int days,
    required VoidCallback onActiveDaysTap,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(Icons.functions_rounded, 'Total steps',
                  _comma(total), _orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(Icons.trending_up_rounded, 'Daily average',
                  _comma(avg), _orange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.emoji_events_rounded,
                'Best day',
                _comma(best),
                _orange,
                sub: bestDate.isNotEmpty ? bestDate : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.calendar_month_rounded,
                'Active days',
                '$days',
                _orange,
                onTap: onActiveDaysTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    Color accent, {
    String? sub,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _brown.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: _brown.withValues(alpha: 0.4)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _brown,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 12,
                color: _brown.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: card,
      ),
    );
  }

  void _openCalendar(BuildContext context, Map<String, int> dateSteps) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActiveDaysCalendar(dateSteps: dateSteps),
    );
  }

  Widget _chartCard(List<QueryDocumentSnapshot> docs) {
    // last 7 days, oldest -> newest
    final last7 = docs.length <= 7 ? docs : docs.sublist(docs.length - 7);

    double maxVal = 0;
    for (final d in last7) {
      maxVal = max(maxVal, _daily(d).toDouble());
    }
    final interval = _niceStep(maxVal);
    double maxY = (maxVal / interval).ceil() * interval;
    if (maxY <= maxVal) maxY += interval; // headroom so the top bar isn't clipped
    if (maxY <= 0) maxY = interval;

    final barGroups = <BarChartGroupData>[];
    final dateLabels = <String>[];
    for (int i = 0; i < last7.length; i++) {
      final daily = _daily(last7[i]).toDouble();
      final isLatest = i == last7.length - 1;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: daily,
              width: 22,
              color: isLatest ? _orange : _yellow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: _yellow.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      );
      final date = (last7[i].data() as Map<String, dynamic>)['date'] ?? '';
      dateLabels.add(date is String && date.length >= 5 ? date.substring(5) : '');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            barGroups: barGroups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: Color(0xFFEEE2C8),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= dateLabels.length) {
                      return const SizedBox();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        dateLabels[index],
                        style: const TextStyle(fontSize: 10, color: _brown),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  reservedSize: 38,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox();
                    return Text(
                      _axisLabel(value),
                      style: const TextStyle(fontSize: 10, color: _brown),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final daily = _daily(doc);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_walk_rounded,
                size: 20, color: _orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              data['date'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _brown,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${_comma(daily)} steps',
            style: const TextStyle(
              fontSize: 15,
              color: _brown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet month calendar that highlights days with step records.
class _ActiveDaysCalendar extends StatefulWidget {
  final Map<String, int> dateSteps; // key "YYYY-MM-DD" -> steps

  const _ActiveDaysCalendar({required this.dateSteps});

  @override
  State<_ActiveDaysCalendar> createState() => _ActiveDaysCalendarState();
}

class _ActiveDaysCalendarState extends State<_ActiveDaysCalendar> {
  static const Color _cream = Color(0xFFFFF6EB);
  static const Color _yellow = Color(0xFFF8D66D);
  static const Color _orange = Color(0xFFF77F42);
  static const Color _brown = Color(0xFF6B4F3A);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

  late DateTime _month; // first day of the visible month
  String? _selected;

  @override
  void initState() {
    super.initState();
    // Start on the month of the most recent active day, else this month.
    final keys = widget.dateSteps.keys.toList()..sort();
    final base = keys.isNotEmpty ? DateTime.tryParse(keys.last) : null;
    final now = base ?? DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  String _key(int y, int m, int d) =>
      '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday - 1;
    final today = DateTime.now();
    final activeThisMonth = widget.dateSteps.keys
        .where((k) => k.startsWith(
            '${_month.year}-${_month.month.toString().padLeft(2, '0')}'))
        .length;

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final key = _key(_month.year, _month.month, day);
      final isActive = widget.dateSteps.containsKey(key);
      final isToday = today.year == _month.year &&
          today.month == _month.month &&
          today.day == day;
      final isSelected = _selected == key;
      cells.add(_dayCell(day, key, isActive, isToday, isSelected));
    }

    return Container(
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _brown.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    size: 20, color: _orange),
                const SizedBox(width: 6),
                const Text(
                  'Active days',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _brown,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _brown),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: _brown),
                  onPressed: () => _shiftMonth(-1),
                ),
                Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _brown,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: _brown),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: _weekdays
                  .map((w) => Expanded(
                        child: Center(
                          child: Text(
                            w,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _brown.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: cells,
            ),
            const SizedBox(height: 12),
            _footer(activeThisMonth),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(
      int day, String key, bool isActive, bool isToday, bool isSelected) {
    final bg = isActive ? _orange : Colors.transparent;
    final textColor = isActive ? Colors.white : _brown;

    return GestureDetector(
      onTap: isActive ? () => setState(() => _selected = key) : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: _brown, width: 2)
              : (isToday && !isActive
                  ? Border.all(color: _orange, width: 1.5)
                  : null),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _footer(int activeThisMonth) {
    if (_selected != null) {
      final steps = widget.dateSteps[_selected] ?? 0;
      final s = steps.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_walk_rounded,
                size: 18, color: _orange),
            const SizedBox(width: 8),
            Text(
              _selected!,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: _brown, fontSize: 14),
            ),
            const Spacer(),
            Text(
              '$s steps',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: _brown, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
                color: _orange, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            activeThisMonth == 0
                ? 'No active days this month'
                : '$activeThisMonth active ${activeThisMonth == 1 ? 'day' : 'days'} this month · tap one',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _brown),
          ),
        ],
      ),
    );
  }
}
