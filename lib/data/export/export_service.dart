// ExportService (S02 §4.4 · data-model.md §6). Pure data → bytes:
//   JSON  — one file, `schema_version`, live rows of every sync table (+
//           photos without paths), local-only columns stripped.
//   CSV   — sessions.csv · planner.csv · wrongs.csv in one zip.
// Sharing (share_plus) lives in share_export.dart so this class is testable
// without platform channels. Import is not built (D1).

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/domain/clock.dart';
import '../../core/domain/local_date.dart';
import '../db/app_database.dart';
import '../db/sync_tables.dart';
import '../repositories/repository_providers.dart';

part 'export_service.g.dart';

enum ExportFormat { json, csv }

class ExportFile {
  const ExportFile({required this.name, required this.bytes, required this.mimeType});

  final String name;
  final Uint8List bytes;
  final String mimeType;
}

class ExportService {
  ExportService({
    required this.db,
    required this.userId,
    this.clock = const SystemClock(),
    this.appVersion = '0.1.0',
  });

  static const int schemaVersion = 1;

  final AppDatabase db;
  final String userId;
  final Clock clock;
  final String appVersion;

  Future<ExportFile> build(ExportFormat format) => switch (format) {
        ExportFormat.json => buildJson(),
        ExportFormat.csv => buildCsvZip(),
      };

  // ---------------------------------------------------------------------
  // JSON

  Future<Map<String, Object?>> exportMap() async {
    final tables = <String, List<Map<String, Object?>>>{};
    for (final t in db.syncTables) {
      tables[t.actualTableName] = await _liveRows(t);
    }
    final photos = await (db.select(db.photos)
          ..where((p) => p.userId.equals(userId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.takenAt)]))
        .get();
    tables['photos'] = <Map<String, Object?>>[
      for (final p in photos) (Map<String, Object?>.of(p.toJson())..remove('local_path')),
    ];
    return <String, Object?>{
      'schema_version': schemaVersion,
      'exported_at': utcIso(clock.now()),
      'app_version': appVersion,
      'user_id': userId,
      'tables': tables,
    };
  }

  Future<ExportFile> buildJson() async {
    final map = await exportMap();
    final text = const JsonEncoder.withIndent('  ').convert(map);
    return ExportFile(
      name: 'soongong-${_stamp()}.json',
      bytes: Uint8List.fromList(utf8.encode(text)),
      mimeType: 'application/json',
    );
  }

  Future<List<Map<String, Object?>>> _liveRows(TableInfo<Table, Object?> t) async {
    final rows = await db.select(t).get();
    final out = <Map<String, Object?>>[];
    for (final r in rows) {
      final json = Map<String, Object?>.of((r as DataClass).toJson());
      if (json['user_id'] != userId) continue;
      if (json['deleted_at'] != null) continue;
      if (json['pending_delete_until'] != null) continue;
      for (final c in localOnlyColumns) {
        json.remove(c);
      }
      out.add(json);
    }
    return out;
  }

  // ---------------------------------------------------------------------
  // CSV zip

  Future<ExportFile> buildCsvZip() async {
    final subjects = <String, String>{
      for (final s in await db.select(db.subjects).get())
        if (s.deletedAt == null && s.name != null) s.id: s.name!,
    };
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('sessions.csv', _csvBytes(await sessionsCsv(subjects))))
      ..addFile(ArchiveFile.bytes('planner.csv', _csvBytes(await plannerCsv(subjects))))
      ..addFile(ArchiveFile.bytes('wrongs.csv', _csvBytes(await wrongsCsv(subjects))));
    return ExportFile(
      name: 'soongong-${_stamp()}.zip',
      bytes: ZipEncoder().encodeBytes(archive),
      mimeType: 'application/zip',
    );
  }

  Future<String> sessionsCsv(Map<String, String> subjects) async {
    final rows = await (db.select(db.sessions)
          ..where((s) => s.userId.equals(userId) & s.deletedAt.isNull() & s.pendingDeleteUntil.isNull())
          ..orderBy([(s) => OrderingTerm.asc(s.startedAt)]))
        .get();
    final lines = <String>[
      csvLine(const <Object?>[
        'id', 'date', 'started_at', 'ended_at', 'kind', 'mode', 'status',
        'subject', 'seated_minutes', 'sensitivity_level', 'note',
      ]),
      for (final s in rows)
        csvLine(<Object?>[
          s.id,
          s.startedAt == null ? '' : LocalDate.of(s.startedAt!).key,
          _local(s.startedAt),
          _local(s.endedAt),
          s.kind?.wire,
          s.mode?.wire,
          s.status?.wire,
          subjects[s.subjectId] ?? '',
          ((s.seatedSeconds ?? 0) / 60).toStringAsFixed(1),
          s.sensitivityLevel,
          s.note,
        ]),
    ];
    return lines.join('\r\n');
  }

  Future<String> plannerCsv(Map<String, String> subjects) async {
    final rows = await (db.select(db.plannerItems)
          ..where((p) => p.userId.equals(userId) & p.deletedAt.isNull() & p.pendingDeleteUntil.isNull())
          ..orderBy([(p) => OrderingTerm.asc(p.date), (p) => OrderingTerm.asc(p.sortOrder)]))
        .get();
    final lines = <String>[
      csvLine(const <Object?>[
        'id', 'date', 'kind', 'title', 'subject', 'range_text', 'target_minutes',
        'start_time', 'end_time', 'is_done', 'done_at', 'band_start', 'band_end',
      ]),
      for (final p in rows)
        csvLine(<Object?>[
          p.id,
          p.date,
          p.kind?.wire,
          p.title,
          subjects[p.subjectId] ?? '',
          p.rangeText,
          p.targetMinutes,
          p.startTime,
          p.endTime,
          p.isDone ?? false,
          _local(p.doneAt),
          p.bandStart,
          p.bandEnd,
        ]),
    ];
    return lines.join('\r\n');
  }

  Future<String> wrongsCsv(Map<String, String> subjects) async {
    final rows = await (db.select(db.wrongItems)
          ..where((w) => w.userId.equals(userId) & w.deletedAt.isNull())
          ..orderBy([(w) => OrderingTerm.asc(w.createdAt), (w) => OrderingTerm.asc(w.number)]))
        .get();
    final entries = <String, ReviewEntryRow>{
      for (final e in await (db.select(db.reviewEntries)..where((e) => e.deletedAt.isNull())).get())
        e.wrongItemId: e,
    };
    final retries = <String, int>{};
    for (final r in await (db.select(db.retryRecords)..where((r) => r.deletedAt.isNull())).get()) {
      if (r.voided ?? false) continue;
      retries[r.wrongItemId] = (retries[r.wrongItemId] ?? 0) + 1;
    }
    final lines = <String>[
      csvLine(const <Object?>[
        'id', 'request_id', 'subject', 'range_text', 'page', 'number', 'mark',
        'confidence', 'user_confirmed', 'status', 'resolved_at',
        'review_due_at', 'review_interval_days', 'retry_count',
      ]),
      for (final w in rows)
        csvLine(<Object?>[
          w.id,
          w.requestId,
          subjects[w.subjectId] ?? '',
          w.rangeText,
          w.pageIndex,
          w.number,
          w.mark?.wire,
          w.confidence?.toStringAsFixed(2),
          w.userConfirmed ?? false,
          w.status?.wire,
          _local(w.resolvedAt),
          _local(entries[w.id]?.dueAt),
          entries[w.id]?.intervalDays,
          retries[w.id] ?? 0,
        ]),
    ];
    return lines.join('\r\n');
  }

  // ---------------------------------------------------------------------
  // helpers

  String _stamp() {
    final t = clock.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}';
  }

  static String _local(DateTime? t) => t == null ? '' : t.toLocal().toIso8601String();

  /// UTF-8 with BOM so spreadsheet apps open Korean text correctly.
  static Uint8List _csvBytes(String content) =>
      Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);

  static String csvEscape(Object? v) {
    final s = v == null ? '' : v.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String csvLine(List<Object?> cells) => cells.map(csvEscape).join(',');
}

@Riverpod(keepAlive: true)
ExportService exportService(Ref ref) => ExportService(
      db: ref.watch(appDatabaseProvider),
      userId: ref.watch(currentUserIdProvider),
      clock: ref.watch(appClockProvider),
    );
