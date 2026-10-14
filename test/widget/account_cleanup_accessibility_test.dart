import 'dart:io';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/common_strings.dart';
import 'package:soongong/core/strings/settings_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/app_button.dart';
import 'package:soongong/core/widgets/app_modal.dart';
import 'package:soongong/data/auth/account_binding.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/features/settings/presentation/account_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/bounded_widget_future.dart';
import '../helpers/fake_auth_backend.dart';
import '../helpers/study_race_harness.dart' show pumpStudy;

Finder _modalButton(String label) => find.descendant(
  of: find.byType(AppModal),
  matching: find.widgetWithText(AppButton, label),
);

void _withinViewport(Rect rect) {
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(390));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(844));
}

void main() {
  for (final brightness in Brightness.values) {
    for (final deleting in [false, true]) {
      final action = deleting ? 'account deletion' : 'logout';
      testWidgets(
        'REG-03 $action cleanup modal retry at 200 percent $brightness',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final semantics = tester.ensureSemantics();
          final directory = Directory.systemTemp.createTempSync(
            'account-cleanup-a11y-',
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
          final response = deleting ? backend.hold('delete-account') : null;
          try {
            h.container.listen(authGateProvider, (_, _) {});
            await pumpStudy(tester);
            expect(h.container.read(authGateProvider), isA<AuthGateSignedIn>());
            final subject = await completeWidgetFuture(
              tester,
              h.container
                  .read(subjectRepositoryProvider)
                  .create(name: 'synthetic-owned-record', colorIndex: 0),
              'seed account record',
            );
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: h.container,
                child: MaterialApp(
                  theme: buildAppTheme(brightness),
                  home: const AccountScreen(),
                ),
              ),
            );
            await pumpStudy(tester);
            final entry = find.byKey(
              deleting ? AccountKeys.deleteAccount : AccountKeys.logout,
            );
            await tester.ensureVisible(entry);
            // A small viewport really scrolls here; its new render position
            // must be laid out before tap computes the hit-test coordinate.
            await pumpStudy(tester);
            _withinViewport(tester.getRect(entry));
            expect(entry.hitTestable(), findsOneWidget);
            await tester.tap(entry);
            await pumpStudy(tester);
            expect(tester.takeException(), isNull);
            expect(find.byType(AppModal), findsOneWidget);

            final confirm = _modalButton(
              deleting
                  ? SettingsStrings.deleteAccountConfirm
                  : SettingsStrings.logoutConfirm,
            );
            await tester.ensureVisible(confirm);
            await pumpStudy(tester);
            _withinViewport(tester.getRect(confirm));
            if (!deleting) unavailable = true;
            await tester.tap(confirm);
            await pumpStudy(tester);
            if (deleting) {
              expect(
                backend.callNames.where((name) => name == 'delete-account'),
                hasLength(1),
              );
              // Fail local cleanup only after the real controller receives
              // the server acknowledgement, matching the DEL-07 fixture.
              unavailable = true;
              response!.complete({});
              await pumpStudy(tester);
            }

            final errorText = deleting
                ? SettingsStrings.accountDeleteLocalPending
                : SettingsStrings.logoutCleanupPending;
            final error = find.text(errorText);
            expect(find.byType(AppModal), findsOneWidget);
            expect(error, findsOneWidget);
            expect(find.text(CommonStrings.actionFailedRetry), findsNothing);
            await tester.ensureVisible(error);
            await pumpStudy(tester);
            _withinViewport(tester.getRect(error));
            expect(
              tester.getSemantics(error).getSemanticsData().label,
              contains(errorText),
            );
            expect(tester.takeException(), isNull);

            final retryLabel = deleting
                ? CommonStrings.retry
                : SettingsStrings.logoutConfirm;
            final retry = _modalButton(retryLabel);
            await tester.ensureVisible(retry);
            await pumpStudy(tester);
            expect(Theme.of(tester.element(retry)).brightness, brightness);
            expect(
              MediaQuery.textScalerOf(tester.element(retry)).scale(10),
              20,
            );
            final rect = tester.getRect(retry);
            _withinViewport(rect);
            expect(rect.width, greaterThanOrEqualTo(44));
            expect(rect.height, greaterThanOrEqualTo(44));
            final data = tester.getSemantics(retry).getSemanticsData();
            expect(data.label, contains(retryLabel));
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.flagsCollection.isEnabled, Tristate.isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            expect(tester.widget<AppButton>(retry).busy, isFalse);
            expect(backend.currentSession?.userId, 'u-1');
            expect(backend.callNames, isNot(contains('signOut')));
            final binding = h.container.read(accountBindingProvider);
            expect(
              await completeWidgetFuture(
                tester,
                binding.deletedAccount(),
                'pending deletion receipt',
              ),
              deleting ? 'u-1' : null,
            );
            expect(
              await completeWidgetFuture(
                tester,
                h.container.read(subjectRepositoryProvider).get(subject.id),
                'record before retry',
              ),
              isNotNull,
            );
            expect(tester.takeException(), isNull);

            unavailable = false;
            await tester.tap(retry);
            await pumpStudy(tester);
            await tester.pumpAndSettle(
              const Duration(milliseconds: 20),
              EnginePhase.sendSemanticsUpdate,
              const Duration(seconds: 5),
            );
            expect(find.byType(AppModal), findsNothing);
            expect(backend.currentSession, isNull);
            expect(
              backend.callNames.where((name) => name == 'delete-account'),
              hasLength(deleting ? 1 : 0),
            );
            expect(
              await completeWidgetFuture(
                tester,
                binding.deletedAccount(),
                'deletion receipt after retry',
              ),
              isNull,
            );
            final rows = await completeWidgetFuture(
              tester,
              h.db.select(h.db.subjects).get(),
              'account records after retry',
            );
            expect(rows, deleting ? isEmpty : hasLength(1));
            expect(tester.takeException(), isNull);
          } finally {
            if (response != null && !response.isCompleted) {
              response.complete({});
            }
            await h.unmount(tester);
            semantics.dispose();
          }
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );
    }
  }
}
