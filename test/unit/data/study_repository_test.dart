import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/study_repository.dart';
import 'package:soongong/data/repositories/sync_writer.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;
  late StudyRepository repo;
  const transcription = DocumentTranscription(kind: TranscriptionKind.text, blocks: [
    TranscriptionBlock(text: '손글씨', box: [0, 0, 1, 1]),
  ], engine: 'test');
  setUp(() { h = TestHarness(); repo = StudyRepository(h.db, h.writer); });
  tearDown(() => h.close());

  test('confirmed revision invalidates previous solution and rejects stale edits', () async {
    final generation = await h.writer.refreshPurgeGeneration();
    final first = await repo.save(transcription: transcription, text: 'x+1', generation: generation);
    await repo.saveSolution(first.id, first.revision, {'answer': '2'}, generation);
    final second = await repo.save(transcription: transcription, text: 'x+2', generation: generation, id: first.id, expectedRevision: 1);
    expect(second.revision, 2);
    expect((await repo.get(first.id))!.solution, isNull);
    await expectLater(repo.saveSolution(first.id, 1, {'answer': '2'}, generation), throwsStateError);
  });
  test('purge barrier refuses late OCR and local-only documents are purged', () async {
    final generation = await h.writer.refreshPurgeGeneration();
    await repo.save(transcription: transcription, text: 'old', generation: generation);
    final purge = LocalPurge(h.db, h.ctx);
    await purge.markPending(1);
    await expectLater(repo.save(transcription: transcription, text: 'late', generation: generation), throwsA(isA<PurgeBarrierError>()));
    await purge.run(epoch: 1);
    expect(await repo.list(), isEmpty);
  });
  test('whole account wipe includes custom local table', () async {
    final generation = await h.writer.refreshPurgeGeneration();
    await repo.save(transcription: transcription, text: 'private', generation: generation);
    await h.db.wipeAll();
    expect(await repo.list(), isEmpty);
  });
  test('malformed response cannot become a transcription', () {
    expect(() => DocumentTranscription.fromJson({'schema_version': 1, 'kind': 'text', 'engine': 'test',
      'blocks': [{'text': 'x', 'box': [1, 0, 0, 1], 'confidence': 0.5}],
    }), throwsFormatException);
  });
}
