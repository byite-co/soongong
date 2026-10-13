import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/contracts/study_restore.dart';
import '../../core/contracts/transcription_engine.dart';

class RemoteStudyRestore implements StudyRestore {
  RemoteStudyRestore(this.client);
  final SupabaseClient client;
  bool _closed = false;
  void close() => _closed = true;
  Future<dynamic> _call(String name, Map<String, dynamic> args) async {
    final session = client.auth.currentSession;
    if (_closed || session == null) throw StateError('study_owner_changed');
    final value = await client
        .rpc(name, params: args)
        .timeout(const Duration(seconds: 30));
    if (_closed || !identical(session, client.auth.currentSession))
      throw StateError('study_owner_changed');
    return value;
  }

  @override
  Future<StudyMetadataPage> metadata({
    required int epoch,
    int since = 0,
    int limit = 100,
  }) async {
    final raw = Map<String, dynamic>.from(
      await _call('study_metadata_v1', {
            'p_epoch': epoch,
            'p_since': since,
            'p_limit': limit,
          })
          as Map,
    );
    if (raw['version'] != 1 ||
        raw['purge_epoch'] != epoch ||
        raw['rows'] is! List ||
        raw['next_seq'] is! int ||
        (raw['next_seq'] as int) < since)
      throw const FormatException('invalid_metadata');
    var previous = since;
    final rows = <StudySummary>[];
    for (final item in raw['rows'] as List) {
      final m = Map<String, dynamic>.from(item as Map);
      if (m['purge_epoch'] != epoch ||
          m['revision'] is! int ||
          (m['revision'] as int) < 1 ||
          m['server_seq'] is! int ||
          (m['server_seq'] as int) <= previous ||
          (m['title'] != null &&
              (m['title'] is! String ||
                  (m['title'] as String).runes.length > 80)))
        throw const FormatException('invalid_metadata');
      previous = m['server_seq'] as int;
      rows.add(
        StudySummary(
          id: m['id'] as String,
          revision: m['revision'] as int,
          kind: TranscriptionKind.values.byName(m['kind'] as String),
          title: m['title'] as String? ?? '',
          epoch: epoch,
          updatedAt: m['updated_at'] as String,
          hasBody: m['has_body'] as bool,
          hasSolution: m['has_solution'] as bool,
          hasPhoto: m['has_photo'] as bool,
          deleted: m['deleted_at'] != null,
          serverSeq: previous,
        ),
      );
    }
    if (rows.length > limit || previous != raw['next_seq'])
      throw const FormatException('invalid_cursor');
    return StudyMetadataPage(List.unmodifiable(rows), previous, epoch);
  }

  @override
  Future<Map<String, dynamic>> body({
    required int epoch,
    required String id,
    required int revision,
  }) async => Map<String, dynamic>.from(
    await _call('study_body_v1', {
          'p_epoch': epoch,
          'p_id': id,
          'p_revision': revision,
        })
        as Map,
  );
  @override
  Future<int> save({
    required int epoch,
    required String id,
    required String title,
    required String text,
    required DocumentTranscription transcription,
    int? expectedRevision,
  }) async {
    final raw = Map<String, dynamic>.from(
      await _call('study_save_v1', {
            'p_epoch': epoch,
            'p_id': id,
            'p_expected_revision': expectedRevision,
            'p_kind': transcription.kind.name,
            'p_title': title,
            'p_text': text,
            'p_transcription': transcription.toJson(),
          })
          as Map,
    );
    if (raw['version'] != 1 ||
        raw['id'] != id ||
        raw['revision'] != (expectedRevision ?? 0) + 1)
      throw const FormatException('invalid_revision');
    return raw['revision'] as int;
  }

  @override
  Future<void> saveSolution({
    required int epoch,
    required String id,
    required int revision,
    required Map<String, dynamic> solution,
  }) async {
    await _call('study_solution_v1', {
      'p_epoch': epoch,
      'p_id': id,
      'p_revision': revision,
      'p_solution': solution,
    });
  }

  @override
  Future<void> delete({required int epoch, required String id}) async {
    await _call('study_delete_v1', {'p_epoch': epoch, 'p_id': id});
  }

  @override
  Future<Map<String, dynamic>> photo({
    required int epoch,
    required String id,
    required String assetId,
  }) async => Map<String, dynamic>.from(
    await _call('study_photo_register_v1', {
          'p_epoch': epoch,
          'p_document': id,
          'p_asset': assetId,
        })
        as Map,
  );
}
