// SensitivityPolicy (S02, pure Dart). Corrections in the last 2 weeks →
// sensitivity level 0–2 (PRD 4.1: every 3 accumulated corrections relax the
// away detection, with a toast). Level → threshold is in [AwayPolicy].

class SensitivityAdjustment {
  const SensitivityAdjustment({
    required this.level,
    required this.previousLevel,
    required this.recentCorrections,
  });

  final int level;
  final int previousLevel;
  final int recentCorrections;

  /// A toast is shown only when the level actually changed.
  bool get changed => level != previousLevel;
}

class SensitivityPolicy {
  const SensitivityPolicy();

  static const Duration window = Duration(days: 14);
  static const int correctionsPerStep = 3;
  static const int maxLevel = 2;

  /// Level for a number of corrections inside [window].
  static int levelFor(int recentCorrections) {
    final l = recentCorrections ~/ correctionsPerStep;
    return l > maxLevel ? maxLevel : l;
  }

  /// Corrections with `at` inside the last 2 weeks (inclusive of [now]).
  static int countRecent(Iterable<DateTime> correctionsAt, DateTime now) {
    final floor = now.subtract(window);
    return correctionsAt.where((t) => !t.isBefore(floor) && !t.isAfter(now)).length;
  }

  /// [auto] off → the user's manual level is kept (no toast).
  SensitivityAdjustment evaluate({
    required int currentLevel,
    required Iterable<DateTime> correctionsAt,
    required DateTime now,
    bool auto = true,
  }) {
    final recent = countRecent(correctionsAt, now);
    final level = auto ? levelFor(recent) : currentLevel;
    return SensitivityAdjustment(
      level: level,
      previousLevel: currentLevel,
      recentCorrections: recent,
    );
  }
}
