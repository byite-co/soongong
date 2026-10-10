// ConnectivityNetworkStatus (S09b): `connectivity_plus` → NetworkStatus.
// Online = at least one transport that is not `none`.

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/contracts/network_status.dart';

class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus([Connectivity? connectivity]) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async => _isOnline(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get online async* {
    yield await isOnline();
    yield* _connectivity.onConnectivityChanged.map(_isOnline);
  }
}
