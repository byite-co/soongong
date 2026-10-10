// Privacy providers (S09): the facts the 카메라와 개인정보 screen shows —
// camera setting, recent corrections, the photo list with its request
// facts — and the two heavier actions: 내 기록 내보내기 (ExportService +
// share) and 모든 기록 삭제 (server purge-all → local purge).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/billing_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/strings/privacy_strings.dart';
import '../../../core/strings/subjects_strings.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_mode.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/export/export_service.dart';
import '../../../data/export/share_export.dart';
import '../../../data/repositories/local_purge.dart';
import '../../../data/repositories/repository_providers.dart';
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
class DeleteAllBlocked extends DeleteAllOutcome {
  const DeleteAllBlocked();
}

class DeleteAllFailed extends DeleteAllOutcome {
  const DeleteAllFailed(this.error);

  final Object error;
}

class PrivacyActions {
  PrivacyActions(this._ref);

  final Ref _ref;

  /// Builds the file and opens the share sheet. Throws on failure so the
  /// screen can offer "다시 시도" with the same format.
  Future<void> export(ExportFormat format) async {
    final file = await _ref.read(exportServiceProvider).build(format);
    await _ref.read(shareExportProvider)(file);
  }

  /// `purge-all` on the server (backend mode) → every local record and photo
  /// (`LocalPurge`), then the default subject is recreated. Login and the
  /// subscription caches stay (PRD 4.4).
  Future<DeleteAllOutcome> deleteAll() async {
    try {
      final sessions = _ref.read(sessionRepositoryProvider);
      if (await sessions.readSnapshot() != null) return const DeleteAllBlocked();
      var epoch = await _ref.read(syncWriterProvider).purgeEpoch() + 1;
      final signedIn = _ref.read(authModeProvider) == AuthMode.backend && _ref.read(authGateProvider) is AuthGateSignedIn;
      if (signedIn) {
        final res = await _ref.read(authBackendProvider).invoke('purge-all');
        final serverEpoch = res['epoch'];
        if (serverEpoch is num) epoch = serverEpoch.toInt();
      }
      await _ref.read(photoRetentionProvider).wipeAll();
      await _ref.read(localPurgeProvider).run(epoch: epoch);
      await _ref.read(subjectRepositoryProvider).ensureDefault();
      return const DeleteAllDone();
    } on Object catch (e) {
      return DeleteAllFailed(e);
    }
  }
}

/// keepAlive: used across async gaps (modal confirm · share sheet).
@Riverpod(keepAlive: true)
PrivacyActions privacyActions(Ref ref) => PrivacyActions(ref);
