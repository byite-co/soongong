import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/app.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/repositories.dart';

void main() {
  testWidgets('app without backend config boots to the home tab (local-only, S05)',
      (tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(db.close);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    expect(find.text(HomeStrings.todayTodos), findsOneWidget);
    expect(find.text(HomeStrings.todosEmpty), findsOneWidget);
    final bar = find.byType(NavigationBar);
    expect(bar, findsOneWidget);
    for (final tab in <String>[
      CommonStrings.tabHome,
      CommonStrings.tabPlanner,
      CommonStrings.tabTimetable,
      CommonStrings.tabStats,
    ]) {
      expect(find.descendant(of: bar, matching: find.text(tab)), findsOneWidget);
    }
    // Dispose the tree and flush drift's stream-close timer before the
    // pending-timer check.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
