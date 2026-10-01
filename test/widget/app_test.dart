import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/app.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/repositories.dart';

void main() {
  testWidgets('app boots to the temporary splash (in-memory database)',
      (tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceIdProvider.overrideWithValue('test-device'),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const SoongongApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(CommonStrings.appName), findsOneWidget);
    expect(find.text(CommonStrings.splashPreparing), findsOneWidget);
  });
}
