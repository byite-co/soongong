// PurgeRecovery (S09c): finishes a 모든 기록 삭제 that was left open —
// `requested` (the server's answer was lost) or `pending` (the server
// purged, local steps remain: blocked by a measurement, killed, a file
// that could not be deleted). It is not tied to the one-shot startup run:
// `resume()` is called at every start, when the session snapshot
// disappears (the measurement was finished or discarded), when the device
// comes back online, when the account signs in again and when the app
// returns to the foreground. The privacy screen shows [PurgeRecoveryState]
// and offers the same `resume()` as "다시 시도". A local retry never starts
// a new purge: an open request is re-sent with its own id, which the server
// replays ([S09e]); while a delete or a `purge-all` call is still running
// the state is "확인 중" and one run follows its completion ([S09d]).

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../measure/domain/session_snapshot.dart';
import 'privacy_providers.dart';

part 'purge_recovery.g.dart';

sealed class PurgeRecoveryState {
  const PurgeRecoveryState();
}

/// Nothing open.
class PurgeRecoveryIdle extends PurgeRecoveryState {
  const PurgeRecoveryIdle();
}

/// `purge-all` was called; the server could not be asked yet whether it
/// purged. Ordinary writes wait (barrier).
class PurgeRecoveryChecking extends PurgeRecoveryState {
  const PurgeRecoveryChecking();
}

/// The server purged; the local purge waits for the measurement to be
/// finished or discarded.
class PurgeRecoveryBlocked extends PurgeRecoveryState {
  const PurgeRecoveryBlocked();
}

/// The server purged; a local step failed — retry.
class PurgeRecoveryFailed extends PurgeRecoveryState {
  const PurgeRecoveryFailed(this.error);

  final Object error;
}

@Riverpod(keepAlive: true)
class PurgeRecoveryStatus extends _$PurgeRecoveryStatus {
  @override
  PurgeRecoveryState build() => const PurgeRecoveryIdle();

  void set(PurgeRecoveryState s) => state = s;
}

class PurgeRecovery {
  PurgeRecovery(this._ref);

  final Ref _ref;
  bool _started = false;
  Future<DeleteAllOutcome?>? _inFlight;
  bool _again = false;

  /// Subscribes to the triggers once (startup).
  void start() {
    if (_started) return;
    _started = true;
    _ref.listen<AsyncValue<SessionSnapshot?>>(_snapshotProvider, (prev, next) {
      if (next.hasValue && next.value == null && prev?.value != null) {
        unawaited(resume());
      }
    });
    _ref.listen<AsyncValue<bool>>(_onlineProvider, (_, next) {
      if (next.value == true) unawaited(resume());
    });
    _ref.listen<AuthGateState>(authGateProvider, (prev, next) {
      if (next is AuthGateSignedIn &&
          !next.fromCache &&
          prev?.userId != next.userId) {
        unawaited(resume());
      }
    });
  }

  /// Continues an open stage for the current account (coalesced: a call
  /// during a run makes it run once more afterwards). Returns the outcome
  /// of that run, null when nothing was open.
  Future<DeleteAllOutcome?> resume() {
    final running = _inFlight;
    if (running != null) {
      _again = true;
      return running;
    }
    final f = _run().whenComplete(() {
      _inFlight = null;
      if (_again) {
        _again = false;
        unawaited(resume());
      }
    });
    _inFlight = f;
    return f;
  }

  Future<DeleteAllOutcome?> _run() async {
    try {
      final actions = _ref.read(privacyActionsProvider);
      final outcome = await actions.resume();
      _ref.read(purgeRecoveryStatusProvider.notifier).set(switch (outcome) {
        null ||
        DeleteAllDone() ||
        DeleteAllPartial() => const PurgeRecoveryIdle(),
        DeleteAllBlocked() => const PurgeRecoveryBlocked(),
        DeleteAllUnconfirmed() => const PurgeRecoveryChecking(),
        DeleteAllFailed(:final error) => PurgeRecoveryFailed(error),
        final DeleteAllLocalPending outcome => PurgeRecoveryFailed(outcome),
      });
      if (outcome != null) appLog.i('purge recovery → ${outcome.runtimeType}');
      // [S09d] "unconfirmed" because a delete / a server call is still
      // running: run again when it finishes so the state settles by itself.
      if (outcome is DeleteAllUnconfirmed) {
        final work = actions.pendingWork;
        if (work != null) {
          unawaited(work.then((_) => resume(), onError: (_) => resume()));
        }
      }
      return outcome;
    } on Object catch (e) {
      appLog.w('purge recovery failed (${e.runtimeType})');
      _ref
          .read(purgeRecoveryStatusProvider.notifier)
          .set(PurgeRecoveryFailed(e));
      return DeleteAllFailed(e);
    }
  }
}

@riverpod
Stream<SessionSnapshot?> _snapshot(Ref ref) =>
    ref.watch(sessionRepositoryProvider).watchSnapshot();

@riverpod
Stream<bool> _online(Ref ref) => ref.watch(networkStatusProvider).online;

@Riverpod(keepAlive: true)
PurgeRecovery purgeRecovery(Ref ref) => PurgeRecovery(ref);
