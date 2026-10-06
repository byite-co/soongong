// SessionRepository (S02). `sessions` · `session_segments` · `corrections`
// · `session_snapshot`. Saving a finished session writes the session and its
// closed segments in one transaction (each row its own outbox entry) and
// clears the snapshot (D23). Corrections re-derive `seated_seconds`.

import 'package:drift/drift.dart';

import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/local_date.dart';
import '../../features/measure/domain/seated_time_calculator.dart';
import '../../features/measure/domain/segment.dart';
import '../../features/measure/domain/segment_corrector.dart';
import '../../features/measure/domain/session_snapshot.dart';
import '../db/app_database.dart';
import 'mappers.dart';
import 'sync_writer.dart';
import 'write_context.dart';

class SessionRepository {
  SessionRepository(this.db, this.writer);

  final AppDatabase db;
  final SyncWriter writer;

  static const SeatedTimeCalculator _calc = SeatedTimeCalculator();
  static const SegmentCorrector _corrector = SegmentCorrector();

  WriteContext get ctx => writer.ctx;
  $SessionsTable get _t => db.sessions;

  Expression<bool> _live($SessionsTable t) =>
      t.userId.equals(ctx.userId) &
      t.deletedAt.isNull() &
      t.pendingDeleteUntil.isNull();

  // ---------------------------------------------------------------------
  // Reads

  /// Sessions whose `started_at` falls inside the local day range
  /// [from]..[to] (inclusive), oldest first.
  Stream<List<StudySession>> watchBetween(LocalDate from, LocalDate to) =>
      _between(from, to).watch().map((rows) => liveOnly(rows.map(sessionOf)));

  Future<List<StudySession>> getBetween(LocalDate from, LocalDate to) async =>
      liveOnly((await _between(from, to).get()).map(sessionOf));

  SimpleSelectStatement<$SessionsTable, SessionRow> _between(
    LocalDate from,
    LocalDate to,
  ) {
    final start = utcIso(from.toDateTime().toUtc());
    final end = utcIso(to.addDays(1).toDateTime().toUtc());
    return db.select(_t)
      ..where(
        (t) =>
            _live(t) &
            t.startedAt.isBiggerOrEqualValue(start) &
            t.startedAt.isSmallerThanValue(end),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]);
  }

  Stream<List<StudySession>> watchAll() =>
      (db.select(_t)
            ..where(_live)
            ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
          .watch()
          .map((rows) => liveOnly(rows.map(sessionOf)));

  Future<List<StudySession>> getAll() async => liveOnly(
    (await (db.select(_t)
              ..where(_live)
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
            .get())
        .map(sessionOf),
  );

  Stream<StudySession?> watch(String id) =>
      (db.select(_t)..where((t) => t.id.equals(id))).watchSingleOrNull().map(
        (r) => r == null ? null : sessionOf(r),
      );

  Future<StudySession?> get(String id) async {
    final r = await (db.select(
      _t,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : sessionOf(r);
  }

  Stream<List<SessionSegment>> watchSegments(String sessionId) =>
      _segmentsQuery(sessionId)
          .watch()
          .map((rows) => liveOnly(rows.map(segmentOf)));

  Future<List<SessionSegment>> getSegments(String sessionId) async =>
      liveOnly((await _segmentsQuery(sessionId).get()).map(segmentOf));

  Stream<List<SessionSegment>> watchAllSegments() =>
      (db.select(db.sessionSegments)
            ..where((s) => s.userId.equals(ctx.userId) & s.deletedAt.isNull())
            ..orderBy([(s) => OrderingTerm.asc(s.startAt)]))
          .watch()
          .map((rows) => liveOnly(rows.map(segmentOf)));

  /// Segments of the user that overlap the local day range [from]..[to]
  /// (inclusive): `end_at > from 00:00` and `start_at < to+1 00:00`. A
  /// segment that crosses midnight is returned for both days; the caller
  /// clips it (`HomeSummary.build`).
  Stream<List<SessionSegment>> watchSegmentsOverlapping(
    LocalDate from,
    LocalDate to,
  ) =>
      _overlapping(from, to)
          .watch()
          .map((rows) => liveOnly(rows.map(segmentOf)));

  Future<List<SessionSegment>> getSegmentsOverlapping(
    LocalDate from,
    LocalDate to,
  ) async =>
      liveOnly((await _overlapping(from, to).get()).map(segmentOf));

  SimpleSelectStatement<$SessionSegmentsTable, SessionSegmentRow> _overlapping(
    LocalDate from,
    LocalDate to,
  ) {
    final start = utcIso(from.toDateTime().toUtc());
    final end = utcIso(to.addDays(1).toDateTime().toUtc());
    return db.select(db.sessionSegments)
      ..where(
        (s) =>
            s.userId.equals(ctx.userId) &
            s.deletedAt.isNull() &
            s.endAt.isBiggerThanValue(start) &
            s.startAt.isSmallerThanValue(end),
      )
      ..orderBy([(s) => OrderingTerm.asc(s.startAt)]);
  }

  SimpleSelectStatement<$SessionSegmentsTable, SessionSegmentRow>
  _segmentsQuery(String sessionId) => db.select(db.sessionSegments)
    ..where((s) => s.sessionId.equals(sessionId) & s.deletedAt.isNull())
    ..orderBy([(s) => OrderingTerm.asc(s.startAt)]);

  Stream<List<Correction>> watchCorrections(String sessionId) =>
      (db.select(db.corrections)
            ..where((c) => c.sessionId.equals(sessionId) & c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.at)]))
          .watch()
          .map((rows) => liveOnly(rows.map(correctionOf)));

  /// All corrections of the user since [since] (sensitivity window).
  Future<List<Correction>> correctionsSince(DateTime since) async => liveOnly(
    (await (db.select(db.corrections)
              ..where(
                (c) =>
                    c.userId.equals(ctx.userId) &
                    c.deletedAt.isNull() &
                    c.at.isBiggerOrEqualValue(utcIso(since)),
              )
              ..orderBy([(c) => OrderingTerm.asc(c.at)]))
            .get())
        .map(correctionOf),
  );

  Stream<List<Correction>> watchAllCorrections() =>
      (db.select(db.corrections)
            ..where((c) => c.userId.equals(ctx.userId) & c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.desc(c.at)]))
          .watch()
          .map((rows) => liveOnly(rows.map(correctionOf)));

  /// Local dates that have at least one saved session (streak, D4).
  Future<Set<LocalDate>> daysWithSessions() async {
    final rows =
        await (db.selectOnly(_t)
              ..addColumns([_t.startedAt])
              ..where(
                _live(_t) &
                    _t.endedAt.isNotNull() &
                    _t.status.isIn([
                      SessionStatus.finished.name,
                      SessionStatus.interrupted.name,
                    ]),
              ))
            .get();
    return <LocalDate>{
      for (final r in rows)
        if (r.read(_t.startedAt) != null)
          LocalDate.of(DateTime.parse(r.read(_t.startedAt)!).toLocal()),
    };
  }

  // ---------------------------------------------------------------------
  // Writes

  /// Persist before opening the camera so even a crash before the first
  /// checkpoint has a recoverable (zero-time) session.
  Future<void> startActive(SessionSnapshot snapshot) =>
      writer.runInTransaction(() async {
        final now = ctx.nowUtc();
        await db
            .into(_t)
            .insert(
              SessionsCompanion.insert(
                id: snapshot.sessionId,
                userId: ctx.userId,
                createdAt: now,
                clientUpdatedAt: now,
                deviceId: ctx.deviceId,
                purgeEpoch: Value(await writer.purgeEpoch()),
                kind: Value(snapshot.kind),
                mode: Value(snapshot.mode),
                startedAt: Value(snapshot.startedAt.toUtc()),
                status: const Value(SessionStatus.active),
                seatedSeconds: const Value(0),
                sensitivityLevel: Value(snapshot.sensitivity),
                subjectId: Value(snapshot.subjectId),
                plannerItemId: Value(snapshot.plannerItemId),
              ),
            );
        await writer.enqueue(_t.actualTableName, snapshot.sessionId);
        await writeSnapshot(snapshot);
      });

  Future<void> markInterrupted(String id) => writer.runInTransaction(() async {
    await (db.update(
      _t,
    )..where((t) => t.id.equals(id) & t.userId.equals(ctx.userId))).write(
      const SessionsCompanion(status: Value(SessionStatus.interrupted)),
    );
    await writer.markUserWrite(_t, id);
  });

  Future<void> discard(String id) => writer.runInTransaction(() async {
    if (await get(id) != null) await commitDelete(id);
    final snapshot = await readSnapshot();
    if (snapshot?.sessionId == id) await clearSnapshot();
  });

  /// Saves a finished (or interrupted/recovered) session with its closed
  /// segments. `seated_seconds` is computed here. The snapshot is removed.
  Future<StudySession> saveFinished({
    required String id,
    required SessionKind kind,
    required SessionMode mode,
    required DateTime startedAt,
    required DateTime endedAt,
    required SessionStatus status,
    required List<Segment> segments,
    required int sensitivityLevel,
    String? subjectId,
    String? plannerItemId,
    String? note,
  }) {
    assert(
      status == SessionStatus.finished || status == SessionStatus.interrupted,
      'only finished/interrupted sessions are stored',
    );
    return writer.runInTransaction(() async {
      final now = ctx.nowUtc();
      final epoch = await writer.purgeEpoch();
      final existing = await get(id);
      if (existing != null && existing.stamp.userId != ctx.userId) {
        throw StateError('Session is not writable');
      }
      if (existing != null) {
        await (db.update(_t)..where((t) => t.id.equals(id))).write(
          SessionsCompanion(
            subjectId: Value(subjectId),
            plannerItemId: Value(plannerItemId),
            kind: Value(kind),
            mode: Value(mode),
            startedAt: Value(startedAt.toUtc()),
            endedAt: Value(endedAt.toUtc()),
            status: Value(status),
            seatedSeconds: Value(_calc.seatedSeconds(segments)),
            sensitivityLevel: Value(sensitivityLevel),
            note: Value(note),
          ),
        );
        await writer.markUserWrite(_t, id);
      } else {
        await db
            .into(_t)
            .insert(
              SessionsCompanion.insert(
                id: id,
                userId: ctx.userId,
                createdAt: now,
                clientUpdatedAt: now,
                deviceId: ctx.deviceId,
                purgeEpoch: Value(epoch),
                subjectId: Value(subjectId),
                plannerItemId: Value(plannerItemId),
                kind: Value(kind),
                mode: Value(mode),
                startedAt: Value(startedAt.toUtc()),
                endedAt: Value(endedAt.toUtc()),
                status: Value(status),
                seatedSeconds: Value(_calc.seatedSeconds(segments)),
                sensitivityLevel: Value(sensitivityLevel),
                note: Value(note),
              ),
            );
        await writer.enqueue(_t.actualTableName, id);
      }
      final previousSegments = await getSegments(id);
      final incomingIds = segments
          .where((s) => !s.isEmpty)
          .map((s) => s.id)
          .toSet();
      for (final old in previousSegments) {
        if (!incomingIds.contains(old.id)) {
          await writer.commitDelete(db.sessionSegments, old.id);
        }
      }
      for (final s in segments) {
        if (s.isEmpty) continue;
        if (previousSegments.any((old) => old.id == s.id)) {
          await (db.update(
            db.sessionSegments,
          )..where((t) => t.id.equals(s.id))).write(
            SessionSegmentsCompanion(
              kind: Value(s.kind),
              startAt: Value(s.startAt.toUtc()),
              endAt: Value(s.endAt.toUtc()),
              corrected: Value(s.corrected),
            ),
          );
          await writer.markUserWrite(db.sessionSegments, s.id);
          continue;
        }
        await db
            .into(db.sessionSegments)
            .insert(
              SessionSegmentsCompanion.insert(
                id: s.id,
                userId: ctx.userId,
                createdAt: now,
                clientUpdatedAt: now,
                deviceId: ctx.deviceId,
                purgeEpoch: Value(epoch),
                sessionId: id,
                kind: Value(s.kind),
                startAt: Value(s.startAt.toUtc()),
                endAt: Value(s.endAt.toUtc()),
                corrected: Value(s.corrected),
              ),
            );
        await writer.enqueue(db.sessionSegments.actualTableName, s.id);
      }
      if ((await readSnapshot())?.sessionId == id) await clearSnapshot();
      return (await get(id))!;
    });
  }

  Future<void> updateNote(String id, String? note) {
    return writer.runInTransaction(() async {
      await (db.update(_t)..where((t) => t.id.equals(id))).write(
        SessionsCompanion(note: Value(note)),
      );
      await writer.markUserWrite(_t, id);
    });
  }

  Future<void> updateSubject(String id, String? subjectId) {
    return writer.runInTransaction(() async {
      await (db.update(_t)..where((t) => t.id.equals(id))).write(
        SessionsCompanion(subjectId: Value(subjectId)),
      );
      await writer.markUserWrite(_t, id);
    });
  }

  /// User correction (away ↔ seated) of one segment: updates the segment,
  /// records a `corrections` row and recomputes `seated_seconds`.
  Future<CorrectionOutcome?> applyCorrection({
    required String sessionId,
    required String segmentId,
    required SegmentKind toKind,
    required int sensitivityBefore,
    required int sensitivityAfter,
  }) {
    return writer.runInTransaction(() async {
      final current = (await getSegments(sessionId))
          .map(
            (s) => Segment(
              id: s.id,
              kind: s.kind,
              startAt: s.startAt,
              endAt: s.endAt,
              corrected: s.corrected,
            ),
          )
          .toList();
      final outcome = _corrector.apply(
        current,
        segmentId: segmentId,
        toKind: toKind,
      );
      if (outcome == null) return null;
      final now = ctx.nowUtc();

      await (db.update(
        db.sessionSegments,
      )..where((s) => s.id.equals(segmentId))).write(
        SessionSegmentsCompanion(
          kind: Value(toKind),
          corrected: const Value(true),
        ),
      );
      await writer.markUserWrite(db.sessionSegments, segmentId, at: now);

      final correctionId = ctx.newId();
      await db
          .into(db.corrections)
          .insert(
            CorrectionsCompanion.insert(
              id: correctionId,
              userId: ctx.userId,
              createdAt: now,
              clientUpdatedAt: now,
              deviceId: ctx.deviceId,
              purgeEpoch: Value(await writer.purgeEpoch()),
              sessionId: sessionId,
              segmentId: Value(segmentId),
              fromKind: Value(outcome.fromKind),
              toKind: Value(outcome.toKind),
              at: Value(now),
              sensitivityBefore: Value(sensitivityBefore),
              sensitivityAfter: Value(sensitivityAfter),
            ),
          );
      await writer.enqueue(db.corrections.actualTableName, correctionId);

      await (db.update(_t)..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(
          seatedSeconds: Value(_calc.seatedSeconds(outcome.segments)),
          sensitivityLevel: Value(sensitivityAfter),
        ),
      );
      await writer.markUserWrite(_t, sessionId, at: now);
      return outcome;
    });
  }

  // ---------------------------------------------------------------------
  // D22 delete (session + its segments + corrections)

  Future<void> softDelete(String id) => writer.softDelete(_t, id);

  Future<void> undoDelete(String id) => writer.undoDelete(_t, id);

  Future<void> commitDelete(String id) {
    return writer.runInTransaction(() async {
      final segs = await (db.select(
        db.sessionSegments,
      )..where((s) => s.sessionId.equals(id) & s.deletedAt.isNull())).get();
      for (final s in segs) {
        await writer.commitDelete(db.sessionSegments, s.id);
      }
      final corr = await (db.select(
        db.corrections,
      )..where((c) => c.sessionId.equals(id) & c.deletedAt.isNull())).get();
      for (final c in corr) {
        await writer.commitDelete(db.corrections, c.id);
      }
      await writer.commitDelete(_t, id);
    });
  }

  // ---------------------------------------------------------------------
  // Server → local

  Future<ApplyServerReport> applyServer(Iterable<Map<String, Object?>> rows) =>
      writer.applyServer(_t, rows);

  Future<ApplyServerReport> applyServerSegments(
    Iterable<Map<String, Object?>> rows,
  ) => writer.applyServer(db.sessionSegments, rows);

  Future<ApplyServerReport> applyServerCorrections(
    Iterable<Map<String, Object?>> rows,
  ) => writer.applyServer(db.corrections, rows);

  // ---------------------------------------------------------------------
  // Snapshot (D23, single row, local only)

  Future<void> writeSnapshot(SessionSnapshot s) {
    return writer.runInTransaction(() async {
      await db.delete(db.sessionSnapshots).go();
      await db
          .into(db.sessionSnapshots)
          .insert(
            SessionSnapshotsCompanion.insert(
              sessionId: s.sessionId,
              mode: s.mode,
              segmentsJson: SessionSnapshot.encodeSegments(s.segments),
              openKind: s.openKind,
              openStart: s.openStart.toUtc(),
              lastSeatedAt: Value(s.lastSeatedAt?.toUtc()),
              awayCandidateSince: Value(s.awayCandidateSince?.toUtc()),
              sensitivity: s.sensitivity,
              savedAt: s.savedAt.toUtc(),
              subjectId: Value(s.subjectId),
              plannerItemId: Value(s.plannerItemId),
              kind: s.kind,
              startedAt: s.startedAt.toUtc(),
            ),
          );
    });
  }

  Future<SessionSnapshot?> readSnapshot() async {
    final r = await db.select(db.sessionSnapshots).getSingleOrNull();
    return r == null ? null : _snapshotOf(r);
  }

  Stream<SessionSnapshot?> watchSnapshot() => db
      .select(db.sessionSnapshots)
      .watchSingleOrNull()
      .map((r) => r == null ? null : _snapshotOf(r));

  Future<void> clearSnapshot() => db.delete(db.sessionSnapshots).go();

  SessionSnapshot _snapshotOf(SessionSnapshotRow r) => SessionSnapshot(
    sessionId: r.sessionId,
    mode: r.mode,
    kind: r.kind,
    startedAt: r.startedAt,
    segments: SessionSnapshot.decodeSegments(r.segmentsJson),
    openKind: r.openKind,
    openStart: r.openStart,
    savedAt: r.savedAt,
    sensitivity: r.sensitivity,
    lastSeatedAt: r.lastSeatedAt,
    awayCandidateSince: r.awayCandidateSince,
    subjectId: r.subjectId,
    plannerItemId: r.plannerItemId,
  );
}
