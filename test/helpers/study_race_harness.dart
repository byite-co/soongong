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
import 'package:soongong/data/engines/transcription/remote_ai_jobs.dart';
import 'package:soongong/data/engines/transcription/remote_transcription_engine.dart';
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

class ObservedTranscriber implements TranscriptionEngine {
  ObservedTranscriber(this.delegate, this.finished, this.onFailure);
  final TranscriptionEngine delegate;
  final Completer<void> finished;
  final void Function(Object) onFailure;
  @override
  Future<DocumentTranscription> transcribe(
    Uint8List image,
    TranscriptionKind kind, {
    required int epoch,
  }) async {
    try {
      return await delegate.transcribe(image, kind, epoch: epoch);
    } on Object catch (error) {
      onFailure(error);
      rethrow;
    } finally {
      // A cancelled quote is followed by a separately observed approved call.
      if (!finished.isCompleted) finished.complete();
    }
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
  StudyRaceHarness({bool useApproval = false}) {
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
        if (!useApproval)
          transcriptionEngineProvider.overrideWithValue(transcriber)
        else
          transcriptionEngineProvider.overrideWith((ref) {
            final controller = ref.watch(aiApprovalControllerProvider);
            final repository = ref.watch(aiRequestRepositoryProvider);
            late RemoteAiJobs jobs;
            jobs = RemoteAiJobs.withTransport(
              session: () => ref.read(currentUserIdProvider),
              approve: (op, epoch) => controller.approve(jobs, op, epoch),
              checkCurrent: controller.check,
              beforeSend: repository.prepare,
              onJob: repository.record,
              invoke: (name, body) async {
                if (name == 'study-job') {
                  return {
                    'version': 2,
                    'quote_id': '22222222-2222-4222-8222-222222222222',
                    'operation': body['operation'],
                    'points': 3,
                    'terms_version': 'fixture-terms',
                  };
                }
                approvedDispatches++;
                final request = body['request_id'] as String;
                // This callback runs while the widget tester may be pumping.
                // Capture the pre-response state; assert in the test body so
                // Flutter's guarded expect API cannot interrupt the request.
                durableStateAtDispatch = (await repository.get(request))?.state;
                return {
                  'version': 2,
                  'job_id': '33333333-3333-4333-8333-333333333333',
                  'request_id': request,
                  'state': 'succeeded',
                  'points_state': 'settled',
                  'result_expired': false,
                  'result': raceTranscription.toJson(),
                };
              },
            );
            return ObservedTranscriber(
              RemoteTranscriptionEngine.withJobs(jobs),
              approvedFinished,
              (error) => approvedFailure = error,
            );
          }),
      ],
    );
  }
  late final AppHarness h;
  final solver = ControlledSolver();
  final transcriber = ControlledTranscriber();
  int approvedDispatches = 0;
  String? durableStateAtDispatch;
  Completer<void> approvedFinished = Completer<void>();
  Object? approvedFailure;
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
    await completeStudy(tester, purge.clearPending());
    await pumpStudy(tester);
  }
}
