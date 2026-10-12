// NotificationPlan (S09 · S09b, pure Dart): which local notifications the
// app schedules for the next days — only the two the PRD allows (4.4): the
// 복습 큐 reminder once a day at the chosen time when something is due
// (premium: the review queue is a premium feature, D18 `entitled`), and 10
// minutes before a timetable recurrence instance (원본 S09 §4.4-5; plain
// planner events are not reminded). Facts only, nothing that urges studying
// (CLAUDE.md §1). Ids are stable per source so re-planning replaces entries.
// The device keeps at most 64 pending notifications (iOS): the plan is
// cut to the 64 soonest entries after sorting, reviews and events mixed.

import '../../../core/contracts/notification_gateway.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/settings_strings.dart';
import '../../timetable/domain/recurrence_expander.dart';

class NotificationPlan {
  const NotificationPlan._();

  static const int horizonDays = 7;

  /// iOS keeps at most 64 pending local notifications.
  static const int deviceLimit = 64;
  static const Duration eventLead = Duration(minutes: 10);
  static const int reviewIdBase = 100;
  static const int eventIdBase = 1000;

  /// [queue] = live review entries (due dates); [recurrences] = live
  /// recurrences. [entitled] gates the review reminders (D18). Everything
  /// is computed in local time from [now]; the result is sorted by time and
  /// cut to [deviceLimit].
  static List<PlannedNotification> build({
    required DateTime now,
    required AppSettings settings,
    required bool entitled,
    required Iterable<ReviewEntry> queue,
    required Iterable<Recurrence> recurrences,
    int horizonDays = horizonDays,
    int limit = deviceLimit,
  }) {
    final out = <PlannedNotification>[];
    final today = LocalDate.of(now);
    final last = today.addDays(horizonDays - 1);

    final reviewTime = settings.notifReviewTime;
    if (reviewTime != null && entitled) {
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
        final at = inst.start.on(inst.date).subtract(eventLead);
        if (!at.isAfter(now)) continue;
        out.add(
          PlannedNotification(
            id: eventId(inst.recurrence.id, inst.date),
            at: at,
            title: inst.title,
            body: SettingsStrings.eventBody(inst.start.key),
          ),
        );
      }
    }

    out.sort((a, b) => a.at.compareTo(b.at));
    return out.length > limit ? out.sublist(0, limit) : out;
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
