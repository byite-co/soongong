// MiniDatePicker (S07): the register sheet's inline date picker (prototype
// N12 `datePick`): month title with 이전/다음, 오늘·내일 shortcuts, weekday
// header and a 6-row grid. Pure selection — the caller owns the value.

import 'package:flutter/material.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/strings/planner_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/lucide_icon.dart';
import '../domain/month_grid.dart';

class MiniDatePicker extends StatefulWidget {
  const MiniDatePicker({
    super.key,
    required this.selected,
    required this.today,
    required this.weekStart,
    required this.onPick,
    this.shortcuts = true,
  });

  final LocalDate selected;
  final LocalDate today;
  final int weekStart;
  final ValueChanged<LocalDate> onPick;

  /// Show the 오늘 · 내일 buttons.
  final bool shortcuts;

  @override
  State<MiniDatePicker> createState() => _MiniDatePickerState();
}

class _MiniDatePickerState extends State<MiniDatePicker> {
  late MonthGrid _grid = MonthGrid.of(widget.selected.year, widget.selected.month, weekStart: widget.weekStart);

  @override
  void didUpdateWidget(MiniDatePicker old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected || old.weekStart != widget.weekStart) {
      _grid = MonthGrid.of(widget.selected.year, widget.selected.month, weekStart: widget.weekStart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final caption = AppTypography.caption;
    Widget shortcut(String label, LocalDate d) => _SmallButton(
          label: label,
          onTap: () => widget.onPick(d),
          background: c.surface,
          color: c.tx2,
        );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              _IconButton(
                icon: LucideIcons.chevronLeft,
                semantics: PlannerStrings.pickerPrev,
                onTap: () => setState(() => _grid = _grid.previous()),
              ),
              Expanded(
                child: Text(
                  PlannerStrings.pickerMonth(_grid.year, _grid.month),
                  textAlign: TextAlign.center,
                  style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.tx),
                ),
              ),
              _IconButton(
                icon: LucideIcons.chevronRight,
                semantics: PlannerStrings.pickerNext,
                onTap: () => setState(() => _grid = _grid.next()),
              ),
              if (widget.shortcuts) ...<Widget>[
                const SizedBox(width: AppSpacing.s6),
                shortcut(PlannerStrings.pickerToday, widget.today),
                const SizedBox(width: AppSpacing.s6),
                shortcut(PlannerStrings.pickerTomorrow, widget.today.addDays(1)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: <Widget>[
              for (final w in _grid.columnWeekdays)
                Expanded(
                  child: Text(
                    PlannerStrings.weekdayOf(w),
                    textAlign: TextAlign.center,
                    style: caption.copyWith(color: c.tx3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          for (var r = 0; r < MonthGrid.rows; r++)
            Row(
              children: <Widget>[
                for (final d in _grid.week(r))
                  Expanded(
                    child: _DayCell(
                      date: d,
                      inMonth: _grid.inMonth(d),
                      selected: d == widget.selected,
                      isToday: d == widget.today,
                      onTap: () => widget.onPick(d),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final LocalDate date;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected
        ? c.onPri
        : isToday
            ? c.priTx
            : inMonth
                ? c.tx
                : c.tx3;
    return Semantics(
      button: true,
      selected: selected,
      label: date.key,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: selected ? c.pri : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: AppTypography.withWeight(AppTypography.label, isToday ? 700 : 500).copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.semantics, required this.onTap});

  final IconData icon;
  final String semantics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.touchTarget,
          height: AppSpacing.touchTarget,
          child: Center(child: LucideIcon.small(icon, color: c.tx2)),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget - 8),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.r8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
