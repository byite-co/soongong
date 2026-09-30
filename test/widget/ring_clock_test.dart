import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('renders hour labels, segments and the centre slot',
      (tester) async {
    await pumpThemed(
      tester,
      const RingClock(
        nowHour: 21,
        segments: <RingSegment>[
          RingSegment(startHour: 9, endHour: 10.5, color: Colors.blue),
          RingSegment(startHour: 21, endHour: 22, color: Colors.blue, ghost: true),
        ],
        outerSegments: <RingSegment>[
          RingSegment(startHour: 8, endHour: 15, color: Colors.orange),
        ],
        center: Text('1시간 28분'),
      ),
    );
    for (final l in <String>['0', '6', '12', '18']) {
      expect(find.text(l), findsOneWidget);
    }
    expect(find.text('1시간 28분'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pump(const Duration(milliseconds: 700)); // ringIn done
  });

  testWidgets('animate:false and reduced motion skip the sweep animation',
      (tester) async {
    await pumpThemed(tester, const RingClock(animate: false, showLabels: false));
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
