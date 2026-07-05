/// All tunable numbers for the statistics feature live here, so the science
/// (stride length, calorie factor) can be adjusted in one place — and, later,
/// personalised per user (height / weight) without touching the UI or the
/// aggregation logic.
class StatsConfig {
  final int dailyGoal;

  /// Metres advanced per step. ~0.71 m is a common average adult stride.
  final double strideMeters;

  /// Kilocalories burned per step. ~0.04 kcal/step is a widely used
  /// approximation for an average adult at walking pace.
  final double kcalPerStep;

  /// Steps per minute assumed when estimating "active minutes" from a step
  /// count (~100 steps/min is the common brisk-walk cadence).
  final int stepsPerActiveMinute;

  const StatsConfig({
    this.dailyGoal = 8000,
    this.strideMeters = 0.71,
    this.kcalPerStep = 0.04,
    this.stepsPerActiveMinute = 100,
  });

  double distanceKm(int steps) => steps * strideMeters / 1000.0;
  double calories(int steps) => steps * kcalPerStep;
  int activeMinutes(int steps) => (steps / stepsPerActiveMinute).round();

  static const StatsConfig defaults = StatsConfig();
}
