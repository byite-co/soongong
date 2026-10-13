import 'transcription_engine.dart';

enum StudyCacheState { missing, loading, available, error }

class StudySummary {
  const StudySummary({
    required this.id,
    required this.revision,
    required this.kind,
    required this.title,
    required this.epoch,
    required this.updatedAt,
    this.hasBody = true,
    this.hasSolution = false,
    this.hasPhoto = false,
    this.deleted = false,
    this.serverSeq,
    this.cache = StudyCacheState.missing,
  });
  final String id, title, updatedAt;
  final int revision, epoch;
  final TranscriptionKind kind;
  final bool hasBody, hasSolution, hasPhoto, deleted;
  final int? serverSeq;
  final StudyCacheState cache;
}

class StudyMetadataPage {
  const StudyMetadataPage(this.rows, this.nextSeq, this.epoch);
  final List<StudySummary> rows;
  final int nextSeq, epoch;
}

/// Executable remote foundation; no background/full S13 scheduler is implied.
abstract interface class StudyRestore {
  Future<StudyMetadataPage> metadata({
    required int epoch,
    int since = 0,
    int limit = 100,
  });
  Future<Map<String, dynamic>> body({
    required int epoch,
    required String id,
    required int revision,
  });
  Future<int> save({
    required int epoch,
    required String id,
    required String title,
    required String text,
    required DocumentTranscription transcription,
    int? expectedRevision,
  });
  Future<void> saveSolution({
    required int epoch,
    required String id,
    required int revision,
    required Map<String, dynamic> solution,
  });
  Future<void> delete({required int epoch, required String id});
  Future<Map<String, dynamic>> photo({
    required int epoch,
    required String id,
    required String assetId,
  });
}
