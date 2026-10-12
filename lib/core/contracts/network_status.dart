// NetworkStatus (S09b): whether the device has a network path at all — the
// 문의 form disables sending while offline (원본 S09 §4.6-13) and keeps the
// draft. A connected network is not a reachable server: callers still
// handle request failures. Implementation: `ConnectivityNetworkStatus`
// (connectivity_plus); tests: `FakeNetworkStatus`.

abstract class NetworkStatus {
  Future<bool> isOnline();

  /// Emits the current state on listen, then every change.
  Stream<bool> get online;
}
