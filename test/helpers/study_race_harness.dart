import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/problem_solver.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/app_button.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/repositories/study_repository.dart';
import 'package:soongong/data/repositories/write_context.dart';
import 'package:soongong/features/reading/application/study_providers.dart';

import 'app_harness.dart';
import 'fake_auth_backend.dart';

const raceTranscription = DocumentTranscription(
  kind: TranscriptionKind.text,
  blocks: [
    TranscriptionBlock(text: 'original problem', box: [0, 0, 1, 1]),
  ],
  engine: 'fixture',
);

class SolverCall {
  SolverCall(this.id, this.revision);
  final String id;
  final int revision;
  final done = Completer<ProblemSolution>();
  void finish(String answer) => done.complete(
    ProblemSolution(
      documentId: id,
      revision: revision,
      answer: answer,
      explanation: 'explanation $answer',
      verification: SolutionVerification.inconclusive,
      model: 'fixture',
      referenceProvided: false,
    ),
  );
}

class ControlledSolver implements ProblemSolver {
  final calls = <SolverCall>[];
  @override
  Future<ProblemSolution> solve({
    required String documentId,
    required int revision,
    required String text,
    required int epoch,
    String? referenceAnswer,
  }) {
    final call = SolverCall(documentId, revision);
    calls.add(call);
    return call.done.future;
  }
}

class ControlledTranscriber implements TranscriptionEngine {
  final calls = <Completer<DocumentTranscription>>[];
  @override
  Future<DocumentTranscription> transcribe(
    Uint8List image,
    TranscriptionKind kind, {
    required int epoch,
  }) {
    final done = Completer<DocumentTranscription>();
    calls.add(done);
    return done.future;
  }
}

// Only the scheduling boundary is controlled; writes still call the actual
// repository, owner/purge transaction checks and in-memory SQL database.
class ControlledStudyRepository extends StudyRepository {
  ControlledStudyRepository(super.db, super.writer);
  Completer<void>? saveWait;
  int saves = 0;
  int solutionSaves = 0;
  int deletes = 0;
  @override
  Future<StudyDocument> save({
    required DocumentTranscription transcription,
    required String text,
    required int generation,
    String? id,
    int? expectedRevision,
    String? plannerItemId,
  }) async {
    saves++;
    await saveWait?.future;
    return super.save(
      transcription: transcription,
      text: text,
      generation: generation,
      id: id,
      expectedRevision: expectedRevision,
      plannerItemId: plannerItemId,
    );
  }

  @override
  Future<void> saveSolution(
    String id,
    int revision,
    Map<String, Object?> solution,
    int generation,
  ) async {
    solutionSaves++;
    await saveWait?.future;
    await super.saveSolution(id, revision, solution, generation);
  }

  @override
  Future<void> delete(String id, int generation) async {
    deletes++;
    await super.delete(id, generation);
  }
}

Future<void> pumpStudy(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<T> completeStudy<T>(WidgetTester tester, Future<T> pending) async {
  await pumpStudy(tester);
  return pending;
}

Future<void> pressStudy(WidgetTester tester, String label) async {
  final button = find.widgetWithText(AppButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await pumpStudy(tester);
}

class StudyRaceHarness {
  StudyRaceHarness() {
    h = AppHarness(
      backend: FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: 'a@x.io'),
        profileRow: {
          ...kProfileRowOnboardingDone,
          'consent_reading_version': ConsentVersions.reading,
          'consent_reading_at': '2026-10-03T01:00:00+00:00',
        },
      ),
      extraOverrides: [
        writeContextProvider.overrideWith(
          (ref) => WriteContext(
            userId: ref.watch(currentUserIdProvider),
            deviceId: 'test-device',
            clock: h.clock,
            newId: () => 'race-document',
          ),
        ),
        studyRepositoryProvider.overrideWith(
          (ref) =>
              ControlledStudyRepository(h.db, ref.watch(syncWriterProvider)),
        ),
        problemSolverProvider.overrideWithValue(solver),
        transcriptionEngineProvider.overrideWithValue(transcriber),
      ],
    );
  }
  late final AppHarness h;
  final solver = ControlledSolver();
  final transcriber = ControlledTranscriber();
  ControlledStudyRepository get repo =>
      h.container.read(studyRepositoryProvider) as ControlledStudyRepository;

  Future<void> ready(WidgetTester tester) async {
    h.container.read(authGateProvider);
    await pumpStudy(tester);
    expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
  }

  Future<StudyDocument> seed(
    WidgetTester tester, {
    String text = 'original problem',
  }) async {
    final generation = await completeStudy(
      tester,
      repo.writer.refreshPurgeGeneration(),
    );
    return completeStudy(
      tester,
      repo.save(
        transcription: raceTranscription,
        text: text,
        generation: generation,
      ),
    );
  }

  Future<void> mount(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: screen,
        ),
      ),
    );
    await pumpStudy(tester);
  }

  Future<void> purge(WidgetTester tester) async {
    final purge = LocalPurge(h.db, repo.writer.ctx);
    await completeStudy(tester, purge.markPending(1));
    await completeStudy(tester, purge.run(epoch: 1));
    await pumpStudy(tester);
  }
}
