import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'sync_stamp.dart';

part 'reading.freezed.dart';

/// `reading_requests` (§2.7). Server-owned columns are only ever written via
/// `applyServer`; [confirmedMarksJson] is local only. JSON columns are kept
/// as raw strings here — the reading feature (S10) decodes them.
@freezed
abstract class ReadingRequest with _$ReadingRequest {
  const factory ReadingRequest({
    required String id,
    required SyncStamp stamp,
    required String requestId,
    required String subjectId,
    required String rangeText,
    String? sessionId,
    String? plannerItemId,
    required ReadingOrigin origin,
    String? payloadHash,
    required ReadingRequestStatus status,
    DateTime? submittedAt,
    DateTime? completedAt,
    String? quotaMonth,
    @Default(false) bool quotaCharged,
    String? resultJson,
    String? marksJson,
    String? failReason,
    String? confirmedMarksJson,
  }) = _ReadingRequest;

  const ReadingRequest._();

  bool get isDraft =>
      status == ReadingRequestStatus.selecting && submittedAt == null;
}

/// `photos` (§2.8) — local only. [localPath] is relative to the app photo
/// directory and must never be logged.
@freezed
abstract class Photo with _$Photo {
  const factory Photo({
    required String id,
    required String userId,
    String? requestId,
    required String localPath,
    required DateTime takenAt,
    required DateTime expiresAt,
    required int width,
    required int height,
    required int pageIndex,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _Photo;

  const Photo._();

  bool get isDeleted => deletedAt != null;
}

/// `wrong_items` (§2.9).
@freezed
abstract class WrongItem with _$WrongItem {
  const factory WrongItem({
    required String id,
    required SyncStamp stamp,
    required String requestId,
    required String subjectId,
    required String rangeText,
    required int pageIndex,
    required int number,
    required WrongMark mark,
    required double confidence,
    required bool userConfirmed,
    @Default(WrongItemStatus.open) WrongItemStatus status,
    DateTime? resolvedAt,
  }) = _WrongItem;
}

/// `review_entries` (§2.10, D9).
@freezed
abstract class ReviewEntry with _$ReviewEntry {
  const factory ReviewEntry({
    required String id,
    required SyncStamp stamp,
    required String wrongItemId,
    required DateTime dueAt,
    required int intervalDays,
    required int consecutiveCorrect,
    RetryResult? lastResult,
  }) = _ReviewEntry;
}

/// `retry_records` (§2.11).
@freezed
abstract class RetryRecord with _$RetryRecord {
  const factory RetryRecord({
    required String id,
    required SyncStamp stamp,
    required String wrongItemId,
    required RetryResult result,
    required DateTime at,
    @Default(false) bool voided,
    DateTime? voidedAt,
  }) = _RetryRecord;
}
