// AgeGateRepository (S03 · D6 steps 1–2). The birth date is a method argument
// only: formatted, sent to `age-check`, and dropped. Nothing here logs it.

import '../../core/logging/app_logger.dart';
import 'auth_backend.dart';
import 'auth_models.dart';

class AgeGateRepository {
  AgeGateRepository(this._backend);

  final AuthBackend _backend;

  /// `ageGate` → `age-check`. Returns a 10-minute ticket or [AgeBlocked].
  Future<AgeGateOutcome> check(DateTime birthDate) async {
    try {
      final res = await _backend.invoke(
        'age-check',
        body: <String, dynamic>{'birth_date': birthDateKey(birthDate)},
        withUser: false,
      );
      if (res['allowed'] == true && res['ticket'] is String) {
        final seconds = (res['expires_in'] as num?)?.toInt() ?? 600;
        appLog.i('age-check: allowed');
        return AgeTicketIssued(
          ticket: res['ticket'] as String,
          expiresAt: DateTime.now().toUtc().add(Duration(seconds: seconds)),
        );
      }
      appLog.i('age-check: blocked');
      return const AgeBlocked();
    } on Object catch (e) {
      final reason = AuthRejectionMapper.fromError(e);
      appLog.w('age-check: failed (${reason.name})');
      return AgeGateFailed(reason);
    }
  }

  /// `issue-pass`: ticket + provider token (or email) → signup pass (10 min).
  Future<PassOutcome> issuePass({
    required String ticket,
    required SignupProvider provider,
    String? idToken,
    String? email,
    String? nonce,
  }) async {
    assert(provider == SignupProvider.email ? email != null : idToken != null);
    try {
      final res = await _backend.invoke(
        'issue-pass',
        body: <String, dynamic>{
          'ticket': ticket,
          'provider': provider.wire,
          if (provider == SignupProvider.email) 'email': email,
          if (provider != SignupProvider.email) 'id_token': idToken,
          'nonce': ?nonce,
        },
        withUser: false,
      );
      final expires = DateTime.tryParse((res['expires_at'] as String?) ?? '')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(minutes: 10));
      appLog.i('issue-pass: issued (${provider.wire})');
      return PassIssued(provider: provider, expiresAt: expires);
    } on Object catch (e) {
      final reason = AuthRejectionMapper.fromError(e);
      appLog.w('issue-pass: failed (${reason.name})');
      return PassFailed(reason);
    }
  }
}
