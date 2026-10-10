// AccountScreen (`/settings/account`, S09b, 원본 S09 §4.2 · PRD 4.3c ·
// userflow acctLogout · acctDelete): email · 로그인 방식 · 동의 ①·② version
// and time (only ② can be withdrawn, `update-consent`) · 마지막 동기화 "—"
// and 지금 동기화 "미연결" until S13 · 로그아웃 · 계정 삭제 (both with a
// confirmation, progress and failure kept open). Facts only. Local-only
// builds show the mode and nothing to act on.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/local_date.dart';
import '../../../core/strings/settings_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/auth/auth_models.dart';
import '../../auth/domain/auth_redirect.dart';
import '../application/account_controller.dart';
import '../application/settings_providers.dart';

/// Widget keys for tests.
abstract final class AccountKeys {
  static const Key logout = Key('account-logout');
  static const Key deleteAccount = Key('account-delete');
  static const Key consentAccount = Key('account-consent-1');
  static const Key consentReading = Key('account-consent-2');
  static const Key revoke = Key('account-revoke');
  static const Key syncLast = Key('account-sync-last');
  static const Key syncNow = Key('account-sync-now');
}

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  void _back() => context.canPop() ? context.pop() : context.go(AppPaths.settings);

  Future<void> _logout() async {
    await showAppModal(
      context,
      title: SettingsStrings.logoutTitle,
      body: SettingsStrings.logoutBody,
      primaryLabel: SettingsStrings.logoutConfirm,
      onConfirm: () => ref.read(accountControllerProvider).logout(),
    );
  }

  Future<void> _deleteAccount() async {
    await showAppModal(
      context,
      title: SettingsStrings.deleteAccountTitle,
      body: SettingsStrings.deleteAccountBody,
      primaryLabel: SettingsStrings.deleteAccountConfirm,
      destructive: true,
      onConfirm: () => ref.read(accountControllerProvider).deleteAccount(),
    );
  }

  Future<void> _revoke() async {
    final ok = await showAppModal(
      context,
      title: SettingsStrings.consentRevokeTitle,
      body: SettingsStrings.consentRevokeBody,
      primaryLabel: SettingsStrings.consentRevokeConfirm,
      destructive: true,
      onConfirm: () => ref.read(accountControllerProvider).revokeReadingConsent(),
    );
    if (ok && mounted) showAppToast(context, message: SettingsStrings.consentRevoked);
  }

  static String _date(DateTime at) => LocalDate.of(at.toLocal()).key;

  String _consentAccountFact(ProfileSnapshot? p) {
    final at = p?.consentAccountAt;
    if (p == null || at == null) return SettingsStrings.consentNone;
    return SettingsStrings.consentVersionAt(p.consentAccountVersion ?? '', _date(at));
  }

  String _consentReadingFact(ProfileSnapshot? p) {
    if (p == null) return SettingsStrings.consentNone;
    final revoked = p.consentReadingRevokedAt;
    final at = p.consentReadingAt;
    if (p.readingConsentActive && at != null) return SettingsStrings.consentVersionAt(p.consentReadingVersion ?? '', _date(at));
    if (revoked != null) return SettingsStrings.consentRevokedAt(_date(revoked));
    return SettingsStrings.consentNone;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final info = ref.watch(accountInfoProvider);
    final profile = info.profile;
    return FlowScaffold(
      title: SettingsStrings.accountTitle,
      onBack: _back,
      child: info.localOnly
          ? const AppListSection(
              children: <Widget>[
                AppListRow(label: SettingsStrings.localOnlyTitle, hint: SettingsStrings.localOnlyBody),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppListSection(
                  children: <Widget>[
                    AppListRow(
                      label: info.email ?? SettingsStrings.accountEmailUnknown,
                      hint: info.providerLabel ?? SettingsStrings.providerUnknown,
                      leading: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.priWeak, shape: BoxShape.circle),
                        child: Text(
                          info.initial,
                          style: AppTypography.withWeight(AppTypography.body, 700).copyWith(color: c.priTx, height: 1),
                        ),
                      ),
                    ),
                  ],
                ),
                AppListSection(
                  title: SettingsStrings.consentSection,
                  children: <Widget>[
                    AppListRow(
                      key: AccountKeys.consentAccount,
                      label: SettingsStrings.consentAccount,
                      hint: _consentAccountFact(profile),
                    ),
                    AppListRow(
                      key: AccountKeys.consentReading,
                      label: SettingsStrings.consentReading,
                      hint: _consentReadingFact(profile),
                      trailing: profile != null && profile.readingConsentActive
                          ? AppButton.secondary(
                              key: AccountKeys.revoke,
                              label: SettingsStrings.consentRevoke,
                              size: AppButtonSize.small,
                              expand: false,
                              onPressed: () => unawaited(_revoke()),
                            )
                          : null,
                    ),
                  ],
                ),
                const AppListSection(
                  title: SettingsStrings.syncSection,
                  children: <Widget>[
                    AppListRow(key: AccountKeys.syncLast, label: SettingsStrings.syncLast, value: SettingsStrings.syncLastNone),
                    AppListRow(key: AccountKeys.syncNow, label: SettingsStrings.syncNow, value: SettingsStrings.syncNotConnected),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppButton.secondary(
                        key: AccountKeys.logout,
                        label: SettingsStrings.logout,
                        size: AppButtonSize.small,
                        onPressed: () => unawaited(_logout()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: SettingsStrings.deleteAccount,
                        child: GestureDetector(
                          key: AccountKeys.deleteAccount,
                          behavior: HitTestBehavior.opaque,
                          onTap: () => unawaited(_deleteAccount()),
                          child: Container(
                            height: AppSpacing.touchTarget,
                            alignment: Alignment.center,
                            child: Text(
                              SettingsStrings.deleteAccount,
                              style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.accTx),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
