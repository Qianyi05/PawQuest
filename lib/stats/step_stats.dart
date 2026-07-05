import 'daily_step.dart';
import 'stats_config.dart';

/// The time window the dashboard is showing.
enum StatsRange { week, month, sixMonth, year }

extension StatsRangeX on StatsRange {
  String get label => switch (this) {
        StatsRange.week => 'Week',
        StatsRange.month => 'Month',
        StatsRange.sixMonth => '6 Months',
        StatsRange.year => 'Year',
      };

  /// Number of days the range spans (used to slice history and to find the
  /// preceding period for the trend comparison).
  int get days => switch (this) {
        StatsRange.week => 7,
        StatsRange.month => 30,
        StatsRange.sixMonth => 182,
        StatsRange.year => 365,
      };
}

/// One bar in the main chart. For week/month this is a single day; for
/// 6-months it is a week; for year it is a month.
class StepBucket {
  final DateTime start;
  final String label;
  final int steps;
  const StepBucket({required this.start, required this.label, required this.steps});
}

/// A fully-computed, ready-to-render snapshot of the user's step statistics.
/// Everything here is derived deterministically from the daily history, so it
/// can be unit-tested without Flutter or Firebase (NFR5).
class StepStats {
  final StatsRange range;
  final StatsConfig config;

  final List<StepBucket> buckets; // main chart
  final int total; // steps in range
  final double dailyAverage; // over the days in range
  final double? deltaPercent; // vs the previous equal-length period (null if no data)

  final double distanceKm;
  final double calories;
  final int activeMinutes;

  final int goalMetDays; // days in range that reached the goal
  final int rangeDays; // days in range that have data
  final int currentStreak; // consecutive goal-met days ending today
  final int longestStreak; // best consecutive goal-met run ever seen

  final DailyStep? bestDay; // highest single day (all history)
  final int bestWeek; // highest 7-day rolling sum (all history)
  final int lifetimeTotal; // sum of all daily steps loaded

  final List<double> weekdayAverages; // index 0=Mon .. 6=Sun
  final List<HeatCell> heatmap; // most recent 35 days for the calendar

  const StepStats({
    required this.range,
    required this.config,
    required this.buckets,
    required this.total,
    required this.dailyAverage,
    required this.deltaPercent,
    required this.distanceKm,
    required this.calories,
    required this.activeMinutes,
    required this.goalMetDays,
    required this.rangeDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.bestDay,
    required this.bestWeek,
    required this.lifetimeTotal,
    required this.weekdayAverages,
    required this.heatmap,
  });

  double get goalRate => rangeDays == 0 ? 0 : goalMetDays / rangeDays;
  int get weekdayPeakIndex {
    var peak = 0;
    for (var i = 1; i < weekdayAverages.length; i++) {
      if (weekdayAverages[i] > weekdayAverages[peak]) peak = i;
    }
    return peak;
  }

  /// Build the statistics from raw history. [history] may be in any order and
  /// may contain gaps; [now] is injectable for testing.
  static StepStats compute(
    List<DailyStep> history, {
    required StatsRange range,
    StatsConfig config = StatsConfig.defaults,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());

    // Index by day for O(1) lookups and de-duplication.
    final byDay = <DateTime, int>{};
    for (final d in history) {
      final k = _dateOnly(d.date);
      byDay[k] = d.steps; // last write wins on duplicates
    }
    int stepsOn(DateTime day) => byDay[_dateOnly(day)] ?? 0;

    // ---- range slice & buckets ------------------------------------------
    final rangeStart = today.subtract(Duration(days: range.days - 1));
    final buckets = _buildBuckets(range, today, stepsOn);

    var total = 0;
    var goalMet = 0;
    var withData = 0;
    for (var i = 0; i < range.days; i++) {
      final day = rangeStart.add(Duration(days: i));
      final s = stepsOn(day);
      total += s;
      if (byDay.containsKey(_dateOnly(day))) withData++;
      if (s >= config.dailyGoal) goalMet++;
    }
    final dailyAverage = total / range.days;

    // ---- trend vs previous equal-length period --------------------------
    var prevTotal = 0;
    for (var i = 0; i < range.days; i++) {
      final day = rangeStart.subtract(Duration(days: range.days - i));
      prevTotal += stepsOn(day);
    }
    final double? delta =
        prevTotal == 0 ? null : (total - prevTotal) / prevTotal * 100.0;

    // ---- streaks (over all history up to today) -------------------------
    var current = 0;
    for (var i = 0;; i++) {
      final day = today.subtract(Duration(days: i));
      if (stepsOn(day) >= config.dailyGoal) {
        current++;
      } else {
        break;
      }
      if (i > 3650) break; // safety
    }
    var longest = 0, run = 0;
    final sortedDays = byDay.keys.toList()..sort();
    DateTime? prev;
    for (final day in sortedDays) {
      if (byDay[day]! < config.dailyGoal) {
        run = 0;
        prev = day;
        continue;
      }
      if (prev != null && day.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
      prev = day;
    }

    // ---- records --------------------------------------------------------
    DailyStep? best;
    for (final d in history) {
      if (best == null || d.steps > best.steps) best = d;
    }
    var bestWeek = 0;
    if (sortedDays.isNotEmpty) {
      for (final anchor in sortedDays) {
        var sum = 0;
        for (var i = 0; i < 7; i++) {
          sum += byDay[_dateOnly(anchor.add(Duration(days: i)))] ?? 0;
        }
        if (sum > bestWeek) bestWeek = sum;
      }
    }
    final lifetime = byDay.values.fold<int>(0, (a, b) => a + b);

    // ---- weekday pattern (Mon..Sun) over loaded history -----------------
    final wSum = List<int>.filled(7, 0);
    final wCount = List<int>.filled(7, 0);
    byDay.forEach((day, steps) {
      final idx = day.weekday - 1; // DateTime.monday == 1
      wSum[idx] += steps;
      wCount[idx] += 1;
    });
    final weekdayAvg = List<double>.generate(
        7, (i) => wCount[i] == 0 ? 0 : wSum[i] / wCount[i]);

    // ---- heatmap: most recent 35 days -----------------------------------
    final heat = <HeatCell>[];
    for (var i = 34; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      heat.add(HeatCell(
          date: day,
          steps: stepsOn(day),
          level: _level(stepsOn(day), config.dailyGoal)));
    }

    return StepStats(
      range: range,
      config: config,
      buckets: buckets,
      total: total,
      dailyAverage: dailyAverage,
      deltaPercent: delta,
      distanceKm: config.distanceKm(total),
      calories: config.calories(total),
      activeMinutes: config.activeMinutes(total),
      goalMetDays: goalMet,
      rangeDays: withData,
      currentStreak: current,
      longestStreak: longest,
      bestDay: best,
      bestWeek: bestWeek,
      lifetimeTotal: lifetime,
      weekdayAverages: weekdayAvg,
      heatmap: heat,
    );
  }

  // -- bucket builders ----------------------------------------------------
  static List<StepBucket> _buildBuckets(
      StatsRange range, DateTime today, int Function(DateTime) stepsOn) {
    switch (range) {
      case StatsRange.week:
        return _daily(7, today, stepsOn, _weekdayShort);
      case StatsRange.month:
        return _daily(30, today, stepsOn, (d) => d.day.toString());
      case StatsRange.sixMonth:
        // 26 weekly buckets
        final out = <StepBucket>[];
        for (var w = 25; w >= 0; w--) {
          final start = today.subtract(Duration(days: w * 7 + today.weekday - 1));
          var sum = 0;
          for (var i = 0; i < 7; i++) {
            sum += stepsOn(start.add(Duration(days: i)));
          }
          out.add(StepBucket(start: start, label: '${start.day}/${start.month}', steps: sum));
        }
        return out;
      case StatsRange.year:
        final out = <StepBucket>[];
        for (var m = 11; m >= 0; m--) {
          final month = DateTime(today.year, today.month - m, 1);
          var sum = 0;
          final next = DateTime(month.year, month.month + 1, 1);
          var day = month;
          while (day.isBefore(next)) {
            sum += stepsOn(day);
            day = day.add(const Duration(days: 1));
          }
          out.add(StepBucket(start: month, label: _monthShort(month.month), steps: sum));
        }
        return out;
    }
  }

  static List<StepBucket> _daily(int n, DateTime today,
      int Function(DateTime) stepsOn, String Function(DateTime) label) {
    final out = <StepBucket>[];
    for (var i = n - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      out.add(StepBucket(start: day, label: label(day), steps: stepsOn(day)));
    }
    return out;
  }

  static int _level(int steps, int goal) {
    if (steps <= 0) return 0;
    final r = steps / goal;
    if (r < 0.25) return 1;
    if (r < 0.5) return 2;
    if (r < 1.0) return 3;
    return 4;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _weekdayShort(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
  static String _monthShort(int m) =>
      const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][((m - 1) % 12) + 1];
}

/// One cell of the activity calendar heatmap.
class HeatCell {
  final DateTime date;
  final int steps;
  final int level; // 0..4 intensity bucket
  const HeatCell({required this.date, required this.steps, required this.level});
}
