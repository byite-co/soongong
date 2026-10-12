import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/contracts/problem_solver.dart';
import '../../../core/contracts/transcription_engine.dart';
import '../../../data/engines/transcription/remote_problem_solver.dart';
import '../../../data/engines/transcription/remote_transcription_engine.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/study_repository.dart';

final transcriptionEngineProvider = Provider<TranscriptionEngine?>((ref) =>
  AppConfig.hasBackendConfig ? RemoteTranscriptionEngine(Supabase.instance.client) : null);

final studyRepositoryProvider = Provider<StudyRepository>((ref) =>
  StudyRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider)));

final studyGenerationProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.syncMeta)..where((m) => m.key.equals('purge_generation')))
    .watchSingleOrNull().map((row) => int.tryParse(row?.value ?? '') ?? 0);
});

final studyDocumentsProvider = FutureProvider.autoDispose<List<StudyDocument>>((ref) {
  ref.watch(studyGenerationProvider);
  return ref.watch(studyRepositoryProvider).list();
});

final problemSolverProvider = Provider<ProblemSolver?>((ref) =>
  AppConfig.hasBackendConfig ? RemoteProblemSolver(Supabase.instance.client) : null);
