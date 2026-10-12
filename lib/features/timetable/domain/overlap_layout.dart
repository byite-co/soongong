// Side-by-side interval layout, adapted from flutter_calendar_view's
// SideEventArranger approach. Copyright (c) 2021 Simform Solutions.
// MIT notice and pinned source: third_party/flutter_calendar_view/.
// This is presentation geometry only; it never changes recorded study time.

import 'dart:math' as math;

class TimetableInterval {
  const TimetableInterval(this.startMinutes, this.endMinutes);

  final double startMinutes;
  final double endMinutes;
}

class TimetablePlacement {
  const TimetablePlacement({
    required this.topFraction,
    required this.heightFraction,
    required this.column,
    required this.columns,
  });

  final double topFraction;
  final double heightFraction;
  final int column;
  final int columns;
  double get leftFraction => column / columns;
  double get widthFraction => 1 / columns;
}

/// Returns one placement per input, in the original order. Touching edges may
/// reuse a column. Overlap is evaluated AFTER minimum height / day-end clamping
/// so two short sessions near midnight cannot cover one another on screen.
List<TimetablePlacement> layoutTimetableIntervals(
  List<TimetableInterval> intervals, {
  double minHeightFraction = 0.02,
}) {
  if (!minHeightFraction.isFinite || minHeightFraction < 0 || minHeightFraction > 1) {
    throw ArgumentError.value(minHeightFraction, 'minHeightFraction');
  }
  final boxes = <_Box>[];
  for (final (index, interval) in intervals.indexed) {
    if (!interval.startMinutes.isFinite || !interval.endMinutes.isFinite ||
        interval.endMinutes <= interval.startMinutes) {
      throw ArgumentError('Timetable intervals must have finite, increasing endpoints');
    }
    final start = (interval.startMinutes / 1440).clamp(0.0, 1.0);
    final end = (interval.endMinutes / 1440).clamp(0.0, 1.0);
    final height = math.max(end - start, minHeightFraction);
    final top = math.min(start, 1.0 - height);
    boxes.add(_Box(index, top, height));
  }
  boxes.sort((a, b) {
    final byTop = a.top.compareTo(b.top);
    if (byTop != 0) return byTop;
    final byHeight = b.height.compareTo(a.height);
    return byHeight != 0 ? byHeight : a.index.compareTo(b.index);
  });

  final result = List<TimetablePlacement?>.filled(intervals.length, null);
  final group = <_Box>[];
  final columnEnds = <double>[];
  var groupEnd = -1.0;
  void flush() {
    for (final box in group) {
      result[box.index] = TimetablePlacement(
        topFraction: box.top,
        heightFraction: box.height,
        column: box.column,
        columns: columnEnds.length,
      );
    }
    group.clear();
    columnEnds.clear();
  }

  for (final box in boxes) {
    if (group.isNotEmpty && box.top >= groupEnd) flush();
    var column = columnEnds.indexWhere((end) => end <= box.top);
    if (column < 0) {
      column = columnEnds.length;
      columnEnds.add(box.bottom);
    } else {
      columnEnds[column] = box.bottom;
    }
    box.column = column;
    group.add(box);
    groupEnd = group.length == 1 ? box.bottom : math.max(groupEnd, box.bottom);
  }
  flush();
  return List<TimetablePlacement>.unmodifiable(result.map((p) => p!));
}

class _Box {
  _Box(this.index, this.top, this.height);
  final int index;
  final double top;
  final double height;
  int column = 0;
  double get bottom => top + height;
}
