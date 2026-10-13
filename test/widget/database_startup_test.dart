import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/database_strings.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/widgets/app_button.dart';
import 'package:soongong/data/db/database_blocked_app.dart';
import 'package:soongong/data/repositories/repository_providers.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final blocked in [true, false]) {
      testWidgets(
        'UI-01/02/03 $brightness blocked=$blocked: Korean themed startup without DB at 200%',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          var databaseReads = 0;
          final semantics = tester.ensureSemantics();
          addTearDown(semantics.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appDatabaseProvider.overrideWith((ref) {
                  databaseReads++;
                  throw StateError('startup must not read DB');
                }),
              ],
              child: blocked
                  ? DatabaseBlockedApp(retry: () async {})
                  : const DatabasePreparingApp(),
            ),
          );
          await tester.pumpAndSettle();
          final text = find.text(
            blocked ? DatabaseStrings.title : DatabaseStrings.preparing,
          );
          final context = tester.element(text);
          expect(Theme.of(context).brightness, brightness);
          expect(Localizations.localeOf(context).languageCode, 'ko');
          expect(MaterialLocalizations.of(context).okButtonLabel, '확인');
          expect(
            Theme.of(context).textTheme.bodyMedium!.fontFamily,
            'Pretendard',
          );
          expect(databaseReads, 0);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(tester.takeException(), isNull);
          final colors = context.colors;
          double contrast(Color a, Color b) {
            final aa = a.computeLuminance();
            final bb = b.computeLuminance();
            return aa > bb ? (aa + .05) / (bb + .05) : (bb + .05) / (aa + .05);
          }

          expect(contrast(colors.tx, colors.bg), greaterThanOrEqualTo(4.5));
          if (blocked) {
            for (final label in [
              DatabaseStrings.description,
              DatabaseStrings.detail,
              DatabaseStrings.retry,
            ]) {
              await tester.ensureVisible(find.text(label));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            final button = find.byType(AppButton);
            final size = tester.getSize(button);
            expect(size.height, greaterThanOrEqualTo(44));
            expect(size.width, greaterThanOrEqualTo(44));
            expect(
              contrast(colors.onPri, colors.pri),
              greaterThanOrEqualTo(4.5),
            );
            final node = tester.getSemantics(button);
            expect(
              node.getSemanticsData().label,
              contains(DatabaseStrings.retry),
            );
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              isTrue,
            );
          }
        },
      );
    }
  }

  testWidgets(
    'UI-04 retry joins taps, recovers after error, ignores disposal',
    (tester) async {
      var calls = 0;
      var result = Completer<void>();
      await tester.pumpWidget(
        DatabaseBlockedApp(
          retry: () {
            calls++;
            return result.future;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(DatabaseStrings.retry));
      await tester.pump();
      await tester.tap(find.text(DatabaseStrings.retry));
      expect(calls, 1);
      result.completeError(StateError('synthetic'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      result = Completer<void>();
      await tester.tap(find.text(DatabaseStrings.retry));
      await tester.pump();
      expect(calls, 2);
      await tester.pumpWidget(const DatabasePreparingApp());
      result.complete();
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
