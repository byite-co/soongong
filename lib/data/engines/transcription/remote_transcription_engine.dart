import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/contracts/transcription_engine.dart';
import 'remote_ai_jobs.dart';

class RemoteTranscriptionEngine implements TranscriptionEngine {
  RemoteTranscriptionEngine(SupabaseClient client, {ApproveAi? approve})
    : jobs = RemoteAiJobs(client, approve: approve);
  RemoteTranscriptionEngine.withJobs(this.jobs);
  final RemoteAiJobs jobs;

  @override
  Future<DocumentTranscription> transcribe(
    Uint8List image,
    TranscriptionKind kind, {
    required int epoch,
  }) async {
    if (image.isEmpty || image.length > 4 * 1024 * 1024) {
      throw const StudyEngineException('image_too_large');
    }
    final response = await jobs.execute({
      'schema_version': 1,
      'operation': 'ocr',
      'kind': kind.name,
      'image': base64Encode(image),
      'purge_epoch': epoch,
      'consent_version': 'study-2026-10-13',
    });
    final result = DocumentTranscription.fromJson(response);
    if (result.kind != kind) {
      throw const StudyEngineException('invalid_transcription');
    }
    return result;
  }
}
