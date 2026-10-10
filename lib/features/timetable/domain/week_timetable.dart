// WeekTimetable (S08, pure Dart): one week of the timetable — seven day
// columns of 순공 blocks (saved sessions' seated/manual runs clipped to each
// local day, from `SeatedSlices`) and the recurrence instances of each day.
// Adjacent slices of one session on one day (gap ≤ 1 min) merge into one
// block so a short detection flicker does not split the drawing; the block
// keeps the exact seconds.

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../stats/domain/seated_slices.dart';
import 'recurrence_expander.dart';

class TimetableBlock {
  const TimetableBlock({
    required this.session,
    required this.day,
    required this.start,
    required this.end,
    required this.seconds,
  });

  final StudySession session;
  final LocalDate day;
  final DateTime start;
  final DateTime end;

  /// Exact seated seconds inside the block (gaps ≤ 1 min excluded).
  final int seconds;

  String get sessionId => session.id;
  String? get subjectId => session.subjectId;
  bool get isSelf => session.kind == SessionKind.self;
  double get startMinutes => start.difference(day.toDateTime()).inSeconds / 60;
  double get endMinutes => end.difference(day.toDateTime()).inSeconds / 60;
}

class WeekTimetable {
  const WeekTimetable._({
    required this.weekStart,
    required this.blocks,
    required this.recurrences,
    required this.totalSeconds,
  });

  static const int _mergeGapSeconds = 60;

  final LocalDate weekStart;

  /// Day → blocks ordered by start (every one of the 7 days has a key).
  final Map<LocalDate, List<TimetableBlock>> blocks;
  final Map<LocalDate, List<RecurrenceInstance>> recurrences;
  final int totalSeconds;

  LocalDate get weekEnd => weekStart.addDays(6);
  List<LocalDate> get days => List<LocalDate>.generate(7, weekStart.addDays);
  bool get hasBlocks => totalSeconds > 0;
  bool get hasRecurrences => recurrences.values.any((l) => l.isNotEmpty);

  int seatedOn(LocalDate day) =>
      (blocks[day] ?? const <TimetableBlock>[]).fold<int>(0, (a, b) => a + b.seconds);

  factory WeekTimetable.build({
    required LocalDate weekStart,
    required Iterable<SessionSegment> segments,
    required Iterable<StudySession> sessions,
    required Iterable<Recurrence> recurrences,
  }) {
    final weekEnd = weekStart.addDays(6);
    final blocks = <LocalDate, List<TimetableBlock>>{
      for (var i = 0; i < 7; i++) weekStart.addDays(i): <TimetableBlock>[],
    };
    final slices = SeatedSlices.clip(from: weekStart, to: weekEnd, segments: segments, sessions: sessions);
    final open = <String, _OpenBlock>{};
    var total = 0;
    for (final s in slices) {
      if (s.seconds <= 0) continue;
      total += s.seconds;
      final key = '${s.session.id}|${s.day.key}';
      final current = open[key];
      if (current != null && s.start.difference(current.end).inSeconds <= _mergeGapSeconds) {
        current
          ..end = s.end.isAfter(current.end) ? s.end : current.end
          ..seconds += s.seconds;
        continue;
      }
      if (current != null) blocks[s.day]!.add(current.toBlock());
      open[key] = _OpenBlock(session: s.session, day: s.day, start: s.start, end: s.end, seconds: s.seconds);
    }
    for (final b in open.values) {
      blocks[b.day]!.add(b.toBlock());
    }
    for (final list in blocks.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    final instances = const RecurrenceExpander().expand(recurrences, from: weekStart, to: weekEnd);
    final byDay = <LocalDate, List<RecurrenceInstance>>{
      for (var i = 0; i < 7; i++) weekStart.addDays(i): <RecurrenceInstance>[],
    };
    for (final inst in instances) {
      byDay[inst.date]?.add(inst);
    }
    return WeekTimetable._(weekStart: weekStart, blocks: blocks, recurrences: byDay, totalSeconds: total);
  }
}

class _OpenBlock {
  _OpenBlock({required this.session, required this.day, required this.start, required this.end, required this.seconds});

  final StudySession session;
  final LocalDate day;
  final DateTime start;
  DateTime end;
  int seconds;

  TimetableBlock toBlock() => TimetableBlock(session: session, day: day, start: start, end: end, seconds: seconds);
}
