// Privacy providers (S09 · S09b · S09c): the facts the 카메라와 개인정보
// screen shows — camera setting, recent corrections, the photo list with
// its request facts — and the two heavier actions: 내 기록 내보내기
// (ExportService + share) and 모든 기록 삭제 (server purge-all → local
// purge). `PrivacyActions` is built per account with its dependencies
// captured ([S09b]): a response arriving after an account switch is
// abandoned, and the local purge runs inside an owned transaction.
//
// 모든 기록 삭제 stages ([S09c] · [S09d] · [S09e], `LocalPurge`):
//   requested  the client request id + the server epoch it was formed
//              against (profile read right before) are stored BEFORE
//              `purge-all` is called; while the server's answer is unknown
//              nothing else is written (barrier)
//   pending    the server epoch is stored (the answer, or the server
//              profile when the answer was lost); the local steps follow
//              inside one owned transaction
//   none       the marker is cleared; ordinary writes resume
// `resume()` continues whatever stage is open — at start, on foreground,
// when the measurement blocking it is resolved, when the network returns
// and when the account signs in again (`PurgeRecovery`). One operation per
// account at a time: a delete or recovery already running is joined, a
// `purge-all` call still running in this process is waited for, never
// second-guessed from the profile. The server keeps a receipt per (account,
// request id) and replays the same id without a second purge whatever ran
// in between, and supersedes a request formed against an older epoch
// (`purge_all(p_user, p_request_id, p_expected_epoch)`, [S09e]); so an
// open request is settled only by server evidence — the profile, or the
// same id sent again — never by elapsed time, and the stored epoch only
// moves forward. A new purge is never started on behalf of an old intent.

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/billing_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/ids.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/strings/privacy_strings.dart';
import '../../../core/strings/subjects_strings.dart';
import '../../../data/auth/auth_backend.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_mode.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/export/export_guard.dart';
import '../../../data/export/export_service.dart';
import '../../../data/export/share_export.dart';
import '../../../data/repositories/local_purge.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/sync_writer.dart';
import '../../measure/domain/sensitivity_policy.dart';
import 'photo_retention.dart';

part 'privacy_providers.g.dart';

@riverpod
Stream<Entitlement> privacyEntitlement(Ref ref) =>
    ref.watch(billingGatewayProvider).entitlement;

/// Corrections inside the sensitivity window (S06 `SensitivityPolicy`).
@riverpod
Future<int> recentCorrections(Ref ref) async {
  final now = ref.watch(appClockProvider).now();
  return (await ref
          .watch(sessionRepositoryProvider)
          .correctionsSince(now.subtract(SensitivityPolicy.window)))
      .length;
}

/// A photo row with the facts of its reading request (subject · range).
class PhotoRow {
  const PhotoRow({required this.photo, required this.label});

  final Photo photo;
  final String label;
}

@riverpod
Stream<List<Photo>> livePhotos(Ref ref) =>
    ref.watch(readingRepositoryProvider).watchAllPhotos();

@riverpod
Stream<List<ReadingRequest>> privacyRequests(Ref ref) => ref
    .watch(readingRepositoryProvider)
    .watchByStatus(ReadingRequestStatus.values.toSet());

@riverpod
Stream<List<Subject>> privacySubjects(Ref ref) =>
    ref.watch(subjectRepositoryProvider).watchAll();

@riverpod
List<PhotoRow>? photoRows(Ref ref) {
  final photos = ref.watch(livePhotosProvider).value;
  if (photos == null) return null;
  final requests = <String, ReadingRequest>{
    for (final r
        in ref.watch(privacyRequestsProvider).value ?? const <ReadingRequest>[])
      r.requestId: r,
  };
  final subjects = <String, Subject>{
    for (final s
        in ref.watch(privacySubjectsProvider).value ?? const <Subject>[])
      s.id: s,
  };
  return <PhotoRow>[
    for (final p in photos)
      PhotoRow(
        photo: p,
        label: () {
          final r = p.requestId == null ? null : requests[p.requestId!];
          if (r == null) return PrivacyStrings.photoUnknownRequest;
          return PrivacyStrings.photoName(
            subjects[r.subjectId]?.name ?? SubjectsStrings.defaultSubjectName,
            r.rangeText,
          );
        }(),
      ),
  ];
}

/// Row-less photo files a previous wipe could not delete ([S09c]); the
/// screen offers a retry. null = the store cannot be listed right now
/// ([S09d]). Re-read after every photo action.
@riverpod
Future<int?> pendingPhotoFiles(Ref ref) {
  ref.watch(livePhotosProvider);
  return ref.watch(photoRetentionProvider).pendingSweepCount();
}

// ---------------------------------------------------------------------------
// Export · delete all

/// Sharing is a platform call; tests override this provider.
typedef ShareExport =
    Future<void> Function(ExportFile file, {required ExportGuard guard});

@Riverpod(keepAlive: true)
ShareExport shareExport(Ref ref) => shareExportFile;

sealed class DeleteAllOutcome {
  const DeleteAllOutcome();
}

class DeleteAllDone extends DeleteAllOutcome {
  const DeleteAllDone();
}

/// A session is being measured (snapshot present) — PRD: 측정 중엔 진입 불가.
/// When the server had already been purged, the local purge stays pending
/// and continues once the measurement is resolved (`PurgeRecovery`).
class DeleteAllBlocked extends DeleteAllOutcome {
  const DeleteAllBlocked();
}

class DeleteAllFailed extends DeleteAllOutcome {
  const DeleteAllFailed(this.error);

  final Object error;
}

/// Records are gone (server + local) but photo files could not all be
/// deleted: [failedPhotos] rows / row-less files stayed (rows keep their
/// place in the photo list; row-less files are retried at the next start /
/// foreground), or the store itself could not be opened
/// ([storeUnavailable], count unknown — the retry marker stays).
class DeleteAllPartial extends DeleteAllOutcome {
  const DeleteAllPartial({
    required this.failedPhotos,
    this.storeUnavailable = false,
  });

  final int failedPhotos;
  final bool storeUnavailable;
}

/// `purge-all` was called but its answer is not known yet — the call is
/// still running, or it was lost and the server cannot say yet whether it
/// served the request. The intent (request id) is kept and nothing is
/// written until it is settled ([S09c] · [S09d]).
class DeleteAllUnconfirmed extends DeleteAllOutcome {
  const DeleteAllUnconfirmed();
}

class _MeasuringNow implements Exception {
  const _MeasuringNow();
}

/// What the server said about one request id.
sealed class PurgeAnswer {
  const PurgeAnswer();
}

/// The server handled the request: it purged now, it replays a request it
/// handled before (whatever ran in between), or it superseded a request
/// formed against an older epoch (a newer purge had already run — nothing
/// more to delete for this intent). [epoch] is the account's CURRENT epoch
/// in every case ([S09e]).
class PurgeServed extends PurgeAnswer {
  const PurgeServed(
    this.epoch, {
    required this.replayed,
    required this.superseded,
  });

  final int epoch;
  final bool replayed;
  final bool superseded;
}

/// The server answered and refused: the request was not served.
class PurgeRefused extends PurgeAnswer {
  const PurgeRefused(this.error);

  final Object error;
}

/// No answer (network · timeout · 5xx): served or not is unknown.
class PurgeUnknown extends PurgeAnswer {
  const PurgeUnknown(this.error);

  final Object error;
}

/// One `purge-all` call of this process, by request id ([S09d]). The record
/// outlives the per-account [PrivacyActions] instance that started it, so
/// a recovery run of a later instance (same account signed in again) finds
/// the call still running — or its answer — instead of asking the server
/// too early.
class PurgeCall {
  PurgeCall(this.future) {
    future.then(
      (a) => answer = a,
      onError: (Object e) => answer = PurgeUnknown(e),
    );
  }

  final Future<PurgeAnswer> future;
  PurgeAnswer? answer;

  bool get running => answer == null;
}

class PrivacyActions {
  PrivacyActions({
    required this.writer,
    required this.sessions,
    required this.subjects,
    required this.photos,
    required this.purge,
    required this.exporter,
    required this.share,
    required this.backend,
    required this.serverPurge,
    String Function()? newRequestId,
  }) : _newRequestId = newRequestId ?? newUuid {
    if (serverPurge) {
      _authSubscription = backend.sessions.listen((session) {
        if (session?.userId != writer.ctx.userId) dispose();
      });
    }
  }

  final SyncWriter writer;
  final SessionRepository sessions;
  final SubjectRepository subjects;
  final PhotoRetention photos;
  final LocalPurge purge;
  final ExportService exporter;
  final ShareExport share;
  final AuthBackend backend;
  final String Function() _newRequestId;

  /// true when `purge-all` must be called first (backend mode, signed in).
  final bool serverPurge;

  /// Process-wide `purge-all` calls by request id (see [PurgeCall]).
  static final Map<String, PurgeCall> _calls = <String, PurgeCall>{};

  /// Tests: forget the calls of earlier harnesses.
  @visibleForTesting
  static void resetCallsForTest() => _calls.clear();

  bool _disposed = false;
  StreamSubscription<AuthSession?>? _authSubscription;
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription?.cancel());
    _authSubscription = null;
  }

  bool _alive() => !_disposed;

  Future<DeleteAllOutcome?>? _inFlight;
  String? _lastRequestId;

  /// Work this instance is doing for 모든 기록 삭제 right now (a delete, a
  /// recovery run), or the server call this process is still waiting for
  /// on the open request — `PurgeRecovery` re-runs when it completes.
  Future<void>? get pendingWork {
    final own = _inFlight;
    if (own != null) return own;
    final id = _lastRequestId;
    final call = id == null ? null : _calls[id];
    return call != null && call.running ? call.future : null;
  }

  /// Builds the file and opens the share sheet. Throws on failure so the
  /// screen can offer "다시 시도" with the same format.
  Future<void> export(ExportFormat format) async {
    final generation = await writer.runOwnedTransaction(
      writer.refreshPurgeGeneration,
      alive: _alive,
    );
    final guard = ExportGuard(
      isCurrent: () =>
          !_disposed &&
          writer.purgeGeneration == generation &&
          (!serverPurge || backend.currentSession?.userId == writer.ctx.userId),
      validate: () => writer.runOwnedTransaction(
        () async {},
        alive: _alive,
        generation: generation,
      ),
    );
    ExportFile? file;
    try {
      await guard.check();
      file = await exporter.build(format);
      await guard.check();
      await share(file, guard: guard);
    } finally {
      file?.bytes.fillRange(0, file.bytes.length, 0);
    }
  }

  /// 모든 기록 삭제. A delete or recovery already running in this instance
  /// is joined (one operation per account). Then: 1. a stage left open is
  /// settled first (pending → local steps; requested → the server's verdict,
  /// re-sending the SAME id when nothing else decides — see
  /// [_settleRequested]); 2. blocked while a session is measured; 3.
  /// backend: the server profile is read (the epoch the request is formed
  /// against — offline: nothing is stored, [DeleteAllFailed]), the request
  /// id + that epoch are stored, then `purge-all`; 4. served → the epoch +
  /// pending marker are stored; refused → the intent is cleared; no answer
  /// → the profile may still show it served, else [DeleteAllUnconfirmed]
  /// with the intent kept; 5. inside one owned transaction: the snapshot is
  /// checked again, the photos are wiped (failed ones keep their rows), the
  /// old-generation records are purged, 기타 is recreated, the marker is
  /// cleared. Login and the subscription caches stay (PRD 4.4).
  Future<DeleteAllOutcome> deleteAll() async {
    final running = _inFlight;
    if (running != null) {
      final joined = await running;
      if (joined != null) return joined;
      return deleteAll();
    }
    final f = _deleteAll().whenComplete(() => _inFlight = null);
    _inFlight = f;
    return await f;
  }

  Future<DeleteAllOutcome> _deleteAll() async {
    try {
      if (_disposed) return DeleteAllFailed(StateError('account changed'));
      var current = await purge.state();
      if (current.stage == PurgeStage.pending) {
        return await _completeLocal(current.pendingEpoch!);
      }
      if (current.stage == PurgeStage.requested) {
        final settled = await _settleRequested(current, resend: true);
        if (settled != null) return settled;
        current = await purge
            .state(); // refused → cleared → a new request below
      }
      if (await sessions.readSnapshot() != null) {
        return const DeleteAllBlocked();
      }
      if (!serverPurge) {
        final epoch = await writer.runOwnedTransaction(
          () => purge.markPending(current.epoch + 1),
          alive: _alive,
          purgeWork: true,
        );
        return await _completeLocal(epoch);
      }
      // The request is formed against the server's current epoch ([S09e]):
      // a request that cannot be formed (offline) is not stored — no barrier
      // for a request the server never heard of.
      final int expected;
      try {
        final row = await backend.fetchOwnProfile();
        if (row == null) return DeleteAllFailed(StateError('no profile'));
        expected = ProfileSnapshot.fromJson(row).purgeEpoch;
      } on Object catch (e) {
        appLog.w(
          'purge-all: profile unreadable before the request (${e.runtimeType}) · nothing stored',
        );
        return DeleteAllFailed(e);
      }
      if (_disposed) return DeleteAllFailed(StateError('account changed'));
      final id = _newRequestId();
      _lastRequestId = id;
      await writer.runOwnedTransaction(
        () => purge.markRequested(id, expectedEpoch: expected),
        alive: _alive,
        purgeWork: true,
      );
      final answer = await _call(id, expected);
      if (_disposed) {
        return DeleteAllFailed(
          StateError('account changed'),
        ); // the call record keeps the answer
      }
      switch (answer) {
        case PurgeServed(:final epoch, :final superseded):
          if (superseded) {
            appLog.i(
              'purge-all: superseded by a newer purge · converging to epoch $epoch',
            );
          }
          return await _confirmServed(epoch);
        case PurgeRefused(:final error):
          await writer.runOwnedTransaction(
            purge.clearRequested,
            alive: _alive,
            purgeWork: true,
          );
          return DeleteAllFailed(error);
        case PurgeUnknown(:final error):
          appLog.w(
            'purge-all: no answer (${error.runtimeType}) · asking the server profile',
          );
          return await _settleRequested(await purge.state(), resend: false) ??
              DeleteAllFailed(error);
      }
    } on _MeasuringNow {
      return const DeleteAllBlocked();
    } on Object catch (e) {
      return DeleteAllFailed(e);
    }
  }

  /// Continues the stage that is open — requested: settled by the call this
  /// process is still waiting for, by its answer, by the server profile, or
  /// by re-sending the same id (see [_settleRequested]); pending: the
  /// remaining local steps. null when nothing is open (or the server refused
  /// the request). While this instance is already deleting or recovering
  /// the result is [DeleteAllUnconfirmed] — nothing is decided twice.
  Future<DeleteAllOutcome?> resume() async {
    if (_inFlight != null) return const DeleteAllUnconfirmed();
    final f = _resume().whenComplete(() => _inFlight = null);
    _inFlight = f;
    return f;
  }

  Future<DeleteAllOutcome?> _resume() async {
    try {
      if (_disposed) return null;
      final s = await purge.state();
      switch (s.stage) {
        case PurgeStage.none:
          return null;
        case PurgeStage.pending:
          return await _completeLocal(s.pendingEpoch!);
        case PurgeStage.requested:
          return await _settleRequested(s, resend: true);
      }
    } on _MeasuringNow {
      return const DeleteAllBlocked();
    } on Object catch (e) {
      return DeleteAllFailed(e);
    }
  }

  /// Sends `purge-all` for [requestId] (formed against [expectedEpoch]): a
  /// call still running for the same id in this process is joined.
  Future<PurgeAnswer> _call(String requestId, int? expectedEpoch) {
    final existing = _calls[requestId];
    if (existing != null && existing.running) return existing.future;
    final call = PurgeCall(_invoke(requestId, expectedEpoch));
    _calls[requestId] = call;
    return call.future;
  }

  Future<PurgeAnswer> _invoke(String requestId, int? expectedEpoch) async {
    try {
      final res = await backend.invoke(
        'purge-all',
        body: <String, dynamic>{
          'request_id': requestId,
          'expected_epoch': ?expectedEpoch,
        },
      );
      final epoch = res['epoch'];
      if (epoch is! num) {
        return PurgeUnknown(StateError('purge-all answered without an epoch'));
      }
      return PurgeServed(
        epoch.toInt(),
        replayed: res['replayed'] == true,
        superseded: res['superseded'] == true,
      );
    } on EdgeFunctionException catch (e) {
      // 4xx = the server answered and did not purge (401/403 no profile,
      // 400 bad request, 429 limit) — except a request timeout.
      if (e.status >= 400 && e.status < 500 && e.status != 408) {
        return PurgeRefused(e);
      }
      return PurgeUnknown(e);
    } on Object catch (e) {
      return PurgeUnknown(e);
    }
  }

  /// The verdict on an open request [s] (stage requested), by server
  /// evidence only — time is never evidence ([S09e]):
  ///   · a call for that id is still running in this process → unconfirmed;
  ///   · it finished → its answer (served → pending + local steps; refused →
  ///     intent cleared, null);
  ///   · the server profile as POSITIVE evidence: `purge_request_id` is ours,
  ///     or the epoch moved past the one the request was formed against →
  ///     served (the server would answer the same id with a replay or a
  ///     superseded receipt; both converge to the current epoch);
  ///   · otherwise, when [resend], the same id and expected epoch are sent
  ///     again — the server replays / supersedes a request it has seen and
  ///     never purges twice — and that answer decides; without an answer the
  ///     request stays open (barrier kept) until the next trigger or retry.
  Future<DeleteAllOutcome?> _settleRequested(
    PurgeState s, {
    required bool resend,
  }) async {
    final id = s.requestId!;
    _lastRequestId = id;
    final call = _calls[id];
    if (call != null && call.running) return const DeleteAllUnconfirmed();
    switch (call?.answer) {
      case PurgeServed(:final epoch):
        return await _confirmServed(epoch);
      case PurgeRefused():
        return await _refused();
      case PurgeUnknown() || null:
        break;
    }
    final profile = await _serverProfile();
    if (_disposed) return DeleteAllFailed(StateError('account changed'));
    if (profile != null) {
      final since = s.expectedEpoch ?? s.epoch;
      if (profile.purgeRequestId == id || profile.purgeEpoch > since) {
        return await _confirmServed(profile.purgeEpoch);
      }
    }
    if (!resend) return const DeleteAllUnconfirmed();
    final again = await _call(id, s.expectedEpoch);
    if (_disposed) return DeleteAllFailed(StateError('account changed'));
    switch (again) {
      case PurgeServed(:final epoch, :final replayed, :final superseded):
        appLog.i(
          'purge-all: resend ${superseded
              ? 'superseded'
              : replayed
              ? 'replayed'
              : 'served'} · converging to epoch $epoch',
        );
        return await _confirmServed(epoch);
      case PurgeRefused():
        return await _refused();
      case PurgeUnknown(:final error):
        appLog.w(
          'purge-all: resend without an answer (${error.runtimeType}) · the request stays open',
        );
        return const DeleteAllUnconfirmed();
    }
  }

  Future<DeleteAllOutcome?> _refused() async {
    await writer.runOwnedTransaction(
      purge.clearRequested,
      alive: _alive,
      purgeWork: true,
    );
    appLog.i('purge: the server refused the request · intent cleared');
    return null;
  }

  Future<DeleteAllOutcome> _confirmServed(int epoch) async {
    final stored = await writer.runOwnedTransaction(
      () => purge.markPending(epoch),
      alive: _alive,
      purgeWork: true,
    );
    return _completeLocal(stored);
  }

  /// The server profile, or null when it cannot be read now (offline).
  Future<ProfileSnapshot?> _serverProfile() async {
    try {
      final row = await backend.fetchOwnProfile();
      return row == null ? null : ProfileSnapshot.fromJson(row);
    } on Object catch (e) {
      appLog.w('purge: server profile unreadable (${e.runtimeType})');
      return null;
    }
  }

  Future<DeleteAllOutcome> _completeLocal(int epoch) async {
    final photoResult = await writer.runOwnedTransaction(
      () async {
        if ((await purge.state()).pendingEpoch != epoch) {
          return null; // finished by another caller
        }
        if (await sessions.readSnapshot() != null) throw const _MeasuringNow();
        final r = await photos.wipeAll(alive: _alive);
        if (_disposed) throw StateError('account changed');
        await purge.run(epoch: epoch);
        await subjects.ensureDefault();
        await purge.clearPending();
        return r;
      },
      alive: _alive,
      purgeWork: true,
    );
    if (photoResult == null) return const DeleteAllDone();
    if (photoResult.allDone) return const DeleteAllDone();
    return DeleteAllPartial(
      failedPhotos: photoResult.failedCount,
      storeUnavailable: photoResult.storeUnavailable,
    );
  }
}

/// Rebuilt when the account (write context) changes; the old instance is
/// disposed so its in-flight work stops.
@Riverpod(keepAlive: true)
PrivacyActions privacyActions(Ref ref) {
  final signedIn =
      ref.watch(authModeProvider) == AuthMode.backend &&
      ref.watch(authGateProvider) is AuthGateSignedIn;
  final a = PrivacyActions(
    writer: ref.watch(syncWriterProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    subjects: ref.watch(subjectRepositoryProvider),
    photos: ref.watch(photoRetentionProvider),
    purge: ref.watch(localPurgeProvider),
    exporter: ref.watch(exportServiceProvider),
    share: ref.watch(shareExportProvider),
    backend: ref.watch(authBackendProvider),
    serverPurge: signedIn,
  );
  ref.onDispose(a.dispose);
  // Invalidate immediately on a gate transition, even before a lazy
  // dependent-provider rebuild. A later A login never revives this instance.
  ref.listen(authGateProvider, (before, after) {
    if (before?.userId != after.userId) a.dispose();
  });
  return a;
}
