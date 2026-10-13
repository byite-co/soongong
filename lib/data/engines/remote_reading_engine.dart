import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart' show Value, Variable, TableInfo, Table;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/contracts/reading_engine.dart';
import '../../core/domain/enums.dart';
import '../repositories/reading_repository.dart';
import '../repositories/wrongs_repository.dart';
import '../temp/owned_temp_store.dart';
import 'transcription/remote_ai_jobs.dart';

class RemoteReadingEngine implements ReadingEngine {
  RemoteReadingEngine({
    required this.invoke,
    required this.owner,
    required this.reading,
    required this.wrongs,
    required this.upload,
    required this.ownsFile,
    required this.alive,
    this.pause = Future<void>.delayed,
  });
  factory RemoteReadingEngine.client(
    SupabaseClient client,
    ReadingRepository reading,
    WrongsRepository wrongs, {
    required bool Function() alive,
    required Future<bool> Function(String) ownsFile,
  }) => RemoteReadingEngine(
    invoke: (name, body) async {
      try {
        return Map<String, dynamic>.from(
          (await client.functions
                      .invoke(name, body: body)
                      .timeout(const Duration(seconds: 65)))
                  .data
              as Map,
        );
      } on FunctionException catch (e) {
        final details = e.details;
        if (details is Map) return Map<String, dynamic>.from(details);
        rethrow;
      }
    },
    owner: () => client.auth.currentUser?.id,
    reading: reading,
    wrongs: wrongs,
    alive: alive,
    ownsFile: ownsFile,
    upload: (path, file) async {
      final bytes = await File(file).readAsBytes();
      if (bytes.isEmpty || bytes.length > 4194304) {
        throw const FormatException('image_too_large');
      }
      try {
        if (!await ownsFile(file) ||
            !alive() ||
            client.auth.currentUser?.id != reading.ctx.userId) {
          throw StateError('image_not_owned');
        }
        await client.storage
            .from('reading-photos')
            .uploadBinary(
              path,
              bytes,
              retryAttempts: 0,
              fileOptions: FileOptions(
                contentType:
                    bytes.length > 4 && bytes[0] == 137 && bytes[1] == 80
                    ? 'image/png'
                    : 'image/jpeg',
                upsert: false,
              ),
            );
      } finally {
        bytes.fillRange(0, bytes.length, 0);
      }
    },
  );
  final StudyInvoke invoke;
  final String? Function() owner;
  final ReadingRepository reading;
  final WrongsRepository wrongs;
  final Future<void> Function(String, String) upload;
  final Future<bool> Function(String) ownsFile;
  final bool Function() alive;
  final Future<void> Function(Duration) pause;
  final Map<String, int> _generations = {};
  void _guard() {
    if (!alive() || owner() != reading.ctx.userId) {
      throw StateError('account_changed');
    }
  }

  Future<int> _generation(String id) async {
    _guard();
    return _generations[id] ??= await reading.writer.refreshPurgeGeneration();
  }

  Future<T> _owned<T>(String id, Future<T> Function() action) async =>
      reading.writer.runOwnedTransaction(
        () async {
          final result = await action();
          _guard();
          return result;
        },
        generation: await _generation(id),
        alive: () => alive() && owner() == reading.ctx.userId,
      );
  Future<Map<String, dynamic>> _call(
    String name,
    String id, [
    Map<String, dynamic> fields = const {},
  ]) async {
    await _owned(id, () async {});
    _guard();
    final out = await invoke(name, {'request_id': id, ...fields});
    await _owned(id, () async {});
    _guard();
    return out;
  }

  @override
  Future<SubmitOutcome> submit(ReadingJob job) async {
    try {
      if (!OwnedTempStore.validId(job.requestId) ||
          job.photoPaths.isEmpty ||
          job.photoPaths.length > 20) {
        throw const FormatException('invalid_images');
      }
      final paths = <String>[];
      for (var i = 0; i < job.photoPaths.length; i++) {
        await _owned(job.requestId, () async {});
        if (!await ownsFile(job.photoPaths[i])) {
          throw StateError('image_not_owned');
        }
        _guard();
        final path = '${reading.ctx.userId}/${job.requestId}/p$i.jpg';
        await upload(path, job.photoPaths[i]);
        paths.add(path);
      }
      final out = await _call('reading-submit', job.requestId, {
        'subject_id': job.subjectId,
        'range_text': job.rangeText,
        'origin': job.origin,
        'session_id': job.sessionId,
        'planner_item_id': job.plannerItemId,
        'object_paths': paths,
      });
      return switch (out['outcome']) {
        'accepted' => const SubmitAccepted(),
        'quota_exhausted' => const SubmitQuotaExhausted(),
        'active_exists' => SubmitActiveExists(out['request_id'] as String),
        'payload_mismatch' => const SubmitPayloadMismatch(),
        'request_deleted' => const SubmitRequestDeleted(),
        'invalid_state' => SubmitInvalidState(out['status'] as String),
        'not_entitled' => const SubmitNotEntitled(),
        'consent_required' => const SubmitConsentRequired(),
        _ => SubmitInvalidState(out['error'] as String? ?? 'unavailable'),
      };
    } on Object {
      return const SubmitOffline();
    }
  }

  static ReadingResult result(
    String id,
    Map<String, dynamic> raw, {
    DateTime? completed,
  }) {
    if (raw['schema_version'] != 2 || raw['pages'] is! List) {
      throw const FormatException('invalid_reading_result');
    }
    final seen = <int>{};
    final pages = <ReadingPage>[];
    for (final value in raw['pages'] as List) {
      final p = Map<String, dynamic>.from(value as Map);
      final index = p['index'];
      if (index is! int ||
          index < 0 ||
          index >= 20 ||
          !seen.add(index) ||
          p['items'] is! List ||
          (p['items'] as List).length > 500) {
        throw const FormatException('invalid_page');
      }
      final numbers = <int>{};
      final items = <ReadingItem>[];
      for (final value in p['items'] as List) {
        final i = Map<String, dynamic>.from(value as Map);
        final number = i['number'];
        final confidence = i['confidence'];
        final box = (i['box'] as List)
            .map((v) => (v as num).toDouble())
            .toList();
        if (number is! int ||
            number < 0 ||
            number > 999999 ||
            !numbers.add(number) ||
            i['needs_review'] != true ||
            (confidence != null &&
                (confidence is! num ||
                    !confidence.isFinite ||
                    confidence < 0 ||
                    confidence > 1)) ||
            box.length != 4 ||
            box.any((v) => !v.isFinite || v < 0 || v > 1) ||
            box[0] > box[2] ||
            box[1] > box[3]) {
          throw const FormatException('invalid_item');
        }
        items.add(
          ReadingItem(
            number: number,
            mark: i['mark'] == null
                ? null
                : Mark.values.byName(i['mark'] as String),
            confidence: (confidence as num?)?.toDouble(),
            box: Rect.fromLTRB(box[0], box[1], box[2], box[3]),
          ),
        );
      }
      pages.add(ReadingPage(index: index, photoPath: '', items: items));
    }
    if (pages.isEmpty ||
        pages.length > 20 ||
        pages.any((p) => p.index >= pages.length)) {
      throw const FormatException('invalid_pages');
    }
    return ReadingResult(
      requestId: id,
      pages: pages,
      completedAt: completed ?? DateTime.now().toUtc(),
    );
  }

  @override
  Stream<ReadingStatus> watch(String requestId) async* {
    final started = DateTime.now();
    while (true) {
      final out = await _call('reading-status', requestId);
      if (out['outcome'] == 'not_found' ||
          out['outcome'] == 'request_deleted' ||
          out['error'] == 'not_found' ||
          out['error'] == 'request_deleted') {
        await _owned(requestId, () => reading.applyDeleted(requestId));
        yield out['outcome'] == 'request_deleted' ||
                out['error'] == 'request_deleted'
            ? const Deleted()
            : const NotFound();
        return;
      }
      final status = out['status'];
      if (status is! String) throw const FormatException('invalid_status');
      await _owned(requestId, () async {
        if (await reading.get(requestId) != null || out['id'] == null) return;
        if (out['id'] != requestId ||
            out['user_id'] != reading.ctx.userId ||
            out['request_id'] != requestId ||
            out['purge_epoch'] != await reading.writer.purgeEpoch() ||
            out['deleted_at'] != null)
          throw StateError('stale_request_snapshot');
        final existing = await reading.db
            .customSelect(
              'SELECT id FROM reading_requests WHERE id=?',
              variables: [Variable(requestId)],
            )
            .getSingleOrNull();
        if (existing != null) throw StateError('request_deleted');
        await reading.writer.applyServer(reading.db.readingRequests, [
          Map<String, Object?>.from(out),
        ]);
      });
      await _owned(
        requestId,
        () => reading.applyStatus(
          requestId,
          status: ReadingRequestStatus.values.firstWhere(
            (s) => s.wire == status,
          ),
          serverVersion: out['server_version'] as int?,
          resultJson: Value(
            out['result_json'] == null ? null : jsonEncode(out['result_json']),
          ),
        ),
      );
      if (status == 'done_unsaved' || status == 'saved') {
        yield Done(
          result(
            requestId,
            Map<String, dynamic>.from(out['result_json'] as Map),
            completed: DateTime.tryParse(out['completed_at'] as String? ?? ''),
          ),
        );
        return;
      }
      if (!{'processing', 'taking_long', 'sending'}.contains(status)) {
        yield Failed(out['fail_reason'] as String? ?? status, retryable: false);
        return;
      }
      final late =
          status == 'taking_long' ||
          DateTime.now().difference(started).inSeconds >= 60;
      yield late ? const TakingLong() : Processing(started);
      await pause(Duration(seconds: late ? 5 : 2));
    }
  }

  @override
  Future<CancelOutcome> cancel(String id) async {
    final out = await _call('reading-cancel', id);
    if (out['outcome'] == 'cancelled') return const CancelCancelled();
    if (out['outcome'] == 'already_done') {
      return CancelAlreadyDone(
        result(id, Map<String, dynamic>.from(out['result'] as Map)),
      );
    }
    if (out['outcome'] == 'already_failed') return const CancelAlreadyFailed();
    throw StateError('cancel_unavailable');
  }

  static Map<String, Object?> _mark(ConfirmedMark m) => {
    'page_index': m.pageIndex,
    'number': m.number,
    'mark': m.mark.name,
    'wrong_item_id': m.wrongItemId,
  };
  static WrongItemDraft _item(Map<String, dynamic> i) => WrongItemDraft(
    id: i['id'] as String,
    pageIndex: i['page_index'] as int,
    number: i['number'] as int,
    mark: Mark.values.byName(i['mark'] as String),
    confidence: (i['confidence'] as num?)?.toDouble(),
    userConfirmed: i['user_confirmed'] == true,
  );
  Future<List<WrongItemDraft>> _mirror(
    String id,
    Map<String, dynamic> out,
  ) => _owned(id, () async {
    final request = await reading.get(id);
    if (request == null || request.stamp.userId != reading.ctx.userId) {
      throw StateError('request_deleted');
    }
    final items = (out['items'] as List)
        .map((v) => _item(Map<String, dynamic>.from(v as Map)))
        .toList();
    final entries = (out['entries'] as List).map((v) {
      final e = Map<String, dynamic>.from(v as Map);
      return ReviewEntryDraft(
        id: e['id'] as String,
        wrongItemId: e['wrong_item_id'] as String,
        dueAt: DateTime.parse(e['due_at'] as String),
        intervalDays: e['interval_days'] as int,
        consecutiveCorrect: e['consecutive_correct'] as int,
      );
    }).toList();
    final itemIds = items.map((i) => i.id).toSet();
    if (itemIds.length != items.length ||
        entries.any((e) => !itemIds.contains(e.wrongItemId))) {
      throw const FormatException('invalid_saved_items');
    }
    final epoch = await reading.writer.purgeEpoch();
    for (final table in <TableInfo<Table, Object?>>[
      reading.db.wrongItems,
      reading.db.reviewEntries,
    ]) {
      final key = table.actualTableName == 'wrong_items' ? 'items' : 'entries';
      final rows = <Map<String, Object?>>[];
      for (final raw in out[key] as List) {
        final row = Map<String, Object?>.from(raw as Map);
        if (row['purge_epoch'] != epoch ||
            (key == 'items' && row['request_id'] != id) ||
            (row['user_id'] != null && row['user_id'] != reading.ctx.userId)) {
          throw StateError('stale_saved_items');
        }
        final existing = await reading.db
            .customSelect(
              'SELECT user_id,deleted_at,server_version FROM ${table.actualTableName} WHERE id=?',
              variables: [Variable(row['id'] as String)],
            )
            .getSingleOrNull();
        if (existing != null) {
          if (existing.read<String>('user_id') != reading.ctx.userId) {
            throw StateError('id_reused');
          }
          if (existing.data['deleted_at'] != null ||
              ((existing.data['server_version'] as int? ?? 0) >
                  (row['server_version'] as int? ?? 0))) {
            continue;
          }
        }
        row['user_id'] = reading.ctx.userId;
        rows.add(row);
      }
      await reading.writer.applyServer(table, rows);
    }
    for (final old in await wrongs.getByRequest(id)) {
      if (itemIds.contains(old.id)) continue;
      await reading.writer.hideLocally(reading.db.wrongItems, old.id);
      final children = await (reading.db.select(
        reading.db.reviewEntries,
      )..where((e) => e.wrongItemId.equals(old.id))).get();
      for (final child in children) {
        await reading.writer.hideLocally(reading.db.reviewEntries, child.id);
      }
    }
    await reading.applyStatus(
      id,
      status: ReadingRequestStatus.saved,
      marksJson: Value(jsonEncode(out['marks'])),
    );
    return items;
  });
  @override
  Future<SaveOutcome> save(
    String id,
    List<ConfirmedMark> marks,
    List<WrongItemDraft> items,
  ) async {
    try {
      final out = await _call('reading-save', id, {
        'marks': marks.map(_mark).toList(),
        'items': items
            .map(
              (i) => {
                'id': i.id,
                'page_index': i.pageIndex,
                'number': i.number,
                'mark': i.mark.name,
                'confidence': i.confidence,
                'user_confirmed': i.userConfirmed,
              },
            )
            .toList(),
      });
      if (out['outcome'] == 'saved' || out['outcome'] == 'already_saved') {
        final saved = await _mirror(id, out);
        return out['outcome'] == 'saved'
            ? const SaveSaved()
            : SaveAlreadySaved(
                marks: (out['marks'] as List)
                    .map((m) => Map<String, dynamic>.from(m as Map))
                    .map(
                      (m) => ConfirmedMark(
                        pageIndex: m['page_index'] as int,
                        number: m['number'] as int,
                        mark: Mark.values.byName(m['mark'] as String),
                        wrongItemId: m['wrong_item_id'] as String?,
                      ),
                    )
                    .toList(),
                serverItems: saved,
              );
      }
      if (out['outcome'] == 'not_unsaved') {
        return SaveNotUnsaved(out['status'] as String);
      }
      return SaveFailed(out['outcome'] as String? ?? 'unavailable');
    } on Object {
      return const SaveOffline();
    }
  }

  @override
  Future<UpdateMarksOutcome> updateMarks(
    String id,
    List<ConfirmedMark> marks,
    List<ReviewEntryDraft> entries,
  ) async {
    try {
      final out = await _call('reading-update-marks', id, {
        'marks': marks.map(_mark).toList(),
        'entries': entries
            .map(
              (e) => {
                'id': e.id,
                'wrong_item_id': e.wrongItemId,
                'due_at': e.dueAt.toUtc().toIso8601String(),
                'interval_days': e.intervalDays,
                'consecutive_correct': e.consecutiveCorrect,
              },
            )
            .toList(),
      });
      if (out['outcome'] == 'updated') {
        return MarksUpdated(await _mirror(id, out));
      }
      if (out['outcome'] == 'not_saved') {
        return MarksNotSaved(out['status'] as String);
      }
      return MarksFailed(out['outcome'] as String? ?? 'unavailable');
    } on Object {
      return const MarksOffline();
    }
  }

  @override
  Future<void> discard(String id) async {
    final out = await _call('reading-discard', id);
    if (out['outcome'] != 'discarded') throw StateError('discard_unavailable');
    await _owned(
      id,
      () => reading.applyStatus(id, status: ReadingRequestStatus.discarded),
    );
  }

  @override
  Future<QuotaSnapshot> quota() async {
    _guard();
    final out = await invoke('reading-quota', {});
    _guard();
    return QuotaSnapshot(
      used: out['used'] as int,
      reserved: out['reserved'] as int,
      limit: out['limit'] as int,
      fetchedAt: DateTime.now().toUtc(),
    );
  }
}

class UnavailableReadingEngine implements ReadingEngine {
  const UnavailableReadingEngine();
  Never _unavailable() => throw StateError('engine_unavailable');
  @override
  Future<SubmitOutcome> submit(ReadingJob j) async => _unavailable();
  @override
  Stream<ReadingStatus> watch(String id) =>
      Stream.error(StateError('engine_unavailable'));
  @override
  Future<CancelOutcome> cancel(String id) async => _unavailable();
  @override
  Future<SaveOutcome> save(
    String id,
    List<ConfirmedMark> m,
    List<WrongItemDraft> i,
  ) async => _unavailable();
  @override
  Future<UpdateMarksOutcome> updateMarks(
    String id,
    List<ConfirmedMark> m,
    List<ReviewEntryDraft> e,
  ) async => _unavailable();
  @override
  Future<void> discard(String id) async => _unavailable();
  @override
  Future<QuotaSnapshot> quota() async => _unavailable();
}
