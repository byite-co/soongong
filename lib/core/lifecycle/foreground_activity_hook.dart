// ForegroundActivityHook (S02, D15): when the app returns to the foreground
// the local day is upserted into `activity_days`. The launch itself is
// counted by the startup tasks. Errors are logged, never surfaced.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_gate.dart';
import '../../data/repositories/repositories.dart';
import '../domain/local_date.dart';
import '../logging/app_logger.dart';

class ForegroundActivityHook extends ConsumerStatefulWidget {
  const ForegroundActivityHook({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ForegroundActivityHook> createState() => _ForegroundActivityHookState();
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
    if (!ref.read(authGateProvider).hasUser) return;
    final today = LocalDate.of(ref.read(appClockProvider).now());
    ref.read(activityRepositoryProvider).touch(today).catchError((Object e, StackTrace st) {
      appLog.w('activity_days touch failed', error: e, stackTrace: st);
      return false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
