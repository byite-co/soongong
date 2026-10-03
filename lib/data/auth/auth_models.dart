// Auth / age-gate models (S03). Pure Dart — no Supabase types here so the
// repositories can be unit-tested against a fake backend.
//
// Signup order (D6, docs/supabase-auth.md): birth date → `age-check` ticket →
// provider token → `issue-pass` → sign in (`signInWithIdToken` / `signUp`) →
// `complete-signup`. The birth date exists only as a method argument; it is
// never stored, logged or sent anywhere but `age-check`.

/// Consent versions sent to `complete-signup` (①) and `update-consent` (②).
/// Bump when the consent text changes (S05 / S09 own the screens).
abstract final class ConsentVersions {
  static const String account = '2026-10-01';
  static const String reading = '2026-10-01';
}

/// Login providers. [wire] is the value sent to `issue-pass` and stored in
/// `signup_passes.provider` / `signup_approvals.provider`.
enum SignupProvider {
  apple('apple'),
  google('google'),
  kakao('kakao'),
  email('email');

  const SignupProvider(this.wire);

  final String wire;
}

/// Result of `AgeGateRepository.check`.
sealed class AgeGateOutcome {
  const AgeGateOutcome();
}

/// 만 14세 이상 — a short-lived ticket (10 min) for `issue-pass`.
class AgeTicketIssued extends AgeGateOutcome {
  const AgeTicketIssued({required this.ticket, required this.expiresAt});

  final String ticket;
  final DateTime expiresAt;
}

/// 만 14세 미만 (D6 v1 policy): the flow ends at `ageBlocked`, no provider call.
class AgeBlocked extends AgeGateOutcome {
  const AgeBlocked();
}

class AgeGateFailed extends AgeGateOutcome {
  const AgeGateFailed(this.reason);

  final AuthRejection reason;
}

/// Result of `AgeGateRepository.issuePass`.
sealed class PassOutcome {
  const PassOutcome();
}

class PassIssued extends PassOutcome {
  const PassIssued({required this.provider, required this.expiresAt});

  final SignupProvider provider;
  final DateTime expiresAt;
}

class PassFailed extends PassOutcome {
  const PassFailed(this.reason);

  final AuthRejection reason;
}

/// Why a sign-in / sign-up / server call did not complete. Mapped to user
/// strings in `core/strings/auth_strings.dart` (S05 error table).
enum AuthRejection {
  /// Before-user-created hook or identities trigger refused the signup: no
  /// valid pass (ticket skipped, pass expired, wrong provider/subject).
  signupPassRequired,

  /// `complete-signup` found no `signup_approvals` row for this user.
  notApproved,

  /// Age ticket missing / expired / tampered (`issue-pass` 400 ticket_invalid).
  ticketInvalid,

  /// Provider id_token failed verification (signature · iss · aud · exp · nonce).
  idTokenInvalid,

  /// Email + password did not match.
  invalidCredentials,

  /// Email already registered (sign-up path).
  emailTaken,

  /// Password shorter than 8 or otherwise refused by Auth.
  weakPassword,

  /// Too many attempts (Auth or Edge rate limit).
  rateLimited,

  /// No network / timeout.
  network,

  unknown,
}

/// Result of a sign-in / sign-up flow.
sealed class SignInOutcome {
  const SignInOutcome();
}

class SignedIn extends SignInOutcome {
  const SignedIn({required this.userId, required this.isNewUser, this.profile});

  final String userId;

  /// true when `complete-signup` created the profile in this flow.
  final bool isNewUser;

  final ProfileSnapshot? profile;
}

class SignInRejected extends SignInOutcome {
  const SignInRejected(this.reason, {this.serverMessage});

  final AuthRejection reason;

  /// Raw server message for logs/dev menu only — never shown as is.
  final String? serverMessage;
}

/// `profiles` row as returned by complete-signup / update-consent.
class ProfileSnapshot {
  const ProfileSnapshot({
    required this.userId,
    required this.onboardingDone,
    required this.purgeEpoch,
    this.consentAccountVersion,
    this.consentAccountAt,
    this.consentReadingVersion,
    this.consentReadingAt,
    this.consentReadingRevokedAt,
  });

  factory ProfileSnapshot.fromJson(Map<String, dynamic> json) => ProfileSnapshot(
        userId: json['user_id'] as String,
        onboardingDone: json['onboarding_done'] == true,
        purgeEpoch: (json['purge_epoch'] as num?)?.toInt() ?? 0,
        consentAccountVersion: json['consent_account_version'] as String?,
        consentAccountAt: _date(json['consent_account_at']),
        consentReadingVersion: json['consent_reading_version'] as String?,
        consentReadingAt: _date(json['consent_reading_at']),
        consentReadingRevokedAt: _date(json['consent_reading_revoked_at']),
      );

  final String userId;
  final bool onboardingDone;
  final int purgeEpoch;
  final String? consentAccountVersion;
  final DateTime? consentAccountAt;
  final String? consentReadingVersion;
  final DateTime? consentReadingAt;
  final DateTime? consentReadingRevokedAt;

  /// Consent ② (external reading transfer) currently valid.
  bool get readingConsentActive =>
      consentReadingAt != null && consentReadingRevokedAt == null;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toUtc() : null;
}

/// Auth session as seen by the app (S05 router guard · `currentUserIdProvider`).
class AuthSession {
  const AuthSession({required this.userId, required this.email});

  final String userId;
  final String? email;
}

/// An Edge Function answered with a non-2xx `{error, detail?}` body.
class EdgeFunctionException implements Exception {
  const EdgeFunctionException(this.status, this.code, {this.detail, this.body});

  final int status;

  /// Server error code (`not_authenticated`, `ticket_invalid`, `rate_limited`, …).
  final String code;
  final String? detail;
  final Map<String, dynamic>? body;

  @override
  String toString() => 'EdgeFunctionException($status $code${detail == null ? '' : ' $detail'})';
}

/// Auth API refused (wraps gotrue's AuthException without exposing the type).
class AuthBackendException implements Exception {
  const AuthBackendException(this.message, {this.statusCode, this.code});

  final String message;
  final String? statusCode;
  final String? code;

  @override
  String toString() => 'AuthBackendException($statusCode $code $message)';
}

class NetworkUnavailableException implements Exception {
  const NetworkUnavailableException();
}

/// Maps backend failures to [AuthRejection] (single place; tested).
abstract final class AuthRejectionMapper {
  /// Message the hook returns (0004_signup.sql) — Auth propagates it verbatim.
  static const String hookRejectMessage = '가입 확인이 필요합니다';

  static AuthRejection fromEdge(EdgeFunctionException e) => switch (e.code) {
        'ticket_invalid' => AuthRejection.ticketInvalid,
        'id_token_invalid' || 'nonce_required' || 'nonce_mismatch' => AuthRejection.idTokenInvalid,
        'not_approved' => AuthRejection.notApproved,
        'rate_limited' => AuthRejection.rateLimited,
        _ => AuthRejection.unknown,
      };

  static AuthRejection fromAuth(AuthBackendException e) {
    final msg = e.message;
    if (msg.contains(hookRejectMessage) || msg.contains('signup_pass_required')) {
      return AuthRejection.signupPassRequired;
    }
    switch (e.code) {
      case 'invalid_credentials':
        return AuthRejection.invalidCredentials;
      case 'user_already_exists':
      case 'email_exists':
        return AuthRejection.emailTaken;
      case 'weak_password':
        return AuthRejection.weakPassword;
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return AuthRejection.rateLimited;
    }
    if (e.statusCode == '429') return AuthRejection.rateLimited;
    final lower = msg.toLowerCase();
    if (lower.contains('invalid login credentials')) return AuthRejection.invalidCredentials;
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return AuthRejection.emailTaken;
    }
    if (lower.contains('password')) return AuthRejection.weakPassword;
    return AuthRejection.unknown;
  }

  static AuthRejection fromError(Object e) => switch (e) {
        EdgeFunctionException() => fromEdge(e),
        AuthBackendException() => fromAuth(e),
        NetworkUnavailableException() => AuthRejection.network,
        _ => AuthRejection.unknown,
      };
}

/// `yyyy-MM-dd` of a local calendar date (what `age-check` expects).
String birthDateKey(DateTime birthDate) {
  final y = birthDate.year.toString().padLeft(4, '0');
  final m = birthDate.month.toString().padLeft(2, '0');
  final d = birthDate.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
