import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/engines/transcription/remote_ai_jobs.dart';
import 'package:soongong/data/repositories/ai_request_repository.dart';
import 'package:soongong/data/repositories/study_repository.dart';
import 'package:soongong/data/repositories/sync_writer.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'db_test_helpers.dart';

const id = '11111111-1111-4111-8111-111111111111';
const quote = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> response({
  String state = 'succeeded',
  bool expired = false,
}) => {
  'version': 2,
  'job_id': quote,
  'request_id': id,
  'state': state,
  'points_state': state == 'succeeded' ? 'settled' : 'reserved',
  'result_expired': expired,
  'result': state == 'succeeded' && !expired
      ? {
          'schema_version': 1,
          'kind': 'text',
          'engine': 'fixture',
          'blocks': [
            {
              'text': 'original',
              'box': [0, 0, 1, 1],
              'confidence': null,
            },
          ],
        }
      : null,
};
void main() {
  late TestHarness h;
  late AiRequestRepository repo;
  setUp(() {
    h = TestHarness();
    repo = AiRequestRepository(StudyRepository(h.db, h.writer));
  });
  tearDown(() => h.close());
  Future<void> prepare() async {
    final g = await h.writer.refreshPurgeGeneration();
    await repo.prepare(
      AiApproval(
        requestId: id,
        quoteId: quote,
        operation: 'ocr_text',
        epoch: 0,
        generation: g,
      ),
      {'image': 'private-image', 'kind': 'text'},
    );
  }

  test(
    'A06 encrypted request identity commits before HTTP; no image in record',
    () async {
      var calls = 0;
      final owner = Object();
      final jobs = RemoteAiJobs.withTransport(
        session: () => owner,
        approve: (op, e) async => const AiApproval(
          requestId: id,
          quoteId: quote,
          operation: 'ocr_text',
          epoch: 0,
        ),
        beforeSend: repo.prepare,
        onJob: repo.record,
        invoke: (name, body) async {
          calls++;
          expect((await repo.get(id))!.state, 'submitting');
          expect(
            (await repo.get(id))!.row.toString(),
            isNot(contains('private-image')),
          );
          return response();
        },
      );
      await jobs.execute({
        'operation': 'ocr',
        'kind': 'text',
        'purge_epoch': 0,
        'image': 'private-image',
      });
      expect(calls, 1);
      await expectLater(
        jobs.execute({
          'operation': 'ocr',
          'kind': 'text',
          'purge_epoch': 0,
          'image': 'private-image',
        }),
        throwsA(anything),
      );
      expect(calls, 1);
    },
  );
  test(
    'A08 pending recovery only records state; missing usage and point facts not invented',
    () async {
      await prepare();
      await repo.record(id, response(state: 'reconciliation_required'));
      expect((await repo.get(id))!.transcription, isNull);
      expect(await repo.documents.list(), isEmpty);
      await expectLater(repo.confirm(id, 'x', 0), throwsStateError);
    },
  );
  test(
    'A09 expired success cannot become an empty confirmed document',
    () async {
      await prepare();
      await repo.record(id, response(expired: true));
      await expectLater(repo.confirm(id, 'x', 0), throwsStateError);
      expect(await repo.documents.list(), isEmpty);
    },
  );
  test(
    'A10 purge and owner boundary reject late result and confirmation',
    () async {
      await prepare();
      await LocalPurge(h.db, h.ctx).markPending(1);
      await LocalPurge(h.db, h.ctx).run(epoch: 1);
      await expectLater(repo.record(id, response()), throwsStateError);
      expect(await repo.list(), isEmpty);
    },
  );
  test(
    'A11 confirmation atomic idempotence revision CAS and deleted document no resurrection',
    () async {
      await prepare();
      await repo.record(id, response());
      await repo.correct(id, 'edited', 0);
      expect(await repo.documents.list(), isEmpty);
      final first = await repo.confirm(id, 'edited', 0);
      final again = await repo.confirm(id, 'ignored duplicate', 0);
      expect(again.id, first.id);
      expect(again.text, 'edited');
      expect((await repo.documents.list()).length, 1);
      final second = await repo.confirm(
        id,
        'revision two',
        0,
        expectedRevision: 1,
      );
      expect(second.revision, 2);
      await expectLater(
        repo.confirm(id, 'stale', 0, expectedRevision: 1),
        throwsStateError,
      );
      await repo.documents.delete(first.id, 0);
      await expectLater(repo.confirm(id, 'resurrect', 0), throwsStateError);
    },
  );
  test(
    'A07 file close/reopen retains request correction and document link',
    () async {
      final dir = await Directory.systemTemp.createTemp('next02_recovery_');
      final file = File('${dir.path}/encrypted.sqlite');
      AppDatabase open() => AppDatabase(
        NativeDatabase(
          file,
          setup: (db) {
            db.execute("PRAGMA key='synthetic-next02-test-key'");
          },
        ),
      );
      var db = open();
      var writer = SyncWriter(db, h.ctx);
      var durable = AiRequestRepository(StudyRepository(db, writer));
      try {
        await writer.refreshPurgeGeneration();
        await durable.prepare(
          const AiApproval(
            requestId: id,
            quoteId: quote,
            operation: 'ocr_text',
            epoch: 0,
          ),
          {'image': 'never persisted'},
        );
        await db.close();
        db = open();
        writer = SyncWriter(db, h.ctx);
        durable = AiRequestRepository(StudyRepository(db, writer));
        await durable.record(id, response());
        await durable.correct(id, 'after restart', 0);
        final document = await durable.confirm(id, 'after restart', 0);
        await db.close();
        db = open();
        durable = AiRequestRepository(
          StudyRepository(db, SyncWriter(db, h.ctx)),
        );
        expect((await durable.get(id))!.correction, 'after restart');
        expect((await durable.confirm(id, 'duplicate', 0)).id, document.id);
        expect((await durable.documents.list()).length, 1);
        await db.wipeAll();
        expect(await durable.list(), isEmpty);
      } finally {
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
