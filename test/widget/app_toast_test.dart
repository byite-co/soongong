import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  tearDown(hideAppToast);

  testWidgets('undo toast: action runs once and the toast hides',
      (tester) async {
    var undone = 0;
    await pumpThemed(
      tester,
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () => showUndoToast(
            ctx,
            message: '기록을 삭제했습니다',
            onUndo: () => undone++,
          ),
          child: const Text('go'),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('기록을 삭제했습니다'), findsOneWidget);
    expect(find.text(CommonStrings.undo), findsOneWidget);
    // Action tap area ≥ 44×44 (S01b).
    final action = find.ancestor(
      of: find.text(CommonStrings.undo),
      matching: find.byType(GestureDetector),
    );
    final size = tester.getSize(action.first);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
    await tester.tap(find.text(CommonStrings.undo));
    await tester.pump();
    expect(undone, 1);
    expect(find.text('기록을 삭제했습니다'), findsNothing);
  });

  testWidgets('undo toast auto-hides after 5 seconds', (tester) async {
    await pumpThemed(
      tester,
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () =>
              showUndoToast(ctx, message: '삭제', onUndo: () {}),
          child: const Text('go'),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('삭제'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('삭제'), findsNothing);
    expect(AppToastController.instance.isVisible, isFalse);
  });
}
