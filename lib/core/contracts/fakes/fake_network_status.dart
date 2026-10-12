// Fake NetworkStatus (S09b): scripted by tests.

import 'dart:async';

import '../network_status.dart';

class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus([this._online = true]);

  bool _online;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  bool get current => _online;

  set current(bool v) {
    _online = v;
    _changes.add(v);
  }

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get online async* {
    yield _online;
    yield* _changes.stream;
  }
}
