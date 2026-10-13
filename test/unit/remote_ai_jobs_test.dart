import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/transcription_engine.dart';
import 'package:soongong/data/engines/transcription/remote_ai_jobs.dart';

const requestId = '11111111-1111-4111-8111-111111111111';
const quoteId = '22222222-2222-4222-8222-222222222222';
const approval = AiApproval(
  requestId: requestId,
  quoteId: quoteId,
  operation: 'ocr_text',
  epoch: 0,
);
const input = {
  'schema_version': 1,
  'operation': 'ocr',
  'kind': 'text',
  'image': 'YQ==',
  'purge_epoch': 0,
  'consent_version': 'study-2026-10-13',
};
Map<String, dynamic> result() => {
  'version': 2,
  'request_id': requestId,
  'job_id': '33333333-3333-4333-8333-333333333333',
  'state': 'succeeded',
  'result': {
    'schema_version': 1,
    'kind': 'text',
    'engine': 'fixture',
    'blocks': <Object>[],
  },
};
void main() {
  test('FD-01 unset point approval sends no request', () async {
    var calls = 0;
    final owner = Object();
    final jobs = RemoteAiJobs.withTransport(
      invoke: (name, body) async {
        calls++;
        return result();
      },
      session: () => owner,
    );
    await expectLater(
      jobs.execute(input),
      throwsA(isA<StudyEngineException>()),
    );
    expect(calls, 0);
  });
  test(
    'FD-02 v2 envelope carries confirmed quote and stable retry identity',
    () async {
      final owner = Object();
      final sent = <Map<String, dynamic>>[];
      final jobs = RemoteAiJobs.withTransport(
        invoke: (name, body) async {
          expect(name, 'study-infer');
          sent.add(body);
          return result();
        },
        session: () => owner,
        approve: (op, epoch) async => approval,
      );
      expect((await jobs.execute(input))['schema_version'], 1);
      await jobs.execute(input);
      expect(sent.first, {
        'version': 2,
        'request_id': requestId,
        'quote_id': quoteId,
        'input': input,
      });
      expect(sent[0], sent[1]);
    },
  );
  test(
    'FD-07 session change while response is pending discards result',
    () async {
      var owner = Object();
      final entered = Completer<void>();
      final response = Completer<Map<String, dynamic>>();
      final jobs = RemoteAiJobs.withTransport(
        invoke: (name, body) {
          entered.complete();
          return response.future;
        },
        session: () => owner,
        approve: (op, epoch) async => approval,
      );
      final pending = jobs.execute(input);
      final failure = expectLater(
        pending,
        throwsA(isA<StudyEngineException>()),
      );
      await entered.future;
      owner = Object();
      response.complete(result());
      await failure;
    },
  );
  for (final bad in [
    {'version': 1},
    {...result(), 'request_id': quoteId},
    {...result(), 'state': 'reconciliation_required', 'result': null},
  ]) {
    test(
      'FD-02 incompatible/mismatched/pending job ${bad['state']} rejected without retry',
      () async {
        final owner = Object();
        var calls = 0;
        final jobs = RemoteAiJobs.withTransport(
          invoke: (name, body) async {
            calls++;
            return bad;
          },
          session: () => owner,
          approve: (op, epoch) async => approval,
        );
        await expectLater(
          jobs.execute(input),
          throwsA(isA<StudyEngineException>()),
        );
        expect(calls, 1);
      },
    );
  }
}
