// Settings providers (S09): the settings stream, the theme the app follows,
// the plan label facts, the account facts (email · 로그인 방식 · 동기화
// 시각) and the premium goal suggestion. Writes go through
// `SettingsController` (3-state: busy → saved / failed, input kept).

import 'package:flutter/material.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/billing_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/lifecycle/calendar_day.dart';
import '../../../core/strings/settings_strings.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_mode.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../stats/domain/seated_aggregate.dart';
import 'notification_scheduler.dart';

part 'settings_providers.g.dart';

@riverpod
Stream<AppSettings> settingsStream(Ref ref) => ref.watch(settingsRepositoryProvider).watch();

/// `ThemeMode` for `MaterialApp` — system until the settings row loads.
@riverpod
ThemeMode appThemeMode(Ref ref) {
  final theme = ref.watch(settingsStreamProvider).value?.theme ?? ThemeSetting.system;
  return switch (theme) {
    ThemeSetting.system => ThemeMode.system,
    ThemeSetting.light => ThemeMode.light,
    ThemeSetting.dark => ThemeMode.dark,
  };
}

@riverpod
Stream<Entitlement> settingsEntitlement(Ref ref) => ref.watch(billingGatewayProvider).entitlement;

@riverpod
Stream<List<WrongItem>> settingsWrongs(Ref ref) => ref.watch(wrongsRepositoryProvider).watchAll();

/// 요금제 row label — facts from the entitlement (D18) and the saved wrongs.
@riverpod
String planLabel(Ref ref) {
  final e = ref.watch(settingsEntitlementProvider).value;
  final wrongs = ref.watch(settingsWrongsProvider).value?.length ?? 0;
  if (e == null) return SettingsStrings.planFree;
  return switch (e.status) {
    EntitlementStatus.trial => SettingsStrings.planTrial,
    EntitlementStatus.premium => SettingsStrings.planPremium,
    EntitlementStatus.cancelPending => SettingsStrings.planCancelPending,
    EntitlementStatus.grace => SettingsStrings.planGrace,
    EntitlementStatus.pendingApproval => SettingsStrings.planPendingApproval,
    EntitlementStatus.expired || EntitlementStatus.free =>
      !e.entitled && wrongs > 0 ? SettingsStrings.planExpiredReadOnly(wrongs) : SettingsStrings.planFree,
  };
}

/// Facts shown on the 계정 card.
class AccountInfo {
  const AccountInfo({required this.localOnly, this.email, this.providerLabel, this.lastSyncedAt});

  final bool localOnly;
  final String? email;
  final String? providerLabel;
  final DateTime? lastSyncedAt;

  String get initial {
    final e = email;
    return e == null || e.isEmpty ? '?' : e.substring(0, 1).toUpperCase();
  }
}

@riverpod
AccountInfo accountInfo(Ref ref) {
  final mode = ref.watch(authModeProvider);
  final gate = ref.watch(authGateProvider);
  if (mode != AuthMode.backend || gate is! AuthGateSignedIn) return const AccountInfo(localOnly: true);
  final backend = ref.watch(authBackendProvider);
  return AccountInfo(
    localOnly: false,
    email: backend.currentSession?.email,
    providerLabel: providerLabelOf(backend.currentProvider),
    lastSyncedAt: ref.watch(syncEngineProvider).lastSyncedAt,
  );
}

String providerLabelOf(String? provider) => switch (provider) {
      'email' => SettingsStrings.providerEmail,
      'google' => SettingsStrings.providerGoogle,
      'apple' => SettingsStrings.providerApple,
      'kakao' => SettingsStrings.providerKakao,
      _ => SettingsStrings.providerUnknown,
    };

/// `방금 동기화됨` · `N분 전 동기화` · … · `아직 동기화 전` (facts).
String syncLabelOf(DateTime? at, DateTime now) {
  if (at == null) return SettingsStrings.syncNever;
  final d = now.difference(at);
  if (d.inMinutes < 1) return SettingsStrings.syncJustNow;
  if (d.inHours < 1) return SettingsStrings.syncMinutesAgo(d.inMinutes);
  if (d.inDays < 1) return SettingsStrings.syncHoursAgo(d.inHours);
  return SettingsStrings.syncDaysAgo(d.inDays);
}

// ---------------------------------------------------------------------------
// Goal suggestion (D25: premium gets a record-based default, 최근 4주 평균)

@riverpod
Stream<List<SessionSegment>> goalWindowSegments(Ref ref) {
  final today = ref.watch(calendarDayProvider);
  return ref.watch(sessionRepositoryProvider).watchSegmentsOverlapping(today.addDays(-27), today);
}

@riverpod
Stream<List<StudySession>> settingsAllSessions(Ref ref) => ref.watch(sessionRepositoryProvider).watchAll();

/// Mean 순공 minutes per recorded day over the last 28 days, rounded to the
/// 30-minute step of the sheet; null when nothing was recorded.
@riverpod
int? goalSuggestionMinutes(Ref ref) {
  final today = ref.watch(calendarDayProvider);
  final segments = ref.watch(goalWindowSegmentsProvider).value;
  final sessions = ref.watch(settingsAllSessionsProvider).value;
  if (segments == null || sessions == null) return null;
  final agg = SeatedAggregate.build(from: today.addDays(-27), to: today, segments: segments, sessions: sessions);
  if (!agg.hasRecord) return null;
  final minutes = agg.averagePerRecordedDay ~/ 60;
  final rounded = ((minutes + 15) ~/ 30) * 30;
  return rounded < 30 ? 30 : rounded;
}

// ---------------------------------------------------------------------------
// Writes

class SettingsController {
  SettingsController(this._ref);

  final Ref _ref;

  Future<bool> _run(Future<void> Function() write, {bool reschedule = false}) async {
    try {
      await write();
      if (reschedule) await _ref.read(notificationSchedulerProvider).reschedule();
      return true;
    } on Object {
      return false;
    }
  }

  Future<bool> setDailyGoal(int minutes) => _run(() => _ref.read(settingsRepositoryProvider).setDailyGoalMinutes(minutes));

  Future<bool> setWeekStart(int weekday) => _run(() => _ref.read(settingsRepositoryProvider).setWeekStart(weekday));

  Future<bool> setTheme(ThemeSetting theme) => _run(() => _ref.read(settingsRepositoryProvider).setTheme(theme));

  Future<bool> setSeatDetection({required bool on}) =>
      _run(() => _ref.read(settingsRepositoryProvider).setSeatDetectionEnabled(on: on));

  Future<bool> setNotifReviewTime(LocalTime? time) =>
      _run(() => _ref.read(settingsRepositoryProvider).setNotifReviewTime(time), reschedule: true);

  Future<bool> setNotifEvent10min({required bool on}) =>
      _run(() => _ref.read(settingsRepositoryProvider).setNotifEvent10min(on: on), reschedule: true);
}

@Riverpod(keepAlive: true)
SettingsController settingsController(Ref ref) => SettingsController(ref);
