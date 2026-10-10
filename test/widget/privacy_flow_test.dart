// PrivacyScreen (S09): hero follows the camera setting, the D14 table, the
// camera toggle, the reading row (free → paywall), the device photos
// (expired purge on open · list · delete one · delete all), 내 기록
// 내보내기 (share · failure + retry) and 모든 기록 삭제 (blocked while
// measuring · done).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/router/app_router.dart';
import 'package:soongong/core/strings/billing_strings.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/core/strings/privacy_strings.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/measure/domain/segment.dart';
import 'package:soongong/features/measure/domain/session_snapshot.dart';
import 'package:soongong/features/privacy/presentation/privacy_screen.dart';
import 'package:soongong/features/privacy/privacy_routes.dart';
import 'package:soongong/features/settings/presentation/settings_screen.dart';

import '../helpers/app_harness.dart';

void main() {
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> openPrivacy(WidgetTester tester) async {
    await h.pumpApp(tester);
    await tester.tap(find.byTooltip(HomeStrings.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.privacyRow));
    await tester.pumpAndSettle();
    expect(find.text(PrivacyStrings.title), findsOneWidget);
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<String> seedPhoto(String rel, {Duration age = const Duration(days: 1)}) async {
    final p = await h.container.read(readingRepositoryProvider).addPhoto(
          localPath: rel,
          takenAt: kHarnessNow.subtract(age),
          width: 1,
          height: 1,
          pageIndex: 0,
        );
    await h.writePhoto(rel);
    return p.id;
  }

  bool fileExists(String rel) => File('${h.photoDir.path}/$rel').existsSync();

  testWidgets('hero · D14 table · corrections fact · camera toggle', (tester) async {
    await openPrivacy(tester);
    expect(find.byKey(PrivacyKeys.heroOn), findsOneWidget);
    expect(find.text(PrivacyStrings.storedNeverBody), findsOneWidget);
    expect(find.text(PrivacyStrings.correctionsStatus(0, true)), findsOneWidget);
    await tapKey(tester, PrivacyKeys.cameraSwitch);
    expect(find.byKey(PrivacyKeys.heroOff), findsOneWidget);
    expect((await h.container.read(settingsRepositoryProvider).get()).seatDetectionEnabled, isFalse);
    await h.unmount(tester);
  });

  testWidgets('reading row (free): 잠금 해제 → paywall', (tester) async {
    await openPrivacy(tester);
    expect(find.text(PrivacyStrings.readingOffBody), findsOneWidget);
    await tapKey(tester, PrivacyKeys.readingAction);
    expect(find.text(BillingStrings.paywallTitle), findsWidgets);
    await h.unmount(tester);
  });

  testWidgets('photos: expired purged on open, list, delete one, delete all', (tester) async {
    await seedPhoto('e/old.jpg', age: const Duration(days: 31));
    final a = await seedPhoto('a/1.jpg');
    final b = await seedPhoto('a/2.jpg');
    await openPrivacy(tester);
    expect(find.text(PrivacyStrings.photosButton(2)), findsOneWidget);
    expect(fileExists('e/old.jpg'), isFalse, reason: '30-day rule on open');

    await tapKey(tester, PrivacyKeys.photosOpen);
    expect(find.text(PrivacyStrings.photosSheetTitle), findsOneWidget);
    expect(find.text(PrivacyStrings.photoUnknownRequest), findsNWidgets(2));
    expect(find.textContaining(PrivacyStrings.photoExpires(PrivacyStrings.monthDay(11, 1))), findsNWidgets(2));
    await tester.tap(find.byKey(PrivacyKeys.photoDelete(a)));
    await tester.pumpAndSettle();
    expect(find.text(PrivacyStrings.deletePhotoTitle), findsOneWidget);
    await tester.tap(find.text(PrivacyStrings.deletePhotoConfirm).last);
    await tester.pumpAndSettle();
    expect(find.byKey(PrivacyKeys.photoDelete(a)), findsNothing);
    expect(find.byKey(PrivacyKeys.photoDelete(b)), findsOneWidget);
    expect(fileExists('a/1.jpg'), isFalse);
    h.container.read(appRouterProvider).pop();
    await tester.pumpAndSettle();
    expect(find.text(PrivacyStrings.photosButton(1)), findsOneWidget);

    await tapKey(tester, PrivacyKeys.photosDeleteAll);
    expect(find.text(PrivacyStrings.deletePhotosTitle(1)), findsOneWidget);
    await tester.tap(find.text(PrivacyStrings.deletePhotoConfirm).last);
    await tester.pumpAndSettle();
    expect(find.text(PrivacyStrings.photosDeleted(1)), findsOneWidget);
    expect(find.text(PrivacyStrings.photosButton(0)), findsOneWidget);
    expect(fileExists('a/2.jpg'), isFalse);
    await tapKey(tester, PrivacyKeys.photosOpen);
    expect(find.byKey(PrivacyKeys.photosEmpty), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('export: CSV → share, sheet closes; failure keeps the sheet with 다시 시도', (tester) async {
    await openPrivacy(tester);
    await tapKey(tester, PrivacyKeys.export);
    expect(find.text(PrivacyStrings.exportHint), findsOneWidget);
    await tester.tap(find.byKey(PrivacyKeys.exportCsv));
    await tester.pumpAndSettle();
    expect(h.exports.length, 1);
    expect(find.text(PrivacyStrings.exportHint), findsNothing);

    h.shareError = Exception('no target');
    await tapKey(tester, PrivacyKeys.export);
    await tester.tap(find.byKey(PrivacyKeys.exportJson));
    await tester.pumpAndSettle();
    expect(find.byKey(PrivacyKeys.exportError), findsOneWidget);
    expect(find.text(PrivacyStrings.exportRetry), findsOneWidget);
    h.shareError = null;
    await tester.tap(find.byKey(PrivacyKeys.exportJson));
    await tester.pumpAndSettle();
    expect(h.exports.length, 2);
    expect(h.exports.last.mimeType, 'application/json');
    await h.unmount(tester);
  });

  testWidgets('모든 기록 삭제: blocked while measuring; then everything gone and 기타 recreated', (tester) async {
    final sessions = h.container.read(sessionRepositoryProvider);
    final subjects = h.container.read(subjectRepositoryProvider);
    final math = await subjects.create(name: '수학', colorIndex: 0);
    await sessions.saveFinished(
      id: 's1',
      kind: SessionKind.study,
      mode: SessionMode.manual,
      startedAt: DateTime(2026, 10, 1, 9),
      endedAt: DateTime(2026, 10, 1, 10),
      status: SessionStatus.finished,
      segments: <Segment>[Segment(id: 'seg', kind: SegmentKind.manual, startAt: DateTime(2026, 10, 1, 9).toUtc(), endAt: DateTime(2026, 10, 1, 10).toUtc())],
      sensitivityLevel: 0,
      subjectId: math.id,
    );
    // A session is being measured (snapshot present) → blocked (PRD 4.4).
    // The home reacts to the snapshot with its recovery sheet, so the
    // privacy screen is pushed over it through the router.
    await sessions.writeSnapshot(
      SessionSnapshot(
        sessionId: 'live',
        mode: SessionMode.manual,
        kind: SessionKind.self,
        startedAt: kHarnessNow,
        segments: const <Segment>[],
        openKind: SegmentKind.manual,
        openStart: kHarnessNow,
        savedAt: kHarnessNow,
        sensitivity: 0,
      ),
    );
    await h.pumpApp(tester);
    unawaited(h.container.read(appRouterProvider).push(privacyPath));
    await tester.pumpAndSettle();
    expect(find.text(PrivacyStrings.title), findsOneWidget);
    await tapKey(tester, PrivacyKeys.deleteAll);
    expect(find.text(PrivacyStrings.deleteAllTitle), findsOneWidget);
    expect(find.textContaining(PrivacyStrings.deleteAllItems.first), findsOneWidget);
    await tester.tap(find.text(PrivacyStrings.deleteAllConfirm).last);
    await tester.pumpAndSettle();
    expect(find.text(PrivacyStrings.deleteAllBlocked), findsOneWidget);
    expect(await sessions.getAll(), isNotEmpty);

    await sessions.clearSnapshot();
    await tapKey(tester, PrivacyKeys.deleteAll);
    await tester.tap(find.text(PrivacyStrings.deleteAllConfirm).last);
    await tester.pumpAndSettle();
    expect(find.text(PrivacyStrings.deleteAllDone), findsOneWidget);
    expect(await sessions.getAll(), isEmpty);
    expect((await subjects.getAll()).map((s) => s.isDefault), [true]);
    await h.unmount(tester);
  });
}
