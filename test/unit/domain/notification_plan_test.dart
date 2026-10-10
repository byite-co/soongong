// NotificationPlan (S09 · S09b): only the two PRD notifications — 복습 큐
// once a day at the chosen time when something is due (entitled accounts
// only), and 10 minutes before a timetable recurrence instance — inside a
// 7-day horizon, never in the past, with stable ids per source so
// re-planning replaces entries, cut to the 64 soonest (device limit).

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/notification_gateway.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/strings/settings_strings.dart';
import 'package:soongong/features/settings/domain/notification_plan.dart';

void main() {
  /// Saturday 2026-10-03 10:00 local.
  final now = DateTime(2026, 10, 3, 10);
  final stamp = SyncStamp(userId: 'u', createdAt: now, clientUpdatedAt: now, deviceId: 'd');

  ReviewEntry entry(String id, DateTime dueAt) =>
      ReviewEntry(id: id, stamp: stamp, wrongItemId: 'w-$id', dueAt: dueAt, intervalDays: 1, consecutiveCorrect: 0);

  Recurrence recurrence({String id = 'r1', List<int> weekdays = const <int>[6, 7], LocalTime start = const LocalTime(16, 0)}) =>
      Recurrence(
        id: id,
        stamp: stamp,
        title: '수학 학원',
        weekdayMask: Recurrence.maskOf(weekdays),
        startTime: start,
        endTime: const LocalTime(17, 30),
      );

  const off = AppSettings();
  const reviewOn = AppSettings(notifReviewTime: LocalTime(21, 0));
  const eventsOn = AppSettings(notifEvent10min: true);

  List<PlannedNotification> build(AppSettings s, {Iterable<ReviewEntry> queue = const [], Iterable<Recurrence> recs = const [], DateTime? at, bool entitled = true}) =>
      NotificationPlan.build(now: at ?? now, settings: s, entitled: entitled, queue: queue, recurrences: recs);

  test('everything off → nothing, whatever is due', () {
    final plan = build(off, queue: [entry('e', now)], recs: [recurrence()]);
    expect(plan, isEmpty);
  });

  test('review reminder: one per day at the chosen time, count = entries due by the end of that day', () {
    final plan = build(
      reviewOn,
      queue: [entry('a', now), entry('b', now.add(const Duration(hours: 2))), entry('c', DateTime(2026, 10, 6, 9))],
    );
    expect(plan.map((n) => n.id), List<int>.generate(7, (i) => NotificationPlan.reviewIdBase + i));
    expect(plan.first.at, DateTime(2026, 10, 3, 21));
    expect(plan.first.title, SettingsStrings.reviewTitle);
    expect(plan.first.body, SettingsStrings.reviewBody(2));
    expect(plan[2].body, SettingsStrings.reviewBody(2), reason: '10/5: c not due yet');
    expect(plan[3].at, DateTime(2026, 10, 6, 21));
    expect(plan[3].body, SettingsStrings.reviewBody(3));
    expect(plan.last.at, DateTime(2026, 10, 9, 21));
  });

  test('review reminder: a time already past today is skipped; nothing due → nothing', () {
    final late = DateTime(2026, 10, 3, 21, 30);
    final plan = build(reviewOn, queue: [entry('a', now)], at: late);
    expect(plan.first.at, DateTime(2026, 10, 4, 21));
    expect(plan.length, 6);
    expect(build(reviewOn), isEmpty);
    expect(build(reviewOn, queue: [entry('far', DateTime(2026, 11, 1))]), isEmpty, reason: 'due after the horizon');
  });

  test('events: recurrence instances in the 7-day window, 10 minutes before, stable ids, sorted', () {
    final rec = recurrence();
    final plan = build(eventsOn, recs: [rec]);
    expect(plan.map((n) => n.at), <DateTime>[DateTime(2026, 10, 3, 15, 50), DateTime(2026, 10, 4, 15, 50)]);
    expect(plan.first.title, '수학 학원');
    expect(plan.first.body, SettingsStrings.eventBody('16:00'));
    expect(plan.first.id, NotificationPlan.eventId('r1', const LocalDate(2026, 10, 3)));
    expect(plan.first.id, build(eventsOn, recs: [rec]).first.id, reason: 'stable across builds');
    expect(plan.first.id, isNot(plan.last.id));
    expect(plan.every((n) => n.id >= NotificationPlan.eventIdBase), isTrue);
  });

  test('review reminders need the entitlement (D18): free → none, premium → planned', () {
    final queue = [entry('a', now)];
    expect(build(reviewOn, queue: queue, entitled: false), isEmpty);
    expect(build(reviewOn, queue: queue).length, 7);
  });

  test('device limit: sorted by time and cut to the 64 soonest, reviews and events mixed', () {
    final recs = [for (var i = 0; i < 10; i++) recurrence(id: 'r$i', weekdays: const <int>[1, 2, 3, 4, 5, 6, 7], start: LocalTime(11 + i, 0))];
    final plan = build(const AppSettings(notifReviewTime: LocalTime(21, 0), notifEvent10min: true), queue: [entry('a', now)], recs: recs);
    expect(plan.length, NotificationPlan.deviceLimit);
    expect(plan.map((n) => n.at), orderedEquals(<DateTime>[...plan.map((n) => n.at)]..sort()));
    final all = build(const AppSettings(notifReviewTime: LocalTime(21, 0), notifEvent10min: true), queue: [entry('a', now)], recs: recs, at: now).length;
    expect(all, 64, reason: '70 instances + 7 reviews → only the 64 soonest survive');
    expect(plan.last.at.isBefore(DateTime(2026, 10, 9, 12)), isTrue);
    expect(plan.where((n) => n.id < NotificationPlan.eventIdBase).length, greaterThan(0), reason: 'earlier reviews kept');
  });

  test('both on: review and event entries interleave by time', () {
    final plan = build(
      const AppSettings(notifReviewTime: LocalTime(21, 0), notifEvent10min: true),
      queue: [entry('a', now)],
      recs: [recurrence()],
    );
    expect(plan.map((n) => n.at).take(3), <DateTime>[
      DateTime(2026, 10, 3, 15, 50),
      DateTime(2026, 10, 3, 21),
      DateTime(2026, 10, 4, 15, 50),
    ]);
  });
}
