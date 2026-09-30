import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/contracts.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';

void main() {
  test('pushPending: Syncing(pending) → Idle, lastSyncedAt set', () async {
    final e = FakeSyncEngine(delay: Duration.zero, pendingCount: 4);
    final states = <SyncState>[];
    final sub = e.state.listen(states.add);
    expect(e.lastSyncedAt, isNull);
    await e.pushPending();
    await Future<void>.delayed(Duration.zero);
    expect(states.first, isA<SyncIdle>());
    expect(states.whereType<SyncSyncing>().single.pending, 4);
    expect(states.last, isA<SyncIdle>());
    expect(e.lastSyncedAt, isNotNull);
    expect(e.pendingCount, 0);
    await sub.cancel();
  });

  test('pull advances the cursor monotonically; 0 restarts', () async {
    final e = FakeSyncEngine(delay: Duration.zero);
    await e.pull();
    expect(e.cursor, 10);
    await e.pull();
    expect(e.cursor, 20);
    await e.pull(sinceSeq: 0);
    expect(e.cursor, 10);
    await e.fullResync();
    expect(e.cursor, 10);
  });

  test('offline and error end states', () async {
    final e = FakeSyncEngine(delay: Duration.zero)..offline = true;
    await e.pushPending();
    expect(e.current, isA<SyncOffline>());
    e
      ..offline = false
      ..failWith = 'boom';
    await e.pull();
    expect((e.current as SyncError).message, 'boom');
    e.force(const SyncFullResyncRequired());
    expect(e.current, isA<SyncFullResyncRequired>());
    await e.dispose();
  });
}
