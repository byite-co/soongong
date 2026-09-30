// Fake ReadingEngine (S01 · S01b). Scenario + delay are chosen in the dev
// menu. The sample result is fixed and contains 3 low-confidence items.
//
// submit() order (S01b · S02 · D16/D17): tombstone → same-id idempotency →
// active request exists → unsaved (done) result exists → quota →
// (re-activate a retryable failure | register a new request). A retryable
// failure is re-activated only after it passed the same active / unsaved /
// quota checks as a brand-new request.

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

/// Server-side state names. `done` = completed but not yet saved
/// (`done_unsaved` on the server, D17: blocks new requests).
enum FakeRequestState { active, done, failed, saved, discarded, cancelled }

class _FakeRequest {
  _FakeRequest(this.job, this.payloadKey);

  final ReadingJob job;
  final String payloadKey;
  FakeRequestState state = FakeRequestState.active;
  bool retryable = false;
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

  /// wrong_item ids that were soft-deleted by [updateMarks] (an item that
  /// became correct). Never reused (D16).
  final Set<String> _wrongItemTombstones = <String>{};
  int _used = 0;

  static String payloadKeyOf(ReadingJob job) =>
      '${job.subjectId}|${job.rangeText}|${job.photoPaths.join(',')}|${job.origin}';

  /// Server state name of a request (dev/test aid).
  FakeRequestState? stateOf(String requestId) => _requests[requestId]?.state;

  @override
  Future<SubmitOutcome> submit(ReadingJob job) async {
    await Future<void>.delayed(delay);

    // 1. tombstone (server 410 request_deleted)
    if (_tombstones.contains(job.requestId)) {
      return const SubmitRequestDeleted();
    }

    // 2. same requestId → idempotent (same payload) / mismatch. A retryable
    //    failure falls through: re-activation must pass steps 3–5 first.
    final key = payloadKeyOf(job);
    final existing = _requests[job.requestId];
    if (existing != null) {
      if (existing.payloadKey != key) return const SubmitPayloadMismatch();
      switch (existing.state) {
        case FakeRequestState.active:
        case FakeRequestState.done:
          return const SubmitAccepted();
        case FakeRequestState.failed:
          if (!existing.retryable) return const SubmitInvalidState('failed');
          break; // retryable → 3–5, then 6 re-activates
        case FakeRequestState.saved:
          return const SubmitInvalidState('saved');
        case FakeRequestState.discarded:
          return const SubmitRequestDeleted();
        case FakeRequestState.cancelled:
          return const SubmitInvalidState('cancelled');
      }
    }

    // 3. another active request
    final active = _firstIn(FakeRequestState.active);
    if (active != null) return SubmitActiveExists(active.job.requestId);

    // 4. an unsaved result blocks new requests (D17)
    final unsaved = _firstIn(FakeRequestState.done);
    if (unsaved != null) return SubmitActiveExists(unsaved.job.requestId);

    // 5. quota
    if (_used >= quotaLimit) return const SubmitQuotaExhausted();
    if (job.photoPaths.isEmpty) return const SubmitPayloadMismatch();

    // 6. re-activate the retryable failure, or register a new request. Every
    //    scenario accepts; the status stream carries the rest.
    if (existing != null) {
      existing
        ..state = FakeRequestState.active
        ..retryable = false;
      return const SubmitAccepted();
    }
    _requests[job.requestId] = _FakeRequest(job, key);
    return const SubmitAccepted();
  }

  _FakeRequest? _firstIn(FakeRequestState state) {
    for (final r in _requests.values) {
      if (r.state == state) return r;
    }
    return null;
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
      case FakeRequestState.done:
      case FakeRequestState.saved:
        yield Done(req.result!);
        return;
      case FakeRequestState.failed:
        yield Failed(
          req.retryable ? 'upload_failed' : 'reading_failed',
          retryable: req.retryable,
        );
        return;
      case FakeRequestState.discarded:
        yield const Deleted();
        return;
      case FakeRequestState.cancelled:
        yield const NotFound();
        return;
      case FakeRequestState.active:
        break;
    }

    // Upload
    for (final p in <double>[0.2, 0.6]) {
      yield Sending(p);
      await Future<void>.delayed(delay);
      if (req.state != FakeRequestState.active) break;
    }
    if (scenario == FakeReadingScenario.sendFail) {
      req
        ..state = FakeRequestState.failed
        ..retryable = true;
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
    if (req.state == FakeRequestState.cancelled) {
      yield const NotFound();
      return;
    }
    if (scenario == FakeReadingScenario.fail) {
      req
        ..state = FakeRequestState.failed
        ..retryable = false;
      yield const Failed('reading_failed', retryable: false);
      return;
    }
    _complete(req);
    yield Done(req.result!);
  }

  void _complete(_FakeRequest req) {
    if (req.state != FakeRequestState.active) return;
    req.state = FakeRequestState.done;
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
        req.state == FakeRequestState.active) {
      _complete(req); // completion wins the race
    }
    switch (req.state) {
      case FakeRequestState.active:
        req.state = FakeRequestState.cancelled;
        return const CancelCancelled();
      case FakeRequestState.done:
      case FakeRequestState.saved:
        return CancelAlreadyDone(req.result!);
      case FakeRequestState.failed:
      case FakeRequestState.discarded:
      case FakeRequestState.cancelled:
        return const CancelAlreadyFailed();
    }
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
        req.state == FakeRequestState.done) {
      // The server already holds a save for this request (e.g. a retried
      // save whose first attempt succeeded): transition happened server-side.
      req
        ..state = FakeRequestState.saved
        ..marks = marks
        ..items = items;
      return SaveAlreadySaved(marks: req.marks, serverItems: req.items);
    }
    switch (req.state) {
      case FakeRequestState.done:
        req
          ..state = FakeRequestState.saved
          ..marks = marks
          ..items = items;
        return const SaveSaved();
      case FakeRequestState.saved:
        return SaveAlreadySaved(marks: req.marks, serverItems: req.items);
      case FakeRequestState.active:
      case FakeRequestState.failed:
      case FakeRequestState.discarded:
      case FakeRequestState.cancelled:
        return SaveNotUnsaved(req.state.name);
    }
  }

  /// Applies the full mark set to the saved items (D16):
  /// - an item that newly becomes non-correct → new [WrongItemDraft] using
  ///   `ConfirmedMark.wrongItemId` (missing id → [MarksFailed]);
  /// - an item that becomes correct → removed (its id becomes a tombstone);
  /// - an item that stays non-correct → mark updated, id kept;
  /// - items not mentioned in [marks] are left untouched.
  ///
  /// Rejected with [MarksFailed] (nothing applied): a new id that is already
  /// in use, a new id that is a tombstone (X→O→X must bring a fresh uuid), and
  /// two new items sharing one id in the same call.
  @override
  Future<UpdateMarksOutcome> updateMarks(
    String requestId,
    List<ConfirmedMark> marks,
    List<ReviewEntryDraft> entries,
  ) async {
    await Future<void>.delayed(delay);
    final req = _requests[requestId];
    if (req == null) return const MarksFailed('not_found');
    if (req.state != FakeRequestState.saved) {
      return MarksNotSaved(req.state.name);
    }

    String keyOf(int page, int number) => '$page:$number';
    final byKey = <String, WrongItemDraft>{
      for (final it in req.items) keyOf(it.pageIndex, it.number): it,
    };
    final result = Map<String, WrongItemDraft>.of(byKey);
    final seen = <String>{};
    final newIds = <String>{};

    for (final m in marks) {
      final k = keyOf(m.pageIndex, m.number);
      if (!seen.add(k)) return MarksFailed('duplicate_mark:$k');
      final existing = byKey[k];
      if (m.mark == Mark.correct) {
        result.remove(k);
        continue;
      }
      if (existing != null) {
        result[k] = WrongItemDraft(
          id: existing.id,
          pageIndex: existing.pageIndex,
          number: existing.number,
          mark: m.mark,
          confidence: existing.confidence,
          userConfirmed: true,
        );
        continue;
      }
      final newId = m.wrongItemId;
      if (newId == null || newId.isEmpty) {
        return MarksFailed('missing_wrong_item_id:$k');
      }
      if (byKey.values.any((it) => it.id == newId)) {
        return MarksFailed('wrong_item_id_reused:$newId');
      }
      if (_wrongItemTombstones.contains(newId)) {
        return MarksFailed('wrong_item_id_tombstoned:$newId');
      }
      if (!newIds.add(newId)) {
        return MarksFailed('wrong_item_id_duplicate:$newId');
      }
      result[k] = WrongItemDraft(
        id: newId,
        pageIndex: m.pageIndex,
        number: m.number,
        mark: m.mark,
        confidence: _confidenceOf(req.result, m.pageIndex, m.number),
        userConfirmed: true,
      );
    }

    final ids = result.values.map((it) => it.id).toSet();
    for (final e in entries) {
      if (!ids.contains(e.wrongItemId)) {
        return MarksFailed('unknown_wrong_item:${e.wrongItemId}');
      }
    }

    // Items that became correct are soft-deleted on the server: keep their
    // ids as tombstones so they are never reused.
    final keptIds = result.values.map((it) => it.id).toSet();
    for (final it in byKey.values) {
      if (!keptIds.contains(it.id)) _wrongItemTombstones.add(it.id);
    }

    req
      ..marks = marks
      ..items = result.values.toList()
      ..items.sort(
        (a, b) => a.pageIndex != b.pageIndex
            ? a.pageIndex.compareTo(b.pageIndex)
            : a.number.compareTo(b.number),
      );
    return MarksUpdated(req.items);
  }

  static double _confidenceOf(ReadingResult? result, int page, int number) {
    if (result == null) return 1;
    for (final p in result.pages) {
      if (p.index != page) continue;
      for (final it in p.items) {
        if (it.number == number) return it.confidence;
      }
    }
    return 1;
  }

  @override
  Future<void> discard(String requestId) async {
    await Future<void>.delayed(delay);
    final req = _requests.remove(requestId);
    if (req != null) {
      req
        ..state = FakeRequestState.discarded
        ..result = null;
    }
    _tombstones.add(requestId);
  }

  @override
  Future<QuotaSnapshot> quota() async {
    final reserved =
        _requests.values.where((r) => r.state == FakeRequestState.active).length;
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
