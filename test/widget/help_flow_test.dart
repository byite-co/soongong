// HelpScreen (S09): FAQ accordion, inquiry validation (empty body · bad
// email), send → sent notice with the kind in the body, 429 → the daily
// limit fact with send disabled, failure → draft kept + support address +
// 다시 보내기.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/help_strings.dart';
import 'package:soongong/core/strings/home_strings.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/features/help/presentation/help_screen.dart';
import 'package:soongong/features/settings/presentation/settings_screen.dart';

import '../helpers/app_harness.dart';

void main() {
  late AppHarness h;

  setUp(() => h = AppHarness(mode: AuthMode.localOnly));
  tearDown(() => h.dispose());

  Future<void> openHelp(WidgetTester tester) async {
    await h.pumpApp(tester);
    await tester.tap(find.byTooltip(HomeStrings.settings));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(SettingsKeys.helpRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsKeys.helpRow));
    await tester.pumpAndSettle();
    expect(find.text(HelpStrings.title), findsOneWidget);
  }

  Future<void> type(WidgetTester tester, Key key, String text) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byKey(key), matching: find.byType(TextField)), text);
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(HelpKeys.send));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HelpKeys.send));
    await tester.pumpAndSettle();
  }

  testWidgets('FAQ: one answer open at a time', (tester) async {
    await openHelp(tester);
    expect(find.text(HelpStrings.faq[0].answer), findsNothing);
    await tester.tap(find.byKey(HelpKeys.faq(0)));
    await tester.pumpAndSettle();
    expect(find.text(HelpStrings.faq[0].answer), findsOneWidget);
    await tester.tap(find.byKey(HelpKeys.faq(1)));
    await tester.pumpAndSettle();
    expect(find.text(HelpStrings.faq[0].answer), findsNothing);
    expect(find.text(HelpStrings.faq[1].answer), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('inquiry: validation, then sent with the kind and reply email', (tester) async {
    await openHelp(tester);
    expect(find.text(HelpStrings.replyEmailLocalHint), findsOneWidget);
    await send(tester);
    expect(find.text(HelpStrings.bodyEmpty), findsOneWidget);
    await type(tester, HelpKeys.body, '사진이 안 올라가요');
    await type(tester, HelpKeys.email, 'nope');
    await send(tester);
    expect(find.text(HelpStrings.replyEmailInvalid), findsOneWidget);
    await type(tester, HelpKeys.email, 'me@x.io');
    await tester.tap(find.byKey(HelpKeys.kind(1)));
    await tester.pumpAndSettle();
    await send(tester);
    expect(find.text(HelpStrings.sent), findsOneWidget);
    final call = h.backend.calls.single;
    expect(call.name, 'submit-inquiry');
    expect(call.body['body'], startsWith(HelpStrings.bodyWithKind(HelpStrings.kinds[1], '사진이 안 올라가요')));
    expect(call.body['reply_email'], 'me@x.io');
    expect(tester.widget<TextField>(find.descendant(of: find.byKey(HelpKeys.body), matching: find.byType(TextField))).controller!.text, '', reason: 'draft cleared after sending');
    await h.unmount(tester);
  });

  testWidgets('429 → daily limit fact, send disabled', (tester) async {
    await openHelp(tester);
    await type(tester, HelpKeys.body, '결제가 두 번 됐어요');
    h.backend.responses['submit-inquiry'] = const EdgeFunctionException(429, 'rate_limited');
    await send(tester);
    expect(find.text(HelpStrings.sendRateLimited), findsOneWidget);
    await send(tester);
    expect(h.backend.calls.length, 1, reason: 'send disabled after the limit');
    await h.unmount(tester);
  });

  testWidgets('failure → draft kept, address shown, 다시 보내기 → sent', (tester) async {
    await openHelp(tester);
    await type(tester, HelpKeys.body, '결제가 두 번 됐어요');
    h.backend.responses['submit-inquiry'] = Exception('offline');
    await send(tester);
    expect(find.text(HelpStrings.sendFailed), findsOneWidget);
    expect(find.text(HelpStrings.supportAddressPending), findsOneWidget, reason: 'no fallback address is invented while SUPPORT_EMAIL is unset (S09b)');
    expect(find.text(HelpStrings.resend), findsOneWidget);
    expect(tester.widget<TextField>(find.descendant(of: find.byKey(HelpKeys.body), matching: find.byType(TextField))).controller!.text, '결제가 두 번 됐어요');
    h.backend.responses.remove('submit-inquiry');
    await send(tester);
    expect(find.text(HelpStrings.sent), findsOneWidget);
    await h.unmount(tester);
  });

  testWidgets('offline: sending is disabled with the fact shown, the draft stays; back online → send works (S09b)', (tester) async {
    h.network.current = false;
    await openHelp(tester);
    await type(tester, HelpKeys.body, '오프라인에서 작성');
    expect(find.byKey(HelpKeys.offline), findsOneWidget);
    await send(tester);
    expect(h.backend.calls, isEmpty);
    h.network.current = true;
    await tester.pumpAndSettle();
    expect(find.byKey(HelpKeys.offline), findsNothing);
    expect(tester.widget<TextField>(find.descendant(of: find.byKey(HelpKeys.body), matching: find.byType(TextField))).controller!.text, '오프라인에서 작성');
    await send(tester);
    expect(h.backend.calls.single.name, 'submit-inquiry');
    expect(find.text(HelpStrings.sent), findsOneWidget);
    await h.unmount(tester);
  });
}
