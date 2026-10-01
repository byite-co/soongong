import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/contracts.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';

ReadingJob job(String id, {List<String>? photos}) => ReadingJob(
      requestId: id,
      subjectId: 'math',
      rangeText: 'p.112–118',
      photoPaths: photos ?? const <String>['a.jpg', 'b.jpg'],
      origin: 'home',
    );

FakeReadingEngine engine(FakeReadingScenario s) =>
    FakeReadingEngine(scenario: s, delay: Duration.zero);

const List<ConfirmedMark> kMarks = <ConfirmedMark>[
  ConfirmedMark(pageIndex: 0, number: 3, mark: Mark.wrong, wrongItemId: 'w3'),
  ConfirmedMark(pageIndex: 0, number: 4, mark: Mark.wrong, wrongItemId: 'w4'),
];
const List<WrongItemDraft> kItems = <WrongItemDraft>[
  WrongItemDraft(
    id: 'w3',
    pageIndex: 0,
    number: 3,
    mark: Mark.wrong,
    confidence: 0.52,
    userConfirmed: true,
  ),
  WrongItemDraft(
    id: 'w4',
    pageIndex: 0,
    number: 4,
    mark: Mark.wrong,
    confidence: 0.91,
    userConfirmed: true,
  ),
];

Future<FakeReadingEngine> savedEngine([
  FakeReadingScenario s = FakeReadingScenario.success,
]) async {
  final e = engine(s);
  await e.submit(job('r1'));
  await e.watch('r1').toList();
  expect(await e.save('r1', kMarks, kItems), isA<SaveSaved>());
  return e;
}

void main() {
  group('submit / watch', () {
    test('success: Sending → Processing → Done with 3 low-confidence items',
        () async {
      final e = engine(FakeReadingScenario.success);
      expect(await e.submit(job('r1')), isA<SubmitAccepted>());
      final statuses = await e.watch('r1').toList();
      expect(statuses.first, isA<Sending>());
      expect(statuses.whereType<Processing>(), isNotEmpty);
      final done = statuses.last as Done;
      final low = done.result.pages
          .expand((p) => p.items)
          .where((i) => i.confidence < 0.6)
          .length;
      expect(low, 3);
      expect(done.result.pages.length, 2);
      final q = await e.quota();
      expect(q.used, 1);
      expect(q.limit, 20);
      expect(q.remaining, 19);
    });

    test('successZeroWrong: every item is correct', () async {
      final e = engine(FakeReadingScenario.successZeroWrong);
      await e.submit(job('r1'));
      final done = (await e.watch('r1').toList()).last as Done;
      expect(
        done.result.pages
            .expand((p) => p.items)
            .every((i) => i.mark == Mark.correct),
        isTrue,
      );
    });

    test('same id is idempotent; a different payload is PayloadMismatch',
        () async {
      final e = engine(FakeReadingScenario.success);
      expect(await e.submit(job('r1')), isA<SubmitAccepted>());
      expect(await e.submit(job('r1')), isA<SubmitAccepted>());
      expect(
        await e.submit(job('r1', photos: const <String>['z.jpg'])),
        isA<SubmitPayloadMismatch>(),
      );
    });

    test('an active request blocks a new id with ActiveExists(activeId)',
        () async {
      final e = engine(FakeReadingScenario.success);
      await e.submit(job('r1'));
      final out = await e.submit(job('r2'));
      expect(out, isA<SubmitActiveExists>());
      expect((out as SubmitActiveExists).requestId, 'r1');
    });

    test('an unsaved (done) result blocks new requests until saved/discarded '
        '(D17)', () async {
      final e = engine(FakeReadingScenario.success);
      await e.submit(job('r1'));
      await e.watch('r1').toList(); // done, unsaved
      expect(e.stateOf('r1'), FakeRequestState.done);
      final blocked = await e.submit(job('r2'));
      expect(blocked, isA<SubmitActiveExists>());
      expect((blocked as SubmitActiveExists).requestId, 'r1');

      expect(await e.save('r1', kMarks, kItems), isA<SaveSaved>());
      expect(await e.submit(job('r2')), isA<SubmitAccepted>());
      await e.watch('r2').toList();
      expect(await e.submit(job('r3')), isA<SubmitActiveExists>());
      await e.discard('r2');
      expect(await e.submit(job('r3')), isA<SubmitAccepted>());
    });

    test('tombstone: unknown id → NotFound; discarded → Deleted / RequestDeleted',
        () async {
      final e = engine(FakeReadingScenario.success);
      expect(await e.watch('nope').toList(), <Matcher>[isA<NotFound>()]);
      await e.submit(job('r1'));
      await e.watch('r1').toList();
      await e.discard('r1');
      expect(await e.watch('r1').toList(), <Matcher>[isA<Deleted>()]);
      expect(await e.submit(job('r1')), isA<SubmitRequestDeleted>());
      expect(await e.submit(job('r2')), isA<SubmitAccepted>());
    });

    test('saved request rejects re-submit with InvalidState(saved)', () async {
      final e = await savedEngine();
      final out = await e.submit(job('r1'));
      expect(out, isA<SubmitInvalidState>());
      expect((out as SubmitInvalidState).status, 'saved');
    });

    test('takingLongThenSuccess emits TakingLong before Done', () async {
      final e = engine(FakeReadingScenario.takingLongThenSuccess);
      await e.submit(job('r1'));
      final statuses = await e.watch('r1').toList();
      expect(statuses.whereType<TakingLong>(), isNotEmpty);
      expect(statuses.last, isA<Done>());
    });

    test('fail: Failed(retryable: false), no quota use, re-submit invalid',
        () async {
      final f = engine(FakeReadingScenario.fail);
      await f.submit(job('r1'));
      final failed = (await f.watch('r1').toList()).last as Failed;
      expect(failed.retryable, isFalse);
      expect((await f.quota()).used, 0); // 횟수 미차감
      expect(await f.submit(job('r1')), isA<SubmitInvalidState>());
    });

    test('sendFail: Failed(retryable: true); same id re-submit retries',
        () async {
      final s = engine(FakeReadingScenario.sendFail);
      await s.submit(job('r1'));
      final sendFailed = (await s.watch('r1').toList()).last as Failed;
      expect(sendFailed.retryable, isTrue);
      expect(await s.submit(job('r2')), isA<SubmitAccepted>(),
          reason: 'a failed upload does not block other requests');
      await s.discard('r2');
      s.scenario = FakeReadingScenario.success;
      expect(await s.submit(job('r1')), isA<SubmitAccepted>());
      expect((await s.watch('r1').toList()).last, isA<Done>());
    });
  });

  group('submit · retryable failure re-activation (S02)', () {
    test('another active request → ActiveExists; unsaved result → ActiveExists; '
        'saved → Accepted', () async {
      final s = engine(FakeReadingScenario.sendFail);
      await s.submit(job('r1'));
      final failed = (await s.watch('r1').toList()).last as Failed;
      expect(failed.retryable, isTrue);

      // Another request is active → the failed one cannot be re-activated.
      s.scenario = FakeReadingScenario.success;
      expect(await s.submit(job('r2')), isA<SubmitAccepted>());
      final blocked = await s.submit(job('r1'));
      expect(blocked, isA<SubmitActiveExists>());
      expect((blocked as SubmitActiveExists).requestId, 'r2');
      expect(s.stateOf('r1'), FakeRequestState.failed,
          reason: 'the rejected retry leaves the failed request untouched');

      // r2 done but unsaved → still blocked (D17).
      await s.watch('r2').toList();
      expect(s.stateOf('r2'), FakeRequestState.done);
      final stillBlocked = await s.submit(job('r1'));
      expect(stillBlocked, isA<SubmitActiveExists>());
      expect((stillBlocked as SubmitActiveExists).requestId, 'r2');

      // Saved → the retry goes through and re-activates r1.
      expect(await s.save('r2', kMarks, kItems), isA<SaveSaved>());
      expect(await s.submit(job('r1')), isA<SubmitAccepted>());
      expect(s.stateOf('r1'), FakeRequestState.active);
      expect((await s.watch('r1').toList()).last, isA<Done>());
    });

    test('quota exhausted → QuotaExhausted, failed request untouched',
        () async {
      final s = FakeReadingEngine(
        scenario: FakeReadingScenario.sendFail,
        delay: Duration.zero,
        quotaLimit: 1,
      );
      await s.submit(job('r1'));
      await s.watch('r1').toList(); // failed, retryable, no quota use
      s.scenario = FakeReadingScenario.success;
      expect(await s.submit(job('r2')), isA<SubmitAccepted>());
      await s.watch('r2').toList(); // used = 1
      expect(await s.save('r2', kMarks, kItems), isA<SaveSaved>());
      expect(await s.submit(job('r1')), isA<SubmitQuotaExhausted>());
      expect(s.stateOf('r1'), FakeRequestState.failed);
    });

    test('tombstone and payload mismatch still win over the retry', () async {
      final s = engine(FakeReadingScenario.sendFail);
      await s.submit(job('r1'));
      await s.watch('r1').toList();
      expect(
        await s.submit(job('r1', photos: const <String>['other.jpg'])),
        isA<SubmitPayloadMismatch>(),
      );
      await s.discard('r1');
      expect(await s.submit(job('r1')), isA<SubmitRequestDeleted>());
    });
  });

  group('cancel', () {
    test('cancelRace: completion wins, CancelAlreadyDone, result kept',
        () async {
      final e = engine(FakeReadingScenario.cancelRace);
      await e.submit(job('r1'));
      final outcome = await e.cancel('r1');
      expect(outcome, isA<CancelAlreadyDone>());
      expect((outcome as CancelAlreadyDone).result.requestId, 'r1');
      expect((await e.watch('r1').toList()).last, isA<Done>());
      expect(e.stateOf('r1'), FakeRequestState.done);
      expect((await e.quota()).used, 1);
    });

    test('active → Cancelled; cancelled request reads as NotFound', () async {
      final e = engine(FakeReadingScenario.success);
      await e.submit(job('r1'));
      expect(await e.cancel('r1'), isA<CancelCancelled>());
      expect(await e.watch('r1').toList(), <Matcher>[isA<NotFound>()]);
      expect(await e.cancel('r1'), isA<CancelAlreadyFailed>());
      expect(await e.cancel('nope'), isA<CancelAlreadyFailed>());
    });
  });

  group('save', () {
    test('done → Saved; second save → AlreadySaved with server items',
        () async {
      final e = await savedEngine();
      final again = await e.save('r1', kMarks, kItems);
      expect(again, isA<SaveAlreadySaved>());
      expect((again as SaveAlreadySaved).serverItems.map((i) => i.id),
          <String>['w3', 'w4']);
      expect(e.stateOf('r1'), FakeRequestState.saved);
    });

    test('saveConflict: first save already reports AlreadySaved', () async {
      final c = engine(FakeReadingScenario.saveConflict);
      await c.submit(job('r1'));
      await c.watch('r1').toList();
      final out = await c.save('r1', kMarks, kItems);
      expect(out, isA<SaveAlreadySaved>());
      expect((out as SaveAlreadySaved).marks, kMarks);
      expect(c.stateOf('r1'), FakeRequestState.saved);
    });

    test('save on an active request → NotUnsaved(active)', () async {
      final e = engine(FakeReadingScenario.success);
      await e.submit(job('r1'));
      final out = await e.save('r1', kMarks, kItems);
      expect(out, isA<SaveNotUnsaved>());
      expect((out as SaveNotUnsaved).status, 'active');
    });
  });

  group('updateMarks', () {
    test('not saved → MarksNotSaved(status)', () async {
      final e = engine(FakeReadingScenario.success);
      await e.submit(job('r1'));
      await e.watch('r1').toList();
      final out = await e.updateMarks('r1', kMarks, const <ReviewEntryDraft>[]);
      expect(out, isA<MarksNotSaved>());
      expect((out as MarksNotSaved).status, 'done');
    });

    test('existing item keeps its id when its mark changes', () async {
      final e = await savedEngine();
      final out = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(pageIndex: 0, number: 3, mark: Mark.partial),
        ],
        const <ReviewEntryDraft>[],
      );
      final items = (out as MarksUpdated).items;
      expect(items.map((i) => i.id), <String>['w3', 'w4']);
      expect(items.first.mark, Mark.partial);
      expect(items.first.userConfirmed, isTrue);
    });

    test('item marked correct is removed', () async {
      final e = await savedEngine();
      final out = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(pageIndex: 0, number: 3, mark: Mark.correct),
        ],
        const <ReviewEntryDraft>[],
      );
      expect((out as MarksUpdated).items.map((i) => i.id), <String>['w4']);
    });

    test('newly wrong item needs wrongItemId → created with the result '
        'confidence; missing id → MarksFailed', () async {
      final e = await savedEngine();
      final missing = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(pageIndex: 1, number: 12, mark: Mark.wrong),
        ],
        const <ReviewEntryDraft>[],
      );
      expect(missing, isA<MarksFailed>());
      expect((missing as MarksFailed).reason, startsWith('missing_wrong_item_id'));
      expect(e.stateOf('r1'), FakeRequestState.saved);

      final out = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(
            pageIndex: 1,
            number: 12,
            mark: Mark.wrong,
            wrongItemId: 'w12',
          ),
        ],
        const <ReviewEntryDraft>[],
      );
      final items = (out as MarksUpdated).items;
      expect(items.map((i) => i.id), <String>['w3', 'w4', 'w12']);
      expect(items.last.confidence, 0.48);
      expect(items.last.userConfirmed, isTrue);
    });

    test('reusing an existing id for a new item is rejected (D16)', () async {
      final e = await savedEngine();
      final out = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(pageIndex: 1, number: 14, mark: Mark.wrong, wrongItemId: 'w3'),
        ],
        const <ReviewEntryDraft>[],
      );
      expect(out, isA<MarksFailed>());
      expect((out as MarksFailed).reason, startsWith('wrong_item_id_reused'));
    });

    test('a tombstoned wrong_item id is never reused (D16)', () async {
      final e = await savedEngine();
      // 3 → correct: w3 is soft-deleted and its id becomes a tombstone.
      final removed = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(pageIndex: 0, number: 3, mark: Mark.correct),
        ],
        const <ReviewEntryDraft>[],
      );
      expect((removed as MarksUpdated).items.map((i) => i.id), <String>['w4']);

      // 3 → wrong again with the old id → rejected, nothing applied.
      final reused = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(
            pageIndex: 0,
            number: 3,
            mark: Mark.wrong,
            wrongItemId: 'w3',
          ),
        ],
        const <ReviewEntryDraft>[],
      );
      expect(reused, isA<MarksFailed>());
      expect(
        (reused as MarksFailed).reason,
        startsWith('wrong_item_id_tombstoned'),
      );
      final unchanged = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[],
        const <ReviewEntryDraft>[],
      );
      expect((unchanged as MarksUpdated).items.map((i) => i.id), <String>['w4']);

      // A fresh uuid is accepted (X→O→X).
      final fresh = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(
            pageIndex: 0,
            number: 3,
            mark: Mark.wrong,
            wrongItemId: 'w3b',
          ),
        ],
        const <ReviewEntryDraft>[],
      );
      expect(
        (fresh as MarksUpdated).items.map((i) => i.id),
        <String>['w3b', 'w4'],
      );
    });

    test('two new items sharing one wrongItemId are rejected', () async {
      final e = await savedEngine();
      final out = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[
          ConfirmedMark(
            pageIndex: 1,
            number: 12,
            mark: Mark.wrong,
            wrongItemId: 'dup',
          ),
          ConfirmedMark(
            pageIndex: 1,
            number: 14,
            mark: Mark.wrong,
            wrongItemId: 'dup',
          ),
        ],
        const <ReviewEntryDraft>[],
      );
      expect(out, isA<MarksFailed>());
      expect((out as MarksFailed).reason, startsWith('wrong_item_id_duplicate'));
      // Nothing was applied — not even the first of the two.
      final again = await e.updateMarks(
        'r1',
        const <ConfirmedMark>[],
        const <ReviewEntryDraft>[],
      );
      expect((again as MarksUpdated).items.map((i) => i.id), <String>['w3', 'w4']);
    });

    test('review entries must point at resulting items', () async {
      final e = await savedEngine();
      final bad = await e.updateMarks(
        'r1',
        kMarks,
        <ReviewEntryDraft>[
          ReviewEntryDraft(
            id: 'e1',
            wrongItemId: 'ghost',
            dueAt: DateTime(2026, 10, 1),
            intervalDays: 1,
            consecutiveCorrect: 0,
          ),
        ],
      );
      expect(bad, isA<MarksFailed>());
      final ok = await e.updateMarks(
        'r1',
        kMarks,
        <ReviewEntryDraft>[
          ReviewEntryDraft(
            id: 'e1',
            wrongItemId: 'w3',
            dueAt: DateTime(2026, 10, 1),
            intervalDays: 1,
            consecutiveCorrect: 0,
          ),
        ],
      );
      expect(ok, isA<MarksUpdated>());
    });
  });
}
