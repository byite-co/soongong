// Fake BillingGateway (S01). Status is forced from the dev menu.

import 'dart:async';

import '../billing_gateway.dart';

class FakeBillingGateway implements BillingGateway {
  FakeBillingGateway({
    Entitlement initial = const Entitlement.free(),
    this.delay = const Duration(milliseconds: 400),
    DateTime Function()? now,
  })  : _current = initial,
        _now = now ?? DateTime.now;

  Duration delay;

  final DateTime Function() _now;
  final StreamController<Entitlement> _controller =
      StreamController<Entitlement>.broadcast();
  Entitlement _current;
  String? _appUserId;

  Entitlement get current => _current;
  String? get appUserId => _appUserId;

  /// Dev menu: force a status (D18 table) and emit it.
  void force(EntitlementStatus status) {
    final now = _now();
    final entitled = switch (status) {
      EntitlementStatus.trial ||
      EntitlementStatus.premium ||
      EntitlementStatus.cancelPending ||
      EntitlementStatus.grace =>
        true,
      _ => false,
    };
    final hasHistory = status != EntitlementStatus.free;
    _emit(
      Entitlement(
        status: status,
        entitled: entitled,
        trialUsed: hasHistory,
        expiresAt: switch (status) {
          EntitlementStatus.trial => now.add(const Duration(days: 7)),
          EntitlementStatus.premium ||
          EntitlementStatus.cancelPending =>
            now.add(const Duration(days: 30)),
          EntitlementStatus.grace ||
          EntitlementStatus.expired =>
            now.subtract(const Duration(days: 1)),
          _ => null,
        },
        graceExpiresAt: status == EntitlementStatus.grace
            ? now.add(const Duration(days: 3))
            : null,
      ),
    );
  }

  void _emit(Entitlement e) {
    _current = e;
    if (!_controller.isClosed) _controller.add(e);
  }

  @override
  Future<void> configure(String appUserId) async {
    _appUserId = appUserId;
  }

  @override
  Stream<Entitlement> get entitlement {
    late StreamController<Entitlement> out;
    StreamSubscription<Entitlement>? sub;
    out = StreamController<Entitlement>(
      onListen: () {
        out.add(_current);
        sub = _controller.stream
            .listen(out.add, onError: out.addError, onDone: out.close);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  @override
  Future<PurchaseOutcome> purchaseMonthly() async {
    await Future<void>.delayed(delay);
    if (_current.status == EntitlementStatus.pendingApproval) {
      return const PurchasePending(askToBuy: true);
    }
    force(
      _current.trialUsed ? EntitlementStatus.premium : EntitlementStatus.trial,
    );
    return const PurchaseSuccess();
  }

  @override
  Future<RestoreOutcome> restore() async {
    await Future<void>.delayed(delay);
    return _current.trialUsed
        ? const RestoreRestored()
        : const RestoreNothing();
  }

  @override
  Future<void> refresh() async {
    await Future<void>.delayed(delay);
    _emit(_current);
  }

  @override
  Future<String?> managementUrl() async =>
      _current.trialUsed ? 'https://example.invalid/manage-subscription' : null;

  Future<void> dispose() => _controller.close();
}
