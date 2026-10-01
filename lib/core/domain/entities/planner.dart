import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import '../local_date.dart';
import 'sync_stamp.dart';

part 'planner.freezed.dart';

/// `planner_items` (§2.5). `kind == event` + [bandStart]/[bandEnd] = 기간 띠.
@freezed
abstract class PlannerItem with _$PlannerItem {
  const factory PlannerItem({
    required String id,
    required SyncStamp stamp,
    required PlannerKind kind,
    required String title,
    String? subjectId,
    String? rangeText,
    int? targetMinutes,
    required LocalDate date,
    LocalTime? startTime,
    LocalTime? endTime,
    @Default(false) bool isDone,
    DateTime? doneAt,
    String? recurrenceId,
    LocalDate? bandStart,
    LocalDate? bandEnd,
    required int sortOrder,
  }) = _PlannerItem;

  const PlannerItem._();

  bool get isBand => kind == PlannerKind.event && bandStart != null;

  /// Text handed to the reading flow (D27): range, else the title.
  String get readingRangeText =>
      (rangeText != null && rangeText!.trim().isNotEmpty) ? rangeText! : title;
}

/// `recurrences` (§2.6). [weekdayMask] bit 0 = Monday … bit 6 = Sunday.
@freezed
abstract class Recurrence with _$Recurrence {
  const factory Recurrence({
    required String id,
    required SyncStamp stamp,
    required String title,
    String? subjectId,
    required int weekdayMask,
    required LocalTime startTime,
    required LocalTime endTime,
    LocalDate? endsOn,
    @Default(true) bool active,
  }) = _Recurrence;

  const Recurrence._();

  /// [weekday] 1 = Monday … 7 = Sunday.
  bool occursOnWeekday(int weekday) => (weekdayMask >> (weekday - 1)) & 1 == 1;

  static int maskOf(Iterable<int> weekdays) =>
      weekdays.fold(0, (m, w) => m | (1 << (w - 1)));
}
