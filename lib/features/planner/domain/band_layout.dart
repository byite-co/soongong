// BandLayout (S07, pure Dart): places 기간 띠 (multi-day events) on the month
// grid. A band is split per grid row; lanes are assigned once per band so a
// band keeps its lane across rows. At most [maxLanes] lanes are drawn; the
// rest is counted per day as an overflow ("+N").

import '../../../core/domain/entities/planner.dart';
import '../../../core/domain/local_date.dart';
import 'month_grid.dart';

class BandSpan {
  const BandSpan({
    required this.item,
    required this.row,
    required this.colStart,
    required this.colEnd,
    required this.lane,
    required this.continuesBefore,
    required this.continuesAfter,
  });

  final PlannerItem item;
  final int row;

  /// Inclusive columns.
  final int colStart;
  final int colEnd;
  final int lane;

  /// The band starts before / ends after this row (or the grid).
  final bool continuesBefore;
  final bool continuesAfter;

  int get length => colEnd - colStart + 1;
}

class BandLayout {
  const BandLayout._({
    required this.spans,
    required this.hiddenPerDay,
    required this.lanesPerDay,
  });

  static const int maxLanes = 2;

  static const BandLayout empty = BandLayout._(
    spans: <BandSpan>[],
    hiddenPerDay: <LocalDate, int>{},
    lanesPerDay: <LocalDate, int>{},
  );

  /// Visible spans (lane < [maxLanes]).
  final List<BandSpan> spans;

  /// Bands covering a day that did not get a visible lane.
  final Map<LocalDate, int> hiddenPerDay;

  /// Number of visible lanes occupied on a day (0..maxLanes) — the cell's
  /// item list starts below them.
  final Map<LocalDate, int> lanesPerDay;

  int hiddenOn(LocalDate d) => hiddenPerDay[d] ?? 0;
  int lanesOn(LocalDate d) => lanesPerDay[d] ?? 0;

  /// [bands] = items with `isBand` (any order). Bands outside the grid are
  /// ignored; partially overlapping ones are clipped.
  factory BandLayout.compute(Iterable<PlannerItem> bands, MonthGrid grid) {
    final list = bands.where((b) => b.isBand).toList()
      ..sort((a, b) {
        final c = a.bandStart!.compareTo(b.bandStart!);
        if (c != 0) return c;
        final la = a.bandStart!.daysUntil(a.bandEnd!);
        final lb = b.bandStart!.daysUntil(b.bandEnd!);
        if (la != lb) return lb.compareTo(la); // longer first
        final t = a.title.compareTo(b.title);
        return t != 0 ? t : a.id.compareTo(b.id);
      });
    // lane → list of (startIndex, endIndex) already placed
    final occupied = <List<(int, int)>>[];
    final spans = <BandSpan>[];
    final hidden = <LocalDate, int>{};
    final lanes = <LocalDate, int>{};
    for (final b in list) {
      final start = b.bandStart!;
      final end = b.bandEnd!.isBefore(start) ? start : b.bandEnd!;
      if (end.isBefore(grid.first) || start.isAfter(grid.last)) continue;
      final s = start.isBefore(grid.first) ? 0 : grid.indexOf(start);
      final e = end.isAfter(grid.last) ? MonthGrid.cellCount - 1 : grid.indexOf(end);
      var lane = 0;
      while (lane < occupied.length && occupied[lane].any((o) => !(o.$2 < s || o.$1 > e))) {
        lane++;
      }
      if (lane == occupied.length) occupied.add(<(int, int)>[]);
      occupied[lane].add((s, e));
      if (lane >= maxLanes) {
        for (var i = s; i <= e; i++) {
          hidden.update(grid.days[i], (v) => v + 1, ifAbsent: () => 1);
        }
        continue;
      }
      for (var i = s; i <= e; i++) {
        final d = grid.days[i];
        final current = lanes[d] ?? 0;
        if (lane + 1 > current) lanes[d] = lane + 1;
      }
      var cursor = s;
      while (cursor <= e) {
        final row = cursor ~/ MonthGrid.columns;
        final rowEnd = row * MonthGrid.columns + MonthGrid.columns - 1;
        final segEnd = e < rowEnd ? e : rowEnd;
        spans.add(
          BandSpan(
            item: b,
            row: row,
            colStart: cursor % MonthGrid.columns,
            colEnd: segEnd % MonthGrid.columns,
            lane: lane,
            continuesBefore: cursor > s || start.isBefore(grid.first),
            continuesAfter: segEnd < e || end.isAfter(grid.last),
          ),
        );
        cursor = segEnd + 1;
      }
    }
    return BandLayout._(
      spans: List<BandSpan>.unmodifiable(spans),
      hiddenPerDay: Map<LocalDate, int>.unmodifiable(hidden),
      lanesPerDay: Map<LocalDate, int>.unmodifiable(lanes),
    );
  }
}
