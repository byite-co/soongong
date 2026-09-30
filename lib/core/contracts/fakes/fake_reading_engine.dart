// Fake ReadingEngine (S01). Scenario + delay are chosen in the dev menu.
// The sample result is fixed and contains 3 low-confidence items.

import 'dart:async';
import 'dart:ui' show Rect;

import '../reading_engine.dart';

enum FakeReadingScenario {
  success,
  successZeroWrong,
  takingLongThenSuccess,
  fail,
  sendFail,
  cancelRace,
  saveConflict,
}

enum _FakeRequestState { active, done, failed, saved, discarded, cancelled }

class _FakeRequest {
  _FakeRequest(this.job, this.payloadKey);

  final ReadingJob job;
  final String payloadKey;
  _FakeRequestState state = _FakeRequestState.active;
  ReadingResult? result;
  List<ConfirmedMark> marks = const <ConfirmedMark>[];
  List<WrongItemDraft> items = const <WrongItemDraft>[];
}

class FakeReadingEngine implements ReadingEngine {
  FakeReadingEngine({
    this.scenario = FakeReadingScenario.success,
    this.delay = const Duration(milliseconds: 600),
    this.quotaLimit = 20,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  FakeReadingScenario scenario;

  /// Delay between status steps.
  Duration delay;

  final int quotaLimit;
  final DateTime Function() _now;
  final Map<String, _FakeRequest> _requests = <String, _FakeRequest>{};
  final Set<String> _tombstones = <String>{};
  int _used = 0;

  static String payloadKeyOf(ReadingJob job) =>
      '${job.subjectId}|${job.rangeText}|${job.photoPaths.join(',')}|${job.origin}';

  @override
  Future<SubmitOutcome> submit(ReadingJob job) async {
    await Future<void>.delayed(delay);
    if (_tombstones.contains(job.requestId)) {
      return const SubmitRequestDeleted();
    }
    final key = payloadKeyOf(job);
    final existing = _requests[job.requestId];
    if (existing != null) {
      if (existing.payloadKey != key) return const SubmitPayloadMismatch();
      return switch (existing.state) {
        _FakeRequestState.active || _FakeRequestState.done => const SubmitAccepted(),
        _FakeRequestState.saved => const SubmitInvalidState('saved'),
        _FakeRequestState.discarded => const SubmitRequestDeleted(),
        _FakeRequestState.failed => const SubmitAccepted(),
        _FakeRequestState.cancelled => const SubmitInvalidState('cancelled'),
      };
    }
    final active = _requests.values
        .where((r) => r.state == _FakeRequestState.active)
        .toList();
    if (active.isNotEmpty) return SubmitActiveExists(active.first.job.requestId);
    if (_used >= quotaLimit) return const SubmitQuotaExhausted();
    if (job.photoPaths.isEmpty) return const SubmitPayloadMismatch();
    _requests[job.requestId] = _FakeRequest(job, key);
    return const SubmitAccepted();
  }

  @override
  Stream<ReadingStatus> watch(String requestId) async* {
    if (_tombstones.contains(requestId)) {
      yield const Deleted();
      return;
    }
    final req = _requests[requestId];
    if (req == null) {
      yield const NotFound();
      return;
    }
    switch (req.state) {
      case _FakeRequestState.done:
      case _FakeRequestState.saved:
        yield Done(req.result!);
        return;
      case _FakeRequestState.failed:
        yield const Failed('reading_failed', retryable: false);
        return;
      case _FakeRequestState.discarded:
        yield const Deleted();
        return;
      case _FakeRequestState.cancelled:
        yield const NotFound();
        return;
      case _FakeRequestState.active:
        break;
    }

    // Upload
    for (final p in <double>[0.2, 0.6]) {
      yield Sending(p);
      await Future<void>.delayed(delay);
      if (req.state != _FakeRequestState.active) break;
    }
    if (scenario == FakeReadingScenario.sendFail) {
      req.state = _FakeRequestState.failed;
      yield const Failed('upload_failed', retryable: true);
      return;
    }
    yield const Sending(1);
    await Future<void>.delayed(delay);

    // Processing
    final startedAt = _now();
    yield Processing(startedAt);
    await Future<void>.delayed(delay);
    if (scenario == FakeReadingScenario.takingLongThenSuccess) {
      yield const TakingLong();
      await Future<void>.delayed(delay * 3);
    }
    if (req.state == _FakeRequestState.cancelled) {
      yield const NotFound();
      return;
    }
    if (scenario == FakeReadingScenario.fail) {
      req.state = _FakeRequestState.failed;
      yield const Failed('reading_failed', retryable: false);
      return;
    }
    _complete(req);
    yield Done(req.result!);
  }

  void _complete(_FakeRequest req) {
    if (req.state != _FakeRequestState.active) return;
    req.state = _FakeRequestState.done;
    req.result = sampleResult(
      req.job,
      _now(),
      zeroWrong: scenario == FakeReadingScenario.successZeroWrong,
    );
    _used++;
  }

  @override
  Future<CancelOutcome> cancel(String requestId) async {
    await Future<void>.delayed(delay);
    final req = _requests[requestId];
    if (req == null) return const CancelAlreadyFailed();
    if (scenario == FakeReadingScenario.cancelRace &&
        req.state == _FakeRequestState.active) {
      _complete(req); // completion wins the race
    }
    return switch (req.state) {
      _FakeRequestState.active => () {
          req.state = _FakeRequestState.cancelled;
          return const CancelCancelled();
        }(),
      _FakeRequestState.done || _FakeRequestState.saved =>
        CancelAlreadyDone(req.result!),
      _ => const CancelAlreadyFailed(),
    };
  }

  @override
  Future<SaveOutcome> save(
    String requestId,
    List<ConfirmedMark> marks,
    List<WrongItemDraft> items,
  ) async {
    await Future<void>.delayed(delay);
    final req = _requests[requestId];
    if (req == null) return const SaveFailed('not_found');
    if (scenario == FakeReadingScenario.saveConflict &&
        req.state == _FakeRequestState.done) {
      req.state = _FakeRequestState.saved;
      req.marks = marks;
      req.items = items;
      return SaveAlreadySaved(marks: req.marks, serverItems: req.items);
    }
    return switch (req.state) {
      _FakeRequestState.done => () {
          req.state = _FakeRequestState.saved;
          req.marks = marks;
          req.items = items;
          return const SaveSaved();
        }(),
      _FakeRequestState.saved =>
        SaveAlreadySaved(marks: req.marks, serverItems: req.items),
      _ => SaveNotUnsaved(req.state.name),
    };
  }

  @override
  Future<UpdateMarksOutcome> updateMarks(
    String requestId,
    List<ConfirmedMark> marks,
    List<ReviewEntryDraft> entries,
  ) async {
    await Future<void>.delayed(delay);
    final req = _requests[requestId];
    if (req == null) return const MarksFailed('not_found');
    if (req.state != _FakeRequestState.saved) {
      return MarksNotSaved(req.state.name);
    }
    req.marks = marks;
    final byKey = <String, ConfirmedMark>{
      for (final m in marks) '${m.pageIndex}:${m.number}': m,
    };
    req.items = req.items
        .map(
          (it) {
            final m = byKey['${it.pageIndex}:${it.number}'];
            return m == null
                ? it
                : WrongItemDraft(
                    id: it.id,
                    pageIndex: it.pageIndex,
                    number: it.number,
                    mark: m.mark,
                    confidence: it.confidence,
                    userConfirmed: true,
                  );
          },
        )
        .toList();
    return MarksUpdated(req.items);
  }

  @override
  Future<void> discard(String requestId) async {
    await Future<void>.delayed(delay);
    final req = _requests.remove(requestId);
    if (req != null) {
      req.state = _FakeRequestState.discarded;
      req.result = null;
    }
    _tombstones.add(requestId);
  }

  @override
  Future<QuotaSnapshot> quota() async {
    final reserved =
        _requests.values.where((r) => r.state == _FakeRequestState.active).length;
    return QuotaSnapshot(
      used: _used,
      reserved: reserved,
      limit: quotaLimit,
      fetchedAt: _now(),
    );
  }

  /// Fixed sample: 2 pages, 3 low-confidence items (numbers 3, 7, 12).
  static ReadingResult sampleResult(
    ReadingJob job,
    DateTime completedAt, {
    bool zeroWrong = false,
  }) {
    ReadingItem item(int n, Mark mark, double conf, double top) => ReadingItem(
          number: n,
          mark: zeroWrong ? Mark.correct : mark,
          confidence: conf,
          box: Rect.fromLTWH(0.08, top, 0.84, 0.06),
        );
    final page0 = <ReadingItem>[
      item(1, Mark.correct, 0.98, 0.10),
      item(2, Mark.correct, 0.97, 0.18),
      item(3, Mark.wrong, 0.52, 0.26), // low confidence
      item(4, Mark.wrong, 0.91, 0.34),
      item(5, Mark.correct, 0.96, 0.42),
      item(6, Mark.partial, 0.88, 0.50),
      item(7, Mark.unsolved, 0.41, 0.58), // low confidence
      item(8, Mark.correct, 0.95, 0.66),
    ];
    final page1 = <ReadingItem>[
      item(9, Mark.correct, 0.97, 0.10),
      item(10, Mark.guessed, 0.83, 0.18),
      item(11, Mark.correct, 0.96, 0.26),
      item(12, Mark.wrong, 0.48, 0.34), // low confidence
      item(13, Mark.correct, 0.99, 0.42),
      item(14, Mark.wrong, 0.9, 0.50),
    ];
    final paths = job.photoPaths;
    return ReadingResult(
      requestId: job.requestId,
      pages: <ReadingPage>[
        ReadingPage(
          index: 0,
          photoPath: paths.isNotEmpty ? paths[0] : 'fake://page0',
          items: page0,
        ),
        ReadingPage(
          index: 1,
          photoPath: paths.length > 1 ? paths[1] : 'fake://page1',
          items: page1,
        ),
      ],
      completedAt: completedAt,
    );
  }
}
