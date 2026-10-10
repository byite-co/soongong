// SettingsScreen (`/settings`, S09, PRD 4.4 · 4.3c · prototype 12 · 12 설정·
// 계정 · N1 · N2 · D14 · N-로그아웃 · N-계정 삭제 · N-알림 권한 거부):
// 공부 (하루 목표 시간 · 과목 관리 · 주 시작 요일), 카메라·데이터 (카메라와
// 개인정보 · 숙제 사진·채점 판독 · 내보내기·삭제), 계정 (card · 로그아웃 ·
// 계정 삭제), 알림 (sheet), 화면 (테마), 이용 (요금제 · 도움말·문의 ·
// version). Every write is 3-state (busy → saved / failed with the choice
// kept, CLAUDE.md §5). Facts only — the screen never evaluates.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/contracts/notification_gateway.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/settings_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../billing/billing_routes.dart';
import '../../help/help_routes.dart';
import '../../planner/presentation/recurrence_editor.dart' show SegmentedChoice;
import '../../privacy/privacy_routes.dart';
import '../../subjects/subjects_routes.dart';
import '../application/account_controller.dart';
import '../application/notification_scheduler.dart';
import '../application/settings_providers.dart';

/// Widget keys for tests.
abstract final class SettingsKeys {
  static const Key goalRow = Key('settings-goal');
  static const Key subjectsRow = Key('settings-subjects');
  static const Key weekStartRow = Key('settings-week-start');
  static const Key privacyRow = Key('settings-privacy');
  static const Key readingRow = Key('settings-reading');
  static const Key exportRow = Key('settings-export');
  static const Key accountCard = Key('settings-account');
  static const Key logout = Key('settings-logout');
  static const Key deleteAccount = Key('settings-delete-account');
  static const Key notifRow = Key('settings-notif');
  static const Key themeChoice = Key('settings-theme');
  static const Key planRow = Key('settings-plan');
  static const Key helpRow = Key('settings-help');
  static const Key version = Key('settings-version');
  static const Key sheetError = Key('settings-sheet-error');
  static const Key goalSave = Key('settings-goal-save');
  static const Key goalApply = Key('settings-goal-apply');
  static Key goalChip(int minutes) => Key('settings-goal-chip-$minutes');
  static const Key weekMonday = Key('settings-week-mon');
  static const Key weekSunday = Key('settings-week-sun');
  static const Key notifPermission = Key('settings-notif-permission');
  static const Key notifReviewSwitch = Key('settings-notif-review');
  static const Key notifEventSwitch = Key('settings-notif-event');
  static Key notifTime(String key) => Key('settings-notif-time-$key');
}

/// Goal chips: 1시간 … 10시간 by 30 min (the default 120 is one of them).
const List<int> kGoalChoicesMinutes = <int>[
  60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 450, 480, 510, 540, 570, 600,
];

/// Default review time when the toggle is turned on (prototype D14).
const String kDefaultReviewTime = '21:00';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _themeBusy = false;

  void _back() => context.canPop() ? context.pop() : context.go(AppPaths.home);

  Future<void> _openGoal(AppSettings s) async {
    final saved = await showAppSheet<bool>(
      context,
      title: SettingsStrings.goalSheetTitle,
      builder: (_) => _GoalSheet(initialMinutes: s.dailyGoalMinutes),
    );
    if (saved == true && mounted) showAppToast(context, message: SettingsStrings.saved);
  }

  Future<void> _openWeekStart(AppSettings s) async {
    final saved = await showAppSheet<bool>(
      context,
      title: SettingsStrings.weekStart,
      builder: (_) => _WeekStartSheet(initial: s.weekStart),
    );
    if (saved == true && mounted) showAppToast(context, message: SettingsStrings.saved);
  }

  Future<void> _openNotifications() => showAppSheet<void>(
        context,
        title: SettingsStrings.notifSheetTitle,
        builder: (_) => const _NotificationsSheet(),
      );

  Future<void> _setTheme(ThemeSetting t) async {
    if (_themeBusy) return;
    setState(() => _themeBusy = true);
    final ok = await ref.read(settingsControllerProvider).setTheme(t);
    if (!mounted) return;
    setState(() => _themeBusy = false);
    if (!ok) showAppToast(context, message: SettingsStrings.saveFailed);
  }

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

  String _notifValue(AppSettings s) {
    final review = s.notifReviewTime;
    if (review == null && !s.notifEvent10min) return SettingsStrings.notifOff;
    final parts = <String>[
      if (review != null) SettingsStrings.notifReviewAt(review.key),
      if (s.notifEvent10min) SettingsStrings.notifEventShort,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(settingsStreamProvider);
    final entitled = ref.watch(settingsEntitlementProvider).value?.entitled ?? false;
    final planLabel = ref.watch(planLabelProvider);
    final account = ref.watch(accountInfoProvider);
    final now = ref.watch(appClockProvider).now();

    return FlowScaffold(
      title: SettingsStrings.title,
      onBack: _back,
      child: switch (settings) {
        AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppListSection(
                title: SettingsStrings.sectionStudy,
                children: <Widget>[
                  AppListRow(
                    key: SettingsKeys.goalRow,
                    label: SettingsStrings.dailyGoal,
                    value: formatDuration(Duration(minutes: value.dailyGoalMinutes)),
                    onTap: () => unawaited(_openGoal(value)),
                  ),
                  AppListRow(
                    key: SettingsKeys.subjectsRow,
                    label: SettingsStrings.subjects,
                    onTap: () => context.push(subjectsPath),
                  ),
                  AppListRow(
                    key: SettingsKeys.weekStartRow,
                    label: SettingsStrings.weekStart,
                    value: value.weekStart == DateTime.sunday ? SettingsStrings.sunday : SettingsStrings.monday,
                    onTap: () => unawaited(_openWeekStart(value)),
                  ),
                ],
              ),
              AppListSection(
                title: SettingsStrings.sectionCameraData,
                children: <Widget>[
                  AppListRow(
                    key: SettingsKeys.privacyRow,
                    label: SettingsStrings.privacy,
                    value: value.seatDetectionEnabled ? SettingsStrings.cameraOn : SettingsStrings.cameraOff,
                    onTap: () => context.push(privacyPath),
                  ),
                  AppListRow(
                    key: SettingsKeys.readingRow,
                    label: SettingsStrings.reading,
                    value: entitled ? SettingsStrings.readingOn : SettingsStrings.readingLocked,
                    onTap: () => context.push(privacyPath),
                  ),
                  AppListRow(
                    key: SettingsKeys.exportRow,
                    label: SettingsStrings.exportDelete,
                    onTap: () => context.push(privacyPath),
                  ),
                ],
              ),
              AppListSection(
                title: SettingsStrings.sectionAccount,
                children: <Widget>[
                  _AccountCard(
                    key: SettingsKeys.accountCard,
                    info: account,
                    now: now,
                    onLogout: () => unawaited(_logout()),
                    onDelete: () => unawaited(_deleteAccount()),
                  ),
                ],
              ),
              AppListSection(
                title: SettingsStrings.sectionNotifications,
                children: <Widget>[
                  AppListRow(
                    key: SettingsKeys.notifRow,
                    label: SettingsStrings.notifications,
                    value: _notifValue(value),
                    onTap: () => unawaited(_openNotifications()),
                  ),
                ],
              ),
              AppListSection(
                title: SettingsStrings.sectionDisplay,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(SettingsStrings.theme, style: AppTypography.body.copyWith(color: c.tx)),
                        const SizedBox(height: AppSpacing.s10),
                        KeyedSubtree(
                          key: SettingsKeys.themeChoice,
                          child: SegmentedChoice<ThemeSetting>(
                            value: value.theme,
                            options: const <(ThemeSetting, String)>[
                              (ThemeSetting.system, SettingsStrings.themeSystem),
                              (ThemeSetting.light, SettingsStrings.themeLight),
                              (ThemeSetting.dark, SettingsStrings.themeDark),
                            ],
                            onChanged: (t) => unawaited(_setTheme(t)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppListSection(
                title: SettingsStrings.sectionUse,
                children: <Widget>[
                  AppListRow(
                    key: SettingsKeys.planRow,
                    label: SettingsStrings.plan,
                    value: planLabel,
                    onTap: () => context.push(paywallPath),
                  ),
                  AppListRow(
                    key: SettingsKeys.helpRow,
                    label: SettingsStrings.help,
                    onTap: () => context.push(helpPath),
                  ),
                ],
              ),
              Center(
                child: Text(
                  SettingsStrings.version(AppConfig.appVersion),
                  key: SettingsKeys.version,
                  style: AppTypography.caption.copyWith(color: c.tx3),
                ),
              ),
            ],
          ),
        AsyncError() => StatePanel.error(
            title: SettingsStrings.loadFailed,
            onAction: () => ref.invalidate(settingsStreamProvider),
          ),
        _ => const StatePanel.loading(),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 계정 card (12 설정 · 계정)

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    super.key,
    required this.info,
    required this.now,
    required this.onLogout,
    required this.onDelete,
  });

  final AccountInfo info;
  final DateTime now;
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (info.localOnly) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(SettingsStrings.localOnlyTitle, style: AppTypography.body.copyWith(color: c.tx)),
            Text(SettingsStrings.localOnlyBody, style: AppTypography.caption.copyWith(color: c.tx3)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.priWeak, shape: BoxShape.circle),
                child: Text(
                  info.initial,
                  style: AppTypography.withWeight(AppTypography.body, 700).copyWith(color: c.priTx, height: 1),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      info.email ?? SettingsStrings.accountEmailUnknown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(color: c.tx),
                    ),
                    Text(
                      '${info.providerLabel ?? SettingsStrings.providerUnknown} · ${syncLabelOf(info.lastSyncedAt, now)}',
                      style: AppTypography.caption.copyWith(color: c.tx3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton.secondary(
                  key: SettingsKeys.logout,
                  label: SettingsStrings.logout,
                  size: AppButtonSize.small,
                  onPressed: onLogout,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Semantics(
                  button: true,
                  label: SettingsStrings.deleteAccount,
                  child: GestureDetector(
                    key: SettingsKeys.deleteAccount,
                    behavior: HitTestBehavior.opaque,
                    onTap: onDelete,
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

// ---------------------------------------------------------------------------
// N1 하루 목표 시간 (D25)

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({required this.initialMinutes});

  final int initialMinutes;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  late int _minutes = widget.initialMinutes;
  bool _saving = false;
  bool _failed = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    final ok = await ref.read(settingsControllerProvider).setDailyGoal(_minutes);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entitled = ref.watch(settingsEntitlementProvider).value?.entitled ?? false;
    final suggestion = ref.watch(goalSuggestionMinutesProvider);
    final choices = <int>{...kGoalChoicesMinutes, _minutes}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(SettingsStrings.goalHint, style: AppTypography.label.copyWith(color: c.tx2)),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s8,
          children: <Widget>[
            for (final m in choices)
              _Chip(
                key: SettingsKeys.goalChip(m),
                label: formatDuration(Duration(minutes: m)),
                selected: m == _minutes,
                onTap: () => setState(() {
                  _minutes = m;
                  _failed = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        if (!entitled)
          PremiumLockHint(
            message: SettingsStrings.goalSuggestedLocked,
            onOpenPaywall: () => context.push(paywallPath),
          )
        else if (suggestion == null)
          Text(SettingsStrings.goalSuggestedNone, style: AppTypography.label.copyWith(color: c.tx3))
        else
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  SettingsStrings.goalSuggested(formatDuration(Duration(minutes: suggestion))),
                  style: AppTypography.label.copyWith(color: c.tx2),
                ),
              ),
              AppButton.secondary(
                key: SettingsKeys.goalApply,
                label: SettingsStrings.goalSuggestedApply,
                size: AppButtonSize.small,
                expand: false,
                onPressed: () => setState(() {
                  _minutes = suggestion;
                  _failed = false;
                }),
              ),
            ],
          ),
        if (_failed) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          const AppNotice.error(SettingsStrings.saveFailed, key: SettingsKeys.sheetError),
        ],
        const SizedBox(height: AppSpacing.s16),
        AppButton(
          key: SettingsKeys.goalSave,
          label: SettingsStrings.goalSave(formatDuration(Duration(minutes: _minutes))),
          busy: _saving,
          busyLabel: SettingsStrings.goalSave(formatDuration(Duration(minutes: _minutes))),
          onPressed: () => unawaited(_save()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// N2 주 시작 요일

class _WeekStartSheet extends ConsumerStatefulWidget {
  const _WeekStartSheet({required this.initial});

  final int initial;

  @override
  ConsumerState<_WeekStartSheet> createState() => _WeekStartSheetState();
}

class _WeekStartSheetState extends ConsumerState<_WeekStartSheet> {
  late int _value = widget.initial;
  bool _saving = false;
  bool _failed = false;

  Future<void> _choose(int weekday) async {
    if (_saving) return;
    setState(() {
      _value = weekday;
      _saving = true;
      _failed = false;
    });
    final ok = await ref.read(settingsControllerProvider).setWeekStart(weekday);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _OptionRow(
          key: SettingsKeys.weekMonday,
          label: SettingsStrings.monday,
          hint: SettingsStrings.mondayHint,
          selected: _value == DateTime.monday,
          busy: _saving && _value == DateTime.monday,
          onTap: () => unawaited(_choose(DateTime.monday)),
        ),
        const SizedBox(height: AppSpacing.s8),
        _OptionRow(
          key: SettingsKeys.weekSunday,
          label: SettingsStrings.sunday,
          hint: SettingsStrings.sundayHint,
          selected: _value == DateTime.sunday,
          busy: _saving && _value == DateTime.sunday,
          onTap: () => unawaited(_choose(DateTime.sunday)),
        ),
        if (_failed) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          const AppNotice.error(SettingsStrings.saveFailed, key: SettingsKeys.sheetError),
        ],
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final String hint;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label · $hint',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s10),
          decoration: BoxDecoration(
            color: selected ? c.priWeak : c.surface,
            border: Border.all(color: selected ? c.pri : c.line),
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx)),
                    Text(hint, style: AppTypography.caption.copyWith(color: c.tx3)),
                  ],
                ),
              ),
              if (busy)
                SizedBox(
                  width: AppIcon.sizeSmall,
                  height: AppIcon.sizeSmall,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.pri),
                )
              else if (selected)
                LucideIcon.small(LucideIcons.check, color: c.priTx),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D14 알림 (permission row · 복습 큐 · 반복 일정 10분 전)

class _NotificationsSheet extends ConsumerStatefulWidget {
  const _NotificationsSheet();

  @override
  ConsumerState<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<_NotificationsSheet> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _write(Future<bool> Function() write, {bool turnedOn = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await write();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
    });
    if (ok && turnedOn) await _ensurePermission();
  }

  /// After a toggle turned on: ask once when unknown; explain when denied
  /// (`nfDenied`). The in-app setting stays saved either way.
  Future<void> _ensurePermission() async {
    final state = ref.read(notificationPermissionStateProvider.notifier);
    var p = ref.read(notificationPermissionStateProvider);
    if (p == NotificationPermission.unknown) p = await state.request();
    if (!mounted || p != NotificationPermission.denied) return;
    await _explainDenied();
  }

  Future<void> _explainDenied() async {
    final open = await showAppModal(
      context,
      title: SettingsStrings.notifDeniedTitle,
      body: SettingsStrings.notifDeniedBody,
      primaryLabel: SettingsStrings.notifOpenSettings,
      secondaryLabel: SettingsStrings.notifLater,
    );
    if (open && mounted) {
      await ref.read(notificationPermissionStateProvider.notifier).openSystemSettings();
    }
  }

  Future<void> _onPermissionTap(NotificationPermission p) async {
    switch (p) {
      case NotificationPermission.granted:
        return;
      case NotificationPermission.unknown:
        final r = await ref.read(notificationPermissionStateProvider.notifier).request();
        if (mounted && r == NotificationPermission.denied) await _explainDenied();
      case NotificationPermission.denied:
        await _explainDenied();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(settingsStreamProvider).value ?? const AppSettings();
    final permission = ref.watch(notificationPermissionStateProvider);
    ref.listen<NotificationPermission>(notificationPermissionStateProvider, (prev, next) {
      if (prev != NotificationPermission.granted && next == NotificationPermission.granted) {
        final review = ref.read(settingsStreamProvider).value?.notifReviewTime;
        showAppToast(
          context,
          message: review == null
              ? SettingsStrings.notifEnabledToastNoReview
              : SettingsStrings.notifEnabledToast(review.key),
        );
      }
    });
    final controller = ref.read(settingsControllerProvider);
    final review = settings.notifReviewTime;
    final permissionLabel = switch (permission) {
      NotificationPermission.granted => SettingsStrings.notifPermissionOn,
      NotificationPermission.denied => SettingsStrings.notifPermissionOff,
      NotificationPermission.unknown => SettingsStrings.notifPermissionUnknown,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: permission != NotificationPermission.granted,
          label: permissionLabel,
          child: GestureDetector(
            key: SettingsKeys.notifPermission,
            behavior: HitTestBehavior.opaque,
            onTap: permission == NotificationPermission.granted ? null : () => unawaited(_onPermissionTap(permission)),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s10),
              decoration: BoxDecoration(
                color: permission == NotificationPermission.granted ? c.okWeak : c.accWeak,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                children: <Widget>[
                  LucideIcon.small(
                    permission == NotificationPermission.granted ? LucideIcons.bell : LucideIcons.bellOff,
                    color: permission == NotificationPermission.granted ? c.okTx : c.accTx,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      permissionLabel,
                      style: AppTypography.label.copyWith(
                        color: permission == NotificationPermission.granted ? c.okTx : c.accTx,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        _SwitchRow(
          switchKey: SettingsKeys.notifReviewSwitch,
          label: SettingsStrings.notifReview,
          hint: SettingsStrings.notifReviewHint,
          value: review != null,
          enabled: !_busy,
          onChanged: (on) => unawaited(
            _write(
              () => controller.setNotifReviewTime(on ? LocalTime.parse(kDefaultReviewTime) : null),
              turnedOn: on,
            ),
          ),
        ),
        if (review != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            children: <Widget>[
              for (final t in SettingsStrings.notifTimes)
                _Chip(
                  key: SettingsKeys.notifTime(t),
                  label: t,
                  selected: review.key == t,
                  onTap: () => unawaited(_write(() => controller.setNotifReviewTime(LocalTime.parse(t)))),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        _SwitchRow(
          switchKey: SettingsKeys.notifEventSwitch,
          label: SettingsStrings.notifEvent,
          hint: SettingsStrings.notifEventHint,
          value: settings.notifEvent10min,
          enabled: !_busy,
          onChanged: (on) => unawaited(_write(() => controller.setNotifEvent10min(on: on), turnedOn: on)),
        ),
        if (_failed) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          const AppNotice.error(SettingsStrings.saveFailed, key: SettingsKeys.sheetError),
        ],
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.switchKey,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final Key switchKey;
  final String label;
  final String hint;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: AppTypography.body.copyWith(color: c.tx)),
              Text(hint, style: AppTypography.caption.copyWith(color: c.tx3)),
            ],
          ),
        ),
        Semantics(
          label: label,
          child: Switch(
            key: switchKey,
            value: value,
            activeTrackColor: c.pri,
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

/// Prototype chip (shared look with the planner sheet's target chips).
class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
          child: Container(
            height: AppLayout.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
            decoration: BoxDecoration(
              color: selected ? c.priWeak : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: selected ? c.pri : c.line, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.withWeight(AppTypography.label, 500).copyWith(
                color: selected ? c.priTx : c.tx2,
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
