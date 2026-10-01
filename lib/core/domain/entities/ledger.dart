import 'package:freezed_annotation/freezed_annotation.dart';

import '../../contracts/billing_gateway.dart' show EntitlementStatus;
import '../../contracts/reading_engine.dart' show QuotaSnapshot;
import '../enums.dart';

part 'ledger.freezed.dart';

/// `subscription_state` cache (§2.13). Written only from the SDK entitlement
/// stream or the pull `ledger` (D18 · D24). [graceExpiresAt] comes from the
/// ledger only — the SDK has no such field.
@freezed
abstract class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState({
    required String userId,
    required EntitlementStatus status,
    required bool entitled,
    DateTime? expiresAt,
    DateTime? graceExpiresAt,
    String? periodType,
    @Default(false) bool willRenew,
    @Default(false) bool trialUsed,
    required SubscriptionSource source,
    required DateTime lastCheckedAt,
  }) = _SubscriptionState;

  const SubscriptionState._();

  factory SubscriptionState.free({
    required String userId,
    required DateTime at,
  }) =>
      SubscriptionState(
        userId: userId,
        status: EntitlementStatus.free,
        entitled: false,
        source: SubscriptionSource.sdk,
        lastCheckedAt: at,
      );
}

/// `reading_quota` cache (§2.14, D16). Display only — the client never
/// computes a charge or a reservation.
@freezed
abstract class ReadingQuota with _$ReadingQuota {
  const factory ReadingQuota({
    required String userId,
    required String month,
    required int used,
    required int reserved,
    required int limit,
  }) = _ReadingQuota;

  const ReadingQuota._();

  int get remaining => (limit - used - reserved).clamp(0, limit);

  QuotaSnapshot toSnapshot(DateTime fetchedAt) => QuotaSnapshot(
        used: used,
        reserved: reserved,
        limit: limit,
        fetchedAt: fetchedAt,
      );
}
