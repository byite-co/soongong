import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/contracts.dart';
import 'package:soongong/core/contracts/fakes/fakes.dart';

void main() {
  test('force() follows the D18 entitled column', () {
    final g = FakeBillingGateway(delay: Duration.zero);
    const entitled = <EntitlementStatus, bool>{
      EntitlementStatus.free: false,
      EntitlementStatus.trial: true,
      EntitlementStatus.premium: true,
      EntitlementStatus.cancelPending: true,
      EntitlementStatus.grace: true,
      EntitlementStatus.expired: false,
      EntitlementStatus.pendingApproval: false,
    };
    for (final entry in entitled.entries) {
      g.force(entry.key);
      expect(g.current.status, entry.key);
      expect(g.current.entitled, entry.value, reason: entry.key.name);
    }
    g.force(EntitlementStatus.grace);
    expect(g.current.graceExpiresAt, isNotNull);
    g.force(EntitlementStatus.premium);
    expect(g.current.graceExpiresAt, isNull);
  });

  test('purchase: trial first, premium once the trial was used', () async {
    final g = FakeBillingGateway(delay: Duration.zero);
    final seen = <EntitlementStatus>[];
    final sub = g.entitlement.listen((e) => seen.add(e.status));
    await g.configure('user-1');
    expect(g.appUserId, 'user-1');
    expect(await g.restore(), isA<RestoreNothing>());
    expect(await g.managementUrl(), isNull);

    expect(await g.purchaseMonthly(), isA<PurchaseSuccess>());
    expect(g.current.status, EntitlementStatus.trial);
    g.force(EntitlementStatus.expired);
    expect(await g.purchaseMonthly(), isA<PurchaseSuccess>());
    expect(g.current.status, EntitlementStatus.premium);
    expect(await g.restore(), isA<RestoreRestored>());
    expect(await g.managementUrl(), isNotNull);

    g.force(EntitlementStatus.pendingApproval);
    expect(await g.purchaseMonthly(), isA<PurchasePending>());

    await Future<void>.delayed(Duration.zero);
    expect(seen.first, EntitlementStatus.free);
    expect(seen, contains(EntitlementStatus.trial));
    await sub.cancel();
    await g.dispose();
  });
}
