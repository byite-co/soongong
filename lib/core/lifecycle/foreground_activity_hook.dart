// ForegroundActivityHook (S02 · S05b, D15): when the app returns to the
// foreground the local day is upserted into `activity_days`, and a sign-in
// that is still running on the cached profile re-reads it from the server.
// The launch itself is counted by the startup tasks. Errors are logged only.

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_gate.dart';
import '../../data/photos/owned_picker_coordinator.dart';
import '../../data/repositories/repositories.dart';
import '../../data/temp/temp_providers.dart';
import '../../features/privacy/application/photo_retention.dart';
import '../../features/privacy/application/purge_recovery.dart';
import '../../features/settings/application/notification_scheduler.dart';
import '../domain/local_date.dart';
import '../logging/app_logger.dart';

class ForegroundActivityHook extends ConsumerStatefulWidget {
  const ForegroundActivityHook({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ForegroundActivityHook> createState() =>
      _ForegroundActivityHookState();
}

class _ForegroundActivityHookState extends ConsumerState<ForegroundActivityHook>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Runs before the auth gate check: revoked scopes survive logout/DB wipe.
    if (Platform.isAndroid || Platform.isIOS) {
      unawaited(
        ref
            .read(ownedPickerCoordinatorProvider)
            .recover()
            .then((_) => ref.read(ownedTempStoreProvider).sweep()),
      );
    } else {
      unawaited(ref.read(ownedTempStoreProvider).sweep());
    }
    final gate = ref.read(authGateProvider);
    if (!gate.hasUser) return;
    if (gate is AuthGateSignedIn && gate.fromCache) {
      ref.read(authGateProvider.notifier).refreshProfile().catchError((
        Object e,
        StackTrace st,
      ) {
        appLog.w('profile refresh failed', error: e, stackTrace: st);
      });
    }
    final today = LocalDate.of(ref.read(appClockProvider).now());
    ref.read(activityRepositoryProvider).touch(today).catchError((
      Object e,
      StackTrace st,
    ) {
      appLog.w('activity_days touch failed', error: e, stackTrace: st);
      return false;
    });
    // S09: 30-day photo expiry on foreground (D14) and the notification plan
    // re-read (device permission may have changed in the OS settings).
    ref.read(photoRetentionProvider).purgeExpired().catchError((
      Object e,
      StackTrace st,
    ) {
      appLog.w('photo expiry failed', error: e, stackTrace: st);
      return 0;
    });
    // S09c: a 모든 기록 삭제 left open (server answer unknown · blocked ·
    // failed) is continued on return.
    unawaited(ref.read(purgeRecoveryProvider).resume());
    ref
        .read(notificationPermissionStateProvider.notifier)
        .refresh()
        .then((_) {
          return ref.read(notificationSchedulerProvider).reschedule();
        })
        .catchError((Object e, StackTrace st) {
          appLog.w('notification refresh failed', error: e, stackTrace: st);
        });
  }

  @override
  Widget build(BuildContext context) {
    // [S09c] Riverpod 3 pauses the `ref.listen` subscriptions a provider
    // created while that provider has no active listener of its own. The
    // two background services below react to streams (settings · review
    // queue · entitlement · session snapshot · network · auth gate) through
    // such subscriptions, so the root of the widget tree — always visible —
    // keeps them active.
    ref.watch(notificationSchedulerProvider);
    ref.watch(purgeRecoveryProvider);
    return widget.child;
  }
}
