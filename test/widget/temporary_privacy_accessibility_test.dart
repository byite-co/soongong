import 'dart:io';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/privacy_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/app_button.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';
import 'package:soongong/features/privacy/presentation/privacy_screen.dart';

import '../helpers/app_harness.dart';
import '../helpers/study_race_harness.dart' show pumpStudy;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'REG-03 privacy unknown cleanup and retry at 200 percent $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final semantics = tester.ensureSemantics();
        final dir = Directory.systemTemp.createTempSync(
          'soongong-privacy-a11y-',
        );
        addTearDown(() => dir.deleteSync(recursive: true));
        var unavailable = true;
        var opens = 0;
        final h = AppHarness(
          mode: AuthMode.localOnly,
          temporaryStore: OwnedTempStore(() async {
            opens++;
            if (unavailable) throw const TempStoreUnavailable();
            return dir;
          }),
        );
        addTearDown(h.dispose);
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: h.container,
              child: MaterialApp(
                theme: buildAppTheme(brightness),
                home: const PrivacyScreen(),
              ),
            ),
          );
          await pumpStudy(tester);
          final notice = find.byKey(PrivacyKeys.sweepNotice);
          final retry = find.byKey(PrivacyKeys.sweepRetry);
          expect(notice, findsOneWidget);
          expect(find.text(PrivacyStrings.sweepUnavailable), findsOneWidget);
          expect(find.text(PrivacyStrings.sweepPending(0)), findsNothing);
          expect(Theme.of(tester.element(retry)).brightness, brightness);
          expect(MediaQuery.textScalerOf(tester.element(retry)).scale(10), 20);
          await tester.ensureVisible(retry);
          await pumpStudy(tester);
          expect(tester.takeException(), isNull);
          final rect = tester.getRect(retry);
          expect(rect.width, greaterThanOrEqualTo(44));
          expect(rect.height, greaterThanOrEqualTo(44));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(390));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(844));
          final data = tester.getSemantics(retry).getSemanticsData();
          expect(data.label, contains(PrivacyStrings.sweepRetry));
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.flagsCollection.isEnabled, Tristate.isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);

          // A failed real store retry remains actionable and never says zero.
          final beforeRetry = opens;
          await tester.tap(retry);
          await pumpStudy(tester);
          expect(opens, greaterThan(beforeRetry));
          expect(notice, findsOneWidget);
          expect(find.text(PrivacyStrings.sweepDone), findsNothing);
          expect(tester.widget<AppButton>(retry).busy, isFalse);
          expect(
            tester
                .getSemantics(retry)
                .getSemanticsData()
                .flagsCollection
                .isEnabled,
            Tristate.isTrue,
          );
          expect(tester.takeException(), isNull);

          unavailable = false;
          await tester.tap(retry);
          await pumpStudy(tester);
          expect(notice, findsNothing);
          expect(find.text(PrivacyStrings.sweepDone), findsOneWidget);
          expect(tester.takeException(), isNull);
          await h.unmount(tester);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
