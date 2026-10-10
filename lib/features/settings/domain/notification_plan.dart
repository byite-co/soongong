// NotificationPlan (S09, pure Dart): which local notifications the app
// schedules for the next days — only the two the PRD allows (4.4): the
// 복습 큐 reminder once a day at the chosen time when something is due, and
// 10 minutes before a timetable event (recurrence instance or planner event
// with a start time). Facts only, nothing that urges studying (CLAUDE.md
// §1). Ids are stable per source so re-planning replaces entries.

import '../../../core/contracts/notification_gateway.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/settings_strings.dart';
import '../../timetable/domain/recurrence_expander.dart';

class NotificationPlan {
  const NotificationPlan._();

  static const int horizonDays = 7;
  static const Duration eventLead = Duration(minutes: 10);
  static const int reviewIdBase = 100;
  static const int eventIdBase = 1000;

  /// [queue] = live review entries (due dates); [events] = planner items of
  /// the window (only `event` kind with a start time counts); [recurrences]
  /// = live recurrences. Everything is computed in local time from [now].
  static List<PlannedNotification> build({
    required DateTime now,
    required AppSettings settings,
    required Iterable<ReviewEntry> queue,
    required Iterable<Recurrence> recurrences,
    required Iterable<PlannerItem> events,
    int horizonDays = horizonDays,
  }) {
    final out = <PlannedNotification>[];
    final today = LocalDate.of(now);
    final last = today.addDays(horizonDays - 1);

    final reviewTime = settings.notifReviewTime;
    if (reviewTime != null) {
      final dueAts = queue.map((e) => e.dueAt.toLocal()).toList();
      for (var i = 0; i < horizonDays; i++) {
        final day = today.addDays(i);
        final at = reviewTime.on(day);
        if (!at.isAfter(now)) continue;
        final endOfDay = day.addDays(1).toDateTime();
        final due = dueAts.where((d) => d.isBefore(endOfDay)).length;
        if (due == 0) continue;
        out.add(
          PlannedNotification(
            id: reviewIdBase + i,
            at: at,
            title: SettingsStrings.reviewTitle,
            body: SettingsStrings.reviewBody(due),
          ),
        );
      }
    }

    if (settings.notifEvent10min) {
      for (final inst in const RecurrenceExpander().expand(recurrences, from: today, to: last)) {
        _addEvent(out, now, inst.recurrence.id, inst.date, inst.start, inst.title);
      }
      for (final item in events) {
        if (item.kind != PlannerKind.event || item.isBand) continue;
        final start = item.startTime;
        if (start == null || item.date.isBefore(today) || item.date.isAfter(last)) continue;
        _addEvent(out, now, item.id, item.date, start, item.title);
      }
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  static void _addEvent(List<PlannedNotification> out, DateTime now, String sourceId, LocalDate date, LocalTime start, String title) {
    final at = start.on(date).subtract(eventLead);
    if (!at.isAfter(now)) return;
    out.add(
      PlannedNotification(
        id: eventId(sourceId, date),
        at: at,
        title: title,
        body: SettingsStrings.eventBody(start.key),
      ),
    );
  }

  /// Stable 31-bit id for one event instance (`source|date`), above the
  /// review ids.
  static int eventId(String sourceId, LocalDate date) {
    var h = 0;
    for (final unit in '$sourceId|${date.key}'.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return eventIdBase + (h % (0x7fffffff - eventIdBase));
  }
}
