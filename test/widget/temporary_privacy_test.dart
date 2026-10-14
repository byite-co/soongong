import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/privacy_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/data/temp/temp_providers.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/privacy/application/purge_recovery.dart';
import 'package:soongong/features/privacy/presentation/privacy_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_backend.dart';
import '../helpers/study_race_harness.dart' show completeStudy, pumpStudy;

void main() {
  Future<void> mount(WidgetTester tester, AppHarness h) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: const PrivacyScreen(),
        ),
      ),
    );
    await pumpStudy(tester);
  }

  testWidgets(
    'DEL-06 unreadable temporary store shows unknown and real retry clears notice',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('soongong-privacy-ui-');
      addTearDown(() => dir.deleteSync(recursive: true));
      var unavailable = true;
      final h = AppHarness(
        mode: AuthMode.localOnly,
        temporaryStore: OwnedTempStore(() async {
          if (unavailable) throw const TempStoreUnavailable();
          return dir;
        }),
      );
      addTearDown(h.dispose);
      await mount(tester, h);
      expect(find.text(PrivacyStrings.sweepUnavailable), findsOneWidget);
      expect(find.text(PrivacyStrings.sweepPending(0)), findsNothing);
      unavailable = false;
      await tester.tap(find.byKey(PrivacyKeys.sweepRetry));
      await pumpStudy(tester);
      expect(find.byKey(PrivacyKeys.sweepNotice), findsNothing);
      expect(find.text(PrivacyStrings.sweepDone), findsOneWidget);
      await h.unmount(tester);
    },
  );

  testWidgets(
    'DEL-07 server-confirmed local pending UI retries local work without a second purge',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('soongong-purge-ui-');
      addTearDown(() => dir.deleteSync(recursive: true));
      var unavailable = false;
      final backend = FakeAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingDone,
      );
      backend.responses['purge-all'] = {'epoch': 1};
      final h = AppHarness(
        backend: backend,
        temporaryStore: OwnedTempStore(() async {
          if (unavailable) throw const TempStoreUnavailable();
          return dir;
        }),
      );
      addTearDown(h.dispose);
      h.container.read(authGateProvider);
      await pumpStudy(tester);
      final writer = h.container.read(syncWriterProvider);
      final generation = await completeStudy(
        tester,
        writer.refreshPurgeGeneration(),
      );
      final task = await completeStudy(
        tester,
        h.container
            .read(tempOwnershipProvider)
            .create(
              writer,
              'export',
              generation: generation,
              alive: () => true,
            ),
      );
      final file = task.file('record.json')..writeAsBytesSync([1, 2, 3]);
      unavailable = true;
      expect(
        await completeStudy(
          tester,
          h.container.read(privacyActionsProvider).deleteAll(),
        ),
        isA<DeleteAllLocalPending>(),
      );
      await completeStudy(
        tester,
        h.container.read(purgeRecoveryProvider).resume(),
      );
      await mount(tester, h);
      expect(
        find.text(PrivacyStrings.deleteAllLocalPending(true)),
        findsOneWidget,
      );
      expect(find.text(PrivacyStrings.deleteAllDone), findsNothing);
      unavailable = false;
      await tester.tap(find.byKey(PrivacyKeys.recoveryRetry));
      await pumpStudy(tester);
      expect(file.existsSync(), isFalse);
      expect(find.byKey(PrivacyKeys.recoveryNotice), findsNothing);
      expect(backend.callNames.where((n) => n == 'purge-all'), hasLength(1));
      await h.unmount(tester);
    },
  );
}
