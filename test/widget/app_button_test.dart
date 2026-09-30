import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('async onPressed locks the button until it completes',
      (tester) async {
    var calls = 0;
    await pumpThemed(
      tester,
      AppButton(
        label: '저장',
        busyLabel: '저장 중…',
        onPressed: () async {
          calls++;
          await Future<void>.delayed(const Duration(seconds: 1));
        },
      ),
    );
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(find.text('저장 중…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('저장 중…'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('저장'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(calls, 2);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('disabled button ignores taps; variants render', (tester) async {
    var tapped = false;
    await pumpThemed(
      tester,
      Column(
        children: <Widget>[
          const AppButton(label: '비활성'),
          AppButton.secondary(label: '취소', onPressed: () => tapped = true),
          AppButton.destructive(label: '삭제', onPressed: () {}),
        ],
      ),
    );
    await tester.tap(find.text('비활성'));
    expect(tapped, isFalse);
    await tester.tap(find.text('취소'));
    expect(tapped, isTrue);
    expect(find.text('삭제'), findsOneWidget);
    // Touch target ≥ 44 for every button.
    for (final e in find.byType(AppButton).evaluate()) {
      expect(e.size!.height, greaterThanOrEqualTo(44));
    }
  });
}
