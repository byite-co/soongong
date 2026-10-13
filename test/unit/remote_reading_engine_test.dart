import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/reading_engine.dart';
import 'package:soongong/data/engines/remote_reading_engine.dart';

import 'data/db_test_helpers.dart';

const id = '11111111-1111-4111-8111-111111111111';
Map<String, dynamic> output() => {
  'schema_version': 2,
  'pages': [
    {
      'index': 0,
      'items': [
        {
          'number': 3,
          'mark': null,
          'confidence': null,
          'box': [0, 0, 1, 1],
          'needs_review': true,
        },
      ],
    },
  ],
};
void main() {
  late TestHarness h;
  setUp(() => h = TestHarness());
  tearDown(() => h.close());
  RemoteReadingEngine engine(
    Future<Map<String, dynamic>> Function(String, Map<String, dynamic>) call, {
    bool owned = true,
    Future<void> Function(String, String)? upload,
    Future<void> Function(Duration)? pause,
  }) => RemoteReadingEngine(
    invoke: call,
    owner: () => h.ctx.userId,
    reading: h.reading,
    wrongs: h.wrongs,
    alive: () => true,
    ownsFile: (_) async => owned,
    upload: upload ?? (_, _) async {},
    pause: pause ?? (_) async {},
  );
  test('A01 default closed engine cannot return fake success', () async {
    await expectLater(
      const UnavailableReadingEngine().quota(),
      throwsStateError,
    );
  });
  for (final outcome in [
    'accepted',
    'quota_exhausted',
    'active_exists',
    'payload_mismatch',
    'request_deleted',
    'invalid_state',
    'not_entitled',
    'consent_required',
  ]) {
    test(
      'A14 actual adapter maps submit $outcome without point calls',
      () async {
        final calls = <String>[];
        final uploads = <String>[];
        final e = engine(
          (n, b) async {
            calls.add(n);
            return {'outcome': outcome, 'request_id': id, 'status': 'failed'};
          },
          upload: (p, _) async {
            uploads.add(p);
          },
        );
        final result = await e.submit(
          const ReadingJob(
            requestId: id,
            subjectId: 'subject',
            rangeText: 'range',
            photoPaths: ['owned.jpg'],
            origin: 'home',
          ),
        );
        expect(
          result.runtimeType,
          {
            'accepted': SubmitAccepted,
            'quota_exhausted': SubmitQuotaExhausted,
            'active_exists': SubmitActiveExists,
            'payload_mismatch': SubmitPayloadMismatch,
            'request_deleted': SubmitRequestDeleted,
            'invalid_state': SubmitInvalidState,
            'not_entitled': SubmitNotEntitled,
            'consent_required': SubmitConsentRequired,
          }[outcome],
        );
        expect(calls, ['reading-submit']);
        expect(uploads, ['u1/$id/p0.jpg']);
      },
    );
  }
  test('A13 adapter never uploads unowned path', () async {
    var calls = 0;
    final e = engine(
      (n, b) async {
        calls++;
        return {};
      },
      owned: false,
      upload: (_, _) async {
        calls++;
      },
    );
    expect(
      await e.submit(
        const ReadingJob(
          requestId: id,
          subjectId: 's',
          rangeText: 'r',
          photoPaths: ['original.jpg'],
          origin: 'home',
        ),
      ),
      isA<SubmitOffline>(),
    );
    expect(calls, 0);
  });
  for (final gone in ['not_found', 'request_deleted'])
    test('A14 $gone is terminal with no second poll', () async {
      var calls = 0;
      final e = engine((n, b) async {
        calls++;
        return {'outcome': gone};
      });
      final statuses = await e.watch(id).toList();
      expect(statuses.length, 1);
      expect(calls, 1);
      expect(
        statuses.single,
        gone == 'not_found' ? isA<NotFound>() : isA<Deleted>(),
      );
    });
  test(
    'A14 polling uses 2s then 5s and returns uncertain output unchanged',
    () async {
      var calls = 0;
      final delays = <Duration>[];
      final e = engine(
        (n, b) async {
          calls++;
          return {
            'status': calls == 1
                ? 'processing'
                : calls == 2
                ? 'taking_long'
                : 'done_unsaved',
            'result_json': calls == 3 ? output() : null,
          };
        },
        pause: (d) async {
          delays.add(d);
        },
      );
      final states = await e.watch(id).toList();
      expect(delays, [const Duration(seconds: 2), const Duration(seconds: 5)]);
      final item = (states.last as Done).result.pages.single.items.single;
      expect(item.mark, isNull);
      expect(item.confidence, isNull);
    },
  );
  test('A15 duplicate number and non-finite coordinate rejected', () {
    final duplicate = output();
    final page = (duplicate['pages'] as List).single as Map;
    page['items'] = [...(page['items'] as List), ...(page['items'] as List)];
    expect(
      () => RemoteReadingEngine.result(id, duplicate),
      throwsFormatException,
    );
    final bad = output();
    ((bad['pages'] as List).single['items'] as List).single['box'] = [
      0,
      0,
      double.nan,
      1,
    ];
    expect(() => RemoteReadingEngine.result(id, bad), throwsFormatException);
  });
  test('A14 cancel completion and failure map server truth', () async {
    expect(
      await engine((n, b) async => {'outcome': 'cancelled'}).cancel(id),
      isA<CancelCancelled>(),
    );
    expect(
      await engine(
        (n, b) async => {'outcome': 'already_done', 'result': output()},
      ).cancel(id),
      isA<CancelAlreadyDone>(),
    );
    expect(
      await engine((n, b) async => {'outcome': 'already_failed'}).cancel(id),
      isA<CancelAlreadyFailed>(),
    );
  });
}
