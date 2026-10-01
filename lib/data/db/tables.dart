// drift tables — schema v1 (S02). Source of truth: docs/data-model.md.
//
// Conventions:
// - Sync tables mix in [SyncColumns] (D2 common fields) and, for the D22
//   undo-able ones, [PendingDeleteColumn].
// - Content columns are nullable on every sync table: a tombstone row keeps
//   only the common fields + the table's keep keys (data-model.md §3).
//   Repositories check `deleted_at` before building an entity.
// - Timestamps: ISO 8601 UTC text. Date keys: local `yyyy-MM-dd`. Times of
//   day: `HH:mm`. Enums: wire names.

import 'package:drift/drift.dart';

import '../../core/domain/enums.dart';
import 'converters.dart';

/// D2 common columns of every synchronised table.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get createdAt => text().map(const UtcDateTimeConverter())();
  TextColumn get clientUpdatedAt => text().map(const UtcDateTimeConverter())();
  TextColumn get deletedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get deviceId => text()();

  /// Local only. +1 on every user write.
  IntColumn get clientRev => integer().withDefault(const Constant(1))();

  /// Local only. Last seen server version (null = unconfirmed new row).
  IntColumn get baseServerVersion => integer().nullable()();
  IntColumn get serverVersion => integer().nullable()();
  IntColumn get serverSeq => integer().nullable()();
  IntColumn get purgeEpoch => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// D22: 5-second undo window before the delete is committed.
mixin PendingDeleteColumn on Table {
  TextColumn get pendingDeleteUntil => text().map(const NullableUtcDateTimeConverter()).nullable()();
}

// ---------------------------------------------------------------------------
// Sync tables

@DataClassName('SubjectRow')
@TableIndex(name: 'subjects_user_sort', columns: {#userId, #sortOrder})
class Subjects extends Table with SyncColumns, PendingDeleteColumn {
  TextColumn get name => text().nullable()();
  IntColumn get colorIndex => integer().nullable()();
  IntColumn get sortOrder => integer().nullable()();
  BoolColumn get isDefault => boolean().nullable()();
}

@DataClassName('SessionRow')
@TableIndex(name: 'sessions_user_started', columns: {#userId, #startedAt})
@TableIndex(name: 'sessions_user_status', columns: {#userId, #status})
class Sessions extends Table with SyncColumns, PendingDeleteColumn {
  TextColumn get subjectId => text().nullable()();
  TextColumn get plannerItemId => text().nullable()();
  TextColumn get kind =>
      text().map(const NullableWireEnumConverter(SessionKind.values)).nullable()();
  TextColumn get mode =>
      text().map(const NullableWireEnumConverter(SessionMode.values)).nullable()();
  TextColumn get startedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get endedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get status => text()
      .map(const NullableWireEnumConverter(SessionStatus.values))
      .nullable()();
  IntColumn get seatedSeconds => integer().nullable()();
  IntColumn get sensitivityLevel => integer().nullable()();
  TextColumn get note => text().nullable()();
}

@DataClassName('SessionSegmentRow')
@TableIndex(name: 'session_segments_session_start', columns: {#sessionId, #startAt})
class SessionSegments extends Table with SyncColumns {
  /// Keep key.
  TextColumn get sessionId => text()();
  TextColumn get kind =>
      text().map(const NullableWireEnumConverter(SegmentKind.values)).nullable()();
  TextColumn get startAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get endAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  BoolColumn get corrected => boolean().nullable()();
}

@DataClassName('CorrectionRow')
@TableIndex(name: 'corrections_user_at', columns: {#userId, #at})
@TableIndex(name: 'corrections_session', columns: {#sessionId})
class Corrections extends Table with SyncColumns {
  /// Keep key.
  TextColumn get sessionId => text()();
  TextColumn get segmentId => text().nullable()();
  TextColumn get fromKind =>
      text().map(const NullableWireEnumConverter(SegmentKind.values)).nullable()();
  TextColumn get toKind =>
      text().map(const NullableWireEnumConverter(SegmentKind.values)).nullable()();
  TextColumn get at => text().map(const NullableUtcDateTimeConverter()).nullable()();
  IntColumn get sensitivityBefore => integer().nullable()();
  IntColumn get sensitivityAfter => integer().nullable()();
}

@DataClassName('PlannerItemRow')
@TableIndex(name: 'planner_items_user_date', columns: {#userId, #date})
@TableIndex(name: 'planner_items_user_band', columns: {#userId, #bandStart})
@TableIndex(name: 'planner_items_recurrence', columns: {#recurrenceId})
class PlannerItems extends Table with SyncColumns, PendingDeleteColumn {
  TextColumn get kind =>
      text().map(const NullableWireEnumConverter(PlannerKind.values)).nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get rangeText => text().nullable()();
  IntColumn get targetMinutes => integer().nullable()();

  /// Local `yyyy-MM-dd`.
  TextColumn get date => text().nullable()();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();
  BoolColumn get isDone => boolean().nullable()();
  TextColumn get doneAt => text().map(const NullableUtcDateTimeConverter()).nullable()();

  /// Keep key.
  TextColumn get recurrenceId => text().nullable()();
  TextColumn get bandStart => text().nullable()();
  TextColumn get bandEnd => text().nullable()();
  IntColumn get sortOrder => integer().nullable()();
}

@DataClassName('RecurrenceRow')
class Recurrences extends Table with SyncColumns, PendingDeleteColumn {
  TextColumn get title => text().nullable()();
  TextColumn get subjectId => text().nullable()();

  /// 7-bit mask, bit 0 = Monday … bit 6 = Sunday.
  IntColumn get weekdayMask => integer().nullable()();
  TextColumn get startTime => text().nullable()();
  TextColumn get endTime => text().nullable()();

  /// Local `yyyy-MM-dd`, inclusive. null = open-ended.
  TextColumn get endsOn => text().nullable()();
  BoolColumn get active => boolean().nullable()();
}

@DataClassName('ReadingRequestRow')
@TableIndex(name: 'reading_requests_user_request', columns: {#userId, #requestId}, unique: true)
@TableIndex(name: 'reading_requests_user_status', columns: {#userId, #status})
class ReadingRequests extends Table with SyncColumns {
  /// Keep key. Idempotency key; the client uses the same uuid as [id].
  TextColumn get requestId => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get rangeText => text().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get plannerItemId => text().nullable()();
  TextColumn get origin =>
      text().map(const NullableWireEnumConverter(ReadingOrigin.values)).nullable()();
  TextColumn get payloadHash => text().nullable()();
  TextColumn get status => text()
      .map(const NullableWireEnumConverter(ReadingRequestStatus.values))
      .nullable()();
  TextColumn get submittedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get completedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get quotaMonth => text().nullable()();
  BoolColumn get quotaCharged => boolean().nullable()();
  TextColumn get resultJson => text().nullable()();
  TextColumn get marksJson => text().nullable()();
  TextColumn get failReason => text().nullable()();

  /// Local only: confirmed marks kept until the save succeeds.
  TextColumn get confirmedMarksJson => text().nullable()();
}

@DataClassName('WrongItemRow')
@TableIndex(name: 'wrong_items_user_status', columns: {#userId, #status})
@TableIndex(name: 'wrong_items_request', columns: {#requestId})
@TableIndex(name: 'wrong_items_user_subject', columns: {#userId, #subjectId})
class WrongItems extends Table with SyncColumns {
  /// Keep key.
  TextColumn get requestId => text()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get rangeText => text().nullable()();
  IntColumn get pageIndex => integer().nullable()();
  IntColumn get number => integer().nullable()();
  TextColumn get mark =>
      text().map(const NullableWireEnumConverter(WrongMark.values)).nullable()();
  RealColumn get confidence => real().nullable()();
  BoolColumn get userConfirmed => boolean().nullable()();
  TextColumn get status => text()
      .map(const NullableWireEnumConverter(WrongItemStatus.values))
      .nullable()();
  TextColumn get resolvedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
}

@DataClassName('ReviewEntryRow')
@TableIndex(name: 'review_entries_user_due', columns: {#userId, #dueAt})
class ReviewEntries extends Table with SyncColumns {
  /// Keep key. One live entry per wrong item — enforced by the partial
  /// unique index `review_entries_live_wrong_item` created in
  /// `AppDatabase.migration.onCreate` (drift's @TableIndex has no WHERE).
  TextColumn get wrongItemId => text()();
  TextColumn get dueAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  IntColumn get intervalDays => integer().nullable()();
  IntColumn get consecutiveCorrect => integer().nullable()();
  TextColumn get lastResult =>
      text().map(const NullableWireEnumConverter(RetryResult.values)).nullable()();
}

@DataClassName('RetryRecordRow')
@TableIndex(name: 'retry_records_wrong_item_at', columns: {#wrongItemId, #at})
class RetryRecords extends Table with SyncColumns {
  /// Keep key.
  TextColumn get wrongItemId => text()();
  TextColumn get result =>
      text().map(const NullableWireEnumConverter(RetryResult.values)).nullable()();
  TextColumn get at => text().map(const NullableUtcDateTimeConverter()).nullable()();
  BoolColumn get voided => boolean().nullable()();
  TextColumn get voidedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
}

@DataClassName('SettingRow')
@TableIndex(name: 'settings_user_key', columns: {#userId, #key}, unique: true)
class Settings extends Table with SyncColumns {
  TextColumn get key => text().nullable()();
  TextColumn get valueJson => text().nullable()();
}

@DataClassName('ActivityDayRow')
@TableIndex(name: 'activity_days_user_date', columns: {#userId, #date}, unique: true)
class ActivityDays extends Table with SyncColumns {
  /// Keep key. Local `yyyy-MM-dd`. `id` = uuid v5 (D24).
  TextColumn get date => text()();
}

// ---------------------------------------------------------------------------
// Server ledger caches (pull `ledger` only — never pushed, D24)

@DataClassName('SubscriptionStateRow')
class SubscriptionStates extends Table {
  TextColumn get userId => text()();
  TextColumn get status => text()();
  BoolColumn get entitled => boolean()();
  TextColumn get expiresAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get graceExpiresAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get periodType => text().nullable()();
  BoolColumn get willRenew => boolean()();
  BoolColumn get trialUsed => boolean()();
  TextColumn get source =>
      text().map(const WireEnumConverter(SubscriptionSource.values))();
  TextColumn get lastCheckedAt => text().map(const UtcDateTimeConverter())();

  @override
  String get tableName => 'subscription_state';

  @override
  Set<Column> get primaryKey => {userId};
}

@DataClassName('ReadingQuotaRow')
class ReadingQuotas extends Table {
  TextColumn get userId => text()();

  /// `yyyy-MM` (KST month, fixed by the server).
  TextColumn get month => text()();
  IntColumn get used => integer()();
  IntColumn get reserved => integer()();

  /// Server JSON key `limit` (SQL reserved word — [S02] decision).
  IntColumn get quotaLimit => integer()();

  @override
  String get tableName => 'reading_quota';

  @override
  Set<Column> get primaryKey => {userId, month};
}

// ---------------------------------------------------------------------------
// Local-only tables

@DataClassName('PhotoRow')
@TableIndex(name: 'photos_request_page', columns: {#requestId, #pageIndex})
@TableIndex(name: 'photos_expires', columns: {#expiresAt})
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get requestId => text().nullable()();

  /// Relative to `ApplicationSupport/photos/`. Never logged.
  TextColumn get localPath => text()();
  TextColumn get takenAt => text().map(const UtcDateTimeConverter())();
  TextColumn get expiresAt => text().map(const UtcDateTimeConverter())();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get pageIndex => integer()();
  TextColumn get createdAt => text().map(const UtcDateTimeConverter())();

  /// Set after the file was deleted ("삭제됨" marker).
  TextColumn get deletedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncOutboxRow')
class SyncOutbox extends Table {
  /// SQL column `table_name` (`tableName` is taken by the drift DSL).
  TextColumn get table => text().named('table_name')();
  TextColumn get rowId => text()();
  TextColumn get mutationId => text()();
  IntColumn get sentClientRev => integer().nullable()();
  TextColumn get queuedAt => text().map(const UtcDateTimeConverter())();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {table, rowId};
}

@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('SyncConflictRow')
class SyncConflicts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get table => text().named('table_name')();
  TextColumn get rowId => text()();
  TextColumn get localJson => text()();
  TextColumn get serverJson => text()();
  TextColumn get resolvedAs =>
      text().map(const WireEnumConverter(ConflictResolution.values))();
  TextColumn get at => text().map(const UtcDateTimeConverter())();
}

/// D23: single row, overwritten every 15 s while a session runs.
@DataClassName('SessionSnapshotRow')
class SessionSnapshots extends Table {
  TextColumn get sessionId => text()();
  TextColumn get mode => text().map(const WireEnumConverter(SessionMode.values))();

  /// Closed segments: `[{id, kind, start_at, end_at, corrected}]`.
  TextColumn get segmentsJson => text()();
  TextColumn get openKind =>
      text().map(const WireEnumConverter(SegmentKind.values))();
  TextColumn get openStart => text().map(const UtcDateTimeConverter())();
  TextColumn get lastSeatedAt => text().map(const NullableUtcDateTimeConverter()).nullable()();
  TextColumn get awayCandidateSince => text().map(const NullableUtcDateTimeConverter()).nullable()();
  IntColumn get sensitivity => integer()();
  TextColumn get savedAt => text().map(const UtcDateTimeConverter())();
  TextColumn get subjectId => text().nullable()();
  TextColumn get plannerItemId => text().nullable()();
  TextColumn get kind => text().map(const WireEnumConverter(SessionKind.values))();
  TextColumn get startedAt => text().map(const UtcDateTimeConverter())();

  @override
  String get tableName => 'session_snapshot';

  @override
  Set<Column> get primaryKey => {sessionId};
}
