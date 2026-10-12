// NotificationScheduler (S09 · S09b): keeps the device's pending
// notifications equal to `NotificationPlan.build(...)` — re-planned when the
// settings, the review queue, the recurrences or the entitlement change,
// when the app returns to the foreground and at startup. Permission is read
// from the gateway and exposed for the 알림 sheet (`nfDenied` flow).
//
// Account boundary ([S09b]): a run captures the account it plans for and
// abandons itself after any await if the write context moved to another
// account, so a stale plan never overwrites the next account's schedule.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/billing_gateway.dart';
import '../../../core/contracts/notification_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../domain/notification_plan.dart';

part 'notification_scheduler.g.dart';

class NotificationScheduler {
  NotificationScheduler(this._ref);

  final Ref _ref;
  bool _started = false;
  Future<void>? _inFlight;
  bool _again = false;

  /// Subscribes to the inputs once; every change re-plans.
  void start() {
    if (_started) return;
    _started = true;
    _ref.listen<AsyncValue<AppSettings>>(_settingsProvider, (_, _) => unawaited(reschedule()));
    _ref.listen<AsyncValue<List<Recurrence>>>(_recurrencesProvider, (_, _) => unawaited(reschedule()));
    _ref.listen<AsyncValue<List<ReviewEntry>>>(_queueProvider, (_, _) => unawaited(reschedule()));
    _ref.listen<AsyncValue<Entitlement>>(_entitlementProvider, (_, _) => unawaited(reschedule()));
    unawaited(reschedule());
  }

  /// Recomputes the plan and hands it to the gateway (coalesces overlapping
  /// calls: the last one runs again after the current finishes).
  Future<void> reschedule() {
    final running = _inFlight;
    if (running != null) {
      _again = true;
      return running;
    }
    final f = _run().whenComplete(() {
      _inFlight = null;
      if (_again) {
        _again = false;
        unawaited(reschedule());
      }
    });
    _inFlight = f;
    return f;
  }

  Future<void> _run() async {
    try {
      final owner = _ref.read(writeContextProvider).userId;
      bool stale() => _ref.read(writeContextProvider).userId != owner;
      final gateway = _ref.read(notificationGatewayProvider);
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      final reviewRepo = _ref.read(reviewRepositoryProvider);
      final planner = _ref.read(plannerRepositoryProvider);
      final entitled = _ref.read(_entitlementProvider).value?.entitled ?? false;

      final settings = await settingsRepo.get();
      if (stale()) return;
      final queue = await reviewRepo.getQueue();
      if (stale()) return;
      final recurrences = await planner.getRecurrences();
      if (stale()) return;
      final now = _ref.read(appClockProvider).now();
      final plan = NotificationPlan.build(
        now: now,
        settings: settings,
        entitled: entitled,
        queue: queue,
        recurrences: recurrences,
      );
      final permission = await gateway.permissionStatus();
      if (stale()) return;
      if (permission == NotificationPermission.denied || plan.isEmpty) {
        await gateway.cancelAll();
      } else {
        await gateway.replaceAll(plan);
      }
    } on Object catch (e, st) {
      appLog.w('notification reschedule failed', error: e, stackTrace: st);
    }
  }
}

@riverpod
Stream<AppSettings> _settings(Ref ref) => ref.watch(settingsRepositoryProvider).watch();

@riverpod
Stream<List<Recurrence>> _recurrences(Ref ref) => ref.watch(plannerRepositoryProvider).watchRecurrences();

@riverpod
Stream<List<ReviewEntry>> _queue(Ref ref) => ref.watch(reviewRepositoryProvider).watchQueue();

@riverpod
Stream<Entitlement> _entitlement(Ref ref) => ref.watch(billingGatewayProvider).entitlement;

@Riverpod(keepAlive: true)
NotificationScheduler notificationScheduler(Ref ref) => NotificationScheduler(ref);

/// Device permission as last read; `refresh()` after the user returns from
/// the OS settings, `request()` from the sheet.
@Riverpod(keepAlive: true)
class NotificationPermissionState extends _$NotificationPermissionState {
  @override
  NotificationPermission build() {
    unawaited(refresh());
    return NotificationPermission.unknown;
  }

  Future<NotificationPermission> refresh() async {
    final s = await ref.read(notificationGatewayProvider).permissionStatus();
    state = s;
    return s;
  }

  Future<NotificationPermission> request() async {
    final s = await ref.read(notificationGatewayProvider).requestPermission();
    state = s;
    await ref.read(notificationSchedulerProvider).reschedule();
    return s;
  }

  Future<void> openSystemSettings() => ref.read(notificationGatewayProvider).openSystemSettings();
}
