import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('SubjectChip always renders its name label', (tester) async {
    var taps = 0;
    await pumpThemed(
      tester,
      Row(
        children: <Widget>[
          SubjectChip.index(
            name: '수학',
            colorIndex: 0,
            brightness: Brightness.light,
            onTap: () => taps++,
          ),
          const SubjectChip(name: '영어', color: Colors.pink, selected: true),
        ],
      ),
    );
    expect(find.text('수학'), findsOneWidget);
    expect(find.text('영어'), findsOneWidget);
    await tester.tap(find.text('수학'));
    expect(taps, 1);
  });

  testWidgets('TimeChip formats durations and ranges', (tester) async {
    await pumpThemed(
      tester,
      Row(
        children: <Widget>[
          TimeChip.duration(const Duration(hours: 1, minutes: 28)),
          TimeChip.range(DateTime(2026, 1, 1, 19, 32), DateTime(2026, 1, 1, 21, 3)),
        ],
      ),
    );
    expect(find.text('1시간 28분'), findsOneWidget);
    expect(find.text('19:32 – 21:03'), findsOneWidget);
  });
}
