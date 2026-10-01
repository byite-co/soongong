// RecurrenceExpander (S02, pure Dart): recurrences → dated instances for
// the weekly timetable / home ring. Instances are not stored (v1: whole
// recurrence edit/delete only). A recurrence appears from the local day it
// was created until `ends_on` (inclusive) while `active`.

import '../../../core/domain/entities/planner.dart';
import '../../../core/domain/local_date.dart';

class RecurrenceInstance {
  const RecurrenceInstance({required this.recurrence, required this.date});

  final Recurrence recurrence;
  final LocalDate date;

  LocalTime get start => recurrence.startTime;
  LocalTime get end => recurrence.endTime;
  DateTime get startAt => start.on(date);
  DateTime get endAt => end.on(date);
  String get title => recurrence.title;
  String? get subjectId => recurrence.subjectId;
}

class RecurrenceExpander {
  const RecurrenceExpander();

  /// Instances on every day of [from]..[to] (inclusive), sorted by date then
  /// start time.
  List<RecurrenceInstance> expand(
    Iterable<Recurrence> recurrences, {
    required LocalDate from,
    required LocalDate to,
  }) {
    final out = <RecurrenceInstance>[];
    if (to.isBefore(from)) return out;
    final days = from.daysUntil(to);
    for (final r in recurrences) {
      if (!r.active || r.weekdayMask == 0) continue;
      final startsOn = LocalDate.of(r.stamp.createdAt);
      for (var i = 0; i <= days; i++) {
        final d = from.addDays(i);
        if (d.isBefore(startsOn)) continue;
        if (r.endsOn != null && d.isAfter(r.endsOn!)) break;
        if (!r.occursOnWeekday(d.weekday)) continue;
        out.add(RecurrenceInstance(recurrence: r, date: d));
      }
    }
    out.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.start.compareTo(b.start);
    });
    return out;
  }

  /// The 7 days of the week containing [anyDay].
  List<RecurrenceInstance> forWeek(
    Iterable<Recurrence> recurrences, {
    required LocalDate anyDay,
    required int weekStart,
  }) {
    final start = anyDay.startOfWeek(weekStart);
    return expand(recurrences, from: start, to: start.addDays(6));
  }
}
