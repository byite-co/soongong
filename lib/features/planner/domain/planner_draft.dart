// PlannerDraft (S07, pure Dart): the register/edit sheet's working copy of
// one planner entry — item (공부 · 할 일 · 자습), 기간 띠 or 반복 일정. Holds
// validation and dirty detection so the sheet shows the "변경 취소" /
// "버리기" confirmation only when something actually changed (PRD 4.2).

import '../../../core/domain/entities/planner.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';

enum DraftEventMode { period, repeat }

/// How a repeat ends (prototype 종료: 계속 · 이달까지 · 날짜 지정 — [S07]).
enum RecurrenceEndOption { never, endOfMonth, date }

enum DraftError {
  titleEmpty,
  rangeTooLong,
  targetInvalid,
  bandOrder,
  noWeekday,
  timeOrder,
}

/// What the draft edits. `newEntry` creates; the others update by id.
sealed class DraftTarget {
  const DraftTarget();
}

class NewEntry extends DraftTarget {
  const NewEntry();
}

class ExistingItem extends DraftTarget {
  const ExistingItem(this.id);
  final String id;
}

class ExistingBand extends DraftTarget {
  const ExistingBand(this.id);
  final String id;
}

class ExistingRecurrence extends DraftTarget {
  const ExistingRecurrence(this.id);
  final String id;
}

class PlannerDraft {
  const PlannerDraft({
    required this.kind,
    required this.date,
    this.title = '',
    this.subjectId,
    this.rangeText = '',
    this.targetMinutes,
    this.eventMode = DraftEventMode.period,
    this._bandStart,
    this._bandEnd,
    this.weekdays = const <int>{},
    this.startTime = const LocalTime(19, 0),
    this.endTime = const LocalTime(21, 0),
    this.endOption = RecurrenceEndOption.never,
    this.endsOn,
  });

  static const int titleMaxLength = 80;
  static const int rangeMaxLength = 40;
  static const List<int> targetChips = <int>[20, 30, 45, 60];
  static const int freeDefaultTargetMinutes = 30;
  static const int timeStepMinutes = 30;

  final PlannerKind kind;
  final String title;
  final String? subjectId;
  final String rangeText;

  /// null = no target (할 일 · 일정).
  final int? targetMinutes;
  final LocalDate date;

  // 일정 — 기간
  final DraftEventMode eventMode;
  final LocalDate? _bandStart;
  final LocalDate? _bandEnd;

  // 일정 — 반복 (1 = Monday … 7 = Sunday)
  final Set<int> weekdays;
  final LocalTime startTime;
  final LocalTime endTime;
  final RecurrenceEndOption endOption;
  final LocalDate? endsOn;

  LocalDate get bandStart => _bandStart ?? date;
  LocalDate get bandEnd => _bandEnd ?? bandStart;

  bool get isEvent => kind == PlannerKind.event;
  bool get isPeriod => isEvent && eventMode == DraftEventMode.period;
  bool get isRepeat => isEvent && eventMode == DraftEventMode.repeat;
  bool get hasTarget => kind == PlannerKind.study || kind == PlannerKind.self;
  bool get hasRange => kind == PlannerKind.study;

  /// A new draft for [date]. Study/self start with the free default target;
  /// the sheet replaces it with the premium suggestion when entitled.
  factory PlannerDraft.create({
    required LocalDate date,
    PlannerKind kind = PlannerKind.study,
    int? defaultTarget = freeDefaultTargetMinutes,
  }) =>
      PlannerDraft(
        kind: kind,
        date: date,
        targetMinutes: kind == PlannerKind.study || kind == PlannerKind.self ? defaultTarget : null,
        bandStart: date,
        bandEnd: date,
      );

  factory PlannerDraft.fromItem(PlannerItem item) => PlannerDraft(
        kind: item.kind,
        date: item.date,
        title: item.title,
        subjectId: item.subjectId,
        rangeText: item.rangeText ?? '',
        targetMinutes: item.targetMinutes,
        eventMode: DraftEventMode.period,
        bandStart: item.bandStart ?? item.date,
        bandEnd: item.bandEnd ?? item.bandStart ?? item.date,
        startTime: item.startTime ?? const LocalTime(19, 0),
        endTime: item.endTime ?? const LocalTime(21, 0),
      );

  factory PlannerDraft.fromRecurrence(Recurrence r, {required LocalDate date}) {
    final days = <int>{
      for (var w = 1; w <= 7; w++)
        if (r.occursOnWeekday(w)) w,
    };
    return PlannerDraft(
      kind: PlannerKind.event,
      date: date,
      title: r.title,
      subjectId: r.subjectId,
      eventMode: DraftEventMode.repeat,
      weekdays: days,
      startTime: r.startTime,
      endTime: r.endTime,
      endOption: r.endsOn == null ? RecurrenceEndOption.never : RecurrenceEndOption.date,
      endsOn: r.endsOn,
    );
  }

  PlannerDraft copyWith({
    PlannerKind? kind,
    String? title,
    Object? subjectId = _unset,
    String? rangeText,
    Object? targetMinutes = _unset,
    LocalDate? date,
    DraftEventMode? eventMode,
    LocalDate? bandStart,
    LocalDate? bandEnd,
    Set<int>? weekdays,
    LocalTime? startTime,
    LocalTime? endTime,
    RecurrenceEndOption? endOption,
    Object? endsOn = _unset,
  }) =>
      PlannerDraft(
        kind: kind ?? this.kind,
        title: title ?? this.title,
        subjectId: identical(subjectId, _unset) ? this.subjectId : subjectId as String?,
        rangeText: rangeText ?? this.rangeText,
        targetMinutes: identical(targetMinutes, _unset) ? this.targetMinutes : targetMinutes as int?,
        date: date ?? this.date,
        eventMode: eventMode ?? this.eventMode,
        bandStart: bandStart ?? _bandStart,
        bandEnd: bandEnd ?? _bandEnd,
        weekdays: weekdays ?? this.weekdays,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        endOption: endOption ?? this.endOption,
        endsOn: identical(endsOn, _unset) ? this.endsOn : endsOn as LocalDate?,
      );

  /// Switching kind keeps the title/subject and applies kind defaults for
  /// the target (study/self keep or get [defaultTarget]; todo/event: none).
  PlannerDraft withKind(PlannerKind kind, {int? defaultTarget = freeDefaultTargetMinutes}) {
    final keepsTarget = kind == PlannerKind.study || kind == PlannerKind.self;
    return copyWith(
      kind: kind,
      targetMinutes: keepsTarget ? (targetMinutes ?? defaultTarget) : null,
      rangeText: kind == PlannerKind.study ? rangeText : '',
    );
  }

  /// The repeat's `ends_on` for the chosen option, relative to [date].
  LocalDate? resolvedEndsOn() => switch (endOption) {
        RecurrenceEndOption.never => null,
        RecurrenceEndOption.endOfMonth => LocalDate(date.year, date.month, _daysInMonth(date.year, date.month)),
        RecurrenceEndOption.date => endsOn ?? date,
      };

  String get trimmedTitle => title.trim();
  String? get trimmedRange => hasRange && rangeText.trim().isNotEmpty ? rangeText.trim() : null;

  List<DraftError> validate() {
    final errors = <DraftError>[];
    if (trimmedTitle.isEmpty) errors.add(DraftError.titleEmpty);
    if (hasRange && rangeText.trim().length > rangeMaxLength) errors.add(DraftError.rangeTooLong);
    if (hasTarget && targetMinutes != null && targetMinutes! < 1) errors.add(DraftError.targetInvalid);
    if (isPeriod && bandEnd.isBefore(bandStart)) errors.add(DraftError.bandOrder);
    if (isRepeat) {
      if (weekdays.isEmpty) errors.add(DraftError.noWeekday);
      if (!(endTime > startTime)) errors.add(DraftError.timeOrder);
    }
    return errors;
  }

  bool get isValid => validate().isEmpty;

  /// Dirty check for the confirmation dialogs: compares what the save would
  /// persist for the current kind (fields that do not apply are ignored).
  bool differsFrom(PlannerDraft other) {
    if (kind != other.kind) return true;
    if (trimmedTitle != other.trimmedTitle) return true;
    if (subjectId != other.subjectId) return true;
    if (hasRange && (trimmedRange ?? '') != (other.trimmedRange ?? '')) return true;
    if (hasTarget && targetMinutes != other.targetMinutes) return true;
    if (isEvent) {
      if (eventMode != other.eventMode) return true;
      if (isPeriod) return bandStart != other.bandStart || bandEnd != other.bandEnd;
      return !_sameSet(weekdays, other.weekdays) ||
          startTime != other.startTime ||
          endTime != other.endTime ||
          resolvedEndsOn() != other.resolvedEndsOn();
    }
    return date != other.date;
  }

  /// New-entry dirtiness: anything typed counts (prototype `closeSheet`).
  bool get hasInput => trimmedTitle.isNotEmpty || rangeText.trim().isNotEmpty;

  static bool _sameSet(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);

  static int _daysInMonth(int year, int month) =>
      month == 12 ? 31 : LocalDate(year, month + 1, 1).addDays(-1).day;
}

const Object _unset = Object();
