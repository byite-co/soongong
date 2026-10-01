import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/db/sync_tables.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  group('applyServer (D2 · no outbox · rev kept)', () {
    test('first load with content-less tombstone rows does not fail; live '
        'rows decode, tombstones are stored and hidden', () async {
      final report = await h.subjects.applyServer(<Map<String, Object?>>[
        serverRow(
          's-live',
          userId: 'u1',
          content: <String, Object?>{
            'name': '수학',
            'color_index': 1,
            'sort_order': 0,
            'is_default': false,
          },
        ),
        serverRow('s-dead', userId: 'u1', serverVersion: 3, serverSeq: 2, deleted: true),
      ]);
      expect(report.applied, 2);
      expect(report.dirtyOverwritten, isEmpty);

      final live = await h.subjects.getAll();
      expect(live.map((s) => s.name), <String>['수학']);
      expect(live.single.stamp.serverVersion, 1);
      expect(live.single.stamp.baseServerVersion, 1);
      expect(live.single.stamp.clientRev, 1);

      final dead = await h.raw('subjects', 's-dead');
      expect(dead!['deleted_at'], isNotNull);
      expect(dead['name'], isNull);
      expect(dead['server_version'], 3);
      expect(await h.subjects.get('s-dead'), isNull, reason: 'never decoded');
      expect(await h.outbox(), isEmpty, reason: 'applyServer never enqueues');
    });

    test('tombstones of child tables keep their keep-keys (wrong_items.request_id)',
        () async {
      await h.wrongs.applyServer(<Map<String, Object?>>[
        serverRow(
          'w-dead',
          userId: 'u1',
          deleted: true,
          content: <String, Object?>{'request_id': 'req-1'},
        ),
      ]);
      final row = await h.raw('wrong_items', 'w-dead');
      expect(row!['request_id'], 'req-1');
      expect(row['subject_id'], isNull);
      expect(await h.wrongs.getByRequest('req-1'), isEmpty);
    });

    test('nested JSON and booleans are normalised; local-only columns and '
        'client_rev survive; a dirty local row is reported', () async {
      final draft = await h.reading.createDraft(
        subjectId: 's',
        rangeText: 'p.1',
        origin: ReadingOrigin.home,
      );
      await h.reading.setConfirmedMarks(draft.requestId, '[{"n":3}]');
      await h.reading.updateDraft(draft.requestId, rangeText: const Value('p.2'));
      final before = await h.raw('reading_requests', draft.id);
      expect(before!['client_rev'], 2);

      final report = await h.reading.applyServer(<Map<String, Object?>>[
        serverRow(
          draft.id,
          userId: 'u1',
          serverVersion: 7,
          content: <String, Object?>{
            'request_id': draft.requestId,
            'subject_id': 's',
            'range_text': 'p.2',
            'origin': 'home',
            'status': 'done_unsaved',
            'submitted_at': '2026-09-30T03:05:00.000Z',
            'quota_charged': true,
            'result_json': <String, Object?>{'pages': <Object?>[]},
          },
        ),
      ]);
      expect(report.dirtyOverwritten, <String>[draft.id]);

      final after = await h.reading.get(draft.requestId);
      expect(after!.status.wire, 'done_unsaved');
      expect(after.quotaCharged, isTrue);
      expect(after.resultJson, '{"pages":[]}');
      expect(after.confirmedMarksJson, '[{"n":3}]', reason: 'local-only kept');
      expect(after.stamp.clientRev, 2, reason: 'rev not bumped');
      expect(after.stamp.serverVersion, 7);
      expect(after.stamp.baseServerVersion, 7);
      expect((await h.outbox('reading_requests')).length, 1, reason: 'unchanged');
    });
  });

  group('user writes', () {
    test('create → rev 1 + outbox; edit → rev 2, same unsent mutation; edit '
        'after a send → new mutation_id', () async {
      final s = await h.subjects.create(name: '국어', colorIndex: 0);
      final first = (await h.outboxRow('subjects', s.id))!;
      expect(first.sentClientRev, isNull);

      await h.subjects.update(s.id, name: '국어2');
      expect((await h.raw('subjects', s.id))!['client_rev'], 2);
      final second = (await h.outboxRow('subjects', s.id))!;
      expect(second.mutationId, first.mutationId, reason: 'unsent → same id');

      await h.markSent('subjects', s.id, 2);
      await h.subjects.update(s.id, colorIndex: 3);
      final third = (await h.outboxRow('subjects', s.id))!;
      expect(third.mutationId, isNot(first.mutationId));
      expect(third.sentClientRev, isNull);
      expect(third.attempts, 0);
      expect((await h.raw('subjects', s.id))!['client_rev'], 3);
    });

    test('commitDelete nulls content columns, keeps common + keep keys, '
        'bumps rev and enqueues', () async {
      await h.sessions.applyServer(<Map<String, Object?>>[
        serverRow(
          'sess-1',
          userId: 'u1',
          content: <String, Object?>{
            'kind': 'study',
            'mode': 'camera',
            'started_at': '2026-09-30T01:00:00.000Z',
            'ended_at': '2026-09-30T02:00:00.000Z',
            'status': 'finished',
            'seated_seconds': 3600,
            'sensitivity_level': 0,
          },
        ),
      ]);
      await h.sessions.applyServerSegments(<Map<String, Object?>>[
        serverRow(
          'seg-1',
          userId: 'u1',
          content: <String, Object?>{
            'session_id': 'sess-1',
            'kind': 'seated',
            'start_at': '2026-09-30T01:00:00.000Z',
            'end_at': '2026-09-30T02:00:00.000Z',
            'corrected': false,
          },
        ),
      ]);
      await h.sessions.commitDelete('sess-1');

      final seg = (await h.raw('session_segments', 'seg-1'))!;
      expect(seg['deleted_at'], isNotNull);
      expect(seg['session_id'], 'sess-1', reason: 'keep key');
      expect(seg['kind'], isNull);
      expect(seg['start_at'], isNull);
      expect(seg['client_rev'], 2);
      expect(seg['server_version'], 1, reason: 'common columns kept');

      final sess = (await h.raw('sessions', 'sess-1'))!;
      expect(sess['deleted_at'], isNotNull);
      expect(sess['kind'], isNull);
      expect(sess['pending_delete_until'], isNull);
      expect((await h.outbox()).map((o) => o.rowId), containsAll(<String>['sess-1', 'seg-1']));
      expect(h.db.contentColumnsOf(h.db.sessionSegments), isNot(contains('session_id')));
    });

    test('applyServerColumns updates only the given server columns and '
        'follows server_version with base', () async {
      final draft = await h.reading.createDraft(
        subjectId: 's',
        rangeText: 'p.1',
        origin: ReadingOrigin.planner,
      );
      await h.reading.applyStatus(
        draft.requestId,
        status: ReadingRequestStatus.processing,
        serverVersion: 2,
        submittedAt: DateTime.utc(2026, 9, 30, 3, 1),
        quotaMonth: '2026-09',
      );
      final r = (await h.reading.get(draft.requestId))!;
      expect(r.status, ReadingRequestStatus.processing);
      expect(r.submittedAt, DateTime.utc(2026, 9, 30, 3, 1));
      expect(r.quotaMonth, '2026-09');
      expect(r.rangeText, 'p.1');
      expect(r.stamp.serverVersion, 2);
      expect(r.stamp.baseServerVersion, 2);
      expect(r.stamp.clientRev, 1);
    });
  });
}
