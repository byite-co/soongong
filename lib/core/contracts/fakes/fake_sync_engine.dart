// Fake SyncEngine (S01). State is forced from the dev menu.

import 'dart:async';

import '../sync_engine.dart';

class FakeSyncEngine implements SyncEngine {
  FakeSyncEngine({
    this.delay = const Duration(milliseconds: 500),
    this.pendingCount = 3,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Duration delay;

  /// Outbox rows reported while syncing.
  int pendingCount;

  /// When true, every operation ends in [SyncOffline].
  bool offline = false;

  /// When non-null, every operation ends in [SyncError].
  String? failWith;

  final DateTime Function() _now;
  final StreamController<SyncState> _controller =
      StreamController<SyncState>.broadcast();
  SyncState _current = const SyncIdle();
  DateTime? _lastSyncedAt;
  int? cursor;

  SyncState get current => _current;

  void force(SyncState state) => _emit(state);

  void _emit(SyncState s) {
    _current = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  Future<void> _run(Future<void> Function() body) async {
    if (offline) {
      _emit(const SyncOffline());
      return;
    }
    _emit(SyncSyncing(pendingCount));
    await Future<void>.delayed(delay);
    final err = failWith;
    if (err != null) {
      _emit(SyncError(err));
      return;
    }
    await body();
    _lastSyncedAt = _now();
    _emit(const SyncIdle());
  }

  @override
  Future<void> pushPending() => _run(() async {
        pendingCount = 0;
      });

  @override
  Future<void> pull({int? sinceSeq}) => _run(() async {
        final from = sinceSeq ?? cursor ?? 0;
        cursor = from + 10;
      });

  @override
  Future<void> fullResync() => _run(() async {
        cursor = 10;
        pendingCount = 0;
      });

  @override
  Stream<SyncState> get state => _replayLatest(() => _current, _controller.stream);

  @override
  DateTime? get lastSyncedAt => _lastSyncedAt;

  Future<void> dispose() => _controller.close();
}

/// Emits the current value on listen, then every later emission. Subscribes
/// synchronously so nothing emitted right after `listen` is missed.
Stream<T> _replayLatest<T>(T Function() current, Stream<T> source) {
  late StreamController<T> out;
  StreamSubscription<T>? sub;
  out = StreamController<T>(
    onListen: () {
      out.add(current());
      sub = source.listen(out.add, onError: out.addError, onDone: out.close);
    },
    onCancel: () => sub?.cancel(),
  );
  return out.stream;
}
