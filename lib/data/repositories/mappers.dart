// Row → entity mappers (S02). A row with `deleted_at` set is a tombstone
// and is never turned into an entity (D2): every mapper returns null for it
// and [tombstoneOf] describes it instead. Content columns are asserted
// non-null only for live rows.

import '../../core/domain/entities/entities.dart';
import '../../core/domain/local_date.dart';
import '../db/app_database.dart';

SyncStamp stampOf({
  required String userId,
  required DateTime createdAt,
  required DateTime clientUpdatedAt,
  required String deviceId,
  required int clientRev,
  required int? baseServerVersion,
  required int? serverVersion,
  required int? serverSeq,
  required int purgeEpoch,
  DateTime? pendingDeleteUntil,
}) =>
    SyncStamp(
      userId: userId,
      createdAt: createdAt,
      clientUpdatedAt: clientUpdatedAt,
      deviceId: deviceId,
      clientRev: clientRev,
      baseServerVersion: baseServerVersion,
      serverVersion: serverVersion,
      serverSeq: serverSeq,
      purgeEpoch: purgeEpoch,
      pendingDeleteUntil: pendingDeleteUntil,
    );

Tombstone tombstoneOf(
  String table,
  String id,
  DateTime deletedAt, [
  Map<String, String?> keepKeys = const <String, String?>{},
]) =>
    Tombstone(table: table, id: id, deletedAt: deletedAt, keepKeys: keepKeys);

Subject? subjectOf(SubjectRow r) {
  if (r.deletedAt != null) return null;
  return Subject(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
      pendingDeleteUntil: r.pendingDeleteUntil,
    ),
    name: r.name!,
    colorIndex: r.colorIndex!,
    sortOrder: r.sortOrder!,
    isDefault: r.isDefault ?? false,
  );
}

StudySession? sessionOf(SessionRow r) {
  if (r.deletedAt != null) return null;
  return StudySession(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
      pendingDeleteUntil: r.pendingDeleteUntil,
    ),
    subjectId: r.subjectId,
    plannerItemId: r.plannerItemId,
    kind: r.kind!,
    mode: r.mode!,
    startedAt: r.startedAt!,
    endedAt: r.endedAt,
    status: r.status!,
    seatedSeconds: r.seatedSeconds!,
    sensitivityLevel: r.sensitivityLevel!,
    note: r.note,
  );
}

SessionSegment? segmentOf(SessionSegmentRow r) {
  if (r.deletedAt != null) return null;
  return SessionSegment(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
    ),
    sessionId: r.sessionId,
    kind: r.kind!,
    startAt: r.startAt!,
    endAt: r.endAt!,
    corrected: r.corrected ?? false,
  );
}

Correction? correctionOf(CorrectionRow r) {
  if (r.deletedAt != null) return null;
  return Correction(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
    ),
    sessionId: r.sessionId,
    segmentId: r.segmentId!,
    fromKind: r.fromKind!,
    toKind: r.toKind!,
    at: r.at!,
    sensitivityBefore: r.sensitivityBefore!,
    sensitivityAfter: r.sensitivityAfter!,
  );
}

PlannerItem? plannerItemOf(PlannerItemRow r) {
  if (r.deletedAt != null) return null;
  return PlannerItem(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
      pendingDeleteUntil: r.pendingDeleteUntil,
    ),
    kind: r.kind!,
    title: r.title!,
    subjectId: r.subjectId,
    rangeText: r.rangeText,
    targetMinutes: r.targetMinutes,
    date: LocalDate.parse(r.date!),
    startTime: LocalTime.tryParse(r.startTime),
    endTime: LocalTime.tryParse(r.endTime),
    isDone: r.isDone ?? false,
    doneAt: r.doneAt,
    recurrenceId: r.recurrenceId,
    bandStart: LocalDate.tryParse(r.bandStart),
    bandEnd: LocalDate.tryParse(r.bandEnd),
    sortOrder: r.sortOrder ?? 0,
  );
}

Recurrence? recurrenceOf(RecurrenceRow r) {
  if (r.deletedAt != null) return null;
  return Recurrence(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
      pendingDeleteUntil: r.pendingDeleteUntil,
    ),
    title: r.title!,
    subjectId: r.subjectId,
    weekdayMask: r.weekdayMask!,
    startTime: LocalTime.parse(r.startTime!),
    endTime: LocalTime.parse(r.endTime!),
    endsOn: LocalDate.tryParse(r.endsOn),
    active: r.active ?? true,
  );
}

ReadingRequest? readingRequestOf(ReadingRequestRow r) {
  if (r.deletedAt != null) return null;
  return ReadingRequest(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
    ),
    requestId: r.requestId,
    subjectId: r.subjectId!,
    rangeText: r.rangeText!,
    sessionId: r.sessionId,
    plannerItemId: r.plannerItemId,
    origin: r.origin!,
    payloadHash: r.payloadHash,
    status: r.status!,
    submittedAt: r.submittedAt,
    completedAt: r.completedAt,
    quotaMonth: r.quotaMonth,
    quotaCharged: r.quotaCharged ?? false,
    resultJson: r.resultJson,
    marksJson: r.marksJson,
    failReason: r.failReason,
    confirmedMarksJson: r.confirmedMarksJson,
  );
}

Photo photoOf(PhotoRow r) => Photo(
      id: r.id,
      userId: r.userId,
      requestId: r.requestId,
      localPath: r.localPath,
      takenAt: r.takenAt,
      expiresAt: r.expiresAt,
      width: r.width,
      height: r.height,
      pageIndex: r.pageIndex,
      createdAt: r.createdAt,
      deletedAt: r.deletedAt,
    );

WrongItem? wrongItemOf(WrongItemRow r) {
  if (r.deletedAt != null) return null;
  return WrongItem(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
    ),
    requestId: r.requestId,
    subjectId: r.subjectId!,
    rangeText: r.rangeText!,
    pageIndex: r.pageIndex!,
    number: r.number!,
    mark: r.mark!,
    confidence: r.confidence!,
    userConfirmed: r.userConfirmed ?? false,
    status: r.status!,
    resolvedAt: r.resolvedAt,
  );
}

ReviewEntry? reviewEntryOf(ReviewEntryRow r) {
  if (r.deletedAt != null) return null;
  return ReviewEntry(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
    ),
    wrongItemId: r.wrongItemId,
    dueAt: r.dueAt!,
    intervalDays: r.intervalDays!,
    consecutiveCorrect: r.consecutiveCorrect!,
    lastResult: r.lastResult,
  );
}

RetryRecord? retryRecordOf(RetryRecordRow r) {
  if (r.deletedAt != null) return null;
  return RetryRecord(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
    ),
    wrongItemId: r.wrongItemId,
    result: r.result!,
    at: r.at!,
    voided: r.voided ?? false,
    voidedAt: r.voidedAt,
  );
}

ActivityDay? activityDayOf(ActivityDayRow r) {
  if (r.deletedAt != null) return null;
  return ActivityDay(
    id: r.id,
    stamp: stampOf(
      userId: r.userId,
      createdAt: r.createdAt,
      clientUpdatedAt: r.clientUpdatedAt,
      deviceId: r.deviceId,
      clientRev: r.clientRev,
      baseServerVersion: r.baseServerVersion,
      serverVersion: r.serverVersion,
      serverSeq: r.serverSeq,
      purgeEpoch: r.purgeEpoch,
    ),
    date: LocalDate.parse(r.date),
  );
}

/// Drops nulls (tombstones) from a mapped list.
List<T> liveOnly<T>(Iterable<T?> items) => <T>[for (final i in items) ?i];
