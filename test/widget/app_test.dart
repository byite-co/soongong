import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/app.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/strings/common_strings.dart';

void main() {
  testWidgets('app boots to the temporary splash', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [deviceIdProvider.overrideWithValue('test-device')],
        child: const SoongongApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(CommonStrings.appName), findsOneWidget);
    expect(find.text(CommonStrings.splashPreparing), findsOneWidget);
  });
}
