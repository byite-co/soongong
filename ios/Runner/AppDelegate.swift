import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var gazeBridge: GazeBridge?
  private var ownedShareBridge: OwnedShareBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let storage = FlutterMethodChannel(name: "co.byite.soongong/storage", binaryMessenger: engineBridge.applicationRegistrar.messenger())
    storage.setMethodCallHandler { call, result in
      guard call.method == "excludeDocumentsFromBackup" else { result(FlutterMethodNotImplemented); return }
      do {
        var directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        result(nil)
      } catch { result(FlutterError(code: "backup_policy_failed", message: nil, details: nil)) }
    }
    ownedShareBridge = OwnedShareBridge(messenger: engineBridge.applicationRegistrar.messenger())
    gazeBridge = GazeBridge(messenger: engineBridge.applicationRegistrar.messenger())
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
