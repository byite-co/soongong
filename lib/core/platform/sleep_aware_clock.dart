// Platform sleep-aware clock ([S06c]). One method channel, one method:
// `elapsedRealtimeMillis` → milliseconds of a monotonic clock that keeps
// counting while the device sleeps. Android: `SystemClock.elapsedRealtime()`
// (MainActivity.kt). iOS: `clock_gettime(CLOCK_MONOTONIC)` (AppDelegate.swift;
// Apple: "will continue to increment while the system is asleep").
// Without a platform answer (tests, unsupported host) the result is null and
// the session clock is simply not corrected.

import 'package:flutter/services.dart';

import '../domain/clock.dart';
import '../logging/app_logger.dart';

class PlatformSleepAwareClock extends SleepAwareClock {
  const PlatformSleepAwareClock();

  static const MethodChannel channel = MethodChannel('co.byite.soongong/clock');
  static const String method = 'elapsedRealtimeMillis';

  @override
  Future<Duration?> elapsedRealtime() async {
    try {
      final ms = await channel.invokeMethod<int>(method);
      return ms == null ? null : Duration(milliseconds: ms);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      appLog.w('sleep-aware clock unavailable: ${e.code}');
      return null;
    }
  }
}
