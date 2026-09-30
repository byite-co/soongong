// ReadingEngine contract (S01). Signatures are frozen — changes require the
// CONTRACT-CHANGE procedure (CLAUDE.md §8). Server-side ledger rules: D16.

import 'dart:ui' show Rect;

class ReadingJob {
  const ReadingJob({
    required this.requestId,
    required this.subjectId,
    required this.rangeText,
    required this.photoPaths,
    required this.origin,
    this.sessionId,
    this.plannerItemId,
  });

  final String requestId;
  final String subjectId;
  final String rangeText;
  final List<String> photoPaths;

  /// planner | wrongs | home
  final String origin;
  final String? sessionId;
  final String? plannerItemId;
}

sealed class ReadingStatus {
  const ReadingStatus();
}

/// Server 410 request_deleted.
class Deleted extends ReadingStatus {
  const Deleted();
}

/// Server 404.
class NotFound extends ReadingStatus {
  const NotFound();
}

class Sending extends ReadingStatus {
  const Sending(this.progress);

  /// 0.0 – 1.0
  final double progress;
}

class Processing extends ReadingStatus {
  const Processing(this.startedAt);

  final DateTime startedAt;
}

class TakingLong extends ReadingStatus {
  const TakingLong();
}

class Failed extends ReadingStatus {
  const Failed(this.reason, {required this.retryable});

  final String reason;
  final bool retryable;
}

class Done extends ReadingStatus {
  const Done(this.result);

  final ReadingResult result;
}

enum Mark { correct, wrong, partial, unsolved, guessed }

class ReadingItem {
  const ReadingItem({
    required this.number,
    required this.mark,
    required this.confidence,
    this.box,
  });

  final int number;
  final Mark mark;
  final double confidence;
  final Rect? box;
}

/// A user-confirmed mark. A new uuid is issued by the client only for items
/// that newly become non-correct; items that keep existing keep their
/// [wrongItemId]. Tombstone ids are never reused (D16).
class ConfirmedMark {
  const ConfirmedMark({
    required this.pageIndex,
    required this.number,
    required this.mark,
    this.wrongItemId,
  });

  final int pageIndex;
  final int number;
  final Mark mark;
  final String? wrongItemId;
}

class WrongItemDraft {
  const WrongItemDraft({
    required this.id,
    required this.pageIndex,
    required this.number,
    required this.mark,
    required this.confidence,
    required this.userConfirmed,
  });

  final String id;
  final int pageIndex;
  final int number;
  final Mark mark;
  final double confidence;
  final bool userConfirmed;
}

class ReviewEntryDraft {
  const ReviewEntryDraft({
    required this.id,
    required this.wrongItemId,
    required this.dueAt,
    required this.intervalDays,
    required this.consecutiveCorrect,
  });

  final String id;
  final String wrongItemId;
  final DateTime dueAt;
  final int intervalDays;
  final int consecutiveCorrect;
}

class ReadingPage {
  const ReadingPage({
    required this.index,
    required this.photoPath,
    required this.items,
  });

  final int index;
  final String photoPath;
  final List<ReadingItem> items;
}

class ReadingResult {
  const ReadingResult({
    required this.requestId,
    required this.pages,
    required this.completedAt,
  });

  final String requestId;
  final List<ReadingPage> pages;
  final DateTime completedAt;
}

/// Server quota cache (used · reserved · limit). Never computed on the
/// client (D16 · D24).
class QuotaSnapshot {
  const QuotaSnapshot({
    required this.used,
    required this.reserved,
    required this.limit,
    required this.fetchedAt,
  });

  final int used;
  final int reserved;
  final int limit;
  final DateTime fetchedAt;

  int get remaining => (limit - used - reserved).clamp(0, limit);
}

// ---------------------------------------------------------------------------
// Outcomes. Variant names carry the outcome prefix so the four hierarchies can
// be imported together without collisions (S01 decision; see decisions.md).

sealed class SubmitOutcome {
  const SubmitOutcome();
}

class SubmitAccepted extends SubmitOutcome {
  const SubmitAccepted();
}

class SubmitQuotaExhausted extends SubmitOutcome {
  const SubmitQuotaExhausted();
}

class SubmitActiveExists extends SubmitOutcome {
  const SubmitActiveExists(this.requestId);

  final String requestId;
}

class SubmitPayloadMismatch extends SubmitOutcome {
  const SubmitPayloadMismatch();
}

class SubmitRequestDeleted extends SubmitOutcome {
  const SubmitRequestDeleted();
}

class SubmitInvalidState extends SubmitOutcome {
  const SubmitInvalidState(this.status);

  /// Server-side state name.
  final String status;
}

class SubmitNotEntitled extends SubmitOutcome {
  const SubmitNotEntitled();
}

class SubmitConsentRequired extends SubmitOutcome {
  const SubmitConsentRequired();
}

class SubmitOffline extends SubmitOutcome {
  const SubmitOffline();
}

sealed class CancelOutcome {
  const CancelOutcome();
}

class CancelCancelled extends CancelOutcome {
  const CancelCancelled();
}

/// Completion won the race — the result is kept.
class CancelAlreadyDone extends CancelOutcome {
  const CancelAlreadyDone(this.result);

  final ReadingResult result;
}

class CancelAlreadyFailed extends CancelOutcome {
  const CancelAlreadyFailed();
}

sealed class SaveOutcome {
  const SaveOutcome();
}

class SaveSaved extends SaveOutcome {
  const SaveSaved();
}

class SaveAlreadySaved extends SaveOutcome {
  const SaveAlreadySaved({required this.marks, required this.serverItems});

  final List<ConfirmedMark> marks;
  final List<WrongItemDraft> serverItems;
}

class SaveNotUnsaved extends SaveOutcome {
  const SaveNotUnsaved(this.status);

  final String status;
}

class SaveOffline extends SaveOutcome {
  const SaveOffline();
}

class SaveFailed extends SaveOutcome {
  const SaveFailed(this.reason);

  final String reason;
}

sealed class UpdateMarksOutcome {
  const UpdateMarksOutcome();
}

class MarksUpdated extends UpdateMarksOutcome {
  const MarksUpdated(this.items);

  final List<WrongItemDraft> items;
}

class MarksNotSaved extends UpdateMarksOutcome {
  const MarksNotSaved(this.status);

  final String status;
}

class MarksOffline extends UpdateMarksOutcome {
  const MarksOffline();
}

class MarksFailed extends UpdateMarksOutcome {
  const MarksFailed(this.reason);

  final String reason;
}

abstract class ReadingEngine {
  /// Same requestId + same payload re-call is idempotent (returns the
  /// existing state).
  Future<SubmitOutcome> submit(ReadingJob job);

  /// reading-status polling. On Deleted/NotFound the stream closes, the local
  /// tombstone is applied and there is no retry.
  Stream<ReadingStatus> watch(String requestId);

  /// Returns the final state — if completion won, the result is kept.
  Future<CancelOutcome> cancel(String requestId);

  /// Server-owned transition to `saved`; marks_json is finalised (D16).
  Future<SaveOutcome> save(
    String requestId,
    List<ConfirmedMark> marks,
    List<WrongItemDraft> items,
  );

  /// Mark edits after save (D16, online only).
  Future<UpdateMarksOutcome> updateMarks(
    String requestId,
    List<ConfirmedMark> marks,
    List<ReviewEntryDraft> entries,
  );

  /// Server-owned transition to `discarded` + result_json deleted.
  Future<void> discard(String requestId);

  /// Server cache (used · reserved · limit).
  Future<QuotaSnapshot> quota();
}
