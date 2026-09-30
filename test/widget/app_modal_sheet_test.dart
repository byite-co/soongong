import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

/// Pumps a button that opens [showAppModal] and records the result.
Future<bool? Function()> pumpModalHost(
  WidgetTester tester, {
  Future<void> Function()? onConfirm,
  bool barrierDismissible = true,
}) async {
  bool? result;
  await pumpThemed(
    tester,
    Builder(
      builder: (ctx) => TextButton(
        onPressed: () async {
          result = await showAppModal(
            ctx,
            title: '이 기록을 삭제할까요?',
            body: '세션 1개가 삭제됩니다.',
            primaryLabel: '삭제',
            destructive: true,
            onConfirm: onConfirm,
            barrierDismissible: barrierDismissible,
          );
        },
        child: const Text('open'),
      ),
    ),
    surfaceSize: const Size(390, 844),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

void main() {
  group('showAppModal', () {
    testWidgets('primary → true, secondary → false, barrier → false',
        (tester) async {
      final result = await pumpModalHost(tester);
      expect(find.text('이 기록을 삭제할까요?'), findsOneWidget);
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(result(), isTrue);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(CommonStrings.cancel));
      await tester.pumpAndSettle();
      expect(result(), isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5)); // barrier
      await tester.pumpAndSettle();
      expect(result(), isFalse);
      expect(find.text('이 기록을 삭제할까요?'), findsNothing);
    });

    testWidgets('back gesture dismisses with false when idle', (tester) async {
      final result = await pumpModalHost(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(result(), isFalse);
      expect(find.text('이 기록을 삭제할까요?'), findsNothing);
    });

    testWidgets(
        'while onConfirm runs: barrier tap, back and cancel are ignored; '
        'resolves true afterwards', (tester) async {
      final gate = Completer<void>();
      var runs = 0;
      final result = await pumpModalHost(
        tester,
        onConfirm: () {
          runs++;
          return gate.future;
        },
      );
      await tester.tap(find.text('삭제'));
      await tester.pump();
      expect(runs, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tapAt(const Offset(5, 5)); // barrier
      await tester.pump();
      await tester.binding.handlePopRoute(); // back
      await tester.pump();
      await tester.tap(find.text(CommonStrings.cancel)); // secondary
      await tester.pump();
      await tester.tap(find.text('삭제'), warnIfMissed: false); // re-tap primary
      await tester.pump();
      expect(find.text('이 기록을 삭제할까요?'), findsOneWidget);
      expect(result(), isNull);
      expect(runs, 1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(result(), isTrue);
      expect(find.text('이 기록을 삭제할까요?'), findsNothing);
    });

    testWidgets('onConfirm throws: modal stays with error line, cancel → false',
        (tester) async {
      var calls = 0;
      final result = await pumpModalHost(
        tester,
        onConfirm: () async {
          calls++;
          throw StateError('boom');
        },
      );
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(result(), isNull);
      expect(find.text('이 기록을 삭제할까요?'), findsOneWidget);
      expect(find.text(CommonStrings.actionFailedRetry), findsOneWidget);

      // Retry is possible, then cancel resolves false.
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      await tester.tap(find.text(CommonStrings.cancel));
      await tester.pumpAndSettle();
      expect(result(), isFalse);
    });

    testWidgets('barrierDismissible: false ignores barrier taps when idle',
        (tester) async {
      final result = await pumpModalHost(tester, barrierDismissible: false);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('이 기록을 삭제할까요?'), findsOneWidget);
      expect(result(), isNull);
      await tester.tap(find.text(CommonStrings.cancel));
      await tester.pumpAndSettle();
      expect(result(), isFalse);
    });
  });

  group('showAppSheet', () {
    testWidgets('bottom sheet on phone', (tester) async {
      await pumpThemed(
        tester,
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showAppSheet<void>(
              ctx,
              title: '등록',
              builder: (_) => const Text('내용'),
            ),
            child: const Text('open'),
          ),
        ),
        surfaceSize: const Size(390, 844),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('등록'), findsOneWidget);
      expect(find.text('내용'), findsOneWidget);
      expect(tester.widget<AppSheet>(find.byType(AppSheet)).showHandle, isTrue);
      expect(tester.getSize(find.byType(AppSheet)).width, 390);
    });

    testWidgets('centred card on tablet', (tester) async {
      await pumpThemed(
        tester,
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showAppSheet<void>(
              ctx,
              title: '등록',
              builder: (_) => const Text('내용'),
            ),
            child: const Text('open'),
          ),
        ),
        surfaceSize: const Size(834, 1194),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('내용'), findsOneWidget);
      expect(tester.widget<AppSheet>(find.byType(AppSheet)).showHandle, isFalse);
      // 520 card minus the 1px border on each side.
      expect(tester.getSize(find.byType(AppSheet)).width, 518);
    });
  });
}
