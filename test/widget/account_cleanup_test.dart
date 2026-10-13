import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/settings_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/app_modal.dart';
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/features/settings/presentation/account_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_auth_backend.dart';
import '../helpers/study_race_harness.dart' show completeStudy, pumpStudy;

void main() {
  testWidgets(
    'DEL-07 account deletion modal distinguishes acknowledged server deletion and retries only local cleanup',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'account-cleanup-ui-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      var unavailable = false;
      final backend = GatedAuthBackend(
        session: const AuthSession(userId: 'u-1', email: null),
        profileRow: kProfileRowOnboardingDone,
      );
      final h = AppHarness(
        backend: backend,
        temporaryStore: OwnedTempStore(() async {
          if (unavailable) throw const TempStoreUnavailable();
          return directory;
        }),
      );
      addTearDown(h.dispose);
      h.container.listen(authGateProvider, (_, _) {});
      await pumpStudy(tester);
      expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
      final subject = await completeStudy(
        tester,
        h.container
            .read(subjectRepositoryProvider)
            .create(name: 'synthetic-owned-record', colorIndex: 0),
      );
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            theme: buildAppTheme(Brightness.light),
            home: const AccountScreen(),
          ),
        ),
      );
      await pumpStudy(tester);
      final response = backend.hold('delete-account');
      await tester.ensureVisible(find.byKey(AccountKeys.deleteAccount));
      await tester.tap(find.byKey(AccountKeys.deleteAccount));
      await pumpStudy(tester);
      await tester.tap(find.text(SettingsStrings.deleteAccountConfirm));
      await pumpStudy(tester);
      expect(
        backend.callNames.where((name) => name == 'delete-account'),
        hasLength(1),
      );
      unavailable = true;
      response.complete({});
      await pumpStudy(tester);

      expect(find.byType(AppModal), findsOneWidget);
      expect(
        find.text(SettingsStrings.accountDeleteLocalPending),
        findsOneWidget,
      );
      expect(find.text(CommonStrings.actionFailedRetry), findsNothing);
      expect(find.text(CommonStrings.retry), findsOneWidget);
      expect(backend.currentSession?.userId, 'u-1');
      final binding = h.container.read(accountBindingProvider);
      expect(await completeStudy(tester, binding.deletedAccount()), 'u-1');
      expect(
        await completeStudy(
          tester,
          h.container.read(subjectRepositoryProvider).get(subject.id),
        ),
        isNotNull,
        reason: 'unconfirmed local cleanup retains rows for its retry',
      );
      expect(tester.takeException(), isNull);

      unavailable = false;
      await tester.tap(find.text(CommonStrings.retry));
      await pumpStudy(tester);
      expect(find.byType(AppModal), findsNothing);
      expect(backend.currentSession, isNull);
      expect(
        backend.callNames.where((name) => name == 'delete-account'),
        hasLength(1),
      );
      expect(await completeStudy(tester, binding.deletedAccount()), isNull);
      expect(
        await completeStudy(tester, h.db.select(h.db.subjects).get()),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await h.unmount(tester);
    },
  );
}
