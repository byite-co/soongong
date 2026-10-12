import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/contracts/transcription_engine.dart';

class RemoteTranscriptionEngine implements TranscriptionEngine {
  RemoteTranscriptionEngine(this.client);
  final SupabaseClient client;

  @override
  Future<DocumentTranscription> transcribe(Uint8List image, TranscriptionKind kind, {required int epoch}) async {
    if (image.isEmpty || image.length > 4 * 1024 * 1024) {
      throw const StudyEngineException('image_too_large');
    }
    final response = await client.functions.invoke('study-infer', body: {
      'schema_version': 1, 'operation': 'ocr', 'kind': kind.name,
      'image': base64Encode(image), 'purge_epoch': epoch,
      'consent_version': 'study-2026-10-13',
    }).timeout(const Duration(seconds: 65));
    return DocumentTranscription.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
