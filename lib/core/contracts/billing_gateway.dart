// BillingGateway contract (S01). Signatures are frozen — changes require the
// CONTRACT-CHANGE procedure (CLAUDE.md §8). Entitlement rules: D18.

enum EntitlementStatus {
  free,
  trial,
  premium,
  cancelPending,
  grace,
  expired,
  pendingApproval,
}

class Entitlement {
  const Entitlement({
    required this.status,
    required this.entitled,
    required this.trialUsed,
    this.expiresAt,
    this.graceExpiresAt,
  });

  const Entitlement.free()
      : status = EntitlementStatus.free,
        entitled = false,
        trialUsed = false,
        expiresAt = null,
        graceExpiresAt = null;

  /// D18 decision table. The app derives this from the SDK's `isActive`,
  /// `expirationDate`, `periodType`, `willRenew`, `billingIssueDetectedAt`.
  final EntitlementStatus status;

  /// App: SDK `EntitlementInfo.isActive`. Server ledger:
  /// `expires_at > now || grace_expires_at > now`. Both must agree.
  final bool entitled;

  final DateTime? expiresAt;

  /// Filled ONLY from the server ledger (`subscription_state.grace_expires_at`).
  /// The SDK has no such field — reading it from the SDK is forbidden.
  final DateTime? graceExpiresAt;

  final bool trialUsed;
}

sealed class PurchaseOutcome {
  const PurchaseOutcome();
}

class PurchaseSuccess extends PurchaseOutcome {
  const PurchaseSuccess();
}

class PurchaseCancelled extends PurchaseOutcome {
  const PurchaseCancelled();
}

class PurchaseFailed extends PurchaseOutcome {
  const PurchaseFailed(this.reason);

  final String reason;
}

/// Ask-to-buy / pending approval. Never resolved by an app timer — only the
/// store state decides (CLAUDE.md §9).
class PurchasePending extends PurchaseOutcome {
  const PurchasePending({required this.askToBuy});

  final bool askToBuy;
}

sealed class RestoreOutcome {
  const RestoreOutcome();
}

class RestoreRestored extends RestoreOutcome {
  const RestoreRestored();
}

class RestoreNothing extends RestoreOutcome {
  const RestoreNothing();
}

class RestoreError extends RestoreOutcome {
  const RestoreError(this.reason);

  final String reason;
}

abstract class BillingGateway {
  Future<void> configure(String appUserId);
  Stream<Entitlement> get entitlement;
  Future<PurchaseOutcome> purchaseMonthly();
  Future<RestoreOutcome> restore();
  Future<void> refresh();
  Future<String?> managementUrl();
}
