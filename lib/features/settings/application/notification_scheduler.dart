// NotificationScheduler (S09): keeps the device's pending notifications
// equal to `NotificationPlan.build(...)` — re-planned when the settings,
// the review queue, the recurrences or the planner events change, when the
// app returns to the foreground and at startup. Permission is read from
// the gateway and exposed for the 알림 sheet (`nfDenied` flow).

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/notification_gateway.dart';
import '../../../core/contracts/providers.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/local_date.dart';
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
      final gateway = _ref.read(notificationGatewayProvider);
      final settings = await _ref.read(settingsRepositoryProvider).get();
      final now = _ref.read(appClockProvider).now();
      final today = LocalDate.of(now);
      final planner = _ref.read(plannerRepositoryProvider);
      final plan = NotificationPlan.build(
        now: now,
        settings: settings,
        queue: await _ref.read(reviewRepositoryProvider).getQueue(),
        recurrences: await planner.getRecurrences(),
        events: await planner.getItemsBetween(today, today.addDays(NotificationPlan.horizonDays - 1)),
      );
      if (await gateway.permissionStatus() == NotificationPermission.denied || plan.isEmpty) {
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
