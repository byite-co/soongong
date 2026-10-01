// SubscriptionRepository (S02). `subscription_state` — a read-only cache of
// the server ledger (D18 · D24). Two inputs only: the RevenueCat SDK
// entitlement (S12) and the pull `ledger`. There is NO user write path and
// nothing here ever reaches the outbox. `grace_expires_at` comes from the
// ledger alone (the SDK has no such field).

import 'package:drift/drift.dart';

import '../../core/contracts/billing_gateway.dart';
import '../../core/domain/entities/entities.dart';
import '../../core/domain/enums.dart';
import '../db/app_database.dart';
import 'write_context.dart';

class SubscriptionRepository {
  SubscriptionRepository(this.db, this.ctx);

  final AppDatabase db;
  final WriteContext ctx;

  $SubscriptionStatesTable get _t => db.subscriptionStates;

  Stream<SubscriptionState?> watch() =>
      (db.select(_t)..where((t) => t.userId.equals(ctx.userId)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _of(r));

  Future<SubscriptionState?> get() async {
    final r = await (db.select(_t)..where((t) => t.userId.equals(ctx.userId)))
        .getSingleOrNull();
    return r == null ? null : _of(r);
  }

  /// SDK entitlement (S12). Keeps the ledger's `grace_expires_at`.
  Future<void> applySdk(Entitlement e, {DateTime? at}) async {
    final now = (at ?? ctx.nowUtc()).toUtc();
    final existing = await get();
    await db.into(_t).insertOnConflictUpdate(
          SubscriptionStatesCompanion.insert(
            userId: ctx.userId,
            status: e.status.name,
            entitled: e.entitled,
            expiresAt: Value(e.expiresAt?.toUtc()),
            graceExpiresAt: Value(existing?.graceExpiresAt),
            periodType: Value(existing?.periodType),
            willRenew: existing?.willRenew ?? false,
            trialUsed: e.trialUsed,
            source: SubscriptionSource.sdk,
            lastCheckedAt: now,
          ),
        );
  }

  /// Pull `ledger.subscription_state` (S13). Keys per data-model.md §2.13.
  Future<void> applyLedger(Map<String, Object?> json, {DateTime? at}) async {
    final now = (at ?? ctx.nowUtc()).toUtc();
    final status = EntitlementStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => EntitlementStatus.free,
    );
    await db.into(_t).insertOnConflictUpdate(
          SubscriptionStatesCompanion.insert(
            userId: ctx.userId,
            status: status.name,
            entitled: _bool(json['entitled']),
            expiresAt: Value(_date(json['expires_at'])),
            graceExpiresAt: Value(_date(json['grace_expires_at'])),
            periodType: Value(json['period_type'] as String?),
            willRenew: _bool(json['will_renew']),
            trialUsed: _bool(json['trial_used']),
            source: SubscriptionSource.ledger,
            lastCheckedAt: now,
          ),
        );
  }

  SubscriptionState _of(SubscriptionStateRow r) => SubscriptionState(
        userId: r.userId,
        status: EntitlementStatus.values.firstWhere(
          (s) => s.name == r.status,
          orElse: () => EntitlementStatus.free,
        ),
        entitled: r.entitled,
        expiresAt: r.expiresAt,
        graceExpiresAt: r.graceExpiresAt,
        periodType: r.periodType,
        willRenew: r.willRenew,
        trialUsed: r.trialUsed,
        source: r.source,
        lastCheckedAt: r.lastCheckedAt,
      );

  static bool _bool(Object? v) => v == true || v == 1;

  static DateTime? _date(Object? v) =>
      v is String && v.isNotEmpty ? DateTime.parse(v).toUtc() : null;
}
