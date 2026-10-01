// WidgetsBinding-backed [LifecycleSource] (S04). The observer is attached
// while someone listens and removed afterwards.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'seat_frame_source.dart';

class WidgetsBindingLifecycleSource implements LifecycleSource {
  WidgetsBindingLifecycleSource() {
    _controller = StreamController<AppLifecycleState>.broadcast(
      onListen: _attach,
      onCancel: _detach,
    );
  }

  late final StreamController<AppLifecycleState> _controller;
  _LifecycleObserver? _observer;

  @override
  Stream<AppLifecycleState> get states => _controller.stream;

  void _attach() {
    if (_observer != null) return;
    final o = _LifecycleObserver(_controller.add);
    WidgetsBinding.instance.addObserver(o);
    _observer = o;
  }

  void _detach() {
    final o = _observer;
    if (o == null) return;
    WidgetsBinding.instance.removeObserver(o);
    _observer = null;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this.onState);

  final void Function(AppLifecycleState state) onState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onState(state);
}
