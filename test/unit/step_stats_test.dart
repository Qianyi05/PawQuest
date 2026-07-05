import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/stats/daily_step.dart';
import 'package:pawquest/stats/stats_config.dart';
import 'package:pawquest/stats/step_stats.dart';

// (the `name:` field) if it differs.

void main() {
  // Fixed "now" so the tests are deterministic. A Wednesday.
  final now = DateTime(2026, 7, 1, 12);
  const config = StatsConfig(dailyGoal: 8000);

  DailyStep day(int daysAgo, int steps) =>
      DailyStep(date: DateTime(2026, 7, 1).subtract(Duration(days: daysAgo)), steps: steps);

  group('StepStats.compute — week range', () {
    test('totals and daily average over 7 days', () {
      final history = [
        day(0, 8000),
        day(1, 6000),
        day(2, 10000),
        day(3, 0),
        day(4, 4000),
        day(5, 8000),
        day(6, 6000),
      ];
      final s = StepStats.compute(history, range: StatsRange.week, config: config, now: now);

      expect(s.total, 42000);
      expect(s.dailyAverage, closeTo(6000, 0.001));
      expect(s.buckets.length, 7);
      // goal met on the three 8000+ days
      expect(s.goalMetDays, 3);
    });

    test('missing days count as zero and never crash', () {
      final s = StepStats.compute([day(0, 5000)],
          range: StatsRange.week, config: config, now: now);
      expect(s.total, 5000);
      expect(s.goalMetDays, 0);
      expect(s.rangeDays, 1); // only one day had data
    });
  });

  group('derived metrics', () {
    test('distance and calories scale with steps', () {
      final s = StepStats.compute([day(0, 10000)],
          range: StatsRange.week, config: config, now: now);
      expect(s.distanceKm, closeTo(10000 * 0.71 / 1000, 0.001)); // 7.1 km
      expect(s.calories, closeTo(10000 * 0.04, 0.001)); // 400 kcal
      expect(s.activeMinutes, 100); // 10000 / 100
    });
  });

  group('streaks', () {
    test('current streak counts consecutive goal-met days ending today', () {
      final history = [day(0, 9000), day(1, 8500), day(2, 8000), day(3, 3000)];
      final s = StepStats.compute(history, range: StatsRange.week, config: config, now: now);
      expect(s.currentStreak, 3);
    });

    test('streak breaks when today is below goal', () {
      final history = [day(0, 100), day(1, 9000), day(2, 9000)];
      final s = StepStats.compute(history, range: StatsRange.week, config: config, now: now);
      expect(s.currentStreak, 0);
    });

    test('longest streak found across history', () {
      final history = [
        day(6, 9000), day(5, 9000), day(4, 9000), day(3, 9000), // 4 in a row
        day(2, 100),
        day(1, 9000), day(0, 9000), // 2 in a row
      ];
      final s = StepStats.compute(history, range: StatsRange.week, config: config, now: now);
      expect(s.longestStreak, 4);
    });
  });

  group('trend vs previous period', () {
    test('positive delta when this week beats last week', () {
      final history = <DailyStep>[];
      for (var i = 0; i < 7; i++) {
        history.add(day(i, 10000)); // this week: 70000
      }
      for (var i = 7; i < 14; i++) {
        history.add(day(i, 5000)); // last week: 35000
      }
      final s = StepStats.compute(history, range: StatsRange.week, config: config, now: now);
      expect(s.deltaPercent, closeTo(100, 0.001)); // doubled
    });

    test('null delta when there is no previous data', () {
      final s = StepStats.compute([day(0, 5000)],
          range: StatsRange.week, config: config, now: now);
      expect(s.deltaPercent, isNull);
    });
  });

  group('records & weekday pattern', () {
    test('best day is the single highest day', () {
      final history = [day(0, 5000), day(3, 14000), day(5, 9000)];
      final s = StepStats.compute(history, range: StatsRange.month, config: config, now: now);
      expect(s.bestDay?.steps, 14000);
    });

    test('weekday averages have 7 entries (Mon..Sun)', () {
      final s = StepStats.compute([day(0, 8000)],
          range: StatsRange.week, config: config, now: now);
      expect(s.weekdayAverages.length, 7);
    });

    test('heatmap always has 35 cells', () {
      final s = StepStats.compute([day(0, 8000)],
          range: StatsRange.week, config: config, now: now);
      expect(s.heatmap.length, 35);
    });
  });
}
