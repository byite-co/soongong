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
  });

  testWidgets('small: visual box is 42 but the tap area is ≥ 44 and hits',
      (tester) async {
    var taps = 0;
    await pumpThemed(
      tester,
      Center(
        child: AppButton(
          label: '작게',
          size: AppButtonSize.small,
          expand: false,
          onPressed: () => taps++,
        ),
      ),
    );
    final tapArea = find.descendant(
      of: find.byType(AppButton),
      matching: find.byType(GestureDetector),
    );
    final areaRect = tester.getRect(tapArea);
    expect(areaRect.height, greaterThanOrEqualTo(44));
    expect(areaRect.width, greaterThanOrEqualTo(44));

    // The painted box is 42 tall, centred inside the tap area.
    final visualRect = tester.getRect(
      find.descendant(of: tapArea, matching: find.byType(AnimatedScale)),
    );
    expect(visualRect.height, 42);
    expect(visualRect.top, greaterThan(areaRect.top));

    // Tapping just outside the painted box but inside the 44 area hits.
    await tester.tapAt(Offset(areaRect.center.dx, areaRect.top + 0.5));
    await tester.pump();
    await tester.tapAt(Offset(areaRect.center.dx, areaRect.bottom - 0.5));
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('a taller parent does not enlarge the tap area (fixed height)',
      (tester) async {
    var taps = 0;
    const parentKey = Key('parent');
    await pumpThemed(
      tester,
      SizedBox(
        key: parentKey,
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: '저장',
                size: AppButtonSize.small,
                onPressed: () => taps++,
              ),
            ),
          ],
        ),
      ),
    );
    final parentRect = tester.getRect(find.byKey(parentKey));
    expect(parentRect.height, 120);

    final tapArea = find.descendant(
      of: find.byType(AppButton),
      matching: find.byType(GestureDetector),
    );
    final areaRect = tester.getRect(tapArea);
    expect(areaRect.height, 44, reason: 'small → max(44, 42)');
    expect(areaRect.width, parentRect.width, reason: 'expand keeps the width');
    // Centred inside the 120-tall parent.
    expect(areaRect.center.dy, closeTo(parentRect.center.dy, 0.01));

    // Inside the parent but outside the 44 band → no tap.
    await tester.tapAt(Offset(areaRect.center.dx, parentRect.top + 5));
    await tester.pump();
    await tester.tapAt(Offset(areaRect.center.dx, parentRect.bottom - 5));
    await tester.pump();
    expect(taps, 0);

    // Inside the 44 band (edges included) → tap.
    await tester.tapAt(Offset(areaRect.center.dx, areaRect.top + 0.5));
    await tester.pump();
    await tester.tapAt(Offset(areaRect.center.dx, areaRect.bottom - 0.5));
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('medium in a tight 200-tall box: tap area is the 46 visual',
      (tester) async {
    await pumpThemed(
      tester,
      SizedBox(
        height: 200,
        width: 300,
        child: AppButton(label: '중간', onPressed: () {}),
      ),
    );
    final areaRect = tester.getRect(
      find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(areaRect.height, 46);
    expect(areaRect.width, 300);
  });

  testWidgets('every size exposes a ≥ 44 tap area', (tester) async {
    await pumpThemed(
      tester,
      Column(
        children: <Widget>[
          for (final s in AppButtonSize.values)
            AppButton(label: s.name, size: s, onPressed: () {}),
        ],
      ),
    );
    for (final e in find.byType(GestureDetector).evaluate()) {
      expect(e.size!.height, greaterThanOrEqualTo(44));
    }
  });
}
