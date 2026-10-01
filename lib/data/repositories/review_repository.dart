// ReviewRepository (S02). `review_entries` · `retry_records` (D9 via
// ReviewScheduler). Recording a retry inserts a record and moves the entry;
// two consecutive 맞음 remove the entry from the queue; voiding a record
// rebuilds the entry from the remaining records.

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../../features/review/domain/review_scheduler.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'sync_writer.dart';
import 'write_context.dart';

class ReviewRepository {
  ReviewRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  static const ReviewScheduler _scheduler = ReviewScheduler();

  WriteContext get ctx => writer.ctx;
  $ReviewEntriesTable get _e => db.reviewEntries;
  $RetryRecordsTable get _r => db.retryRecords;

  Expression<bool> _live($ReviewEntriesTable t) =>
      t.userId.equals(ctx.userId) & t.deletedAt.isNull();

  // ---------------------------------------------------------------------
  // Reads

  /// Whole queue ordered by due time (earliest first).
  Stream<List<ReviewEntry>> watchQueue() => (db.select(_e)
        ..where(_live)
        ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
      .watch()
      .map((rows) => liveOnly(rows.map(reviewEntryOf)));

  Future<List<ReviewEntry>> getQueue() async => liveOnly(
        (await (db.select(_e)
                  ..where(_live)
                  ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
                .get())
            .map(reviewEntryOf),
      );

  /// Entries due at or before [now].
  Stream<List<ReviewEntry>> watchDue(DateTime now) => (db.select(_e)
        ..where((t) => _live(t) & t.dueAt.isSmallerOrEqualValue(utcIso(now)))
        ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
      .watch()
      .map((rows) => liveOnly(rows.map(reviewEntryOf)));

  Future<ReviewEntry?> entryFor(String wrongItemId) async {
    final r = await (db.select(_e)
          ..where((t) => t.wrongItemId.equals(wrongItemId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return r == null ? null : reviewEntryOf(r);
  }

  Stream<ReviewEntry?> watchEntryFor(String wrongItemId) => (db.select(_e)
        ..where((t) => t.wrongItemId.equals(wrongItemId) & t.deletedAt.isNull()))
      .watchSingleOrNull()
      .map((r) => r == null ? null : reviewEntryOf(r));

  /// Retry history, newest first (voided ones included for the history view).
  Stream<List<RetryRecord>> watchRetries(String wrongItemId) => (db.select(_r)
        ..where((t) => t.wrongItemId.equals(wrongItemId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.at)]))
      .watch()
      .map((rows) => liveOnly(rows.map(retryRecordOf)));

  Future<List<RetryRecord>> getRetries(String wrongItemId) async => liveOnly(
        (await (db.select(_r)
                  ..where((t) => t.wrongItemId.equals(wrongItemId) & t.deletedAt.isNull())
                  ..orderBy([(t) => OrderingTerm.asc(t.at)]))
                .get())
            .map(retryRecordOf),
      );

  Future<List<RetryRecord>> getAllRetries() async => liveOnly(
        (await (db.select(_r)
                  ..where((t) => t.userId.equals(ctx.userId) & t.deletedAt.isNull())
                  ..orderBy([(t) => OrderingTerm.asc(t.at)]))
                .get())
            .map(retryRecordOf),
      );

  // ---------------------------------------------------------------------
  // Writes

  /// 맞음 / 부분 / 또 틀림 for [wrongItemId] at [at].
  Future<ReviewOutcome> recordRetry({
    required String wrongItemId,
    required RetryResult result,
    DateTime? at,
  }) {
    return db.transaction(() async {
      final now = (at ?? ctx.nowUtc()).toUtc();
      final epoch = await writer.purgeEpoch();
      final recordId = ctx.newId();
      await db.into(_r).insert(
            RetryRecordsCompanion.insert(
              id: recordId,
              userId: ctx.userId,
              createdAt: now,
              clientUpdatedAt: now,
              deviceId: ctx.deviceId,
              purgeEpoch: Value(epoch),
              wrongItemId: wrongItemId,
              result: Value(result),
              at: Value(now),
              voided: const Value(false),
            ),
          );
      await writer.enqueue(_r.actualTableName, recordId);

      final entry = await entryFor(wrongItemId);
      final current = entry == null
          ? _scheduler.initial(await _wrongItemCreatedAt(wrongItemId) ?? now)
          : ReviewSchedule(
              intervalDays: entry.intervalDays,
              consecutiveCorrect: entry.consecutiveCorrect,
              dueAt: entry.dueAt,
              lastResult: entry.lastResult,
            );
      final outcome = _scheduler.record(current, result, now);
      await _applyOutcome(wrongItemId, entry, outcome, now, epoch);
      return outcome;
    });
  }

  /// `rtVoid`: cancels a record and rebuilds the entry from the rest.
  Future<ReviewOutcome> voidRetry(String retryId, {DateTime? at}) {
    return db.transaction(() async {
      final now = (at ?? ctx.nowUtc()).toUtc();
      final row = await (db.select(_r)..where((t) => t.id.equals(retryId))).getSingle();
      await (db.update(_r)..where((t) => t.id.equals(retryId))).write(
        RetryRecordsCompanion(voided: const Value(true), voidedAt: Value(now)),
      );
      await writer.markUserWrite(_r, retryId, at: now);

      final wrongItemId = row.wrongItemId;
      final remaining = (await getRetries(wrongItemId))
          .where((r) => !r.voided)
          .map((r) => RetryEvent(result: r.result, at: r.at));
      final createdAt = await _wrongItemCreatedAt(wrongItemId) ?? now;
      final outcome = _scheduler.rebuild(createdAt, remaining);
      final entry = await entryFor(wrongItemId);
      await _applyOutcome(wrongItemId, entry, outcome, now, await writer.purgeEpoch());
      return outcome;
    });
  }

  /// Removes the entry (e.g. the wrong item was marked 해결).
  Future<void> leaveQueue(String wrongItemId) async {
    final entry = await entryFor(wrongItemId);
    if (entry != null) await writer.commitDelete(_e, entry.id);
  }

  Future<void> _applyOutcome(
    String wrongItemId,
    ReviewEntry? entry,
    ReviewOutcome outcome,
    DateTime now,
    int epoch,
  ) async {
    switch (outcome) {
      case ReviewScheduled(:final schedule):
        if (entry == null) {
          final id = ctx.newId();
          await db.into(_e).insert(
                ReviewEntriesCompanion.insert(
                  id: id,
                  userId: ctx.userId,
                  createdAt: now,
                  clientUpdatedAt: now,
                  deviceId: ctx.deviceId,
                  purgeEpoch: Value(epoch),
                  wrongItemId: wrongItemId,
                  dueAt: Value(schedule.dueAt.toUtc()),
                  intervalDays: Value(schedule.intervalDays),
                  consecutiveCorrect: Value(schedule.consecutiveCorrect),
                  lastResult: Value(schedule.lastResult),
                ),
              );
          await writer.enqueue(_e.actualTableName, id);
        } else {
          await (db.update(_e)..where((t) => t.id.equals(entry.id))).write(
            ReviewEntriesCompanion(
              dueAt: Value(schedule.dueAt.toUtc()),
              intervalDays: Value(schedule.intervalDays),
              consecutiveCorrect: Value(schedule.consecutiveCorrect),
              lastResult: Value(schedule.lastResult),
            ),
          );
          await writer.markUserWrite(_e, entry.id, at: now);
        }
      case ReviewGraduated():
        if (entry != null) await writer.commitDelete(_e, entry.id);
    }
  }

  Future<DateTime?> _wrongItemCreatedAt(String wrongItemId) async {
    final w = await (db.select(db.wrongItems)..where((t) => t.id.equals(wrongItemId)))
        .getSingleOrNull();
    return w?.createdAt;
  }

  // ---------------------------------------------------------------------
  // Server → local

  Future<ApplyServerReport> applyServerEntries(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_e, rows);

  Future<ApplyServerReport> applyServerRetries(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_r, rows);
}
