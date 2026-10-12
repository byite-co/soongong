import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/contracts/problem_solver.dart';
import '../../core/contracts/transcription_engine.dart';
import '../db/app_database.dart';
import 'local_purge.dart';
import 'sync_writer.dart';

class StudyDocument {
  const StudyDocument({required this.id, required this.text, required this.revision, required this.kind, this.solution});
  final String id;
  final String text;
  final int revision;
  final TranscriptionKind kind;
  final Map<String, dynamic>? solution;
}

class StudyRepository {
  StudyRepository(this.db, this.writer);
  final AppDatabase db;
  final SyncWriter writer;

  Future<StudyDocument> save({required DocumentTranscription transcription, required String text,
      required int generation, String? id, int? expectedRevision, String? plannerItemId}) =>
      writer.runOwnedTransaction(() async {
        if (text.trim().isEmpty || text.length > 20000) throw ArgumentError('invalid_text');
        final epoch = (await LocalPurge.readState(db)).epoch;
        final existing = id == null ? null : await get(id);
        if (id != null && (existing == null || existing.revision != expectedRevision)) {
          throw StateError('document_changed');
        }
        if (plannerItemId != null) {
          final item = await (db.select(db.plannerItems)..where((p) =>
            p.id.equals(plannerItemId) & p.userId.equals(writer.ctx.userId) & p.deletedAt.isNull())).getSingleOrNull();
          if (item == null) throw StateError('planner_item_unavailable');
        }
        final documentId = id ?? writer.ctx.newId();
        final revision = (existing?.revision ?? 0) + 1;
        await db.customStatement('INSERT INTO study_documents '
          '(id,user_id,purge_epoch,revision,kind,text,transcription_json,planner_item_id,updated_at) '
          'VALUES (?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET '
          'revision=excluded.revision,text=excluded.text,transcription_json=excluded.transcription_json,'
          'kind=excluded.kind,solution_json=NULL,updated_at=excluded.updated_at', [
          documentId, writer.ctx.userId, epoch, revision, transcription.kind.name, text,
          jsonEncode(transcription.toJson()), plannerItemId, writer.ctx.nowUtc().toIso8601String(),
        ]);
        return StudyDocument(id: documentId, text: text, revision: revision, kind: transcription.kind);
      }, generation: generation);

  Future<StudyDocument?> get(String id) async {
    final row = await db.customSelect('SELECT * FROM study_documents WHERE id=? AND user_id=?',
      variables: [Variable(id), Variable(writer.ctx.userId)]).getSingleOrNull();
    return row == null ? null : _document(row);
  }

  Future<List<StudyDocument>> list() async => (await db.customSelect(
    'SELECT * FROM study_documents WHERE user_id=? ORDER BY updated_at DESC LIMIT 100',
    variables: [Variable(writer.ctx.userId)],
  ).get()).map(_document).toList();

  Future<void> delete(String id, int generation) => writer.runOwnedTransaction(() async {
    await db.customStatement('DELETE FROM study_documents WHERE id=? AND user_id=?', [id, writer.ctx.userId]);
  }, generation: generation);

  Future<void> saveSolution(String id, int revision, Map<String, Object?> solution, int generation) =>
    writer.runOwnedTransaction(() async {
      final current = await get(id);
      if (current == null || current.revision != revision) throw StateError('document_changed');
      final parsed = ProblemSolution.fromJson(Map<String, dynamic>.from(solution));
      if (parsed.documentId != id || parsed.revision != revision) throw StateError('solution_document_mismatch');
      await db.customStatement('UPDATE study_documents SET solution_json=? WHERE id=? AND user_id=?',
        [jsonEncode(parsed.toJson()), id, writer.ctx.userId]);
    }, generation: generation);

  static StudyDocument _document(QueryRow row) => StudyDocument(
    id: row.read<String>('id'), text: row.read<String>('text'), revision: row.read<int>('revision'),
    kind: TranscriptionKind.values.byName(row.read<String>('kind')),
    solution: row.readNullable<String>('solution_json') == null ? null :
      jsonDecode(row.read<String>('solution_json')) as Map<String, dynamic>,
  );
}
