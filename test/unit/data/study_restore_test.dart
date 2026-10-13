import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/study_restore.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/data/export/export_service.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/study_repository.dart';

import 'db_test_helpers.dart';

class BodyTransport implements StudyRestore {
  final entered = Completer<void>();
  final response = Completer<Map<String, dynamic>>();
  final calls = <String>[];
  @override
  Future<Map<String, dynamic>> body({
    required int epoch,
    required String id,
    required int revision,
  }) {
    calls.add(id);
    entered.complete();
    return response.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const tr = DocumentTranscription(
  kind: TranscriptionKind.text,
  engine: 'fixture',
  blocks: [],
);
StudySummary meta(
  String id, {
  int revision = 1,
  int seq = 1,
  bool deleted = false,
}) => StudySummary(
  id: id,
  revision: revision,
  kind: TranscriptionKind.text,
  title: 'bounded title',
  epoch: 0,
  updatedAt: '2026-10-13',
  serverSeq: seq,
  deleted: deleted,
);
Map<String, dynamic> body(String id, {int revision = 1}) => {
  'version': 1,
  'id': id,
  'revision': revision,
  'purge_epoch': 0,
  'text': 'private full body',
  'transcription': tr.toJson(),
  'solution': null,
};
void main() {
  late TestHarness h;
  late StudyRepository repo;
  late int generation;
  var alive = true;
  setUp(() async {
    h = TestHarness();
    alive = true;
    repo = StudyRepository(h.db, h.writer, alive: () => alive);
    generation = await h.writer.refreshPurgeGeneration();
  });
  tearDown(() => h.close());
  Future<void> seed() => repo.applyMetadata(
    StudyMetadataPage([meta('a'), meta('b', seq: 2)], 2, 0),
    generation,
  );
  test(
    'FD-04/05 list and offline miss never read remote or fabricate an empty body',
    () async {
      await seed();
      final remote = BodyTransport();
      expect((await repo.list()).map((m) => m.title), [
        'bounded title',
        'bounded title',
      ]);
      expect(
        await repo.loadBody('a', remote, generation: generation, online: false),
        isNull,
      );
      expect(await h.raw('study_documents', 'a'), isNull);
      expect(remote.calls, isEmpty);
      expect(await repo.cacheState('a'), StudyCacheState.missing);
      final pending = repo.loadBody('a', remote, generation: generation);
      await remote.entered.future;
      expect(await repo.cacheState('a'), StudyCacheState.loading);
      expect(await repo.cacheState('b'), StudyCacheState.missing);
      remote.response.complete(body('a'));
      expect((await pending)!.text, 'private full body');
      expect(await repo.cacheState('a'), StudyCacheState.available);
      expect(
        (await repo.loadBody('a', remote, generation: generation))!.text,
        'private full body',
      );
      expect(remote.calls, ['a']);
    },
  );
  test(
    'FD-11 pending purge suppresses the list before physical row cleanup',
    () async {
      await seed();
      await LocalPurge(h.db, h.ctx).markPending(1);
      expect(await repo.list(), isEmpty);
      expect(await h.raw('study_metadata', 'a'), isNotNull);
    },
  );
  for (final online in [true, false]) {
    test(
      'FD-07 cached return rejects an old purge generation online=$online',
      () async {
        final oldGeneration = generation;
        final purge = LocalPurge(h.db, h.ctx);
        await purge.markPending(1);
        await purge.run(epoch: 1);
        await purge.clearPending();
        final fresh = await h.writer.refreshPurgeGeneration();
        final saved = await repo.save(
          transcription: tr,
          text: 'new generation',
          generation: fresh,
        );
        final remote = BodyTransport();
        await expectLater(
          repo.loadBody(
            saved.id,
            remote,
            generation: oldGeneration,
            online: online,
          ),
          throwsA(isA<StateError>()),
        );
        expect(remote.calls, isEmpty);
        expect((await repo.get(saved.id))!.text, 'new generation');
      },
    );
  }
  test(
    'FD-05 invalid body enters error; metadata remains and no body is saved',
    () async {
      await seed();
      final remote = BodyTransport();
      final pending = repo.loadBody('a', remote, generation: generation);
      final failure = expectLater(pending, throwsFormatException);
      await remote.entered.future;
      remote.response.complete({...body('a'), 'text': ''});
      await failure;
      expect(await repo.cacheState('a'), StudyCacheState.error);
      expect(await repo.get('a'), isNull);
      expect(await repo.list(), hasLength(2));
    },
  );
  for (final boundary in ['delete', 'revision', 'purge', 'owner']) {
    test('FD-06/07 selected body after $boundary is discarded', () async {
      await seed();
      final remote = BodyTransport();
      final pending = repo.loadBody('a', remote, generation: generation);
      final failure = expectLater(pending, throwsA(isA<StateError>()));
      await remote.entered.future;
      switch (boundary) {
        case 'delete':
          await repo.delete('a', generation);
        case 'revision':
          await repo.applyMetadata(
            StudyMetadataPage([meta('a', revision: 2, seq: 3)], 3, 0),
            generation,
          );
        case 'purge':
          final purge = LocalPurge(h.db, h.ctx);
          await purge.markPending(1);
          await purge.run(epoch: 1);
        case 'owner':
          alive = false;
          await h.db.wipeAll();
      }
      remote.response.complete(body('a'));
      await failure;
      expect(await h.raw('study_documents', 'a'), isNull);
    });
  }
  test(
    'FD-06 same-revision remote solution change invalidates cached body',
    () async {
      await seed();
      final remote = BodyTransport()..response.complete(body('a'));
      await repo.loadBody('a', remote, generation: generation);
      await repo.applyMetadata(
        StudyMetadataPage([meta('a', seq: 3)], 3, 0),
        generation,
      );
      expect(await repo.get('a'), isNull);
      expect(await repo.cacheState('a'), StudyCacheState.missing);
    },
  );
  test(
    'FD-06 local dirty edit and tombstone cannot be overwritten by a remote page',
    () async {
      await seed();
      final remote = BodyTransport()..response.complete(body('a'));
      await repo.loadBody('a', remote, generation: generation);
      await repo.save(
        transcription: tr,
        text: 'local edit',
        generation: generation,
        id: 'a',
        expectedRevision: 1,
      );
      await repo.applyMetadata(
        StudyMetadataPage([meta('a', revision: 3, seq: 4)], 4, 0),
        generation,
      );
      expect((await repo.get('a'))!.text, 'local edit');
      await repo.delete('a', generation);
      await repo.applyMetadata(
        StudyMetadataPage([meta('a', revision: 4, seq: 5)], 5, 0),
        generation,
      );
      expect(await repo.get('a'), isNull);
      expect((await repo.list()).map((m) => m.id), ['b']);
    },
  );
  test(
    'FD-11 metadata export excludes other owners; wipe includes both raw tables',
    () async {
      await seed();
      await h.db.customStatement(
        "INSERT INTO study_metadata SELECT 'other','u2',purge_epoch,revision,kind,'other private',has_body,has_solution,has_photo,cache_state,deleted,server_seq,updated_at FROM study_metadata WHERE id='a'",
      );
      final exported = await ExportService(db: h.db, userId: 'u1').exportMap();
      expect(exported.toString(), isNot(contains('other private')));
      expect((exported['tables'] as Map)['study_documents'], isEmpty);
      expect((exported['tables'] as Map)['study_metadata'], hasLength(2));
      await h.db.wipeAll();
      expect(
        await h.db.customSelect('SELECT * FROM study_metadata').get(),
        isEmpty,
      );
      expect(
        await h.db.customSelect('SELECT * FROM study_documents').get(),
        isEmpty,
      );
    },
  );
}
