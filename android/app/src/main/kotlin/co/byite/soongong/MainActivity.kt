package co.byite.soongong

import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // [S06c] Sleep-aware monotonic clock for the measurement session clock
        // (lib/core/platform/sleep_aware_clock.dart). elapsedRealtime() keeps
        // counting through deep sleep; Dart's Stopwatch (CLOCK_MONOTONIC) does not.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLOCK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "elapsedRealtimeMillis" -> result.success(SystemClock.elapsedRealtime())
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CLOCK_CHANNEL = "co.byite.soongong/clock"
    }
}
