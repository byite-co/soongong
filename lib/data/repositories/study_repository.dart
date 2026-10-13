import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/contracts/problem_solver.dart';
import '../../core/contracts/study_restore.dart';
import '../../core/contracts/transcription_engine.dart';
import '../db/app_database.dart';
import 'local_purge.dart';
import 'sync_writer.dart';

class StudyDocument {
  const StudyDocument({
    required this.id,
    required this.text,
    required this.revision,
    required this.kind,
    this.solution,
  });
  final String id;
  final String text;
  final int revision;
  final TranscriptionKind kind;
  final Map<String, dynamic>? solution;
}

class StudyRepository {
  StudyRepository(this.db, this.writer, {this.alive});
  final AppDatabase db;
  final SyncWriter writer;
  final bool Function()? alive;
  void _guard() {
    if (alive != null && !alive!()) {
      throw StateError('study_owner_changed');
    }
  }

  static String titleFor(String text) => String.fromCharCodes(
    text.replaceAll(RegExp(r'[\r\n\t]'), ' ').trim().runes.take(80),
  );

  Future<StudyDocument> save({
    required DocumentTranscription transcription,
    required String text,
    required int generation,
    String? id,
    int? expectedRevision,
    String? plannerItemId,
  }) => writer.runOwnedTransaction(
    () async {
      if (text.trim().isEmpty || text.length > 20000) {
        throw ArgumentError('invalid_text');
      }
      final epoch = (await LocalPurge.readState(db)).epoch;
      final existing = id == null ? null : await get(id);
      if (id != null &&
          (existing == null || existing.revision != expectedRevision)) {
        throw StateError('document_changed');
      }
      if (plannerItemId != null) {
        final item =
            await (db.select(db.plannerItems)..where(
                  (p) =>
                      p.id.equals(plannerItemId) &
                      p.userId.equals(writer.ctx.userId) &
                      p.deletedAt.isNull() &
                      p.pendingDeleteUntil.isNull(),
                ))
                .getSingleOrNull();
        if (item == null) {
          throw StateError('planner_item_unavailable');
        }
      }
      final documentId = id ?? writer.ctx.newId();
      final revision = (existing?.revision ?? 0) + 1;
      if (existing == null) {
        if (await _summary(documentId) != null) {
          throw Exception('document_changed');
        }
        // A generated ID is a new row, never permission to overwrite a row
        // that happens to have the same ID (including another account's row).
        await db.customStatement(
          'INSERT INTO study_documents '
          '(id,user_id,purge_epoch,revision,kind,text,transcription_json,planner_item_id,updated_at) '
          'VALUES (?,?,?,?,?,?,?,?,?)',
          [
            documentId,
            writer.ctx.userId,
            epoch,
            revision,
            transcription.kind.name,
            text,
            jsonEncode(transcription.toJson()),
            plannerItemId,
            writer.ctx.nowUtc().toIso8601String(),
          ],
        );
      } else {
        await db.customStatement(
          'UPDATE study_documents SET revision=?,text=?,transcription_json=?,'
          'kind=?,solution_json=NULL,updated_at=? WHERE id=? AND user_id=? AND revision=?',
          [
            revision,
            text,
            jsonEncode(transcription.toJson()),
            transcription.kind.name,
            writer.ctx.nowUtc().toIso8601String(),
            documentId,
            writer.ctx.userId,
            expectedRevision,
          ],
        );
      }
      await db.customStatement(
        'INSERT INTO study_metadata (id,user_id,purge_epoch,revision,kind,title,has_body,has_solution,has_photo,cache_state,updated_at) '
        "VALUES (?,?,?,?,?,?,1,0,0,'available',?) ON CONFLICT(id) DO UPDATE SET "
        'revision=excluded.revision,kind=excluded.kind,title=excluded.title,has_body=1,has_solution=0,server_seq=NULL,cache_state=excluded.cache_state,updated_at=excluded.updated_at',
        [
          documentId,
          writer.ctx.userId,
          epoch,
          revision,
          transcription.kind.name,
          titleFor(text),
          writer.ctx.nowUtc().toIso8601String(),
        ],
      );
      _guard();
      return StudyDocument(
        id: documentId,
        text: text,
        revision: revision,
        kind: transcription.kind,
      );
    },
    generation: generation,
    alive: alive,
  );

  Future<StudyDocument?> get(String id) => writer.runOwnedTransaction(() async {
    final row = await db
        .customSelect(
          'SELECT b.id,b.text,b.revision,b.kind,b.solution_json FROM study_documents b '
          'JOIN study_metadata m ON m.id=b.id AND m.user_id=b.user_id AND m.revision=b.revision '
          'WHERE b.id=? AND b.user_id=? AND m.deleted=0',
          variables: [Variable(id), Variable(writer.ctx.userId)],
        )
        .getSingleOrNull();
    _guard();
    return row == null ? null : _document(row);
  }, alive: alive);

  Future<List<StudySummary>> list() => writer.runOwnedTransaction(
    () async {
      _guard();
      if ((await LocalPurge.readState(db)).inProgress) {
        return <StudySummary>[];
      }
      final rows = await db
          .customSelect(
            'SELECT id,user_id,purge_epoch,revision,kind,title,has_body,has_solution,has_photo,cache_state,deleted,server_seq,updated_at '
            'FROM study_metadata WHERE user_id=? AND deleted=0 ORDER BY updated_at DESC,id LIMIT 100',
            variables: [Variable(writer.ctx.userId)],
          )
          .get();
      _guard();
      return rows.map(_metadata).toList();
    },
    alive: alive,
    purgeWork: true,
  );

  Future<void> delete(String id, int generation) => writer.runOwnedTransaction(
    () async {
      await db.customStatement(
        'DELETE FROM study_documents WHERE id=? AND user_id=?',
        [id, writer.ctx.userId],
      );
      await db.customStatement(
        "UPDATE study_metadata SET deleted=1,title='',has_body=0,has_solution=0,has_photo=0,cache_state='missing' WHERE id=? AND user_id=?",
        [id, writer.ctx.userId],
      );
      await db.customStatement(
        'UPDATE study_ai_requests SET result_json=NULL,corrected_text=NULL,result_expired=1 WHERE document_id=? AND user_id=?',
        [id, writer.ctx.userId],
      );
      _guard();
    },
    generation: generation,
    alive: alive,
  );

  Future<void> saveSolution(
    String id,
    int revision,
    Map<String, Object?> solution,
    int generation,
  ) => writer.runOwnedTransaction(
    () async {
      final current = await get(id);
      if (current == null || current.revision != revision) {
        throw StateError('document_changed');
      }
      final parsed = ProblemSolution.fromJson(
        Map<String, dynamic>.from(solution),
      );
      if (parsed.documentId != id || parsed.revision != revision) {
        throw StateError('solution_document_mismatch');
      }
      await db.customStatement(
        'UPDATE study_documents SET solution_json=? WHERE id=? AND user_id=?',
        [jsonEncode(parsed.toJson()), id, writer.ctx.userId],
      );
      await db.customStatement(
        'UPDATE study_metadata SET has_solution=1,server_seq=NULL WHERE id=? AND user_id=?',
        [id, writer.ctx.userId],
      );
      _guard();
    },
    generation: generation,
    alive: alive,
  );

  Future<StudySummary?> _summary(String id) async {
    final row = await db
        .customSelect(
          'SELECT * FROM study_metadata WHERE id=? AND user_id=?',
          variables: [Variable(id), Variable(writer.ctx.userId)],
        )
        .getSingleOrNull();
    return row == null ? null : _metadata(row);
  }

  /// Explicit S13 entry point. It does not run automatically or enqueue D2 rows.
  Future<void> applyMetadata(
    StudyMetadataPage page,
    int generation,
  ) => writer.runOwnedTransaction(
    () async {
      if ((await LocalPurge.readState(db)).epoch != page.epoch) {
        throw StateError('stale_epoch');
      }
      for (final m in page.rows) {
        if (m.epoch != page.epoch ||
            m.revision < 1 ||
            m.title.runes.length > 80 ||
            m.serverSeq == null) {
          throw const FormatException('invalid_metadata');
        }
        final old = await _summary(m.id);
        if (old != null &&
            (old.deleted ||
                old.serverSeq == null ||
                old.serverSeq! >= m.serverSeq!)) {
          continue;
        }
        // A newer server sequence may contain a new solution at the SAME
        // document revision. Invalidate its body cache as one unit.
        await db.customStatement(
          'DELETE FROM study_documents WHERE id=? AND user_id=?',
          [m.id, writer.ctx.userId],
        );
        if (old != null) {
          await db.customStatement(
            'DELETE FROM study_metadata WHERE id=? AND user_id=?',
            [m.id, writer.ctx.userId],
          );
        }
        await db.customStatement(
          'INSERT INTO study_metadata(id,user_id,purge_epoch,revision,kind,title,has_body,has_solution,has_photo,cache_state,deleted,server_seq,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',
          [
            m.id,
            writer.ctx.userId,
            m.epoch,
            m.revision,
            m.kind.name,
            m.deleted ? '' : m.title,
            m.hasBody ? 1 : 0,
            m.hasSolution ? 1 : 0,
            m.hasPhoto ? 1 : 0,
            'missing',
            m.deleted ? 1 : 0,
            m.serverSeq,
            m.updatedAt,
          ],
        );
      }
      _guard();
    },
    generation: generation,
    alive: alive,
  );

  Future<StudyCacheState> cacheState(String id) =>
      writer.runOwnedTransaction(() async {
        final state = (await _summary(id))?.cache ?? StudyCacheState.missing;
        _guard();
        return state;
      }, alive: alive);

  /// No remote call for a list, cached body, or an offline cache miss.
  Future<StudyDocument?> loadBody(
    String id,
    StudyRestore remote, {
    required int generation,
    bool online = true,
  }) async {
    // Cached/offline reads must validate the caller's captured generation too.
    final cached = await writer.runOwnedTransaction(
      () => get(id),
      generation: generation,
      alive: alive,
    );
    _guard();
    if (cached != null || !online) {
      return cached;
    }
    final captured = await writer.runOwnedTransaction(
      () async {
        final m = await _summary(id);
        if (m == null || m.deleted || !m.hasBody) {
          throw StateError('document_unavailable');
        }
        if (m.cache == StudyCacheState.loading) {
          throw StateError('body_loading');
        }
        await db.customStatement(
          "UPDATE study_metadata SET cache_state='loading' WHERE id=? AND user_id=?",
          [id, writer.ctx.userId],
        );
        return m;
      },
      generation: generation,
      alive: alive,
    );
    Future<void> check() async {
      _guard();
      final current = await _summary(id);
      if (current == null ||
          current.deleted ||
          current.revision != captured.revision ||
          current.serverSeq != captured.serverSeq ||
          (await LocalPurge.readState(db)).epoch != captured.epoch) {
        throw StateError('stale_body');
      }
    }

    try {
      final body = await remote.body(
        epoch: captured.epoch,
        id: id,
        revision: captured.revision,
      );
      await writer.runOwnedTransaction(
        () async {
          await check();
          if (body['version'] != 1 ||
              body['id'] != id ||
              body['revision'] != captured.revision ||
              body['purge_epoch'] != captured.epoch ||
              body['text'] is! String ||
              (body['text'] as String).trim().isEmpty ||
              (body['text'] as String).length > 20000) {
            throw const FormatException('invalid_body');
          }
          final tr = DocumentTranscription.fromJson(
            Map<String, dynamic>.from(body['transcription'] as Map),
          );
          if (tr.kind != captured.kind) {
            throw const FormatException('invalid_body');
          }
          final raw = body['solution'];
          if (raw != null) {
            final s = ProblemSolution.fromJson(
              Map<String, dynamic>.from(raw as Map),
            );
            if (s.documentId != id || s.revision != captured.revision) {
              throw const FormatException('invalid_solution');
            }
          }
          await db.customStatement(
            'INSERT INTO study_documents(id,user_id,purge_epoch,revision,kind,text,transcription_json,solution_json,updated_at) VALUES(?,?,?,?,?,?,?,?,?)',
            [
              id,
              writer.ctx.userId,
              captured.epoch,
              captured.revision,
              captured.kind.name,
              body['text'],
              jsonEncode(tr.toJson()),
              raw == null ? null : jsonEncode(raw),
              captured.updatedAt,
            ],
          );
          await db.customStatement(
            "UPDATE study_metadata SET cache_state='available' WHERE id=? AND user_id=?",
            [id, writer.ctx.userId],
          );
          _guard();
        },
        generation: generation,
        alive: alive,
      );
      return await get(id);
    } on Object {
      await writer.runOwnedTransaction(
        () async {
          await check();
          await db.customStatement(
            "UPDATE study_metadata SET cache_state='error' WHERE id=? AND user_id=?",
            [id, writer.ctx.userId],
          );
        },
        generation: generation,
        alive: alive,
      );
      rethrow;
    }
  }

  static StudySummary _metadata(QueryRow r) => StudySummary(
    id: r.read<String>('id'),
    revision: r.read<int>('revision'),
    kind: TranscriptionKind.values.byName(r.read<String>('kind')),
    title: r.read<String>('title'),
    epoch: r.read<int>('purge_epoch'),
    updatedAt: r.read<String>('updated_at'),
    hasBody: r.read<int>('has_body') == 1,
    hasSolution: r.read<int>('has_solution') == 1,
    hasPhoto: r.read<int>('has_photo') == 1,
    deleted: r.read<int>('deleted') == 1,
    serverSeq: r.readNullable<int>('server_seq'),
    cache: StudyCacheState.values.byName(r.read<String>('cache_state')),
  );

  static StudyDocument _document(QueryRow row) => StudyDocument(
    id: row.read<String>('id'),
    text: row.read<String>('text'),
    revision: row.read<int>('revision'),
    kind: TranscriptionKind.values.byName(row.read<String>('kind')),
    solution: row.readNullable<String>('solution_json') == null
        ? null
        : jsonDecode(row.read<String>('solution_json')) as Map<String, dynamic>,
  );
}
