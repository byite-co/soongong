import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/local_date.dart';
import 'package:soongong/data/repositories/study_repository.dart';
import 'package:soongong/data/repositories/sync_writer.dart';
import 'package:soongong/data/repositories/write_context.dart';

import 'db_test_helpers.dart';

const _transcription = DocumentTranscription(
  kind: TranscriptionKind.text,
  blocks: [
    TranscriptionBlock(text: 'confirmed', box: [0, 0, 1, 1]),
  ],
  engine: 'fixture',
);

void main() {
  late TestHarness h;
  late StudyRepository repo;
  setUp(() {
    h = TestHarness();
    repo = StudyRepository(h.db, h.writer);
  });
  tearDown(() => h.close());

  for (final owner in ['u1', 'u2']) {
    test(
      'RC05-INT04 UUID collision preserves the $owner original row',
      () async {
        final generation = await h.writer.refreshPurgeGeneration();
        final original = await repo.save(
          transcription: _transcription,
          text: 'original',
          generation: generation,
        );
        final before = await h.raw('study_documents', original.id);
        final colliding = StudyRepository(
          h.db,
          SyncWriter(
            h.db,
            WriteContext(
              userId: owner,
              deviceId: h.ctx.deviceId,
              clock: h.clock,
              newId: () => original.id,
            ),
          ),
        );
        await expectLater(
          colliding.save(
            transcription: _transcription,
            text: 'collision',
            generation: generation,
          ),
          throwsA(isA<Exception>()),
        );
        expect(await h.raw('study_documents', original.id), before);
        expect(await repo.list(), hasLength(1));
      },
    );
  }

  test(
    'RC05-INT04 pending planner is refused and undo restores eligibility',
    () async {
      final planner = await h.planner.createItem(
        kind: PlannerKind.study,
        title: 'math',
        date: const LocalDate(2026, 10, 13),
      );
      final generation = await h.writer.refreshPurgeGeneration();
      await h.planner.softDeleteItem(planner.id);
      await expectLater(
        repo.save(
          transcription: _transcription,
          text: 'pending',
          generation: generation,
          plannerItemId: planner.id,
        ),
        throwsStateError,
      );
      expect(await repo.list(), isEmpty);
      await h.planner.undoDeleteItem(planner.id);
      final saved = await repo.save(
        transcription: _transcription,
        text: 'after undo',
        generation: generation,
        plannerItemId: planner.id,
      );
      expect(
        (await h.raw('study_documents', saved.id))!['planner_item_id'],
        planner.id,
      );
    },
  );

  test(
    'RC05-INT04 ordinary edit advances revision and stale edit changes nothing',
    () async {
      final generation = await h.writer.refreshPurgeGeneration();
      final first = await repo.save(
        transcription: _transcription,
        text: 'first',
        generation: generation,
      );
      final edited = await repo.save(
        transcription: _transcription,
        text: 'second',
        generation: generation,
        id: first.id,
        expectedRevision: first.revision,
      );
      expect(edited.revision, 2);
      final before = await h.raw('study_documents', first.id);
      await expectLater(
        repo.save(
          transcription: _transcription,
          text: 'stale',
          generation: generation,
          id: first.id,
          expectedRevision: first.revision,
        ),
        throwsStateError,
      );
      expect(await h.raw('study_documents', first.id), before);
    },
  );
}
