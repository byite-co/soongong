// S09b: user-facing privacy / help wording stays inside what is decided —
// no vendor promise beyond D14 (학습 미사용 · vendor 30일 삭제), no invented
// support mailbox or reply-time promise, consent ② lines reused verbatim.

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/config/app_config.dart';
import 'package:soongong/core/strings/consent_strings.dart';
import 'package:soongong/core/strings/help_strings.dart';
import 'package:soongong/core/strings/privacy_strings.dart';
import 'package:soongong/core/strings/settings_strings.dart';

void main() {
  test('privacy strings: D14 rows present, vendor terms pending, no claims beyond D14', () {
    expect(PrivacyStrings.d14Rows.length, 11);
    final vendor = PrivacyStrings.d14Rows.firstWhere((r) => r.$2.contains('외부 AI'));
    expect(vendor.$3, contains('확정 전'));
    final all = <String>[
      PrivacyStrings.storedVendorPending,
      PrivacyStrings.readingStatusOn,
      PrivacyStrings.readingStatusOff,
      for (final r in PrivacyStrings.d14Rows) ...<String>[r.$1, r.$2, r.$3],
      ...ConsentStrings.readingLines,
    ].join('\n');
    expect(all, isNot(contains('학습 미사용')));
    expect(all, isNot(contains('유일하게 기기 밖')));
    expect(ConsentStrings.readingVendor, contains('확정 전'));
  });

  test('help strings: no invented mailbox or reply-time promise; the fallback is config-driven', () {
    final all = <String>[HelpStrings.sent, HelpStrings.sendFailed, HelpStrings.offline, HelpStrings.supportAddressPending].join('\n');
    expect(all, isNot(contains('@')));
    expect(all, isNot(contains('하루 안에')));
    expect(AppConfig.hasSupportEmail, isFalse, reason: 'unset in this build → the screen states the address is pending');
    expect(HelpStrings.supportAddress('x@y.z'), contains('x@y.z'));
  });

  test('account strings: sync facts stay "—" / 미연결 until S13', () {
    expect(SettingsStrings.syncLastNone, '—');
    expect(SettingsStrings.syncNotConnected, isNotEmpty);
  });
}
