// Time formatting helpers (pure Dart, S01). Local time in, strings out.

/// `1시간 28분` · `45분` · `2시간` · `0분`. Negative durations clamp to 0.
String formatDuration(Duration d) {
  final total = d.isNegative ? 0 : d.inMinutes;
  final h = total ~/ 60;
  final m = total % 60;
  if (h == 0) return '$m분';
  if (m == 0) return '$h시간';
  return '$h시간 $m분';
}

String _two(int v) => v.toString().padLeft(2, '0');

/// `19:32`
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// `19:32 – 21:03` (en dash, spaced).
String formatTimeRange(DateTime start, DateTime end) =>
    '${formatClock(start)} – ${formatClock(end)}';

/// Fractional hour of day (0.0 – 24.0) for ring placement.
double hourOfDay(DateTime t) =>
    t.hour + t.minute / 60 + t.second / 3600;
