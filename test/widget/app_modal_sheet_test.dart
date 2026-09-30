import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('showAppModal resolves true on primary, false on secondary',
      (tester) async {
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
            );
          },
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('이 기록을 삭제할까요?'), findsOneWidget);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('showAppSheet: bottom sheet on phone', (tester) async {
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

  testWidgets('showAppSheet: centred card on tablet', (tester) async {
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
}
