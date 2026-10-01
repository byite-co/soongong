import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/features/measure/domain/segment.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;
  late ExportService svc;

  setUp(() {
    h = TestHarness();
    svc = ExportService(db: h.db, userId: h.ctx.userId, clock: h.clock, appVersion: '0.1.0+1');
  });
  tearDown(() => h.close());

  test('JSON: schema_version, live rows only, local-only columns stripped, '
      'photos without paths, ISO timestamps', () async {
    final math = await h.subjects.create(name: '수학', colorIndex: 1);
    final gone = await h.subjects.create(name: '삭제됨', colorIndex: 2);
    await h.subjects.softDelete(gone.id);
    await h.subjects.commitDelete(gone.id);
    final pending = await h.subjects.create(name: '보류', colorIndex: 3);
    await h.subjects.softDelete(pending.id);
    await h.sessions.saveFinished(
      id: 'sess-1',
      kind: SessionKind.study,
      mode: SessionMode.camera,
      startedAt: kT0,
      endedAt: kT0.add(const Duration(minutes: 30)),
      status: SessionStatus.finished,
      segments: <Segment>[
        Segment(id: 'seg-1', kind: SegmentKind.seated, startAt: kT0, endAt: kT0.add(const Duration(minutes: 30))),
      ],
      sensitivityLevel: 0,
      subjectId: math.id,
      note: 'a,b "c"',
    );
    await h.reading.addPhoto(localPath: 'secret/path.jpg', takenAt: kT0, width: 1, height: 1, pageIndex: 0);

    final file = await svc.buildJson();
    expect(file.name, startsWith('soongong-'));
    expect(file.name, endsWith('.json'));
    expect(file.mimeType, 'application/json');
    final map = jsonDecode(utf8.decode(file.bytes)) as Map<String, dynamic>;
    expect(map['schema_version'], 1);
    expect(map['app_version'], '0.1.0+1');
    expect(map['exported_at'], '2026-09-30T03:00:00.000Z');
    final tables = map['tables'] as Map<String, dynamic>;
    expect(tables.keys, containsAll(<String>['subjects', 'sessions', 'session_segments', 'wrong_items', 'activity_days', 'photos']));
    expect(tables.keys, isNot(contains('sync_outbox')));
    expect(tables.keys, isNot(contains('reading_quota')));

    final subjects = tables['subjects'] as List<dynamic>;
    // commitDelete created the default subject; tombstone and pending-delete
    // rows are excluded.
    expect(subjects.map((s) => (s as Map<String, dynamic>)['name']), <String>['수학', '기타']);
    final subject = subjects.first as Map<String, dynamic>;
    expect(subject.keys, isNot(contains('client_rev')));
    expect(subject.keys, isNot(contains('base_server_version')));
    expect(subject.keys, isNot(contains('pending_delete_until')));
    expect(subject['created_at'], '2026-09-30T03:00:00.000Z');
    expect(subject['is_default'], false);

    final session = (tables['sessions'] as List<dynamic>).single as Map<String, dynamic>;
    expect(session['kind'], 'study');
    expect(session['seated_seconds'], 1800);
    expect(session['note'], 'a,b "c"');

    final photo = (tables['photos'] as List<dynamic>).single as Map<String, dynamic>;
    expect(photo.keys, isNot(contains('local_path')));
    expect(photo['page_index'], 0);
  });

  test('CSV zip: three files, BOM, header, escaping, subject names', () async {
    final math = await h.subjects.create(name: '수학', colorIndex: 1);
    await h.sessions.saveFinished(
      id: 'sess-1',
      kind: SessionKind.todo,
      mode: SessionMode.manual,
      startedAt: kT0,
      endedAt: kT0.add(const Duration(minutes: 45)),
      status: SessionStatus.finished,
      segments: <Segment>[
        Segment(id: 'seg-1', kind: SegmentKind.manual, startAt: kT0, endAt: kT0.add(const Duration(minutes: 45))),
      ],
      sensitivityLevel: 1,
      subjectId: math.id,
      note: 'line1\nline2',
    );
    await h.planner.createItem(kind: PlannerKind.study, title: '문제집, 1장', date: LocalDate.of(kT0), subjectId: math.id, rangeText: 'p.1–9');

    final file = await svc.buildCsvZip();
    expect(file.name, endsWith('.zip'));
    expect(file.mimeType, 'application/zip');
    final archive = ZipDecoder().decodeBytes(file.bytes);
    expect(archive.map((f) => f.name), containsAll(<String>['sessions.csv', 'planner.csv', 'wrongs.csv']));

    String text(String name) {
      final bytes = archive.firstWhere((f) => f.name == name).readBytes()!;
      expect(bytes.sublist(0, 3), <int>[0xEF, 0xBB, 0xBF], reason: 'UTF-8 BOM');
      return utf8.decode(bytes.sublist(3));
    }

    final sessions = text('sessions.csv').split('\r\n');
    expect(sessions.first, startsWith('id,date,started_at,ended_at,kind,mode,status,subject,seated_minutes'));
    expect(sessions[1], contains(',todo,manual,finished,수학,45.0,1,"line1\nline2"'));

    final planner = text('planner.csv').split('\r\n');
    expect(planner[1], contains('"문제집, 1장",수학,p.1–9'));
    expect(text('wrongs.csv').split('\r\n').length, 1, reason: 'header only');

    expect(ExportService.csvEscape('plain'), 'plain');
    expect(ExportService.csvEscape('a"b'), '"a""b"');
    expect(ExportService.csvEscape(null), '');
    expect(ExportService.csvLine(<Object?>[1, null, 'x,y']), '1,,"x,y"');
  });
}
