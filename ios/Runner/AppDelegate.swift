import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerSleepAwareClock(messenger: engineBridge.applicationRegistrar.messenger())
  }

  // [S06c] Sleep-aware monotonic clock for the measurement session clock
  // (lib/core/platform/sleep_aware_clock.dart). CLOCK_MONOTONIC keeps counting
  // while the system is asleep (Apple clock_gettime(3)); mach_absolute_time,
  // which Dart's Stopwatch is based on, does not.
  private func registerSleepAwareClock(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "co.byite.soongong/clock", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "elapsedRealtimeMillis" else {
        result(FlutterMethodNotImplemented)
        return
      }
      var ts = timespec()
      clock_gettime(CLOCK_MONOTONIC, &ts)
      result(Int64(ts.tv_sec) * 1_000 + Int64(ts.tv_nsec) / 1_000_000)
    }
  }
}
