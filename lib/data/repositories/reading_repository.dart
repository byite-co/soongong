// ReadingRepository (S02). `reading_requests` (mixed ownership, D24) and
// `photos` (local only).
//
// Client-owned writes (sync_push): a draft's subject · range · origin ·
// session · planner item while `selecting`, and the delete-only mutation of
// a `saved` request (D16). Everything after submission (`status`,
// `submitted_at`, `result_json`, `marks_json`, …) enters ONLY through
// [applyServer] / [applyStatus] — no rev bump, no outbox. The local
// `sending` flag and `payload_hash` cache are local-only writes as well.

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'sync_writer.dart';
import 'write_context.dart';

/// Result of [ReadingRepository.deleteDraft].
enum DraftDeleteOutcome {
  /// Tombstoned and enqueued.
  deleted,

  /// The draft is in `sending`: a submit call is in flight. Nothing changed.
  submitting,

  /// Already submitted (any server-owned status). Nothing changed.
  notDraft,

  /// No such request (or already a tombstone). Nothing changed.
  notFound,
}

class ReadingRepository {
  ReadingRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  /// Photo retention (D14).
  static const Duration photoRetention = Duration(days: 30);

  WriteContext get ctx => writer.ctx;
  $ReadingRequestsTable get _t => db.readingRequests;
  $PhotosTable get _p => db.photos;

  Expression<bool> _live($ReadingRequestsTable t) =>
      t.userId.equals(ctx.userId) & t.deletedAt.isNull();

  // ---------------------------------------------------------------------
  // Reads

  Stream<ReadingRequest?> watch(String requestId) =>
      (db.select(_t)..where((t) => t.requestId.equals(requestId)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : readingRequestOf(r));

  Future<ReadingRequest?> get(String requestId) async {
    final r = await (db.select(_t)..where((t) => t.requestId.equals(requestId)))
        .getSingleOrNull();
    return r == null ? null : readingRequestOf(r);
  }

  /// The request that blocks a new one (D17): processing · taking_long ·
  /// done_unsaved. At most one exists.
  Stream<ReadingRequest?> watchBlocking() => (db.select(_t)
        ..where(
          (t) =>
              _live(t) &
              t.status.isInValues(const <ReadingRequestStatus>[
                ReadingRequestStatus.processing,
                ReadingRequestStatus.takingLong,
                ReadingRequestStatus.doneUnsaved,
              ]),
        )
        ..orderBy([(t) => OrderingTerm.desc(t.submittedAt)])
        ..limit(1))
      .watchSingleOrNull()
      .map((r) => r == null ? null : readingRequestOf(r));

  Stream<List<ReadingRequest>> watchByStatus(Set<ReadingRequestStatus> statuses) =>
      (db.select(_t)
            ..where((t) => _live(t) & t.status.isInValues(statuses.toList()))
            ..orderBy([(t) => OrderingTerm.desc(t.clientUpdatedAt)]))
          .watch()
          .map((rows) => liveOnly(rows.map(readingRequestOf)));

  Stream<List<ReadingRequest>> watchSaved() =>
      watchByStatus(const <ReadingRequestStatus>{ReadingRequestStatus.saved});

  Future<List<ReadingRequest>> getAll() async => liveOnly(
        (await (db.select(_t)
                  ..where(_live)
                  ..orderBy([(t) => OrderingTerm.desc(t.clientUpdatedAt)]))
                .get())
            .map(readingRequestOf),
      );

  // ---------------------------------------------------------------------
  // Drafts (client-owned, `selecting`)

  Future<ReadingRequest> createDraft({
    required String subjectId,
    required String rangeText,
    required ReadingOrigin origin,
    String? sessionId,
    String? plannerItemId,
  }) {
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      final id = ctx.newId(); // request_id == id
      await db.into(_t).insert(
            ReadingRequestsCompanion.insert(
              id: id,
              userId: ctx.userId,
              createdAt: now,
              clientUpdatedAt: now,
              deviceId: ctx.deviceId,
              purgeEpoch: Value(await writer.purgeEpoch()),
              requestId: id,
              subjectId: Value(subjectId),
              rangeText: Value(rangeText),
              sessionId: Value(sessionId),
              plannerItemId: Value(plannerItemId),
              origin: Value(origin),
              status: const Value(ReadingRequestStatus.selecting),
              quotaCharged: const Value(false),
            ),
          );
      await writer.enqueue(_t.actualTableName, id);
      return (await get(id))!;
    });
  }

  /// Edits a draft. Throws [StateError] once the request was submitted.
  Future<void> updateDraft(
    String requestId, {
    Value<String> subjectId = const Value.absent(),
    Value<String> rangeText = const Value.absent(),
    Value<String?> sessionId = const Value.absent(),
    Value<String?> plannerItemId = const Value.absent(),
  }) {
    return writer.runInTransaction(() async {
      final current = await get(requestId);
      if (current == null) throw StateError('request not found');
      if (!current.isDraft) throw StateError('request already submitted');
      await (db.update(_t)..where((t) => t.id.equals(current.id))).write(
        ReadingRequestsCompanion(
          subjectId: subjectId.present ? Value(subjectId.value) : const Value.absent(),
          rangeText: rangeText.present ? Value(rangeText.value) : const Value.absent(),
          sessionId: sessionId.present ? Value(sessionId.value) : const Value.absent(),
          plannerItemId:
              plannerItemId.present ? Value(plannerItemId.value) : const Value.absent(),
        ),
      );
      await writer.markUserWrite(_t, current.id);
    });
  }

  /// Local-only: the draft is being submitted (`sending`). No outbox.
  Future<void> setLocalSending(String requestId, {required String payloadHash}) =>
      writer.applyServerColumns(_t, requestId, <String, Object?>{
        'status': ReadingRequestStatus.sending.wire,
        'payload_hash': payloadHash,
      });

  /// Local-only: `reading-status` answered 404 for a `sending` draft → back
  /// to `selecting` so [deleteDraft] is allowed. A 404 is NOT proof that the
  /// server never received the submit: the delete becomes final only once
  /// the tombstone mutation pushed by [deleteDraft] is accepted. A rejection
  /// (`version_conflict` with a server row in `processing` etc.) is applied
  /// through `applyServer` and handled from the server state (cancel /
  /// complete) — never re-pushed on the `deleted_at`-wins rule.
  Future<void> revertToSelecting(String requestId) async {
    final current = await get(requestId);
    if (current == null || current.status != ReadingRequestStatus.sending) return;
    await writer.applyServerColumns(_t, requestId, <String, Object?>{
      'status': ReadingRequestStatus.selecting.wire,
    });
  }

  /// Local-only: confirmed marks kept until the save succeeds (D16).
  Future<void> setConfirmedMarks(String requestId, String? json) =>
      writer.applyServerColumns(
        _t,
        requestId,
        <String, Object?>{'confirmed_marks_json': json},
      );

  /// Deletes a `selecting` draft as a tombstone mutation — ALWAYS pushed,
  /// whatever its send history (S02c, data-model.md §7 ①): the server either
  /// tombstones its copy or inserts the tombstone (D2). A draft that is
  /// being submitted (`sending`) is never deleted here: the caller (S10)
  /// checks `reading-status` first — `processing`/`taking_long` →
  /// `cancel()`; 404 → [revertToSelecting] then [deleteDraft] again, and
  /// the deletion is confirmed only by the server accepting the tombstone
  /// push (a 404 is not proof of non-receipt — see [revertToSelecting]).
  Future<DraftDeleteOutcome> deleteDraft(String requestId) {
    return writer.runInTransaction(() async {
      final current = await get(requestId);
      if (current == null) return DraftDeleteOutcome.notFound;
      if (current.status == ReadingRequestStatus.sending) {
        return DraftDeleteOutcome.submitting;
      }
      if (!current.isDraft) return DraftDeleteOutcome.notDraft;
      await writer.commitDelete(_t, current.id);
      return DraftDeleteOutcome.deleted;
    });
  }

  // ---------------------------------------------------------------------
  // Server → local (D2 applyServer path)

  /// Pull rows. Tombstones drop every payload column (generic rule); rows
  /// that arrive as `expired` / `discarded` also lose `result_json` and the
  /// local `confirmed_marks_json` (D8, S02b).
  Future<ApplyServerReport> applyServer(Iterable<Map<String, Object?>> rows) {
    return writer.runInTransaction(() async {
      final list = rows.toList();
      final report = await writer.applyServer(_t, list);
      for (final raw in list) {
        final id = raw['id'];
        if (id is! String) continue;
        if (_isPurgedStatus(raw['status'])) {
          await writer.applyServerColumns(_t, id, const <String, Object?>{
            'result_json': null,
            'confirmed_marks_json': null,
          });
        }
      }
      return report;
    });
  }

  static bool _isPurgedStatus(Object? status) =>
      status == ReadingRequestStatus.expired.wire ||
      status == ReadingRequestStatus.discarded.wire;

  /// `reading-status` / `reading-submit` / `reading-save` … responses.
  /// Only the supplied fields change. `expired` / `discarded` always clear
  /// `result_json` and `confirmed_marks_json` (D8).
  Future<void> applyStatus(
    String requestId, {
    required ReadingRequestStatus status,
    int? serverVersion,
    DateTime? submittedAt,
    DateTime? completedAt,
    String? quotaMonth,
    bool? quotaCharged,
    String? payloadHash,
    Value<String?> resultJson = const Value.absent(),
    Value<String?> marksJson = const Value.absent(),
    Value<String?> failReason = const Value.absent(),
    bool clearConfirmedMarks = false,
  }) async {
    final purged = _isPurgedStatus(status.wire);
    final cols = <String, Object?>{
      'status': status.wire,
      'server_version': ?serverVersion,
      'submitted_at': ?submittedAt,
      'completed_at': ?completedAt,
      'quota_month': ?quotaMonth,
      'quota_charged': ?quotaCharged,
      'payload_hash': ?payloadHash,
      if (resultJson.present) 'result_json': resultJson.value,
      if (marksJson.present) 'marks_json': marksJson.value,
      if (failReason.present) 'fail_reason': failReason.value,
      if (clearConfirmedMarks) 'confirmed_marks_json': null,
      if (purged) 'result_json': null,
      if (purged) 'confirmed_marks_json': null,
    };
    await writer.applyServerColumns(_t, requestId, cols);
  }

  /// Server 410 `request_deleted` → local tombstone (content, result, marks
  /// and confirmed marks NULL, `request_id` kept), polling stops (D16).
  Future<void> applyDeleted(String requestId) =>
      writer.tombstoneLocally(_t, requestId);

  // ---------------------------------------------------------------------
  // Saved result delete (S11 `wdDelRes`, offline allowed, D16)

  /// Delete-only mutation on a `saved` request; children are hidden locally
  /// and replaced by the server tombstones on pull. Photos stay.
  Future<void> deleteSavedResult(String requestId) {
    return writer.runInTransaction(() async {
      final current = await get(requestId);
      if (current == null) throw StateError('request not found');
      if (current.status != ReadingRequestStatus.saved) {
        throw StateError('only saved results can be deleted (${current.status.wire})');
      }
      final wrongs = await (db.select(db.wrongItems)
            ..where((w) => w.requestId.equals(requestId) & w.deletedAt.isNull()))
          .get();
      final wrongIds = wrongs.map((w) => w.id).toList();
      for (final id in wrongIds) {
        await writer.hideLocally(db.wrongItems, id);
      }
      if (wrongIds.isNotEmpty) {
        final entries = await (db.select(db.reviewEntries)
              ..where((e) => e.wrongItemId.isIn(wrongIds) & e.deletedAt.isNull()))
            .get();
        for (final e in entries) {
          await writer.hideLocally(db.reviewEntries, e.id);
        }
        final retries = await (db.select(db.retryRecords)
              ..where((r) => r.wrongItemId.isIn(wrongIds) & r.deletedAt.isNull()))
            .get();
        for (final r in retries) {
          await writer.hideLocally(db.retryRecords, r.id);
        }
      }
      await writer.commitDelete(_t, current.id);
    });
  }

  // ---------------------------------------------------------------------
  // Photos (local only, D14)

  Future<Photo> addPhoto({
    required String localPath,
    required DateTime takenAt,
    required int width,
    required int height,
    required int pageIndex,
    String? requestId,
  }) async {
    final id = ctx.newId();
    final now = ctx.nowUtc();
    await db.into(_p).insert(
          PhotosCompanion.insert(
            id: id,
            userId: ctx.userId,
            requestId: Value(requestId),
            localPath: localPath,
            takenAt: takenAt.toUtc(),
            expiresAt: takenAt.toUtc().add(photoRetention),
            width: width,
            height: height,
            pageIndex: pageIndex,
            createdAt: now,
          ),
        );
    return photoOf(
      await (db.select(_p)..where((p) => p.id.equals(id))).getSingle(),
    );
  }

  Future<void> attachPhotos(String requestId, List<String> photoIds) async {
    for (var i = 0; i < photoIds.length; i++) {
      await (db.update(_p)..where((p) => p.id.equals(photoIds[i]))).write(
        PhotosCompanion(requestId: Value(requestId), pageIndex: Value(i)),
      );
    }
  }

  Stream<List<Photo>> watchPhotos(String requestId) => (db.select(_p)
        ..where((p) => p.requestId.equals(requestId))
        ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
      .watch()
      .map((rows) => rows.map(photoOf).toList());

  Future<List<Photo>> getPhotos(String requestId) async =>
      (await (db.select(_p)
                ..where((p) => p.requestId.equals(requestId))
                ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]))
              .get())
          .map(photoOf)
          .toList();

  /// Every photo row (the privacy screen lists them, `photoDel` marks).
  Stream<List<Photo>> watchAllPhotos({bool includeDeleted = false}) =>
      (db.select(_p)
            ..where((p) => includeDeleted ? const Constant(true) : p.deletedAt.isNull())
            ..orderBy([(p) => OrderingTerm.desc(p.takenAt)]))
          .watch()
          .map((rows) => rows.map(photoOf).toList());

  Future<List<Photo>> getAllPhotos({bool includeDeleted = false}) async =>
      (await (db.select(_p)
                ..where((p) => includeDeleted ? const Constant(true) : p.deletedAt.isNull())
                ..orderBy([(p) => OrderingTerm.desc(p.takenAt)]))
              .get())
          .map(photoOf)
          .toList();

  /// Photos past their 30-day retention (file deletion is the caller's job;
  /// call [markPhotoDeleted] afterwards).
  Future<List<Photo>> expiredPhotos(DateTime now) async =>
      (await (db.select(_p)
                ..where(
                  (p) =>
                      p.deletedAt.isNull() &
                      p.expiresAt.isSmallerOrEqualValue(utcIso(now)),
                ))
              .get())
          .map(photoOf)
          .toList();

  /// File is gone → keep the row as a "삭제됨" marker.
  Future<void> markPhotoDeleted(String id) =>
      (db.update(_p)..where((p) => p.id.equals(id)))
          .write(PhotosCompanion(deletedAt: Value(ctx.nowUtc())));

  /// Removes photo rows entirely (logout / purge).
  Future<void> purgePhotoRows(Iterable<String> ids) =>
      (db.delete(_p)..where((p) => p.id.isIn(ids.toList()))).go();
}
