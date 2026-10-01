import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/core/strings/subjects_strings.dart';
import 'package:soongong/data/seed/dev_seeder.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;
  late DevSeeder seeder;

  setUp(() {
    h = TestHarness();
    seeder = DevSeeder(
      db: h.db,
      ctx: h.ctx,
      subjects: h.subjects,
      sessions: h.sessions,
      planner: h.planner,
      reading: h.reading,
      wrongs: h.wrongs,
      review: h.review,
      settings: h.settings,
      quota: h.quota,
      activity: h.activity,
    );
  });
  tearDown(() => h.close());

  test('seedSubjects: 5 + 기타, idempotent, 기타 last', () async {
    final first = await seeder.seedSubjects();
    expect(first.map((s) => s.name), <String>[...SubjectsStrings.devSeedNames, SubjectsStrings.defaultSubjectName]);
    expect(first.last.isDefault, isTrue);
    final again = await seeder.seedSubjects();
    expect(again.length, 6);
  });

  test('insertSampleData: 30 days of sessions, 2 weeks of planner, 23 wrong '
      'items, empty outbox; clearSampleData leaves only subjects', () async {
    final today = LocalDate.of(h.clock.now());
    await seeder.insertSampleData();

    final sessions = await h.sessions.getAll();
    expect(sessions.length, greaterThan(20));
    final days = sessions.map((s) => LocalDate.of(s.startedAt)).toSet();
    expect(days.every((d) => !d.isBefore(today.addDays(-29)) && !d.isAfter(today)), isTrue);
    expect(days.length, greaterThan(15));
    for (final s in sessions.take(5)) {
      expect(await h.sessions.getSegments(s.id), isNotEmpty);
      expect(s.seatedSeconds, greaterThan(0));
    }

    final items = await h.planner.getAllItems();
    final dated = items.where((i) => !i.isBand);
    expect(dated.every((i) => !i.date.isBefore(today.addDays(-7)) && !i.date.isAfter(today.addDays(7))), isTrue);
    expect(items.where((i) => i.isBand).length, 1);
    expect((await h.planner.getRecurrences()).single.title, '수학 학원');

    final wrongs = await h.wrongs.getAll();
    expect(wrongs.length, 23);
    expect(wrongs.where((w) => w.status == WrongItemStatus.resolved), isNotEmpty);
    expect((await h.reading.watchSaved().first).length, 3);
    expect((await h.review.getQueue()).length, greaterThan(10));
    expect((await h.quota.get(today.monthKey))!.used, 3);
    expect((await h.settings.get()).dailyGoalMinutes, 150);
    expect((await h.activity.getAll()).length, greaterThan(10));
    expect(await h.outbox(), isEmpty, reason: 'sample data is never pushed');

    await seeder.clearSampleData();
    expect(await h.sessions.getAll(), isEmpty);
    expect(await h.planner.getAllItems(), isEmpty);
    expect(await h.wrongs.getAll(), isEmpty);
    expect((await h.subjects.getAll()).length, 6);
    expect(await h.outbox(), isEmpty);
  });
}
