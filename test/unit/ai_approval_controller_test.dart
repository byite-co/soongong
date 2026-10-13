import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/features/reading/application/ai_approval_controller.dart';
import 'package:soongong/data/engines/transcription/remote_ai_jobs.dart';

void main() {
  const q1 = '11111111-1111-4111-8111-111111111111',
      q2 = '22222222-2222-4222-8222-222222222222';
  for (final cancel in [true, false])
    test(
      'A04 quote cancel=$cancel and changed quote requires another explicit approval',
      () async {
        final controller = AiApprovalController();
        final owner = Object();
        var calls = 0, presented = 0;
        final jobs = RemoteAiJobs.withTransport(
          session: () => owner,
          invoke: (n, b) async {
            calls++;
            return {
              'version': 2,
              'quote_id': calls == 1 ? q1 : q2,
              'operation': 'ocr_text',
              'points': calls == 1 ? 2 : 3,
              'terms_version': 'fixture',
            };
          },
        );
        controller.bind(
          valid: () => true,
          generation: 4,
          present: (q) async {
            presented++;
            return !cancel;
          },
        );
        if (cancel) {
          await expectLater(
            controller.approve(jobs, 'ocr_text', 0),
            throwsA(anything),
          );
          expect(presented, 1);
          expect(calls, 1);
        } else {
          final result = await controller.approve(jobs, 'ocr_text', 0);
          expect(presented, 2);
          expect(result.quoteId, q2);
          expect(result.generation, 4);
        }
      },
    );
  test(
    'A05 owner consent epoch invalidation and old dialog cannot approve new scope',
    () async {
      final controller = AiApprovalController();
      final owner = Object();
      final dialog = Completer<bool>();
      final entered = Completer<void>();
      final jobs = RemoteAiJobs.withTransport(
        session: () => owner,
        invoke: (n, b) async => {
          'version': 2,
          'quote_id': q1,
          'operation': 'ocr_text',
          'points': 2,
          'terms_version': 'fixture',
        },
      );
      final release = controller.bind(
        valid: () => true,
        generation: 0,
        present: (q) {
          entered.complete();
          return dialog.future;
        },
      );
      final operation = controller.approve(jobs, 'ocr_text', 0);
      final failure = expectLater(operation, throwsA(anything));
      await entered.future;
      expect(
        () => controller.bind(
          valid: () => true,
          generation: 0,
          present: (q) async => true,
        ),
        throwsStateError,
      );
      release();
      controller.bind(
        valid: () => true,
        generation: 1,
        present: (q) async => true,
      );
      dialog.complete(true);
      await failure;
      expect(controller.requestId, isNull);
    },
  );
}
