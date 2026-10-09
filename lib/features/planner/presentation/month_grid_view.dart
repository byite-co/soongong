// MonthGridView (S07): the 6-week grid (or the selected week when folded).
// Per cell: blue density wash (4 levels), today's orange border, subject
// colour bar + title per item (≤ 3 lines, then "+N"), band lanes (≤ 2,
// overflow "+N"), dots when folded, and the oblique 3D column when the
// extrusion is on. Pure widget: the screen owns gestures and state.

import 'package:flutter/material.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/planner_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/lucide_icon.dart';
import '../domain/band_layout.dart';
import '../domain/density_scale.dart';
import '../domain/month_aggregate.dart';
import '../domain/month_grid.dart';
import 'planner_3d_painter.dart';

/// Widget keys for tests.
abstract final class PlannerGridKeys {
  static Key cell(LocalDate d) => Key('planner-cell-${d.key}');
  static Key band(String id, int row) => Key('planner-band-$id-$row');
}

class MonthGridView extends StatelessWidget {
  const MonthGridView({
    super.key,
    required this.aggregate,
    required this.density,
    required this.today,
    required this.selected,
    required this.subjects,
    required this.collapsedRow,
    required this.extrusion,
    required this.entitled,
    required this.onPickDay,
  });

  final MonthAggregate aggregate;
  final DensityScale density;
  final LocalDate today;
  final LocalDate? selected;
  final Map<String, Subject> subjects;

  /// null = all 6 rows; otherwise only this row is shown (folded).
  final int? collapsedRow;

  /// 0 = flat grid … 1 = full 3D columns.
  final double extrusion;
  final bool entitled;
  final ValueChanged<LocalDate> onPickDay;

  bool get collapsed => collapsedRow != null;

  @override
  Widget build(BuildContext context) {
    final grid = aggregate.grid;
    final rows = collapsed ? <int>[collapsedRow!] : List<int>.generate(MonthGrid.rows, (i) => i);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth / MonthGrid.columns;
        final rowH = constraints.maxHeight / rows.length;
        final bandOpacity = collapsed ? 0.0 : 1 - extrusion;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
              children: <Widget>[
                for (final r in rows)
                  SizedBox(
                    height: rowH,
                    child: Row(
                      children: <Widget>[
                        for (final d in grid.week(r))
                          SizedBox(
                            width: cellW,
                            child: _DayCell(
                              date: d,
                              day: aggregate.dayOf(d),
                              inMonth: grid.inMonth(d),
                              isToday: d == today,
                              isSelected: d == selected,
                              isFuture: d.isAfter(today),
                              level: density.levelOf(aggregate.seatedOn(d)),
                              columnRatio: _columnRatio(d),
                              tone: _tone(d),
                              lanes: aggregate.bandLayout.lanesOn(d),
                              hiddenBands: aggregate.bandLayout.hiddenOn(d),
                              subjects: subjects,
                              collapsed: collapsed,
                              extrusion: extrusion,
                              onTap: () => onPickDay(d),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            if (bandOpacity > 0)
              for (final span in aggregate.bandLayout.spans)
                Positioned(
                  left: span.colStart * cellW + 2,
                  width: span.length * cellW - 4,
                  top: span.row * rowH + 30 + span.lane * (AppPlanner.bandHeight + AppPlanner.bandGap),
                  height: AppPlanner.bandHeight,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: bandOpacity,
                      child: _BandStrip(span: span, subjects: subjects),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  /// 0..1 height of the cell's column: past/today = 순공 vs the density
  /// reference; future (premium only) = planned minutes vs the reference.
  double _columnRatio(LocalDate d) {
    final seated = aggregate.seatedOn(d);
    if (seated > 0) return density.ratioOf(seated);
    if (!entitled || !d.isAfter(today)) return 0;
    final planned = aggregate.dayOf(d).plannedMinutes * 60;
    if (planned <= 0) return 0;
    final ref = density.referenceSeconds > 0 ? density.referenceSeconds : 300 * 60;
    final r = planned / ref;
    return r > 1 ? 1 : r;
  }

  ColumnTone _tone(LocalDate d) {
    if (d == today) return ColumnTone.today;
    return aggregate.seatedOn(d) > 0 ? ColumnTone.seated : ColumnTone.planned;
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.isFuture,
    required this.level,
    required this.columnRatio,
    required this.tone,
    required this.lanes,
    required this.hiddenBands,
    required this.subjects,
    required this.collapsed,
    required this.extrusion,
    required this.onTap,
  });

  final LocalDate date;
  final DayAggregate day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool isFuture;
  final int level;
  final double columnRatio;
  final ColumnTone tone;
  final int lanes;
  final int hiddenBands;
  final Map<String, Subject> subjects;
  final bool collapsed;
  final double extrusion;
  final VoidCallback onTap;

  Color _itemColor(AppColors c, PlannerItem it) {
    final s = it.subjectId == null ? null : subjects[it.subjectId];
    if (s != null) return c.subject(s.colorIndex);
    return switch (it.kind) {
      PlannerKind.self => c.acc,
      PlannerKind.event => c.tx,
      _ => c.tx3,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = day.items;
    final has3d = extrusion > 0 && columnRatio > 0 && inMonth;
    final maxH = collapsed ? AppPlanner.columnMaxCollapsed : AppPlanner.columnMax;
    final h = has3d ? (columnRatio * maxH).clamp(4.0, maxH) : 0.0;
    final lift = h * extrusion;
    final dx = Planner3dPainter.shearOf(lift);

    final wash = level == 0 || !inMonth
        ? Colors.transparent
        : c.pri.withValues(alpha: AppPlanner.densityAlpha[level]);
    final bg = isToday
        ? c.accWeak
        : has3d
            ? c.surface
            : wash;

    final cap = collapsed ? 0 : (AppPlanner.maxItemLines - lanes).clamp(0, AppPlanner.maxItemLines);
    final shown = items.length > cap ? (cap - 1).clamp(0, cap) : cap;
    final visible = items.take(shown).toList();
    final more = items.length - visible.length;

    final (front, side) = switch (tone) {
      ColumnTone.today => (c.acc, c.isDark ? AppPlanner.todaySideDark : AppPlanner.todaySide),
      ColumnTone.seated => (
          c.isDark ? AppPlanner.columnFrontDark : AppPlanner.columnFront,
          c.isDark ? AppPlanner.columnSideDark : AppPlanner.columnSide
        ),
      ColumnTone.planned => (
          c.isDark ? AppPlanner.plannedFrontDark : AppPlanner.plannedFront,
          c.isDark ? AppPlanner.plannedSideDark : AppPlanner.plannedSide
        ),
    };
    final numberColor = isToday
        ? c.accTx
        : !inMonth
            ? c.tx3
            : date.weekday == DateTime.sunday
                ? const Color(0xFFC0392B)
                : date.weekday == DateTime.saturday
                    ? c.priTx
                    : c.tx;

    final content = Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(has3d || isToday ? 3 : 0),
        border: isToday ? Border.all(color: c.acc, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected && !isToday ? Border.all(color: c.tx, width: 2) : null,
                ),
                child: Text(
                  '${date.day}',
                  style: AppTypography.withWeight(AppTypography.caption, 600)
                      .copyWith(color: numberColor, height: 1, fontFeatures: AppTypography.tabularFigures),
                ),
              ),
            ],
          ),
          if (collapsed)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (final it in items.take(4))
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: it.isDone ? _itemColor(c, it) : c.tx3,
                      ),
                    ),
                ],
              ),
            )
          else ...<Widget>[
            for (var i = 0; i < lanes; i++)
              const SizedBox(height: AppPlanner.bandHeight + AppPlanner.bandGap),
            if (hiddenBands > 0)
              Text(
                PlannerStrings.more(hiddenBands),
                textAlign: TextAlign.right,
                style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10, height: 1.3),
              ),
            if (extrusion < 1 && !has3d || extrusion == 0) ...<Widget>[
              for (final it in visible) _ItemLine(item: it, color: _itemColor(c, it), inMonth: inMonth),
              if (more > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    PlannerStrings.more(more),
                    style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10, height: 1.3),
                  ),
                ),
            ] else if (items.isNotEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
                child: Wrap(
                  spacing: 3,
                  runSpacing: 3,
                  children: <Widget>[
                    for (final it in items.take(8))
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: it.isDone ? _itemColor(c, it) : Colors.transparent,
                          border: Border.all(color: _itemColor(c, it), width: 1.25),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(3, 2, 0, 0),
                child: Text(
                  '${day.doneCount}/${day.plannableCount}',
                  style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10, height: 1.3),
                ),
              ),
            ],
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: PlannerStrings.cellSemantics(date.key, items.length, PlannerStrings.hm(day.seatedSeconds)),
      child: GestureDetector(
        key: PlannerGridKeys.cell(date),
        behavior: HitTestBehavior.opaque,
        onTap: inMonth ? onTap : null,
        child: Opacity(
          opacity: inMonth ? 1 : 0.45,
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            clipBehavior: Clip.none,
            child: CustomPaint(
              painter: has3d
                  ? Planner3dPainter(
                      heightPx: h,
                      t: extrusion,
                      front: front,
                      side: side,
                      top: c.surface,
                      edge: c.line,
                      opacity: tone == ColumnTone.planned ? AppPlanner.plannedOpacity : 1,
                    )
                  : null,
              child: Transform.translate(
                offset: Offset(-dx, -lift),
                child: ClipRect(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item, required this.color, required this.inMonth});

  final PlannerItem item;
  final Color color;
  final bool inMonth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isTodo = item.kind == PlannerKind.todo;
    return Opacity(
      opacity: item.isDone ? 0.55 : (inMonth ? 1 : 0.4),
      child: Container(
        padding: EdgeInsets.only(left: isTodo ? 0 : 4, top: 1, bottom: 1),
        decoration: isTodo
            ? null
            : BoxDecoration(border: Border(left: BorderSide(color: color, width: 2))),
        child: Row(
          children: <Widget>[
            if (isTodo && !item.isDone)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: color, width: 1.25),
                ),
              ),
            if (item.isDone)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: LucideIcon(LucideIcons.check, size: 9, color: color),
              ),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTypography.caption.copyWith(
                  color: item.isDone ? c.tx2 : c.tx,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandStrip extends StatelessWidget {
  const _BandStrip({required this.span, required this.subjects});

  final BandSpan span;
  final Map<String, Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = span.item.subjectId == null ? null : subjects[span.item.subjectId];
    final color = s != null ? c.subject(s.colorIndex) : c.tx;
    const radius = Radius.circular(3);
    return Container(
      key: PlannerGridKeys.band(span.item.id, span.row),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: span.continuesBefore ? Radius.zero : radius,
          right: span.continuesAfter ? Radius.zero : radius,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        span.item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: AppTypography.withWeight(AppTypography.caption, 600)
            .copyWith(color: Colors.white, fontSize: 10, height: 1.2),
      ),
    );
  }
}
