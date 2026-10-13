import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/study_strings.dart';
import 'package:soongong/core/widgets/app_button.dart';
import 'package:soongong/features/reading/application/study_providers.dart';
import 'package:soongong/features/reading/presentation/problem_solver_screen.dart';

import '../helpers/study_race_harness.dart';

void main() {
  Future<StudyRaceHarness> start(WidgetTester tester) async {
    final rig = StudyRaceHarness();
    addTearDown(rig.h.dispose);
    await rig.ready(tester);
    final document = await rig.seed(tester);
    await rig.mount(tester, ProblemSolverScreen(documentId: document.id));
    await tester.tap(find.byType(CheckboxListTile));
    await pumpStudy(tester);
    return rig;
  }

  bool busy(WidgetTester tester) => tester
      .widget<AppButton>(find.widgetWithText(AppButton, StudyStrings.solve))
      .busy;

  testWidgets('RC05-RACE05 revision edit removes cached displayed solution', (
    tester,
  ) async {
    final rig = await start(tester);
    await pressStudy(tester, StudyStrings.solve);
    rig.solver.calls.single.finish('old answer');
    await pumpStudy(tester);
    expect(find.text('old answer'), findsOneWidget);
    final generation = rig.repo.writer.purgeGeneration!;
    await completeStudy(
      tester,
      rig.repo.save(
        transcription: raceTranscription,
        text: 'new revision',
        generation: generation,
        id: 'race-document',
        expectedRevision: 1,
      ),
    );
    rig.h.container.invalidate(studyDocumentsProvider);
    await pumpStudy(tester);
    expect(find.text('new revision'), findsOneWidget);
    expect(find.text('old answer'), findsNothing);
    expect(find.text(StudyStrings.saveSolution), findsNothing);
    await pressStudy(tester, StudyStrings.solve);
    expect(rig.solver.calls.last.revision, 2);
    rig.solver.calls.last.finish('new answer');
    await pumpStudy(tester);
    expect(find.text('new answer'), findsOneWidget);
  });

  testWidgets(
    'RC05-RACE05 stale solver error/finally cannot clear newer request',
    (tester) async {
      final rig = await start(tester);
      await pressStudy(tester, StudyStrings.solve);
      await completeStudy(
        tester,
        rig.repo.save(
          transcription: raceTranscription,
          text: 'new revision',
          generation: rig.repo.writer.purgeGeneration!,
          id: 'race-document',
          expectedRevision: 1,
        ),
      );
      rig.h.container.invalidate(studyDocumentsProvider);
      await pumpStudy(tester);
      expect(busy(tester), isFalse);
      await pressStudy(tester, StudyStrings.solve);
      expect(rig.solver.calls, hasLength(2));
      rig.solver.calls.first.done.completeError(StateError('old request'));
      await pumpStudy(tester);
      expect(busy(tester), isTrue);
      expect(find.text(StudyStrings.error), findsNothing);
      rig.solver.calls.last.finish('current answer');
      await pumpStudy(tester);
      expect(busy(tester), isFalse);
      expect(find.text('current answer'), findsOneWidget);
    },
  );

  testWidgets(
    'RC05-RACE05 old save failure after purge leaves new solve busy',
    (tester) async {
      final rig = await start(tester);
      await pressStudy(tester, StudyStrings.solve);
      rig.solver.calls.single.finish('old answer');
      await pumpStudy(tester);
      final wait = Completer<void>();
      rig.repo.saveWait = wait;
      await pressStudy(tester, StudyStrings.saveSolution);
      expect(rig.repo.solutionSaves, 1);
      await rig.purge(tester);
      rig.repo.saveWait = null;
      await rig.seed(tester, text: 'after purge');
      rig.h.container.invalidate(studyDocumentsProvider);
      await pumpStudy(tester);
      await pressStudy(tester, StudyStrings.solve);
      expect(rig.solver.calls, hasLength(2));
      wait.complete(); // real repository refuses the old captured generation
      await pumpStudy(tester);
      expect(busy(tester), isTrue);
      expect(find.text(StudyStrings.error), findsNothing);
      expect(find.text(StudyStrings.saved), findsNothing);
      expect(
        (await completeStudy(tester, rig.repo.get('race-document')))!.solution,
        isNull,
      );
      rig.solver.calls.last.finish('new answer');
      await pumpStudy(tester);
      expect(find.text('new answer'), findsOneWidget);
    },
  );

  testWidgets('RC05-RACE05 duplicate solve and dispose suppress late result', (
    tester,
  ) async {
    final rig = await start(tester);
    final action = tester
        .widget<AppButton>(find.widgetWithText(AppButton, StudyStrings.solve))
        .onPressed!;
    action();
    action();
    await pumpStudy(tester);
    expect(rig.solver.calls, hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    rig.solver.calls.single.finish('disposed answer');
    await pumpStudy(tester);
    expect(tester.takeException(), isNull);
    expect(
      (await completeStudy(tester, rig.repo.get('race-document')))!.solution,
      isNull,
    );
  });
}
