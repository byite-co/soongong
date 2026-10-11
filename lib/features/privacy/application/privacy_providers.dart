// Privacy providers (S09 · S09b · S09c): the facts the 카메라와 개인정보
// screen shows — camera setting, recent corrections, the photo list with
// its request facts — and the two heavier actions: 내 기록 내보내기
// (ExportService + share) and 모든 기록 삭제 (server purge-all → local
// purge). `PrivacyActions` is built per account with its dependencies
// captured ([S09b]): a response arriving after an account switch is
// abandoned, and the local purge runs inside an owned transaction.
//
// 모든 기록 삭제 stages ([S09c], `LocalPurge`):
//   requested  stored BEFORE `purge-all` is called; while the server's
//              answer is unknown nothing else is written (barrier)
//   pending    the server epoch is stored (the response, or the server
//              profile's `purge_epoch` when the response was lost); the
//              local steps follow inside one owned transaction
//   none       the marker is cleared; ordinary writes resume
// `resume()` continues whatever stage is open — at start, on foreground,
// when the measurement blocking it is resolved, when the network returns
// and when the account signs in again (`PurgeRecovery`). The server purge
// is never called a second time to retry a local step.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/billing_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/strings/privacy_strings.dart';
import '../../../core/strings/subjects_strings.dart';
import '../../../data/auth/auth_backend.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_mode.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
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
Stream<Entitlement> privacyEntitlement(Ref ref) => ref.watch(billingGatewayProvider).entitlement;

/// Corrections inside the sensitivity window (S06 `SensitivityPolicy`).
@riverpod
Future<int> recentCorrections(Ref ref) async {
  final now = ref.watch(appClockProvider).now();
  return (await ref.watch(sessionRepositoryProvider).correctionsSince(now.subtract(SensitivityPolicy.window))).length;
}

/// A photo row with the facts of its reading request (subject · range).
class PhotoRow {
  const PhotoRow({required this.photo, required this.label});

  final Photo photo;
  final String label;
}

@riverpod
Stream<List<Photo>> livePhotos(Ref ref) => ref.watch(readingRepositoryProvider).watchAllPhotos();

@riverpod
Stream<List<ReadingRequest>> privacyRequests(Ref ref) => ref.watch(readingRepositoryProvider).watchByStatus(
      ReadingRequestStatus.values.toSet(),
    );

@riverpod
Stream<List<Subject>> privacySubjects(Ref ref) => ref.watch(subjectRepositoryProvider).watchAll();

@riverpod
List<PhotoRow>? photoRows(Ref ref) {
  final photos = ref.watch(livePhotosProvider).value;
  if (photos == null) return null;
  final requests = <String, ReadingRequest>{
    for (final r in ref.watch(privacyRequestsProvider).value ?? const <ReadingRequest>[]) r.requestId: r,
  };
  final subjects = <String, Subject>{
    for (final s in ref.watch(privacySubjectsProvider).value ?? const <Subject>[]) s.id: s,
  };
  return <PhotoRow>[
    for (final p in photos)
      PhotoRow(
        photo: p,
        label: () {
          final r = p.requestId == null ? null : requests[p.requestId!];
          if (r == null) return PrivacyStrings.photoUnknownRequest;
          return PrivacyStrings.photoName(subjects[r.subjectId]?.name ?? SubjectsStrings.defaultSubjectName, r.rangeText);
        }(),
      ),
  ];
}

/// Row-less photo files a previous wipe could not delete ([S09c]); the
/// screen offers a retry. Re-read after every photo action.
@riverpod
Future<int> pendingPhotoFiles(Ref ref) {
  ref.watch(livePhotosProvider);
  return ref.watch(photoRetentionProvider).pendingSweepCount();
}

// ---------------------------------------------------------------------------
// Export · delete all

/// Sharing is a platform call; tests override this provider.
typedef ShareExport = Future<void> Function(ExportFile file);

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

/// Records are gone (server + local) but [failedPhotos] photo files could
/// not be deleted; rows keep their place in the photo list and row-less
/// files are retried at the next start / foreground.
class DeleteAllPartial extends DeleteAllOutcome {
  const DeleteAllPartial({required this.failedPhotos});

  final int failedPhotos;
}

/// `purge-all` was called but neither its answer nor the server profile
/// could be read: the intent is kept and nothing is written until the
/// server confirms or denies it ([S09c]).
class DeleteAllUnconfirmed extends DeleteAllOutcome {
  const DeleteAllUnconfirmed();
}

class _MeasuringNow implements Exception {
  const _MeasuringNow();
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
  });

  final SyncWriter writer;
  final SessionRepository sessions;
  final SubjectRepository subjects;
  final PhotoRetention photos;
  final LocalPurge purge;
  final ExportService exporter;
  final ShareExport share;
  final AuthBackend backend;

  /// true when `purge-all` must be called first (backend mode, signed in).
  final bool serverPurge;

  bool _disposed = false;
  void dispose() => _disposed = true;
  bool _alive() => !_disposed;

  /// Builds the file and opens the share sheet. Throws on failure so the
  /// screen can offer "다시 시도" with the same format.
  Future<void> export(ExportFormat format) async {
    final file = await exporter.build(format);
    await share(file);
  }

  /// 1. a stage left open is continued instead of starting over; 2. blocked
  /// while a session is measured; 3. backend: the intent is stored, then
  /// `purge-all`; a lost answer is reconciled with the server profile; 4.
  /// the epoch + pending marker are stored; 5. inside one owned
  /// transaction: the snapshot is checked again, the photos are wiped
  /// (failed ones keep their rows), the old-generation records are purged,
  /// 기타 is recreated, the marker is cleared. Login and the subscription
  /// caches stay (PRD 4.4).
  Future<DeleteAllOutcome> deleteAll() async {
    try {
      if (_disposed) return DeleteAllFailed(StateError('account changed'));
      final current = await purge.state();
      if (current.inProgress) {
        final continued = await resume();
        if (continued != null) return continued;
        // The earlier request turned out not to have purged: start over.
      }
      if (await sessions.readSnapshot() != null) return const DeleteAllBlocked();
      if (!serverPurge) {
        final epoch = current.epoch + 1;
        await writer.runOwnedTransaction(() => purge.markPending(epoch), alive: _alive, purgeWork: true);
        return await _completeLocal(epoch);
      }
      await writer.runOwnedTransaction(purge.markRequested, alive: _alive, purgeWork: true);
      Map<String, dynamic> res;
      try {
        res = await backend.invoke('purge-all');
      } on Object catch (e) {
        if (_disposed) return DeleteAllFailed(StateError('account changed')); // marker stays → resumed on return
        appLog.w('purge-all failed · asking the server profile', error: e);
        return await resume() ?? DeleteAllFailed(e); // null = the server did not purge (marker cleared)
      }
      if (_disposed) return DeleteAllFailed(StateError('account changed')); // marker stays → resumed on return
      final serverEpoch = res['epoch'];
      final epoch = serverEpoch is num ? serverEpoch.toInt() : current.epoch + 1;
      await writer.runOwnedTransaction(() => purge.markPending(epoch), alive: _alive, purgeWork: true);
      return await _completeLocal(epoch);
    } on _MeasuringNow {
      return const DeleteAllBlocked();
    } on Object catch (e) {
      return DeleteAllFailed(e);
    }
  }

  /// Continues the stage that is open — requested: the server profile's
  /// `purge_epoch` decides (larger than ours = purged → pending; equal =
  /// not purged → the intent is cleared and null is returned; unreadable =
  /// [DeleteAllUnconfirmed]); pending: the remaining local steps. null when
  /// nothing is open.
  Future<DeleteAllOutcome?> resume() async {
    try {
      if (_disposed) return null;
      final s = await purge.state();
      switch (s.stage) {
        case PurgeStage.none:
          return null;
        case PurgeStage.pending:
          return await _completeLocal(s.pendingEpoch!);
        case PurgeStage.requested:
          final serverEpoch = await _serverEpoch();
          if (_disposed) return DeleteAllFailed(StateError('account changed'));
          if (serverEpoch == null) return const DeleteAllUnconfirmed();
          if (serverEpoch > s.epoch) {
            await writer.runOwnedTransaction(() => purge.markPending(serverEpoch), alive: _alive, purgeWork: true);
            return await _completeLocal(serverEpoch);
          }
          await writer.runOwnedTransaction(purge.clearRequested, alive: _alive, purgeWork: true);
          appLog.i('purge: the server epoch is unchanged → the request did not purge · intent cleared');
          return null;
      }
    } on _MeasuringNow {
      return const DeleteAllBlocked();
    } on Object catch (e) {
      return DeleteAllFailed(e);
    }
  }

  /// The server's current `purge_epoch` for this account, or null when the
  /// profile cannot be read now (offline).
  Future<int?> _serverEpoch() async {
    try {
      final row = await backend.fetchOwnProfile();
      return row == null ? null : ProfileSnapshot.fromJson(row).purgeEpoch;
    } on Object catch (e) {
      appLog.w('purge: server profile unreadable', error: e);
      return null;
    }
  }

  Future<DeleteAllOutcome> _completeLocal(int epoch) async {
    final photoResult = await writer.runOwnedTransaction(
      () async {
        if ((await purge.state()).pendingEpoch != epoch) return null; // finished by another caller
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
    return photoResult.allDone ? const DeleteAllDone() : DeleteAllPartial(failedPhotos: photoResult.failedCount);
  }
}

/// Rebuilt when the account (write context) changes; the old instance is
/// disposed so its in-flight work stops.
@Riverpod(keepAlive: true)
PrivacyActions privacyActions(Ref ref) {
  final signedIn = ref.watch(authModeProvider) == AuthMode.backend && ref.watch(authGateProvider) is AuthGateSignedIn;
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
  return a;
}
