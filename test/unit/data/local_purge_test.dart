// LocalPurge (S09 · S09b, 모든 기록 삭제): every record of the user leaves
// the device — sync tables · outbox · conflicts · snapshot · cursor — the
// server epoch is stored, photo rows are left to PhotoRetention, another
// user's rows are untouched, and the pending marker round-trips.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  Future<int> count(String table, {String? userId}) async {
    final where = userId == null ? '' : " WHERE user_id = '$userId'";
    return (await h.db.customSelect('SELECT COUNT(*) AS n FROM $table$where').getSingle()).read<int>('n');
  }

  test('purges the user, keeps other users, stores the epoch', () async {
    final math = await h.subjects.create(name: '수학', colorIndex: 1);
    await h.sessions.saveFinished(
      id: 'sess-1',
      kind: SessionKind.study,
      mode: SessionMode.manual,
      startedAt: kT0,
      endedAt: kT0.add(const Duration(minutes: 10)),
      status: SessionStatus.finished,
      segments: <Segment>[Segment(id: 'seg-1', kind: SegmentKind.manual, startAt: kT0, endAt: kT0.add(const Duration(minutes: 10)))],
      sensitivityLevel: 0,
      subjectId: math.id,
    );
    await h.planner.createItem(kind: PlannerKind.todo, title: '프린트', date: LocalDate.of(kT0));
    await h.settings.setDailyGoalMinutes(150);
    await h.reading.addPhoto(localPath: 'p/1.jpg', takenAt: kT0, width: 1, height: 1, pageIndex: 0);
    await h.sessions.writeSnapshot(
      SessionSnapshot(
        sessionId: 'live',
        mode: SessionMode.manual,
        kind: SessionKind.self,
        startedAt: kT0,
        segments: const <Segment>[],
        openKind: SegmentKind.manual,
        openStart: kT0,
        savedAt: kT0,
        sensitivity: 0,
      ),
    );
    await h.db.into(h.db.syncMeta).insertOnConflictUpdate(SyncMetaCompanion.insert(key: LocalPurge.cursorKey, value: '42'));

    // Another user's subject on the same device.
    final other = WriteContext(userId: 'u2', deviceId: 'dev-a', clock: h.clock, newId: () => 'other-1');
    await SubjectRepository(h.db, SyncWriter(h.db, other)).create(name: '영어', colorIndex: 2);

    expect(await count(h.db.syncOutbox.actualTableName), greaterThan(0));
    expect(await count('subjects', userId: 'u1'), 1);

    await LocalPurge(h.db, h.ctx).run(epoch: 7);

    for (final t in h.db.syncTables) {
      expect(await count(t.actualTableName, userId: 'u1'), 0, reason: t.actualTableName);
    }
    expect(await count(h.db.photos.actualTableName), 1, reason: 'photo rows belong to PhotoRetention.wipeAll (failed files keep their row, S09b)');
    expect(await count(h.db.syncOutbox.actualTableName), 0);
    expect(await count(h.db.syncConflicts.actualTableName), 0);
    expect(await count(h.db.sessionSnapshots.actualTableName), 0);
    expect(await h.sessions.readSnapshot(), isNull);
    expect(await h.writer.purgeEpoch(), 7);
    final cursor = await (h.db.select(h.db.syncMeta)..where((m) => m.key.equals(LocalPurge.cursorKey))).getSingleOrNull();
    expect(cursor, isNull);
    expect(await count('subjects', userId: 'u2'), 1, reason: 'other account untouched');
    expect(await h.subjects.getAll(), isEmpty);
  });

  test('pending marker: markPending stores the epoch + marker, run keeps the epoch, clearPending removes the marker', () async {
    final purge = LocalPurge(h.db, h.ctx);
    expect(await purge.pendingEpoch(), isNull);
    await purge.markPending(5);
    expect(await purge.pendingEpoch(), 5);
    expect(await h.writer.purgeEpoch(), 5);
    await purge.run(epoch: 5);
    expect(await purge.pendingEpoch(), 5, reason: 'run alone does not close the marker');
    await purge.clearPending();
    expect(await purge.pendingEpoch(), isNull);
    expect(await h.writer.purgeEpoch(), 5);
  });
}
