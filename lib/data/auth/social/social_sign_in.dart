// SocialSignIn (S05): the seam between the login screens and the native
// provider SDKs (Apple · Google · Kakao). Screens only see our own types, so
// widget tests run against [FakeSocialSignIn] and can assert "the SDK was
// never called" (age gate blocked → provider call count 0, D6).
//
// The age gate decides first; this seam is reached only with a ticket (new
// account) or for an existing-account sign-in attempt.

import '../auth_models.dart';

sealed class SocialTokenOutcome {
  const SocialTokenOutcome();
}

/// Provider token obtained. [rawNonce] is the un-hashed nonce handed to
/// Apple; Supabase verifies `sha256(rawNonce)` against the id_token.
class SocialTokenAcquired extends SocialTokenOutcome {
  const SocialTokenAcquired({required this.idToken, this.accessToken, this.rawNonce});

  final String idToken;
  final String? accessToken;
  final String? rawNonce;
}

/// The user dismissed the provider UI. Not an error; nothing to show.
class SocialTokenCancelled extends SocialTokenOutcome {
  const SocialTokenCancelled();
}

/// Provider not configured for this build/platform (missing client id, Apple
/// on Android, …). The button shows one factual sentence.
class SocialTokenUnavailable extends SocialTokenOutcome {
  const SocialTokenUnavailable(this.reason);

  final String reason;
}

/// Provider SDK failed (no network, SDK error). [message] is for logs only.
class SocialTokenFailed extends SocialTokenOutcome {
  const SocialTokenFailed(this.message, {this.network = false});

  final String message;
  final bool network;
}

abstract class SocialSignIn {
  /// Whether [provider] can be attempted in this build on this platform.
  bool isAvailable(SignupProvider provider);

  /// Runs the provider UI and returns its token. Never throws.
  Future<SocialTokenOutcome> acquire(SignupProvider provider);
}

/// Test double: scripted outcomes + call counting.
class FakeSocialSignIn implements SocialSignIn {
  FakeSocialSignIn({
    this.outcome = const SocialTokenAcquired(idToken: 'fake.id.token', rawNonce: 'fake-nonce'),
    Set<SignupProvider>? available,
  }) : available = available ?? {SignupProvider.apple, SignupProvider.google, SignupProvider.kakao};

  SocialTokenOutcome outcome;
  final Set<SignupProvider> available;
  final List<SignupProvider> calls = <SignupProvider>[];

  int get callCount => calls.length;

  @override
  bool isAvailable(SignupProvider provider) => available.contains(provider);

  @override
  Future<SocialTokenOutcome> acquire(SignupProvider provider) async {
    calls.add(provider);
    return outcome;
  }
}
