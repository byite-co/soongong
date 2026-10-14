package co.byite.soongong

import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var gazeBridge: GazeBridge? = null
    private var ownedShareBridge: OwnedShareBridge? = null

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ownedShareBridge?.dispose(); ownedShareBridge = null
        gazeBridge?.dispose(); gazeBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ownedShareBridge = OwnedShareBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        gazeBridge = GazeBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
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
