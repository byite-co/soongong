// DevSeeder (S02 §4.5, dev flavor only). Default subjects on first start and
// the dev-menu "샘플 데이터 넣기 / 지우기": 30 days of sessions, 2 weeks of
// planner items, 23 wrong items across 3 saved reading requests. Everything
// goes through the repositories (the real write path); the outbox is then
// cleared because sample rows must never be pushed.

import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/contracts/reading_engine.dart';
import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/local_date.dart';
import '../../core/strings/subjects_strings.dart';
import '../../features/measure/domain/segment.dart';
import '../../features/reading/domain/reading_quota_policy.dart';
import '../db/app_database.dart';
import '../repositories/repositories.dart';

part 'dev_seeder.g.dart';

class DevSeeder {
  DevSeeder({
    required this.db,
    required this.ctx,
    required this.subjects,
    required this.sessions,
    required this.planner,
    required this.reading,
    required this.wrongs,
    required this.review,
    required this.settings,
    required this.quota,
    required this.activity,
  });

  final AppDatabase db;
  final WriteContext ctx;
  final SubjectRepository subjects;
  final SessionRepository sessions;
  final PlannerRepository planner;
  final ReadingRepository reading;
  final WrongsRepository wrongs;
  final ReviewRepository review;
  final SettingsRepository settings;
  final QuotaRepository quota;
  final ActivityRepository activity;

  /// 기타 + 국어·수학·영어·과학·사회 when no user subject exists yet.
  Future<List<Subject>> seedSubjects() async {
    await subjects.ensureDefault();
    final existing = await subjects.getAll();
    if (existing.where((s) => !s.isDefault).isNotEmpty) return existing;
    for (var i = 0; i < SubjectsStrings.devSeedNames.length; i++) {
      await subjects.create(name: SubjectsStrings.devSeedNames[i], colorIndex: i);
    }
    final all = await subjects.getAll();
    await subjects.reorder(<String>[
      ...all.where((s) => !s.isDefault).map((s) => s.id),
      ...all.where((s) => s.isDefault).map((s) => s.id),
    ]);
    return subjects.getAll();
  }

  /// Sessions 30 days · planner 2 weeks · 23 wrong items. Deterministic
  /// (seeded RNG) so screenshots are reproducible.
  Future<void> insertSampleData({DateTime? now, bool clearOutbox = true}) async {
    final today = LocalDate.of(now ?? ctx.clock.now());
    final rng = Random(42);
    final subs = (await seedSubjects()).where((s) => !s.isDefault).toList();
    Subject pick() => subs[rng.nextInt(subs.length)];

    await _seedSessions(rng, today, pick);
    await _seedPlanner(rng, today, subs);
    await _seedWrongs(rng, today, subs);
    await _seedLedger(today);
    if (clearOutbox) await db.delete(db.syncOutbox).go();
  }

  /// Wipes every table and re-seeds the subjects.
  Future<void> clearSampleData() async {
    await db.wipeAll();
    await seedSubjects();
    await db.delete(db.syncOutbox).go();
  }

  Future<void> _seedSessions(Random rng, LocalDate today, Subject Function() pick) async {
    const kinds = SessionKind.values;
    for (var offset = 29; offset >= 0; offset--) {
      final day = today.addDays(-offset);
      final count = const <int>[0, 1, 1, 2, 2, 3][rng.nextInt(6)];
      if (count > 0) await activity.touch(day);
      var hour = 8 + rng.nextInt(4);
      for (var i = 0; i < count; i++) {
        final start = DateTime(day.year, day.month, day.day, hour, rng.nextInt(60));
        final minutes = 25 + rng.nextInt(95);
        final end = start.add(Duration(minutes: minutes));
        final camera = rng.nextInt(10) < 8;
        final segments = _segments(rng, start, end, camera: camera);
        final kind = kinds[rng.nextInt(kinds.length)];
        await sessions.saveFinished(
          id: ctx.newId(),
          kind: kind,
          mode: camera ? SessionMode.camera : SessionMode.manual,
          startedAt: start,
          endedAt: end,
          status: rng.nextInt(20) == 0 ? SessionStatus.interrupted : SessionStatus.finished,
          segments: segments,
          sensitivityLevel: rng.nextInt(3),
          subjectId: kind == SessionKind.self ? null : pick().id,
        );
        hour += 2 + rng.nextInt(3);
        if (hour > 22) break;
      }
    }
  }

  List<Segment> _segments(Random rng, DateTime start, DateTime end, {required bool camera}) {
    if (!camera) {
      return <Segment>[
        Segment(id: ctx.newId(), kind: SegmentKind.manual, startAt: start, endAt: end),
      ];
    }
    final out = <Segment>[];
    var cursor = start;
    final gaps = rng.nextInt(3);
    for (var g = 0; g < gaps; g++) {
      final seated = cursor.add(Duration(minutes: 10 + rng.nextInt(25)));
      if (!seated.isBefore(end)) break;
      out.add(Segment(id: ctx.newId(), kind: SegmentKind.seated, startAt: cursor, endAt: seated));
      final away = seated.add(Duration(minutes: 2 + rng.nextInt(7)));
      if (!away.isBefore(end)) {
        cursor = seated;
        out.add(Segment(id: ctx.newId(), kind: SegmentKind.away, startAt: seated, endAt: end));
        return out;
      }
      out.add(Segment(id: ctx.newId(), kind: SegmentKind.away, startAt: seated, endAt: away));
      cursor = away;
    }
    out.add(Segment(id: ctx.newId(), kind: SegmentKind.seated, startAt: cursor, endAt: end));
    return out;
  }

  Future<void> _seedPlanner(Random rng, LocalDate today, List<Subject> subs) async {
    const titles = <PlannerKind, List<String>>{
      PlannerKind.study: <String>['문제집 p.10–20', '개념 정리', '기출 3회', '단원 복습'],
      PlannerKind.todo: <String>['단어 30개', '숙제 제출', '오답 정리', '요약 노트'],
      PlannerKind.self: <String>['자습', '자율 학습'],
    };
    for (var offset = -7; offset <= 7; offset++) {
      final day = today.addDays(offset);
      final count = 1 + rng.nextInt(3);
      for (var i = 0; i < count; i++) {
        final kind = PlannerKind.values[rng.nextInt(3)];
        final options = titles[kind]!;
        final subject = subs[rng.nextInt(subs.length)];
        final item = await planner.createItem(
          kind: kind,
          title: options[rng.nextInt(options.length)],
          date: day,
          subjectId: kind == PlannerKind.self ? null : subject.id,
          rangeText: kind == PlannerKind.study ? 'p.${10 + rng.nextInt(90)}–${100 + rng.nextInt(50)}' : null,
          targetMinutes: 30 + 15 * rng.nextInt(5),
          startTime: rng.nextBool() ? LocalTime(18 + rng.nextInt(4), 0) : null,
        );
        if (offset < 0 && rng.nextInt(10) < 7) {
          await planner.setDone(item.id, done: true);
        }
      }
    }
    final examStart = today.addDays(5);
    await planner.createItem(
      kind: PlannerKind.event,
      title: '중간고사',
      date: examStart,
      bandStart: examStart,
      bandEnd: examStart.addDays(2),
    );
    await planner.createRecurrence(
      title: '수학 학원',
      weekdayMask: Recurrence.maskOf(<int>[DateTime.tuesday, DateTime.thursday]),
      startTime: const LocalTime(19, 0),
      endTime: const LocalTime(21, 0),
      subjectId: subs.first.id,
    );
  }

  /// 3 saved requests → 8 + 8 + 7 = 23 wrong items, some resolved / retried.
  Future<void> _seedWrongs(Random rng, LocalDate today, List<Subject> subs) async {
    const marks = <Mark>[Mark.wrong, Mark.wrong, Mark.partial, Mark.unsolved, Mark.guessed];
    final specs = <(int, String, int)>[(1, 'p.112–118', 8), (2, '3단원 연습문제', 8), (3, '모의고사 1회', 7)];
    var wrongIndex = 0;
    for (var r = 0; r < specs.length; r++) {
      final (subjIdx, range, count) = specs[r];
      final subject = subs[subjIdx % subs.length];
      final savedAt = today.addDays(-(20 - r * 6)).toDateTime().add(const Duration(hours: 20));
      final draft = await reading.createDraft(
        subjectId: subject.id,
        rangeText: range,
        origin: ReadingOrigin.planner,
      );
      final items = <WrongItemDraft>[];
      final entries = <ReviewEntryDraft>[];
      final marksJson = <Map<String, Object?>>[];
      for (var i = 0; i < count; i++) {
        final id = ctx.newId();
        final mark = marks[rng.nextInt(marks.length)];
        final number = 2 + i * 2 + rng.nextInt(2);
        final page = i < count ~/ 2 ? 0 : 1;
        items.add(
          WrongItemDraft(
            id: id,
            pageIndex: page,
            number: number,
            mark: mark,
            confidence: 0.4 + rng.nextDouble() * 0.6,
            userConfirmed: true,
          ),
        );
        entries.add(
          ReviewEntryDraft(
            id: ctx.newId(),
            wrongItemId: id,
            dueAt: savedAt.add(const Duration(days: 1)),
            intervalDays: 1,
            consecutiveCorrect: 0,
          ),
        );
        marksJson.add(<String, Object?>{
          'page_index': page,
          'number': number,
          'mark': mark.name,
          'wrong_item_id': id,
        });
        wrongIndex++;
      }
      await reading.applyStatus(
        draft.requestId,
        status: ReadingRequestStatus.saved,
        serverVersion: 3,
        submittedAt: savedAt.subtract(const Duration(minutes: 5)),
        completedAt: savedAt.subtract(const Duration(minutes: 4)),
        quotaMonth: ReadingQuotaPolicy.monthKey(savedAt),
        quotaCharged: true,
        marksJson: Value(jsonEncode(marksJson)),
      );
      await wrongs.applySaved(
        requestId: draft.requestId,
        subjectId: subject.id,
        rangeText: range,
        items: items,
        entries: entries,
        at: savedAt,
      );
      // Some retries in the past, a few resolved.
      for (var i = 0; i < items.length; i++) {
        final w = items[i];
        if (i % 4 == 0) {
          await review.recordRetry(
            wrongItemId: w.id,
            result: i % 8 == 0 ? RetryResult.correct : RetryResult.partial,
            at: savedAt.add(const Duration(days: 1, hours: 2)),
          );
        }
        if (i % 5 == 4) await wrongs.setStatus(w.id, WrongItemStatus.resolved);
      }
    }
    assert(wrongIndex == 23, 'sample must contain 23 wrong items');
  }

  Future<void> _seedLedger(LocalDate today) async {
    await quota.applyLedger(<String, Object?>{
      'month': today.monthKey,
      'used': 3,
      'reserved': 0,
      'limit': ReadingQuotaPolicy.defaultLimit,
    });
    await settings.setDailyGoalMinutes(150);
  }
}

@Riverpod(keepAlive: true)
DevSeeder devSeeder(Ref ref) => DevSeeder(
      db: ref.watch(appDatabaseProvider),
      ctx: ref.watch(writeContextProvider),
      subjects: ref.watch(subjectRepositoryProvider),
      sessions: ref.watch(sessionRepositoryProvider),
      planner: ref.watch(plannerRepositoryProvider),
      reading: ref.watch(readingRepositoryProvider),
      wrongs: ref.watch(wrongsRepositoryProvider),
      review: ref.watch(reviewRepositoryProvider),
      settings: ref.watch(settingsRepositoryProvider),
      quota: ref.watch(quotaRepositoryProvider),
      activity: ref.watch(activityRepositoryProvider),
    );
