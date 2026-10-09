// DensityScale (S07, pure Dart): maps a day's 순공 seconds to one of four
// shade levels (PRD 4.2 "셀 배경 농도 = 순공 시간"). The reference is the
// top-10% boundary of the user's own daily totals over the last 60 days, so
// the scale follows the student's record rather than a fixed number.
// Levels are shades only — never a grade (CLAUDE.md §1).

class DensityScale {
  const DensityScale({required this.referenceSeconds});

  /// Days considered when computing the reference.
  static const int windowDays = 60;

  /// Share of the highest days that defines the reference boundary.
  static const double topShare = 0.10;

  static const int levels = 4;

  static const DensityScale none = DensityScale(referenceSeconds: 0);

  /// Seconds at the top-10% boundary; 0 when there is no positive day.
  final int referenceSeconds;

  /// [dailySeconds] = 순공 seconds of each day in the window (zeros allowed).
  /// The reference is the smallest value that still belongs to the top 10%
  /// of the positive days (the 90th percentile by rank).
  factory DensityScale.fromDaily(Iterable<int> dailySeconds) {
    final positive = dailySeconds.where((s) => s > 0).toList()..sort();
    if (positive.isEmpty) return none;
    final n = positive.length;
    // Rank of the boundary: ceil(n × 0.9), 1-based, clamped to [1, n].
    var rank = (n * (1 - topShare)).ceil();
    if (rank < 1) rank = 1;
    if (rank > n) rank = n;
    return DensityScale(referenceSeconds: positive[rank - 1]);
  }

  /// 0 = no 순공 that day · 1..4 = share of the reference in quarters,
  /// capped at 4 for days above the reference.
  int levelOf(int seconds) {
    if (seconds <= 0 || referenceSeconds <= 0) return 0;
    final ratio = seconds / referenceSeconds;
    final level = (ratio * levels).ceil();
    if (level < 1) return 1;
    return level > levels ? levels : level;
  }

  /// 0.0..1.0 share of the reference (capped), for column heights.
  double ratioOf(int seconds) {
    if (seconds <= 0 || referenceSeconds <= 0) return 0;
    final r = seconds / referenceSeconds;
    return r > 1 ? 1 : r;
  }
}
