import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/contracts/transcription_engine.dart';
import '../../../data/engines/transcription/remote_transcription_engine.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../data/repositories/study_repository.dart';

final transcriptionEngineProvider = Provider<TranscriptionEngine?>((ref) =>
  AppConfig.hasBackendConfig ? RemoteTranscriptionEngine(Supabase.instance.client) : null);

final studyRepositoryProvider = Provider<StudyRepository>((ref) =>
  StudyRepository(ref.watch(appDatabaseProvider), ref.watch(syncWriterProvider)));

final studyDocumentsProvider = FutureProvider.autoDispose<List<StudyDocument>>((ref) =>
  ref.watch(studyRepositoryProvider).list());
