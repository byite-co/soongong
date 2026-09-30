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

void main() {
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
      done.result.pages.expand((p) => p.items).every((i) => i.mark == Mark.correct),
      isTrue,
    );
  });

  test('submit is idempotent; a different payload is PayloadMismatch',
      () async {
    final e = engine(FakeReadingScenario.success);
    expect(await e.submit(job('r1')), isA<SubmitAccepted>());
    expect(await e.submit(job('r1')), isA<SubmitAccepted>());
    expect(
      await e.submit(job('r1', photos: const <String>['z.jpg'])),
      isA<SubmitPayloadMismatch>(),
    );
    expect(await e.submit(job('r2')), isA<SubmitActiveExists>());
  });

  test('watch of an unknown id → NotFound; after discard → Deleted', () async {
    final e = engine(FakeReadingScenario.success);
    expect(await e.watch('nope').toList(), <Matcher>[isA<NotFound>()]);
    await e.submit(job('r1'));
    await e.watch('r1').toList();
    await e.discard('r1');
    expect(await e.watch('r1').toList(), <Matcher>[isA<Deleted>()]);
    expect(await e.submit(job('r1')), isA<SubmitRequestDeleted>());
  });

  test('takingLongThenSuccess emits TakingLong before Done', () async {
    final e = engine(FakeReadingScenario.takingLongThenSuccess);
    await e.submit(job('r1'));
    final statuses = await e.watch('r1').toList();
    expect(statuses.whereType<TakingLong>(), isNotEmpty);
    expect(statuses.last, isA<Done>());
  });

  test('fail: Failed(retryable: false); sendFail: Failed(retryable: true)',
      () async {
    final f = engine(FakeReadingScenario.fail);
    await f.submit(job('r1'));
    final failed = (await f.watch('r1').toList()).last as Failed;
    expect(failed.retryable, isFalse);
    expect((await f.quota()).used, 0); // 횟수 미차감

    final s = engine(FakeReadingScenario.sendFail);
    await s.submit(job('r1'));
    final sendFailed = (await s.watch('r1').toList()).last as Failed;
    expect(sendFailed.retryable, isTrue);
  });

  test('cancelRace: completion wins, result kept', () async {
    final e = engine(FakeReadingScenario.cancelRace);
    await e.submit(job('r1'));
    final outcome = await e.cancel('r1');
    expect(outcome, isA<CancelAlreadyDone>());
    expect((await e.watch('r1').toList()).last, isA<Done>());
  });

  test('cancel of an active request → Cancelled', () async {
    final e = engine(FakeReadingScenario.success);
    await e.submit(job('r1'));
    expect(await e.cancel('r1'), isA<CancelCancelled>());
  });

  test('save then updateMarks; saveConflict → AlreadySaved', () async {
    final e = engine(FakeReadingScenario.success);
    await e.submit(job('r1'));
    await e.watch('r1').toList();
    const marks = <ConfirmedMark>[
      ConfirmedMark(pageIndex: 0, number: 3, mark: Mark.wrong, wrongItemId: 'w1'),
    ];
    const items = <WrongItemDraft>[
      WrongItemDraft(
        id: 'w1',
        pageIndex: 0,
        number: 3,
        mark: Mark.wrong,
        confidence: 0.52,
        userConfirmed: true,
      ),
    ];
    expect(await e.save('r1', marks, items), isA<SaveSaved>());
    expect(await e.save('r1', marks, items), isA<SaveAlreadySaved>());
    final upd = await e.updateMarks(
      'r1',
      const <ConfirmedMark>[
        ConfirmedMark(pageIndex: 0, number: 3, mark: Mark.partial, wrongItemId: 'w1'),
      ],
      const <ReviewEntryDraft>[],
    );
    expect(upd, isA<MarksUpdated>());
    expect((upd as MarksUpdated).items.single.mark, Mark.partial);

    final c = engine(FakeReadingScenario.saveConflict);
    await c.submit(job('r1'));
    await c.watch('r1').toList();
    expect(await c.save('r1', marks, items), isA<SaveAlreadySaved>());
  });
}
