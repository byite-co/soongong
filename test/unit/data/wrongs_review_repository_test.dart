import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/reading_engine.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/features/review/domain/review_scheduler.dart';

import 'db_test_helpers.dart';

Future<void> seedSaved(TestHarness h) => h.wrongs.applySaved(
      requestId: 'req-1',
      subjectId: 'math',
      rangeText: 'p.10',
      items: const <WrongItemDraft>[
        WrongItemDraft(id: 'w1', pageIndex: 0, number: 3, mark: Mark.wrong, confidence: 0.5, userConfirmed: true),
        WrongItemDraft(id: 'w2', pageIndex: 0, number: 7, mark: Mark.unsolved, confidence: 0.4, userConfirmed: true),
        WrongItemDraft(id: 'w0', pageIndex: 0, number: 1, mark: Mark.correct, confidence: 0.9, userConfirmed: true),
      ],
      entries: <ReviewEntryDraft>[
        ReviewEntryDraft(id: 'e1', wrongItemId: 'w1', dueAt: kT0.add(const Duration(days: 1)), intervalDays: 1, consecutiveCorrect: 0),
        ReviewEntryDraft(id: 'e2', wrongItemId: 'w2', dueAt: kT0.add(const Duration(days: 1)), intervalDays: 1, consecutiveCorrect: 0),
      ],
    );

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  test('applySaved mirrors server-created rows without outbox; correct items '
      'are skipped; setStatus is a user write', () async {
    await seedSaved(h);
    expect((await h.wrongs.getByRequest('req-1')).map((w) => w.id), <String>['w1', 'w2']);
    expect(await h.outbox(), isEmpty);
    expect((await h.review.getQueue()).map((e) => e.wrongItemId), <String>['w1', 'w2']);

    await h.wrongs.setStatus('w1', WrongItemStatus.resolved);
    final w1 = (await h.wrongs.get('w1'))!;
    expect(w1.status, WrongItemStatus.resolved);
    expect(w1.resolvedAt, kT0);
    expect(w1.stamp.clientRev, 2);
    expect(await h.outboxRow('wrong_items', 'w1'), isNotNull);
    expect((await h.wrongs.watchAll(status: WrongItemStatus.open).first).map((w) => w.id), <String>['w2']);
    final counts = await h.wrongs.countsBySubject();
    expect(counts['math'], (open: 1, resolved: 1));
  });

  test('recordRetry follows D9: 맞음 ×2 → entry leaves the queue; 또 틀림 '
      'resets; watchDue', () async {
    await seedSaved(h);
    h.clock.jumpTo(kT0.add(const Duration(days: 1)));
    final first = await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.correct);
    expect(first, isA<ReviewScheduled>());
    var e1 = (await h.review.entryFor('w1'))!;
    expect(e1.intervalDays, 2);
    expect(e1.consecutiveCorrect, 1);
    expect(e1.dueAt, kT0.add(const Duration(days: 3)));
    expect(e1.lastResult, RetryResult.correct);
    expect(e1.id, 'e1', reason: 'entry updated in place');

    h.clock.jumpTo(kT0.add(const Duration(days: 3)));
    expect((await h.review.watchDue(h.ctx.nowUtc()).first).map((e) => e.wrongItemId), containsAll(<String>['w1', 'w2']));
    final second = await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.correct);
    expect(second, isA<ReviewGraduated>());
    expect(await h.review.entryFor('w1'), isNull);
    expect((await h.raw('review_entries', 'e1'))!['deleted_at'], isNotNull);
    expect((await h.review.getRetries('w1')).length, 2);

    final wrong = await h.review.recordRetry(wrongItemId: 'w2', result: RetryResult.wrong);
    e1 = (await h.review.entryFor('w2'))!;
    expect(wrong, isA<ReviewScheduled>());
    expect(e1.intervalDays, 1);
    expect(e1.dueAt, kT0.add(const Duration(days: 4)));
    expect((await h.outbox('retry_records')).length, 3);
  });

  test('graduated → 또 틀림 re-enters at 1 day; void afterwards matches the '
      'full rebuild (S02b single transition)', () async {
    await seedSaved(h);
    h.clock.jumpTo(kT0.add(const Duration(days: 1)));
    await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.correct);
    h.clock.jumpTo(kT0.add(const Duration(days: 3)));
    expect(await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.correct), isA<ReviewGraduated>());
    expect(await h.review.entryFor('w1'), isNull);

    h.clock.jumpTo(kT0.add(const Duration(days: 10)));
    final back = await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.wrong);
    expect(back, isA<ReviewScheduled>());
    final entry = (await h.review.entryFor('w1'))!;
    expect(entry.intervalDays, 1);
    expect(entry.consecutiveCorrect, 0);
    expect(entry.dueAt, kT0.add(const Duration(days: 11)));
    expect(entry.lastResult, RetryResult.wrong);
    expect(entry.id, isNot('e1'), reason: 'fresh row; e1 is a tombstone');

    // 부분 after re-entry keeps the 1-day interval.
    h.clock.jumpTo(kT0.add(const Duration(days: 11)));
    await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.partial);
    expect((await h.review.entryFor('w1'))!.dueAt, kT0.add(const Duration(days: 12)));

    // Void the re-entry record: rebuild of [correct, correct, partial] ==
    // incremental: graduated at 4 d, then partial re-enters with 4 d.
    final records = await h.review.getRetries('w1');
    final wrongRecord = records.firstWhere((r) => r.result == RetryResult.wrong);
    final outcome = await h.review.voidRetry(wrongRecord.id);
    final expected = const ReviewScheduler().rebuild(
      (await h.wrongs.get('w1'))!.stamp.createdAt,
      records
          .where((r) => r.id != wrongRecord.id)
          .map((r) => RetryEvent(result: r.result, at: r.at)),
    );
    expect(outcome, expected);
    final e = (await h.review.entryFor('w1'))!;
    expect(e.intervalDays, 4);
    expect(e.consecutiveCorrect, 0);
    expect(e.lastResult, RetryResult.partial);
  });

  test('partial unique index: a second live entry for one wrong item is '
      'rejected; a tombstoned one does not block (S02b)', () async {
    await seedSaved(h);
    final now = kT0;
    Future<void> insertEntry(String id) => h.db.into(h.db.reviewEntries).insert(
          ReviewEntriesCompanion.insert(
            id: id,
            userId: 'u1',
            createdAt: now,
            clientUpdatedAt: now,
            deviceId: 'd',
            wrongItemId: 'w1',
            dueAt: Value(now),
            intervalDays: const Value(1),
            consecutiveCorrect: const Value(0),
          ),
        );
    await expectLater(insertEntry('dup'), throwsA(isA<Exception>()));
    expect(await h.raw('review_entries', 'dup'), isNull);

    await h.writer.commitDelete(h.db.reviewEntries, 'e1'); // tombstone
    await insertEntry('after'); // allowed again
    expect((await h.review.entryFor('w1'))!.id, 'after');
    expect(
      AppDatabase.partialUniqueIndexes.single,
      contains('review_entries_live_wrong_item'),
    );
  });

  test('voidRetry rebuilds the entry from the remaining records (rtVoid)', () async {
    await seedSaved(h);
    h.clock.jumpTo(kT0.add(const Duration(days: 1)));
    await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.correct);
    h.clock.jumpTo(kT0.add(const Duration(days: 3)));
    await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.correct);
    expect(await h.review.entryFor('w1'), isNull);

    final second = (await h.review.getRetries('w1')).last;
    final outcome = await h.review.voidRetry(second.id);
    expect(outcome, isA<ReviewScheduled>());
    final entry = (await h.review.entryFor('w1'))!;
    expect(entry.intervalDays, 2);
    expect(entry.consecutiveCorrect, 1);
    expect(entry.dueAt, kT0.add(const Duration(days: 3)));
    expect(entry.id, isNot('e1'), reason: 'a fresh entry (old one is a tombstone)');
    final voided = (await h.review.watchRetries('w1').first).firstWhere((r) => r.id == second.id);
    expect(voided.voided, isTrue);
    expect(voided.voidedAt, kT0.add(const Duration(days: 3)));

    // Voiding the first as well → back to the initial 1-day schedule.
    final first = (await h.review.getRetries('w1')).first;
    await h.review.voidRetry(first.id);
    final reset = (await h.review.entryFor('w1'))!;
    expect(reset.intervalDays, 1);
    expect(reset.consecutiveCorrect, 0);
    expect(reset.dueAt, kT0.add(const Duration(days: 1)), reason: 'initial from wrong item creation');
  });
}
