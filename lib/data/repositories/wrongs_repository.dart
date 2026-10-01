// WrongsRepository (S02). `wrong_items`. Rows are created by the server at
// `reading-save` (D16 · D24): [applySaved] mirrors them locally without an
// outbox entry; the pull later brings their server versions. The only user
// write is `status` (open ↔ resolved), pushed through sync_push.

import 'package:drift/drift.dart';

import '../../core/contracts/reading_engine.dart'
    show Mark, ReviewEntryDraft, WrongItemDraft;
import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'sync_writer.dart';
import 'write_context.dart';

class WrongsRepository {
  WrongsRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  WriteContext get ctx => writer.ctx;
  $WrongItemsTable get _t => db.wrongItems;

  Expression<bool> _live($WrongItemsTable t) =>
      t.userId.equals(ctx.userId) & t.deletedAt.isNull();

  SimpleSelectStatement<$WrongItemsTable, WrongItemRow> _query({
    WrongItemStatus? status,
    String? subjectId,
    String? requestId,
  }) =>
      db.select(_t)
        ..where((t) {
          var e = _live(t);
          if (status != null) e = e & t.status.equalsValue(status);
          if (subjectId != null) e = e & t.subjectId.equals(subjectId);
          if (requestId != null) e = e & t.requestId.equals(requestId);
          return e;
        })
        ..orderBy([
          (t) => OrderingTerm.desc(t.createdAt),
          (t) => OrderingTerm.asc(t.pageIndex),
          (t) => OrderingTerm.asc(t.number),
        ]);

  Stream<List<WrongItem>> watchAll({WrongItemStatus? status}) =>
      _query(status: status).watch().map((rows) => liveOnly(rows.map(wrongItemOf)));

  Stream<List<WrongItem>> watchBySubject(String subjectId, {WrongItemStatus? status}) =>
      _query(status: status, subjectId: subjectId)
          .watch()
          .map((rows) => liveOnly(rows.map(wrongItemOf)));

  Stream<List<WrongItem>> watchByRequest(String requestId) =>
      _query(requestId: requestId).watch().map((rows) => liveOnly(rows.map(wrongItemOf)));

  Future<List<WrongItem>> getAll({WrongItemStatus? status}) async =>
      liveOnly((await _query(status: status).get()).map(wrongItemOf));

  Future<List<WrongItem>> getByRequest(String requestId) async =>
      liveOnly((await _query(requestId: requestId).get()).map(wrongItemOf));

  Future<WrongItem?> get(String id) async {
    final r = await (db.select(_t)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : wrongItemOf(r);
  }

  Stream<WrongItem?> watch(String id) => (db.select(_t)..where((t) => t.id.equals(id)))
      .watchSingleOrNull()
      .map((r) => r == null ? null : wrongItemOf(r));

  /// Open / resolved counts per subject id.
  Future<Map<String, ({int open, int resolved})>> countsBySubject() async {
    final rows = await getAll();
    final out = <String, ({int open, int resolved})>{};
    for (final w in rows) {
      final cur = out[w.subjectId] ?? (open: 0, resolved: 0);
      out[w.subjectId] = w.status == WrongItemStatus.open
          ? (open: cur.open + 1, resolved: cur.resolved)
          : (open: cur.open, resolved: cur.resolved + 1);
    }
    return out;
  }

  /// 해결 처리 toggle — the one client-editable column.
  Future<void> setStatus(String id, WrongItemStatus status) {
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      await (db.update(_t)..where((t) => t.id.equals(id))).write(
        WrongItemsCompanion(
          status: Value(status),
          resolvedAt: Value(status == WrongItemStatus.resolved ? now : null),
        ),
      );
      await writer.markUserWrite(_t, id, at: now);
    });
  }

  /// Mirrors the rows `reading-save` created (client-generated ids) so the
  /// result is visible immediately. No outbox: the server already has them;
  /// `server_version` stays null until the next pull replaces the rows.
  Future<void> applySaved({
    required String requestId,
    required String subjectId,
    required String rangeText,
    required List<WrongItemDraft> items,
    required List<ReviewEntryDraft> entries,
    DateTime? at,
  }) {
    return writer.runInTransaction(() async {
      final now = (at ?? ctx.nowUtc()).toUtc();
      final epoch = await writer.purgeEpoch();
      for (final it in items) {
        final mark = _wrongMarkOf(it.mark);
        if (mark == null) continue; // correct items are not wrong items
        await db.into(_t).insertOnConflictUpdate(
              WrongItemsCompanion.insert(
                id: it.id,
                userId: ctx.userId,
                createdAt: now,
                clientUpdatedAt: now,
                deviceId: ctx.deviceId,
                purgeEpoch: Value(epoch),
                requestId: requestId,
                subjectId: Value(subjectId),
                rangeText: Value(rangeText),
                pageIndex: Value(it.pageIndex),
                number: Value(it.number),
                mark: Value(mark),
                confidence: Value(it.confidence),
                userConfirmed: Value(it.userConfirmed),
                status: const Value(WrongItemStatus.open),
              ),
            );
      }
      for (final e in entries) {
        await db.into(db.reviewEntries).insertOnConflictUpdate(
              ReviewEntriesCompanion.insert(
                id: e.id,
                userId: ctx.userId,
                createdAt: now,
                clientUpdatedAt: now,
                deviceId: ctx.deviceId,
                purgeEpoch: Value(epoch),
                wrongItemId: e.wrongItemId,
                dueAt: Value(e.dueAt.toUtc()),
                intervalDays: Value(e.intervalDays),
                consecutiveCorrect: Value(e.consecutiveCorrect),
              ),
            );
      }
    });
  }

  Future<ApplyServerReport> applyServer(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_t, rows);

  static WrongMark? _wrongMarkOf(Mark m) => switch (m) {
        Mark.correct => null,
        Mark.wrong => WrongMark.wrong,
        Mark.partial => WrongMark.partial,
        Mark.unsolved => WrongMark.unsolved,
        Mark.guessed => WrongMark.guessed,
      };
}
