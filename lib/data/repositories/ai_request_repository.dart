import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../core/contracts/transcription_engine.dart';
import '../engines/transcription/remote_ai_jobs.dart';
import 'local_purge.dart';
import 'study_repository.dart';

class PendingAiRequest {
  PendingAiRequest(this.row);
  final Map<String, dynamic> row;
  String get id => row['request_id'] as String;
  int get epoch => row['purge_epoch'] as int;
  int get generation => row['generation'] as int;
  String get operation => row['operation'] as String;
  String get state => row['state'] as String;
  String? get pointsState => row['points_state'] as String?;
  bool get expired => row['result_expired'] == 1;
  String? get documentId => row['document_id'] as String?;
  int? get revision => row['document_revision'] as int?;
  String? get correction => row['corrected_text'] as String?;
  DocumentTranscription? get transcription => row['result_json'] == null
      ? null
      : DocumentTranscription.fromJson(
          jsonDecode(row['result_json'] as String) as Map<String, dynamic>,
        );
}

/// Uses the same encrypted file and transaction barrier as confirmed documents.
class AiRequestRepository {
  AiRequestRepository(this.documents, {this.accessAllowed});
  final StudyRepository documents;
  final bool Function()? accessAllowed;
  Future<T> _owned<T>(int? generation, Future<T> Function() action) =>
      documents.writer.runOwnedTransaction(
        action,
        generation: generation,
        alive: () =>
            (documents.alive?.call() ?? true) &&
            (accessAllowed?.call() ?? true),
      );

  Future<void> prepare(
    AiApproval approval,
    Map<String, dynamic> input,
  ) => _owned(approval.generation, () async {
    final purge = await LocalPurge.readState(documents.db);
    if (purge.epoch != approval.epoch ||
        !{'ocr_text', 'ocr_math'}.contains(approval.operation)) {
      throw StateError('stale_approval');
    }
    final digest = sha256.convert(utf8.encode(jsonEncode(input))).toString();
    // INSERT (never replace) makes an ID collision or repeated dispatch fail closed.
    await documents.db.customStatement(
      'INSERT INTO study_ai_requests '
      '(request_id,user_id,purge_epoch,generation,quote_id,operation,input_digest,approved,created_at,state) VALUES(?,?,?,?,?,?,?,1,?,?)',
      [
        approval.requestId,
        documents.writer.ctx.userId,
        approval.epoch,
        approval.generation,
        approval.quoteId,
        approval.operation,
        digest,
        documents.writer.ctx.nowUtc().toIso8601String(),
        'submitting',
      ],
    );
  });

  Future<PendingAiRequest?> get(String id) => _owned(null, () async {
    final purge = await LocalPurge.readState(documents.db);
    final row = await documents.db
        .customSelect(
          'SELECT * FROM study_ai_requests WHERE request_id=? AND user_id=? AND purge_epoch=?',
          variables: [
            Variable(id),
            Variable(documents.writer.ctx.userId),
            Variable(purge.epoch),
          ],
        )
        .getSingleOrNull();
    return row == null ? null : PendingAiRequest(row.data);
  });
  Future<List<PendingAiRequest>> list() => _owned(null, () async {
    final purge = await LocalPurge.readState(documents.db);
    final rows = await documents.db
        .customSelect(
          'SELECT * FROM study_ai_requests WHERE user_id=? AND purge_epoch=? ORDER BY created_at DESC LIMIT 100',
          variables: [
            Variable(documents.writer.ctx.userId),
            Variable(purge.epoch),
          ],
        )
        .get();
    return rows.map((r) => PendingAiRequest(r.data)).toList();
  });

  Future<void> record(String id, Map<String, dynamic> job) async {
    final old = await get(id);
    if (old == null) throw StateError('request_unavailable');
    await _owned(old.generation, () async {
      if (old.documentId != null &&
          await documents.get(old.documentId!) == null) {
        throw StateError('document_deleted');
      }
      if (job['version'] != 2 ||
          job['request_id'] != id ||
          !{
            'reserved',
            'dispatching',
            'succeeded',
            'failed',
            'cancelled',
            'reconciliation_required',
          }.contains(job['state'])) {
        throw const FormatException('invalid_job');
      }
      final expired = job['result_expired'] == true;
      final raw = job['result'];
      if (raw != null) {
        final result = DocumentTranscription.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        if ('ocr_${result.kind.name}' != old.operation ||
            job['state'] != 'succeeded' ||
            expired) {
          throw const FormatException('invalid_job');
        }
      }
      await documents.db.customStatement(
        'UPDATE study_ai_requests SET state=?,points_state=?,result_json=?,result_expired=? WHERE request_id=? AND user_id=?',
        [
          job['state'],
          job['points_state'],
          raw == null ? null : jsonEncode(raw),
          expired ? 1 : 0,
          id,
          documents.writer.ctx.userId,
        ],
      );
    });
  }

  Future<void> correct(
    String id,
    String text,
    int generation,
  ) => _owned(generation, () async {
    if (text.length > 20000) throw ArgumentError('invalid_text');
    await documents.db.customStatement(
      'UPDATE study_ai_requests SET corrected_text=? WHERE request_id=? AND user_id=?',
      [text, id, documents.writer.ctx.userId],
    );
  });
  Future<StudyDocument> confirm(
    String id,
    String text,
    int generation, {
    int? expectedRevision,
    String? plannerItemId,
  }) => _owned(generation, () async {
    final request = await get(id);
    if (request == null ||
        request.expired ||
        request.state != 'succeeded' ||
        request.transcription == null) {
      throw StateError('result_unavailable');
    }
    if (request.documentId != null && expectedRevision == null) {
      final existing = await documents.get(request.documentId!);
      if (existing == null) throw StateError('document_deleted');
      return existing;
    }
    final result = await documents.save(
      transcription: request.transcription!,
      text: text,
      generation: generation,
      id: request.documentId,
      expectedRevision: expectedRevision,
      plannerItemId: plannerItemId,
    );
    await documents.db.customStatement(
      'UPDATE study_ai_requests SET corrected_text=?,document_id=?,document_revision=? WHERE request_id=? AND user_id=?',
      [text, result.id, result.revision, id, documents.writer.ctx.userId],
    );
    return result;
  });
}
