// Privacy providers (S09 · S09b): the facts the 카메라와 개인정보 screen
// shows — camera setting, recent corrections, the photo list with its
// request facts — and the two heavier actions: 내 기록 내보내기
// (ExportService + share) and 모든 기록 삭제 (server purge-all → local
// purge). `PrivacyActions` is built per account with its dependencies
// captured ([S09b]): a response arriving after an account switch is
// abandoned, and the local purge runs inside an owned transaction.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/billing_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/strings/privacy_strings.dart';
import '../../../core/strings/subjects_strings.dart';
import '../../../data/auth/auth_backend.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_mode.dart';
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
/// and completes at the next start (`completePending`).
class DeleteAllBlocked extends DeleteAllOutcome {
  const DeleteAllBlocked();
}

class DeleteAllFailed extends DeleteAllOutcome {
  const DeleteAllFailed(this.error);

  final Object error;
}

/// Records are gone (server + local) but [failedPhotos] files could not be
/// deleted; their rows stay in the photo list for a retry.
class DeleteAllPartial extends DeleteAllOutcome {
  const DeleteAllPartial({required this.failedPhotos});

  final int failedPhotos;
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

  /// 1. blocked while a session is measured; 2. `purge-all` (backend); the
  /// response is dropped if the account changed meanwhile; 3. the new epoch
  /// + a pending marker are stored; 4. inside one owned transaction: the
  /// snapshot is checked again, the photos are deleted (failed ones keep
  /// their rows), the records are purged, 기타 is recreated, the marker is
  /// cleared. Login and the subscription caches stay (PRD 4.4).
  Future<DeleteAllOutcome> deleteAll() async {
    try {
      if (_disposed) return DeleteAllFailed(StateError('account changed'));
      if (await sessions.readSnapshot() != null) return const DeleteAllBlocked();
      var epoch = await writer.purgeEpoch() + 1;
      if (serverPurge) {
        final res = await backend.invoke('purge-all');
        if (_disposed) return DeleteAllFailed(StateError('account changed'));
        final serverEpoch = res['epoch'];
        if (serverEpoch is num) epoch = serverEpoch.toInt();
      }
      await writer.runOwnedTransaction(() => purge.markPending(epoch), alive: _alive);
      return await _completeLocal(epoch);
    } on _MeasuringNow {
      return const DeleteAllBlocked();
    } on Object catch (e) {
      return DeleteAllFailed(e);
    }
  }

  /// Finishes a local purge left pending (app start, [S09b]); null when
  /// nothing is pending.
  Future<DeleteAllOutcome?> completePending() async {
    try {
      final epoch = await purge.pendingEpoch();
      if (epoch == null) return null;
      return await _completeLocal(epoch);
    } on _MeasuringNow {
      return const DeleteAllBlocked();
    } on Object catch (e) {
      return DeleteAllFailed(e);
    }
  }

  Future<DeleteAllOutcome> _completeLocal(int epoch) async {
    final photoResult = await writer.runOwnedTransaction(
      () async {
        if (await sessions.readSnapshot() != null) throw const _MeasuringNow();
        final r = await photos.wipeAll();
        await purge.run(epoch: epoch);
        await subjects.ensureDefault();
        await purge.clearPending();
        return r;
      },
      alive: _alive,
    );
    return photoResult.failed.isEmpty ? const DeleteAllDone() : DeleteAllPartial(failedPhotos: photoResult.failed.length);
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
