// ReadingQuotaPolicy (S02, pure Dart, D16): DISPLAY ONLY. The monthly
// count lives in the server ledger; the client shows `used · reserved ·
// limit` and the remaining number derived from them. There is no charge or
// reservation logic here, and the "can submit" hint is advisory — the server
// decides at `reading-submit`.

import '../../../core/domain/entities/ledger.dart';

class QuotaView {
  const QuotaView({
    required this.month,
    required this.used,
    required this.reserved,
    required this.limit,
    required this.isKnown,
  });

  /// Nothing pulled for this month yet — show "—", not 20.
  const QuotaView.unknown(String month)
      : this(
          month: month,
          used: 0,
          reserved: 0,
          limit: ReadingQuotaPolicy.defaultLimit,
          isKnown: false,
        );

  final String month;
  final int used;
  final int reserved;
  final int limit;
  final bool isKnown;

  int get remaining => (limit - used - reserved).clamp(0, limit);

  /// Advisory only (soft gate before the server answers).
  bool get hasRemaining => isKnown && remaining > 0;
}

class ReadingQuotaPolicy {
  const ReadingQuotaPolicy();

  static const int defaultLimit = 20;

  /// `yyyy-MM` of the device's local time. The server fixes `quota_month`
  /// in KST at submit time; the two only differ around midnight for users
  /// outside KST, which the ledger corrects on the next pull.
  static String monthKey(DateTime now) {
    final l = now.isUtc ? now.toLocal() : now;
    return '${l.year}-${l.month.toString().padLeft(2, '0')}';
  }

  QuotaView view(ReadingQuota? ledger, {required String month}) {
    if (ledger == null || ledger.month != month) return QuotaView.unknown(month);
    return QuotaView(
      month: month,
      used: ledger.used,
      reserved: ledger.reserved,
      limit: ledger.limit,
      isKnown: true,
    );
  }
}
