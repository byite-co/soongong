import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/features/timetable/domain/recurrence_expander.dart';

Recurrence rec(
  String id, {
  required Iterable<int> weekdays,
  required DateTime createdLocal,
  LocalDate? endsOn,
  bool active = true,
  String start = '19:00',
  String end = '20:00',
}) =>
    Recurrence(
      id: id,
      stamp: SyncStamp(
        userId: 'u',
        createdAt: createdLocal.toUtc(),
        clientUpdatedAt: createdLocal.toUtc(),
        deviceId: 'd',
      ),
      title: id,
      weekdayMask: Recurrence.maskOf(weekdays),
      startTime: LocalTime.parse(start),
      endTime: LocalTime.parse(end),
      endsOn: endsOn,
      active: active,
    );

void main() {
  const exp = RecurrenceExpander();
  final created = DateTime(2026, 9, 1);

  test('weekday mask: bit 0 = Monday … bit 6 = Sunday', () {
    final r = rec('mwf', weekdays: <int>[1, 3, 5], createdLocal: created);
    expect(r.weekdayMask, 1 | 4 | 16);
    expect(r.occursOnWeekday(DateTime.monday), isTrue);
    expect(r.occursOnWeekday(DateTime.tuesday), isFalse);
    expect(r.occursOnWeekday(DateTime.sunday), isFalse);
    expect(rec('sun', weekdays: <int>[7], createdLocal: created).weekdayMask, 64);
  });

  test('forWeek expands only matching weekdays, sorted by date then start', () {
    final recs = <Recurrence>[
      rec('late', weekdays: <int>[1], createdLocal: created, start: '21:00', end: '22:00'),
      rec('mwf', weekdays: <int>[1, 3, 5], createdLocal: created),
    ];
    // Week of Wed 2026-09-30 (Mon 28 – Sun 4 Oct).
    final week = exp.forWeek(recs, anyDay: LocalDate.parse('2026-09-30'), weekStart: 1);
    expect(
      week.map((i) => '${i.date.key} ${i.title}'),
      <String>[
        '2026-09-28 mwf',
        '2026-09-28 late',
        '2026-09-30 mwf',
        '2026-10-02 mwf',
      ],
    );
    expect(week.first.startAt, DateTime(2026, 9, 28, 19));
    expect(week.first.endAt, DateTime(2026, 9, 28, 20));
  });

  test('ends_on (inclusive), inactive and the creation day are respected', () {
    final recs = <Recurrence>[
      rec('ends', weekdays: <int>[1, 2, 3, 4, 5, 6, 7], createdLocal: created, endsOn: LocalDate.parse('2026-09-29')),
      rec('off', weekdays: <int>[1, 2, 3, 4, 5, 6, 7], createdLocal: created, active: false),
      rec('new', weekdays: <int>[1, 2, 3, 4, 5, 6, 7], createdLocal: DateTime(2026, 9, 30, 8)),
    ];
    final out = exp.expand(recs, from: LocalDate.parse('2026-09-28'), to: LocalDate.parse('2026-10-01'));
    expect(
      out.map((i) => '${i.date.key} ${i.title}'),
      <String>[
        '2026-09-28 ends',
        '2026-09-29 ends',
        '2026-09-30 new',
        '2026-10-01 new',
      ],
    );
    expect(exp.expand(recs, from: LocalDate.parse('2026-10-02'), to: LocalDate.parse('2026-10-01')), isEmpty);
  });
}
