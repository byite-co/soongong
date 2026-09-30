import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/widgets/widgets.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('empty state offers the next action', (tester) async {
    var pressed = false;
    await pumpThemed(
      tester,
      StatePanel.empty(actionLabel: '집중 시작', onAction: () => pressed = true),
    );
    expect(find.text(CommonStrings.emptyTitle), findsOneWidget);
    await tester.tap(find.text('집중 시작'));
    expect(pressed, isTrue);
  });

  testWidgets('error state shows retry; loading shows an indicator',
      (tester) async {
    await pumpThemed(tester, StatePanel.error(onAction: () {}));
    expect(find.text(CommonStrings.errorTitle), findsOneWidget);
    expect(find.text(CommonStrings.retry), findsOneWidget);

    await pumpThemed(tester, const StatePanel.loading());
    expect(find.text(CommonStrings.loading), findsOneWidget);
  });
}
