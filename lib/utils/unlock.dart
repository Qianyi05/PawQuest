/// Pure helpers for the step-based unlock mechanic.
///
/// Kept free of Flutter/Firebase so the core game rule is trivially unit
/// testable.
class Unlock {
  const Unlock._();

  /// A milestone (city / food) is unlocked once [steps] reaches its
  /// [stepRequired] threshold.
  static bool isUnlocked(int steps, int stepRequired) => steps >= stepRequired;

  /// How many milestones are unlocked for the given [steps], from a list of
  /// step [thresholds].
  static int unlockedCount(int steps, Iterable<int> thresholds) =>
      thresholds.where((t) => steps >= t).length;
}
