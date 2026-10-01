import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/reading_engine.dart';
import 'package:soongong/core/domain/enums.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  test('draft: create enqueues; edit allowed while selecting; local sending '
      'flag and payload hash are not user writes', () async {
    final d = await h.reading.createDraft(subjectId: 'math', rangeText: 'p.10', origin: ReadingOrigin.planner, plannerItemId: 'p1');
    expect(d.requestId, d.id);
    expect(d.status, ReadingRequestStatus.selecting);
    expect(d.isDraft, isTrue);
    expect(await h.outboxRow('reading_requests', d.id), isNotNull);

    await h.reading.updateDraft(d.requestId, rangeText: const Value('p.11'));
    expect((await h.reading.get(d.requestId))!.rangeText, 'p.11');
    expect((await h.raw('reading_requests', d.id))!['client_rev'], 2);

    await h.reading.setLocalSending(d.requestId, payloadHash: 'h1');
    final sending = (await h.reading.get(d.requestId))!;
    expect(sending.status, ReadingRequestStatus.sending);
    expect(sending.payloadHash, 'h1');
    expect(sending.stamp.clientRev, 2, reason: 'local-only');

    await h.reading.revertLocalSending(d.requestId);
    expect((await h.reading.get(d.requestId))!.status, ReadingRequestStatus.selecting);
  });

  test('after submission the draft is frozen; server transitions arrive via '
      'applyStatus; blocking request is exposed', () async {
    final d = await h.reading.createDraft(subjectId: 'math', rangeText: 'p.10', origin: ReadingOrigin.home);
    await h.reading.applyStatus(d.requestId, status: ReadingRequestStatus.processing, serverVersion: 1, submittedAt: kT0);
    expect(() => h.reading.updateDraft(d.requestId, rangeText: const Value('x')), throwsStateError);
    expect((await h.reading.watchBlocking().first)!.requestId, d.requestId);

    await h.reading.applyStatus(
      d.requestId,
      status: ReadingRequestStatus.doneUnsaved,
      serverVersion: 2,
      completedAt: kT0.add(const Duration(seconds: 8)),
      quotaCharged: true,
      resultJson: const Value('{"pages":[]}'),
    );
    final done = (await h.reading.get(d.requestId))!;
    expect(done.status, ReadingRequestStatus.doneUnsaved);
    expect(done.resultJson, '{"pages":[]}');
    expect(done.quotaCharged, isTrue);
    expect((await h.reading.watchBlocking().first)!.requestId, d.requestId);

    await h.reading.setConfirmedMarks(d.requestId, '[]');
    await h.reading.applyStatus(
      d.requestId,
      status: ReadingRequestStatus.saved,
      serverVersion: 3,
      marksJson: const Value('[{"n":3,"m":"wrong"}]'),
      clearConfirmedMarks: true,
    );
    final saved = (await h.reading.get(d.requestId))!;
    expect(saved.marksJson, '[{"n":3,"m":"wrong"}]');
    expect(saved.confirmedMarksJson, isNull);
    expect(await h.reading.watchBlocking().first, isNull);
    expect((await h.reading.watchSaved().first).single.requestId, d.requestId);
    expect((await h.outbox('reading_requests')).length, 1, reason: 'only the draft create');
    expect((await h.raw('reading_requests', d.id))!['client_rev'], 1);
  });

  test('deleteSavedResult: delete-only mutation on the request, children '
      'hidden locally without outbox, request_id kept on the tombstone', () async {
    final d = await h.reading.createDraft(subjectId: 'math', rangeText: 'p.10', origin: ReadingOrigin.home);
    await h.reading.applyStatus(d.requestId, status: ReadingRequestStatus.processing, serverVersion: 1);
    expect(() => h.reading.deleteSavedResult(d.requestId), throwsStateError);
    await h.reading.applyStatus(d.requestId, status: ReadingRequestStatus.saved, serverVersion: 2);

    await h.wrongs.applySaved(
      requestId: d.requestId,
      subjectId: 'math',
      rangeText: 'p.10',
      items: const <WrongItemDraft>[
        WrongItemDraft(id: 'w1', pageIndex: 0, number: 3, mark: Mark.wrong, confidence: 0.5, userConfirmed: true),
      ],
      entries: <ReviewEntryDraft>[
        ReviewEntryDraft(id: 'e1', wrongItemId: 'w1', dueAt: kT0.add(const Duration(days: 1)), intervalDays: 1, consecutiveCorrect: 0),
      ],
    );
    await h.review.recordRetry(wrongItemId: 'w1', result: RetryResult.partial);
    final outboxBefore = (await h.outbox()).length;

    await h.reading.deleteSavedResult(d.requestId);

    expect(await h.reading.get(d.requestId), isNull);
    final dead = (await h.raw('reading_requests', d.id))!;
    expect(dead['deleted_at'], isNotNull);
    expect(dead['request_id'], d.requestId);
    expect(dead['marks_json'], isNull);
    expect(dead['subject_id'], isNull);
    expect(await h.wrongs.getByRequest(d.requestId), isEmpty);
    expect(await h.review.entryFor('w1'), isNull);
    expect(await h.review.getRetries('w1'), isEmpty);
    expect((await h.raw('wrong_items', 'w1'))!['subject_id'], 'math', reason: 'hidden, content kept');
    expect((await h.outbox()).length, outboxBefore, reason: 'request already enqueued (draft); children not enqueued');
    expect((await h.outboxRow('wrong_items', 'w1')), isNull);
  });

  test('photos: add / attach / expiry / deleted marker', () async {
    final p1 = await h.reading.addPhoto(localPath: 'a.jpg', takenAt: kT0, width: 100, height: 200, pageIndex: 0);
    final p2 = await h.reading.addPhoto(localPath: 'b.jpg', takenAt: kT0, width: 100, height: 200, pageIndex: 5);
    expect(p1.expiresAt, kT0.add(const Duration(days: 30)));
    await h.reading.attachPhotos('req-1', <String>[p2.id, p1.id]);
    final photos = await h.reading.watchPhotos('req-1').first;
    expect(photos.map((p) => p.localPath), <String>['b.jpg', 'a.jpg']);
    expect(photos.map((p) => p.pageIndex), <int>[0, 1]);

    expect(await h.reading.expiredPhotos(kT0.add(const Duration(days: 29))), isEmpty);
    expect((await h.reading.expiredPhotos(kT0.add(const Duration(days: 30)))).length, 2);
    await h.reading.markPhotoDeleted(p1.id);
    expect((await h.reading.getAllPhotos()).map((p) => p.id), <String>[p2.id]);
    expect((await h.reading.getAllPhotos(includeDeleted: true)).length, 2);
    await h.reading.purgePhotoRows(<String>[p1.id, p2.id]);
    expect(await h.reading.getAllPhotos(includeDeleted: true), isEmpty);
  });

  test('deleteDraft removes a never-pushed draft physically; a pushed one '
      'is hidden', () async {
    final a = await h.reading.createDraft(subjectId: 's', rangeText: 'p', origin: ReadingOrigin.home);
    await h.reading.deleteDraft(a.requestId);
    expect(await h.raw('reading_requests', a.id), isNull);
    expect(await h.outboxRow('reading_requests', a.id), isNull);

    final b = await h.reading.createDraft(subjectId: 's', rangeText: 'p', origin: ReadingOrigin.home);
    await h.reading.applyServer(<Map<String, Object?>>[
      serverRow(b.id, userId: 'u1', content: <String, Object?>{
        'request_id': b.requestId,
        'subject_id': 's',
        'range_text': 'p',
        'origin': 'home',
        'status': 'selecting',
        'quota_charged': false,
      }),
    ]);
    await h.reading.deleteDraft(b.requestId);
    expect((await h.raw('reading_requests', b.id))!['deleted_at'], isNotNull);
    expect((await h.raw('reading_requests', b.id))!['range_text'], 'p');
  });
}
