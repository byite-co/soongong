import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/core/strings/study_strings.dart';
import 'package:soongong/core/widgets/app_button.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/photos/study_image_picker.dart';
import 'package:soongong/features/reading/application/study_providers.dart';
import 'package:soongong/features/reading/presentation/transcription_screen.dart';

import '../helpers/study_race_harness.dart';

class _Image implements StudyPickedImage {
  @override
  Future<int> length() async => 64;
  @override
  Future<Uint8List> readAsBytes() async => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
  );
  @override
  Future<void> cleanup() async {}
}

void main() {
  Future<StudyRaceHarness> start(
    WidgetTester tester, {
    bool seed = true,
  }) async {
    final rig = StudyRaceHarness();
    addTearDown(rig.h.dispose);
    await rig.ready(tester);
    if (seed) await rig.seed(tester);
    await rig.mount(
      tester,
      TranscriptionScreen(pickImage: (_) async => _Image()),
    );
    return rig;
  }

  Future<void> selectAndRecognize(WidgetTester tester) async {
    await pressStudy(tester, StudyStrings.select);
    await tester.tap(find.byType(CheckboxListTile));
    await pumpStudy(tester);
    await pressStudy(tester, StudyStrings.recognize);
  }

  testWidgets(
    'A01/A04 actual approval injection cancel zero and repeated taps one durable request',
    (tester) async {
      final rig = StudyRaceHarness(useApproval: true);
      addTearDown(rig.h.dispose);
      await rig.ready(tester);
      await rig.mount(
        tester,
        TranscriptionScreen(pickImage: (_) async => _Image()),
      );
      await selectAndRecognize(tester);
      expect(find.textContaining('3 AI 포인트'), findsOneWidget);
      expect(find.textContaining('fixture-terms'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await pumpStudy(tester);
      expect(rig.approvedDispatches, 0);
      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, StudyStrings.recognize),
      );
      button.onPressed?.call();
      button.onPressed?.call();
      await pumpStudy(tester);
      await tester.tap(find.widgetWithText(TextButton, '포인트 확인 · 실행'));
      await pumpStudy(tester);
      expect(rig.approvedDispatches, 1);
      expect(await completeStudy(tester, rig.repo.list()), isEmpty);
      await pressStudy(tester, StudyStrings.confirm);
      expect((await completeStudy(tester, rig.repo.list())).length, 1);
    },
  );

  for (final change in ['purge', 'account']) {
    testWidgets(
      'RC05-RACE06 $change while delete dialog is open preserves replacement',
      (tester) async {
        final rig = await start(tester);
        final oldRepo = rig.repo;
        await tester.tap(find.byTooltip(StudyStrings.delete));
        await pumpStudy(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        if (change == 'purge') {
          await rig.purge(tester);
        } else {
          rig.h.backend.profileRow = {
            ...rig.h.backend.profileRow!,
            'user_id': 'u-2',
          };
          rig.h.backend.emitSession(
            const AuthSession(userId: 'u-2', email: 'b@x.io'),
          );
          await pumpStudy(tester);
        }
        await rig.seed(tester, text: 'replacement document');
        rig.h.container.invalidate(studyDocumentsProvider);
        await pumpStudy(tester);
        await tester.tap(find.widgetWithText(TextButton, StudyStrings.delete));
        await pumpStudy(tester);
        expect(oldRepo.deletes, 0);
        expect(rig.repo.deletes, 0);
        final replacement = await completeStudy(
          tester,
          rig.repo.get('race-document'),
        );
        expect(
          replacement,
          isNotNull,
          reason: 'stale dialog must not delete the replacement',
        );
        expect(replacement!.text, 'replacement document');
        expect(find.text(StudyStrings.error), findsNothing);
      },
    );
  }

  testWidgets(
    'RC05-RACE06 delete re-tap opens one dialog; cancel and normal confirm remain usable',
    (tester) async {
      final rig = await start(tester);
      final action = tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == StudyStrings.delete,
            ),
          )
          .onPressed!;
      action();
      action();
      await pumpStudy(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, StudyStrings.cancel));
      await pumpStudy(tester);
      expect(rig.repo.deletes, 0);
      await tester.tap(find.byTooltip(StudyStrings.delete));
      await pumpStudy(tester);
      await tester.tap(find.widgetWithText(TextButton, StudyStrings.delete));
      await pumpStudy(tester);
      expect(rig.repo.deletes, 1);
      expect(await completeStudy(tester, rig.repo.list()), isEmpty);
      expect(find.text(StudyStrings.error), findsNothing);
    },
  );

  testWidgets(
    'RC05-RACE06 old text save catch/finally cannot alter new OCR after purge',
    (tester) async {
      final rig = await start(tester, seed: false);
      await selectAndRecognize(tester);
      rig.transcriber.calls.single.complete(raceTranscription);
      await pumpStudy(tester);
      final wait = Completer<void>();
      rig.repo.saveWait = wait;
      await pressStudy(tester, StudyStrings.confirm);
      expect(rig.repo.saves, 1);
      await rig.purge(tester);
      rig.repo.saveWait = null;
      await selectAndRecognize(tester);
      expect(rig.transcriber.calls, hasLength(2));
      wait.complete();
      await pumpStudy(tester);
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, StudyStrings.recognize),
            )
            .busy,
        isTrue,
      );
      expect(find.text(StudyStrings.error), findsNothing);
      expect(find.text(StudyStrings.saved), findsNothing);
      expect(await completeStudy(tester, rig.repo.list()), isEmpty);
      rig.transcriber.calls.last.complete(raceTranscription);
      await pumpStudy(tester);
      await pressStudy(tester, StudyStrings.confirm);
      expect(find.text(StudyStrings.saved), findsOneWidget);
      expect(await completeStudy(tester, rig.repo.list()), hasLength(1));
    },
  );

  testWidgets('RC05-RACE06 disposed text save error has no UI callback', (
    tester,
  ) async {
    final rig = await start(tester, seed: false);
    await selectAndRecognize(tester);
    rig.transcriber.calls.single.complete(raceTranscription);
    await pumpStudy(tester);
    final wait = Completer<void>();
    rig.repo.saveWait = wait;
    await pressStudy(tester, StudyStrings.confirm);
    await tester.pumpWidget(const SizedBox.shrink());
    wait.completeError(StateError('late save failure'));
    await pumpStudy(tester);
    expect(tester.takeException(), isNull);
    expect(await completeStudy(tester, rig.repo.list()), isEmpty);
  });
  testWidgets('A12 long malformed LaTeX stays editable and never auto saves', (
    tester,
  ) async {
    final rig = await start(tester, seed: false);
    await pressStudy(tester, StudyStrings.select);
    await tester.tap(find.text(StudyStrings.math));
    await tester.tap(find.byType(CheckboxListTile));
    await pumpStudy(tester);
    await pressStudy(tester, StudyStrings.recognize);
    final malformed = List.filled(1500, r'\frac{').join();
    rig.transcriber.calls.single.complete(
      DocumentTranscription(
        kind: TranscriptionKind.math,
        engine: 'fixture',
        blocks: [
          TranscriptionBlock(text: malformed, box: const [0, 0, 1, 1]),
        ],
      ),
    );
    await pumpStudy(tester);
    expect(tester.takeException(), isNull);
    expect(await completeStudy(tester, rig.repo.list()), isEmpty);
    expect(find.text('LaTeX 원문 · 자동 실행이나 수학적 검증을 하지 않습니다.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'x^{2}');
    await pressStudy(tester, StudyStrings.confirm);
    final documents = await completeStudy(tester, rig.repo.list());
    expect(documents.length, 1);
    expect(
      (await completeStudy(tester, rig.repo.get(documents.single.id)))!.text,
      'x^{2}',
    );
  });
}
