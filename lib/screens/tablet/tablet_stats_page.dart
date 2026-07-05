import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../providers/step_provider.dart';
import '../../theme/app_palette.dart';
import '../../stats/daily_step.dart';
import '../../stats/stats_config.dart';
import '../../stats/stats_repository.dart';
import '../../stats/step_stats.dart';

/// A dedicated tablet screen that visualises the user's walking data, with the
/// kind of comprehensive breakdown found in Apple Health, Fitbit and Garmin
/// Connect — reframed for PawQuest (steps become a journey across Italy).
///
/// Drop this into `TabletDashboardScreen._pages` and add a matching
/// NavigationRail destination (see the integration note in the bundle).
class TabletStatsPage extends StatefulWidget {
  const TabletStatsPage({super.key, this.config = StatsConfig.defaults});

  final StatsConfig config;

  @override
  State<TabletStatsPage> createState() => _TabletStatsPageState();
}

class _TabletStatsPageState extends State<TabletStatsPage> {
  final _repo = StatsRepository();
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeProvider>().palette;
    final live = context.watch<StepProvider>();

    return Container(
      color: palette.background,
      child: SafeArea(
        child: StreamBuilder<List<DailyStep>>(
          stream: _repo.watch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: palette.primary));
            }
            final history = snapshot.data ?? const <DailyStep>[];
            final stats = StepStats.compute(
              history,
              range: _range,
              config: widget.config,
            );
            return _buildDashboard(context, palette, stats, live);
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AppPalette p, StepStats s,
      StepProvider live) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final todaySteps = live.todaySteps;
      final lifetime = live.steps > s.lifetimeTotal ? live.steps : s.lifetimeTotal;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(p),
            const SizedBox(height: 18),
            _kpiRow(p, s),
            const SizedBox(height: 14),
            _row(wide, [
              _Flex(3, _card(p, 'Steps per ${_bucketNoun()}',
                  height: 260, child: _StepsBarChart(palette: p, stats: s))),
              _Flex(2, _card(p, "Today's goal",
                  height: 260,
                  child: _GoalRing(palette: p, steps: todaySteps, goal: s.config.dailyGoal, streak: s.currentStreak))),
            ]),
            const SizedBox(height: 14),
            _row(wide, [
              _Flex(1, _card(p, 'Weekly pattern',
                  subtitle: 'average by day of week',
                  height: 200,
                  child: _WeekdayBars(palette: p, averages: s.weekdayAverages, peak: s.weekdayPeakIndex))),
              _Flex(1, _card(p, 'Goal achievement',
                  subtitle: 'days goal met in range',
                  height: 200,
                  child: _GoalDonut(palette: p, met: s.goalMetDays, total: s.rangeDays))),
            ]),
            const SizedBox(height: 14),
            _card(p, 'Activity calendar',
                subtitle: 'last 5 weeks — darker means more steps',
                child: _Heatmap(palette: p, cells: s.heatmap)),
            const SizedBox(height: 14),
            _row(wide, [
              _Flex(1, _card(p, 'Records',
                  child: _RecordsCard(palette: p, stats: s, lifetime: lifetime))),
              _Flex(1, _card(p, 'Insights',
                  child: _InsightsCard(palette: p, stats: s))),
            ]),
            const SizedBox(height: 14),
            _JourneyCard(palette: p, lifetime: lifetime, config: s.config,
                dailyAverage: s.dailyAverage),
          ],
        ),
      );
    });
  }

  String _bucketNoun() => switch (_range) {
        StatsRange.week => 'day',
        StatsRange.month => 'day',
        StatsRange.sixMonth => 'week',
        StatsRange.year => 'month',
      };

  // ---- header + range selector -----------------------------------------
  Widget _header(AppPalette p) {
    return Row(
      children: [
        Icon(Icons.insights_rounded, color: p.primary, size: 26),
        const SizedBox(width: 10),
        Text('Step statistics',
            style: TextStyle(
                color: p.text, fontSize: 22, fontWeight: FontWeight.w800)),
        const Spacer(),
        _SegmentedRange(
          palette: p,
          value: _range,
          onChanged: (r) => setState(() => _range = r),
        ),
      ],
    );
  }

  Widget _kpiRow(AppPalette p, StepStats s) {
    final tiles = [
      _StatTile(p, 'Total ${s.range.label.toLowerCase()}', _fmt(s.total),
          delta: s.deltaPercent),
      _StatTile(p, 'Daily average', _fmt(s.dailyAverage.round()),
          sub: 'goal ${_fmt(s.config.dailyGoal)}'),
      _StatTile(p, 'Distance', '${s.distanceKm.toStringAsFixed(1)} km',
          sub: '${s.config.strideMeters} m / step'),
      _StatTile(p, 'Active energy', '${_fmt(s.calories.round())} kcal',
          sub: '${s.activeMinutes} active min'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final t in tiles) SizedBox(width: 210, child: t)],
    );
  }

  // ---- tiny layout helpers ---------------------------------------------
  Widget _row(bool wide, List<_Flex> children) {
    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i].child,
            if (i != children.length - 1) const SizedBox(height: 14),
          ]
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(flex: children[i].flex, child: children[i].child),
            if (i != children.length - 1) const SizedBox(width: 14),
          ]
        ],
      ),
    );
  }

  Widget _card(AppPalette p, String title,
      {String? subtitle, double? height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: p.text.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Text(title,
              style: TextStyle(
                  color: p.text, fontSize: 15, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(color: p.textMuted, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          // Fixed-height cards let the chart fill; auto-height cards size to
          // their content (safe inside the scroll view).
          height == null ? child : Expanded(child: child),
        ],
      ),
    );
  }
}

class _Flex {
  final int flex;
  final Widget child;
  _Flex(this.flex, this.child);
}

// =====================================================================
//  Range selector
// =====================================================================
class _SegmentedRange extends StatelessWidget {
  const _SegmentedRange(
      {required this.palette, required this.value, required this.onChanged});
  final AppPalette palette;
  final StatsRange value;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.textMuted.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in StatsRange.values)
            GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: r == value ? palette.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  r.label,
                  style: TextStyle(
                    color: r == value ? Colors.white : palette.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================================
//  KPI stat tile
// =====================================================================
class _StatTile extends StatelessWidget {
  const _StatTile(this.p, this.label, this.value, {this.sub, this.delta});
  final AppPalette p;
  final String label;
  final String value;
  final String? sub;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: p.text.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: p.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: p.text, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (delta != null)
            Row(children: [
              Icon(delta! >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 15,
                  color: delta! >= 0 ? const Color(0xFF639922) : p.danger),
              const SizedBox(width: 4),
              Text('${delta! >= 0 ? '+' : ''}${delta!.toStringAsFixed(0)}% vs last',
                  style: TextStyle(
                      color: delta! >= 0 ? const Color(0xFF639922) : p.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ])
          else if (sub != null)
            Text(sub!, style: TextStyle(color: p.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// =====================================================================
//  Main steps bar chart (with dashed average line)
// =====================================================================
class _StepsBarChart extends StatelessWidget {
  const _StepsBarChart({required this.palette, required this.stats});
  final AppPalette palette;
  final StepStats stats;

  @override
  Widget build(BuildContext context) {
    final buckets = stats.buckets;
    if (buckets.isEmpty) return _empty(palette);
    final maxSteps =
        buckets.map((b) => b.steps).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxSteps <= 0 ? stats.config.dailyGoal : maxSteps) * 1.2;
    final avg = buckets.map((b) => b.steps).fold<int>(0, (a, b) => a + b) /
        buckets.length;
    final labelEvery = (buckets.length / 8).ceil().clamp(1, 999);
    final barWidth = (buckets.length > 20) ? 6.0 : 14.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => palette.text,
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              _fmt(rod.toY.round()),
              TextStyle(
                  color: palette.surface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
              color: palette.textMuted.withValues(alpha: 0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(_short(value.round()),
                    style: TextStyle(color: palette.textMuted, fontSize: 10));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                if (i % labelEvery != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(buckets[i].label,
                      style:
                          TextStyle(color: palette.textMuted, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: avg,
            color: palette.primary,
            strokeWidth: 2,
            dashArray: [6, 4],
          ),
        ]),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: buckets[i].steps.toDouble(),
                color: palette.primary,
                width: barWidth,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]),
        ],
      ),
    );
  }
}

// =====================================================================
//  Goal ring (today)
// =====================================================================
class _GoalRing extends StatelessWidget {
  const _GoalRing(
      {required this.palette,
      required this.steps,
      required this.goal,
      required this.streak});
  final AppPalette palette;
  final int steps;
  final int goal;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final ratio = goal == 0 ? 0.0 : (steps / goal).clamp(0.0, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: ratio,
                      strokeWidth: 12,
                      backgroundColor:
                          palette.textMuted.withValues(alpha: 0.15),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(palette.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(ratio * 100).round()}%',
                          style: TextStyle(
                              color: palette.text,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                      Text('${_fmt(steps)} / ${_fmt(goal)}',
                          style: TextStyle(
                              color: palette.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department_rounded,
                size: 18, color: palette.accent),
            const SizedBox(width: 4),
            Text('$streak-day streak',
                style: TextStyle(
                    color: palette.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

// =====================================================================
//  Weekday pattern
// =====================================================================
class _WeekdayBars extends StatelessWidget {
  const _WeekdayBars(
      {required this.palette, required this.averages, required this.peak});
  final AppPalette palette;
  final List<double> averages;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final maxV = averages.fold<double>(1, (a, b) => a > b ? a : b);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Text(_short(averages[i].round()),
                      style:
                          TextStyle(color: palette.textMuted, fontSize: 9)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (averages[i] / maxV).clamp(0.02, 1.0),
                        widthFactor: 0.6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: i == peak
                                ? palette.primary
                                : palette.accent.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(labels[i],
                      style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// =====================================================================
//  Goal-met donut
// =====================================================================
class _GoalDonut extends StatelessWidget {
  const _GoalDonut(
      {required this.palette, required this.met, required this.total});
  final AppPalette palette;
  final int met;
  final int total;

  @override
  Widget build(BuildContext context) {
    final missed = (total - met).clamp(0, total);
    final rate = total == 0 ? 0.0 : met / total;
    return Row(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(PieChartData(
                startDegreeOffset: -90,
                sectionsSpace: 0,
                centerSpaceRadius: 34,
                sections: [
                  PieChartSectionData(
                      value: met.toDouble(),
                      color: const Color(0xFF639922),
                      radius: 16,
                      showTitle: false),
                  PieChartSectionData(
                      value: missed.toDouble() == 0 && met == 0
                          ? 1
                          : missed.toDouble(),
                      color: palette.textMuted.withValues(alpha: 0.18),
                      radius: 16,
                      showTitle: false),
                ],
              )),
              Text('${(rate * 100).round()}%',
                  style: TextStyle(
                      color: palette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(palette, const Color(0xFF639922), '$met days met'),
              const SizedBox(height: 8),
              _legendDot(palette, palette.textMuted.withValues(alpha: 0.3),
                  '$missed days missed'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(AppPalette p, Color c, String label) {
    return Row(children: [
      Container(
          width: 11,
          height: 11,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: p.text, fontSize: 13)),
    ]);
  }
}

// =====================================================================
//  Activity heatmap (5 weeks x 7 days)
// =====================================================================
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.palette, required this.cells});
  final AppPalette palette;
  final List<HeatCell> cells;

  @override
  Widget build(BuildContext context) {
    // cells are oldest..newest (35). Lay out as 5 columns (weeks) x 7 rows.
    const weekdayLabels = ['Mon', '', 'Wed', '', 'Fri', '', 'Sun'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final l in weekdayLabels)
              SizedBox(
                height: 26,
                child: Text(l,
                    style:
                        TextStyle(color: palette.textMuted, fontSize: 9)),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              for (var w = 0; w < 5; w++)
                Expanded(
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Builder(builder: (_) {
                          final idx = w * 7 + d;
                          final cell = idx < cells.length ? cells[idx] : null;
                          return Container(
                            height: 22,
                            margin: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: _color(palette, cell?.level ?? 0),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _color(AppPalette p, int level) {
    if (level <= 0) return p.textMuted.withValues(alpha: 0.10);
    // tint the palette primary by intensity
    return p.primary.withValues(alpha: [0.0, 0.25, 0.45, 0.7, 1.0][level.clamp(0, 4)]);
  }
}

// =====================================================================
//  Records
// =====================================================================
class _RecordsCard extends StatelessWidget {
  const _RecordsCard(
      {required this.palette, required this.stats, required this.lifetime});
  final AppPalette palette;
  final StepStats stats;
  final int lifetime;

  @override
  Widget build(BuildContext context) {
    final best = stats.bestDay;
    final rows = <(IconData, String, String)>[
      (
        Icons.emoji_events_rounded,
        'Best day',
        best == null ? '—' : '${_fmt(best.steps)} · ${_weekday(best.date)}'
      ),
      (Icons.calendar_month_rounded, 'Best week', _fmt(stats.bestWeek)),
      (Icons.local_fire_department_rounded, 'Longest streak',
          '${stats.longestStreak} days'),
      (Icons.directions_walk_rounded, 'Lifetime', '${_fmt(lifetime)} steps'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(r.$1, size: 18, color: palette.accent),
                const SizedBox(width: 10),
                Text(r.$2,
                    style: TextStyle(color: palette.textMuted, fontSize: 13)),
                const Spacer(),
                Text(r.$3,
                    style: TextStyle(
                        color: palette.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
      ],
    );
  }

  String _weekday(DateTime d) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
}

// =====================================================================
//  Insights (auto-generated text)
// =====================================================================
class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.palette, required this.stats});
  final AppPalette palette;
  final StepStats stats;

  @override
  Widget build(BuildContext context) {
    final insights = <(IconData, Color, String)>[];

    if (stats.deltaPercent != null) {
      final up = stats.deltaPercent! >= 0;
      insights.add((
        up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        up ? const Color(0xFF639922) : palette.danger,
        '${up ? 'Up' : 'Down'} ${stats.deltaPercent!.abs().toStringAsFixed(0)}% vs the previous ${stats.range.label.toLowerCase()}.'
      ));
    }
    const wd = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    insights.add((
      Icons.calendar_today_rounded,
      palette.primary,
      'You move most on ${wd[stats.weekdayPeakIndex]}s.'
    ));
    final toAvg = stats.dailyAverage.round();
    insights.add((
      Icons.flag_rounded,
      palette.accent,
      stats.currentStreak > 0
          ? '${stats.currentStreak}-day goal streak — keep it going!'
          : 'Hit ${_fmt(stats.config.dailyGoal)} today to start a new streak.'
    ));
    insights.add((
      Icons.map_rounded,
      palette.primary,
      'Averaging ${_fmt(toAvg)} steps/day.'
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ins in insights.take(3))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ins.$2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(ins.$1, size: 17, color: ins.$2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ins.$3,
                      style: TextStyle(
                          color: palette.text,
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =====================================================================
//  Journey card (PawQuest hook)
// =====================================================================
class _JourneyCard extends StatelessWidget {
  const _JourneyCard(
      {required this.palette,
      required this.lifetime,
      required this.config,
      required this.dailyAverage});
  final AppPalette palette;
  final int lifetime;
  final StatsConfig config;
  final double dailyAverage;

  @override
  Widget build(BuildContext context) {
    final km = config.distanceKm(lifetime);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.place_rounded, color: palette.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(color: palette.text, fontSize: 14, height: 1.4),
                children: [
                  const TextSpan(
                      text: 'Your journey: ',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                      text:
                          "you've walked ${km.toStringAsFixed(1)} km. "),
                  TextSpan(
                    text: 'Keep exploring Italy — every step unlocks more.',
                    style: TextStyle(color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  helpers
// =====================================================================
Widget _empty(AppPalette p) => Center(
      child: Text('No step data yet',
          style: TextStyle(color: p.textMuted, fontSize: 13)),
    );

/// Thousands separator without pulling in `intl`.
String _fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Compact axis label: 8000 -> 8k.
String _short(int n) {
  if (n >= 1000) {
    final k = n / 1000;
    return '${k % 1 == 0 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}k';
  }
  return n.toString();
}
