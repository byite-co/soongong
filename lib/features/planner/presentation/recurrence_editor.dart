// RecurrenceEditor (S07): 요일 · 시작/끝 시각(30분 단위) · 종료(계속 · 이달까지 ·
// 날짜 지정) for a 반복 일정 (prototype `repeatSheet`). Shared with the
// timetable's `evEdit` (S08): it edits a plain [RecurrenceFields] value and
// never touches the repositories. Whole-recurrence edits only (PRD 4.2).

import 'package:flutter/material.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/strings/planner_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/lucide_icon.dart';
import '../domain/planner_draft.dart';
import 'mini_date_picker.dart';

/// The editable part of a recurrence. [weekdays] 1 = Monday … 7 = Sunday.
class RecurrenceFields {
  const RecurrenceFields({
    required this.weekdays,
    required this.startTime,
    required this.endTime,
    required this.endOption,
    this.endsOn,
  });

  final Set<int> weekdays;
  final LocalTime startTime;
  final LocalTime endTime;
  final RecurrenceEndOption endOption;
  final LocalDate? endsOn;

  RecurrenceFields copyWith({
    Set<int>? weekdays,
    LocalTime? startTime,
    LocalTime? endTime,
    RecurrenceEndOption? endOption,
    LocalDate? endsOn,
  }) =>
      RecurrenceFields(
        weekdays: weekdays ?? this.weekdays,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        endOption: endOption ?? this.endOption,
        endsOn: endsOn ?? this.endsOn,
      );

  /// "매주 월·수 19:00–21:00 · …" or the prompt to pick weekdays.
  String summary(int weekStart) {
    if (weekdays.isEmpty) return PlannerStrings.repeatPickDays;
    final order = List<int>.generate(7, (i) => (weekStart - 1 + i) % 7 + 1);
    final names = order.where(weekdays.contains).map(PlannerStrings.weekdayOf).join('·');
    return PlannerStrings.repeatSummary(names, startTime.key, endTime.key);
  }
}

class RecurrenceEditor extends StatelessWidget {
  const RecurrenceEditor({
    super.key,
    required this.value,
    required this.onChanged,
    required this.weekStart,
    required this.today,
    this.showDatePicker = true,
  });

  final RecurrenceFields value;
  final ValueChanged<RecurrenceFields> onChanged;
  final int weekStart;
  final LocalDate today;

  /// Inline picker when 종료 = 날짜 지정.
  final bool showDatePicker;

  static const int stepMinutes = PlannerDraft.timeStepMinutes;

  LocalTime _shift(LocalTime t, int minutes) {
    var m = t.minutesOfDay + minutes;
    if (m < 0) m = 0;
    if (m > 23 * 60 + 30) m = 23 * 60 + 30;
    return LocalTime(m ~/ 60, m % 60);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final order = List<int>.generate(7, (i) => (weekStart - 1 + i) % 7 + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var i = 0; i < order.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.s6),
              Expanded(
                child: _WeekdayChip(
                  label: PlannerStrings.weekdayOf(order[i]),
                  selected: value.weekdays.contains(order[i]),
                  onTap: () {
                    final next = Set<int>.of(value.weekdays);
                    if (!next.remove(order[i])) next.add(order[i]);
                    onChanged(value.copyWith(weekdays: next));
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: <Widget>[
            Expanded(
              child: StepperField(
                label: PlannerStrings.periodStart,
                text: value.startTime.key,
                decSemantics: PlannerStrings.halfHourBefore,
                incSemantics: PlannerStrings.halfHourAfter,
                onDec: () => onChanged(value.copyWith(startTime: _shift(value.startTime, -stepMinutes))),
                onInc: () {
                  final next = _shift(value.startTime, stepMinutes);
                  if (next < value.endTime) onChanged(value.copyWith(startTime: next));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: StepperField(
                label: PlannerStrings.periodEnd,
                text: value.endTime.key,
                decSemantics: PlannerStrings.halfHourBefore,
                incSemantics: PlannerStrings.halfHourAfter,
                onDec: () {
                  final next = _shift(value.endTime, -stepMinutes);
                  if (next > value.startTime) onChanged(value.copyWith(endTime: next));
                },
                onInc: () => onChanged(value.copyWith(endTime: _shift(value.endTime, stepMinutes))),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
          decoration: BoxDecoration(
            color: c.sunk,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  PlannerStrings.repeatEnd,
                  style: AppTypography.caption.copyWith(color: c.tx3),
                ),
              ),
              SegmentedChoice<RecurrenceEndOption>(
                value: value.endOption,
                options: const <(RecurrenceEndOption, String)>[
                  (RecurrenceEndOption.never, PlannerStrings.repeatEndNever),
                  (RecurrenceEndOption.endOfMonth, PlannerStrings.repeatEndMonth),
                  (RecurrenceEndOption.date, PlannerStrings.repeatEndDate),
                ],
                onChanged: (o) => onChanged(
                  value.copyWith(
                    endOption: o,
                    endsOn: o == RecurrenceEndOption.date ? (value.endsOn ?? today.addDays(28)) : value.endsOn,
                  ),
                ),
                compact: true,
              ),
            ],
          ),
        ),
        if (showDatePicker && value.endOption == RecurrenceEndOption.date) ...<Widget>[
          const SizedBox(height: AppSpacing.s10),
          MiniDatePicker(
            selected: value.endsOn ?? today,
            today: today,
            weekStart: weekStart,
            shortcuts: false,
            onPick: (d) => onChanged(value.copyWith(endsOn: d)),
          ),
        ],
        const SizedBox(height: AppSpacing.s10),
        Text(value.summary(weekStart), style: AppTypography.caption.copyWith(color: c.tx3)),
      ],
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: AppSpacing.touchTarget,
          decoration: BoxDecoration(
            color: selected ? c.priWeak : c.surface,
            borderRadius: BorderRadius.circular(AppRadius.r10),
            border: Border.all(color: selected ? c.pri : c.line, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: selected ? c.priTx : c.tx2),
          ),
        ),
      ),
    );
  }
}

/// `시작 / 끝` card with − · value · + (prototype period/time steppers).
/// Tapping the value runs [onTapValue] (e.g. opens a date picker).
class StepperField extends StatelessWidget {
  const StepperField({
    super.key,
    required this.label,
    required this.text,
    required this.onDec,
    required this.onInc,
    required this.decSemantics,
    required this.incSemantics,
    this.onTapValue,
  });

  final String label;
  final String text;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final String decSemantics;
  final String incSemantics;
  final VoidCallback? onTapValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget btn(IconData icon, String semantics, VoidCallback onTap) => Semantics(
          button: true,
          label: '$label $semantics',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: Center(child: LucideIcon.small(icon, color: c.tx2)),
            ),
          ),
        );
    final value = Text(
      text,
      style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx, fontFeatures: AppTypography.tabularFigures),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s10, AppSpacing.s12, AppSpacing.s10),
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTypography.caption.copyWith(color: c.tx3)),
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: <Widget>[
              btn(LucideIcons.minus, decSemantics, onDec),
              Expanded(
                child: onTapValue == null
                    ? Center(child: FittedBox(fit: BoxFit.scaleDown, child: value))
                    : Semantics(
                        button: true,
                        label: '$label $text',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onTapValue,
                          child: SizedBox(
                            height: AppSpacing.touchTarget,
                            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: value)),
                          ),
                        ),
                      ),
              ),
              btn(LucideIcons.plus, incSemantics, onInc),
            ],
          ),
        ],
      ),
    );
  }
}

/// Prototype's sunk segmented control (종류 · 기간/반복 · 종료).
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.compact = false,
    this.leading,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  /// Smaller height for inline use (종료).
  final bool compact;

  /// Optional dot per option (kind selector).
  final Widget Function(T option, bool selected)? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: compact ? c.surface : c.sunk,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: <Widget>[
          for (final (opt, label) in options)
            Flexible(
              fit: compact ? FlexFit.loose : FlexFit.tight,
              child: Semantics(
                button: true,
                selected: opt == value,
                label: label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(opt),
                  child: Container(
                    height: compact ? 34 : AppSpacing.touchTarget,
                    padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.s10 : AppSpacing.s4),
                    decoration: BoxDecoration(
                      color: opt == value ? (compact ? c.sunk : c.surface) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.r8 - 2),
                      boxShadow: opt == value && !compact ? c.shadow : AppShadow.none,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (leading != null) ...<Widget>[
                          leading!(opt, opt == value),
                          const SizedBox(width: AppSpacing.s6),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.withWeight(AppTypography.label, 600)
                                .copyWith(color: opt == value ? c.tx : c.tx3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
