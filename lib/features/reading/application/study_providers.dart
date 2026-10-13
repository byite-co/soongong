import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/contracts/problem_solver.dart';
import '../../../core/contracts/study_restore.dart';
import '../../../core/contracts/transcription_engine.dart';
import '../../../data/engines/transcription/remote_ai_jobs.dart';
import '../../../data/engines/transcription/remote_problem_solver.dart';
import '../../../data/engines/transcription/remote_transcription_engine.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/repositories/ai_request_repository.dart';
import '../../../data/repositories/remote_study_restore.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/study_repository.dart';
import 'ai_approval_controller.dart';

final aiApprovalControllerProvider = Provider<AiApprovalController>((ref) {
  ref.watch(currentUserIdProvider);
  final controller = AiApprovalController();
  ref.onDispose(controller.close);
  return controller;
});
final aiRequestRepositoryProvider = Provider<AiRequestRepository>((ref) {
  final owner = ref.watch(currentUserIdProvider);
  return AiRequestRepository(
    ref.watch(studyRepositoryProvider),
    accessAllowed: () {
      final gate = ref.read(authGateProvider);
      return gate is AuthGateSignedIn &&
          gate.userId == owner &&
          gate.profile?.readingConsentActive == true;
    },
  );
});
final aiRequestsProvider = FutureProvider.autoDispose((ref) {
  ref.watch(studyGenerationProvider);
  ref.watch(authGateProvider);
  return ref.watch(aiRequestRepositoryProvider).list();
});
final remoteAiJobsProvider = Provider<RemoteAiJobs?>((ref) {
  if (!AppConfig.hasBackendConfig || !AppConfig.devOcrEnabled) return null;
  final controller = ref.watch(aiApprovalControllerProvider);
  final repository = ref.watch(aiRequestRepositoryProvider);
  late RemoteAiJobs jobs;
  jobs = RemoteAiJobs(
    Supabase.instance.client,
    approve: (op, epoch) => controller.approve(jobs, op, epoch),
    beforeSend: repository.prepare,
    onJob: repository.record,
    checkCurrent: controller.check,
  );
  return jobs;
});

final transcriptionEngineProvider = Provider<TranscriptionEngine?>((ref) {
  final jobs = ref.watch(remoteAiJobsProvider);
  return jobs == null ? null : RemoteTranscriptionEngine.withJobs(jobs);
});

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  var alive = true;
  ref.onDispose(() => alive = false);
  return StudyRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    alive: () => alive,
  );
});

final studyRestoreProvider = Provider<StudyRestore?>((ref) {
  ref.watch(currentUserIdProvider);
  if (!AppConfig.hasBackendConfig) {
    return null;
  }
  final remote = RemoteStudyRestore(Supabase.instance.client);
  ref.onDispose(remote.close);
  return remote;
});

final studyGenerationProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.syncMeta)
        ..where((m) => m.key.equals('purge_generation')))
      .watchSingleOrNull()
      .map((row) => int.tryParse(row?.value ?? '') ?? 0);
});

final studyDocumentsProvider = FutureProvider.autoDispose<List<StudySummary>>((
  ref,
) {
  ref.watch(studyGenerationProvider);
  return ref.watch(studyRepositoryProvider).list();
});

// Only the opened document reads its cached body. No automatic remote restore yet.
final studyDocumentProvider = FutureProvider.autoDispose
    .family<StudyDocument?, String>((ref, id) {
      ref.watch(studyDocumentsProvider);
      return ref.watch(studyRepositoryProvider).get(id);
    });

final problemSolverProvider = Provider<ProblemSolver?>(
  (ref) => AppConfig.hasBackendConfig
      ? RemoteProblemSolver(Supabase.instance.client)
      : null,
);
