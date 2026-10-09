// LoginController (S05 · PRD 4.3c · D6): one controller for the login
// screens. It talks to [SocialSignIn] (native tokens), [AuthRepository] and
// the [SignupFlow]; screens only navigate on the returned [LoginNext].
//
// Rules implemented here
//   · a social attempt without a ticket is a sign-in; the hook's
//     `signupPassRequired` means "new account" → gate (provider remembered)
//   · with a ticket: expired ticket → gate; `issue-pass` runs inside the
//     repository; hook rejection with a ticket = pass expired → gate
//   · failures keep the input and show one sentence; busy locks re-entry

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/auth/social/social_sign_in.dart';
import '../../../data/repositories/repository_providers.dart';
import 'post_login.dart';
import 'signup_flow.dart';

part 'login_controller.g.dart';

enum LoginNext {
  none,
  gate,
  password,
  signup,
  consent,
  onboarding,
  home,

  /// Signed in but the profile could not be read yet → `/` resolves it.
  launch,
}

class LoginState {
  const LoginState({this.busy = false, this.busyLabel, this.error, this.resetSent = false});

  final bool busy;
  final String? busyLabel;
  final String? error;
  final bool resetSent;
}

final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String email) => _emailRe.hasMatch(email.trim());

@Riverpod(keepAlive: true)
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState();

  void clearError() => state = LoginState(resetSent: state.resetSent);

  // ---------------------------------------------------------------------
  // Social

  Future<LoginNext> signInWithSocial(SignupProvider provider) async {
    if (state.busy) return LoginNext.none;
    final social = ref.read(socialSignInProvider);
    if (!social.isAvailable(provider)) {
      state = const LoginState(error: AuthStrings.loginProviderUnavailable);
      return LoginNext.none;
    }
    final ticket = _ticketOrNull();
    if (ticket == _expired) return LoginNext.gate;

    state = LoginState(busy: true, busyLabel: AuthStrings.loginChecking(providerLabel(provider)));
    final token = await social.acquire(provider);
    switch (token) {
      case SocialTokenCancelled():
        state = const LoginState();
        return LoginNext.none;
      case SocialTokenUnavailable():
        state = const LoginState(error: AuthStrings.loginProviderUnavailable);
        return LoginNext.none;
      case SocialTokenFailed(:final network):
        state = LoginState(
          error: network ? AuthStrings.rejectNetwork : AuthStrings.loginProviderFailed,
        );
        return LoginNext.none;
      case SocialTokenAcquired():
        ref.read(authGateProvider.notifier).beginLogin();
        final outcome = await ref.read(authRepositoryProvider).signInWithProvider(
              provider: provider,
              idToken: token.idToken,
              accessToken: token.accessToken,
              nonce: token.rawNonce,
              ticket: ticket,
            );
        return _handle(outcome, provider: provider, hadTicket: ticket != null);
    }
  }

  // ---------------------------------------------------------------------
  // Email

  /// `lgEmail`: existing → password · new → gate (or signup when a ticket
  /// is already valid).
  Future<LoginNext> submitEmail(String email) async {
    if (state.busy) return LoginNext.none;
    final trimmed = email.trim();
    if (!isValidEmail(trimmed)) {
      state = const LoginState(error: AuthStrings.emailInvalid);
      return LoginNext.none;
    }
    state = const LoginState(busy: true);
    try {
      final exists = await ref.read(authRepositoryProvider).checkEmailExists(trimmed);
      ref.read(signupFlowProvider.notifier).setPendingEmail(trimmed);
      state = const LoginState();
      if (exists) return LoginNext.password;
      final now = ref.read(appClockProvider).now();
      return ref.read(signupFlowProvider).hasValidTicket(now) ? LoginNext.signup : LoginNext.gate;
    } on Object catch (e) {
      state = LoginState(error: AuthStrings.forRejection(AuthRejectionMapper.fromError(e)));
      return LoginNext.none;
    }
  }

  /// `lgPw`: existing account.
  Future<LoginNext> signInWithPassword(String password) async {
    if (state.busy) return LoginNext.none;
    final email = ref.read(signupFlowProvider).pendingEmail;
    if (email == null) return LoginNext.none;
    if (password.isEmpty) {
      state = const LoginState(error: AuthStrings.rejectInvalidCredentials);
      return LoginNext.none;
    }
    state = const LoginState(busy: true, busyLabel: AuthStrings.loginBusy);
    ref.read(authGateProvider.notifier).beginLogin();
    final outcome = await ref.read(authRepositoryProvider).signInWithEmail(email: email, password: password);
    return _handle(outcome, hadTicket: false);
  }

  /// `lgSignup`: new account with a valid ticket.
  Future<LoginNext> signUpWithPassword(String password) async {
    if (state.busy) return LoginNext.none;
    final email = ref.read(signupFlowProvider).pendingEmail;
    if (email == null) return LoginNext.none;
    if (password.length < 8) {
      state = const LoginState(error: AuthStrings.rejectWeakPassword);
      return LoginNext.none;
    }
    final ticket = _ticketOrNull();
    if (ticket == null) {
      // No ticket at all on the signup screen (deep link / restart) → gate.
      ref.read(signupFlowProvider.notifier).setNotice(AuthStrings.rejectTicketInvalid);
      return LoginNext.gate;
    }
    if (ticket == _expired) return LoginNext.gate;
    state = const LoginState(busy: true, busyLabel: AuthStrings.loginBusy);
    ref.read(authGateProvider.notifier).beginLogin();
    final outcome = await ref
        .read(authRepositoryProvider)
        .signUpWithEmail(ticket: ticket, email: email, password: password);
    return _handle(outcome, hadTicket: true);
  }

  /// `lgReset`: reset mail for the pending e-mail. true = sent.
  Future<bool> sendPasswordReset() async {
    if (state.busy) return false;
    final email = ref.read(signupFlowProvider).pendingEmail;
    if (email == null) return false;
    state = const LoginState(busy: true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      state = const LoginState(resetSent: true);
      return true;
    } on Object catch (e) {
      final reason = AuthRejectionMapper.fromError(e);
      state = LoginState(
        error: reason == AuthRejection.unknown
            ? AuthStrings.resetSendFailed
            : AuthStrings.forRejection(reason),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------

  static const String _expired = '\u0000expired';

  /// Ticket to use: null (no ticket → existing-account attempt), the ticket,
  /// or [_expired] after sending the user back to the gate.
  String? _ticketOrNull() {
    final flow = ref.read(signupFlowProvider);
    if (!flow.hasTicket) return null;
    final now = ref.read(appClockProvider).now();
    final ticket = flow.validTicket(now);
    if (ticket != null) return ticket;
    ref.read(signupFlowProvider.notifier)
      ..clearTicket()
      ..setNotice(AuthStrings.rejectTicketInvalid);
    state = const LoginState();
    return _expired;
  }

  Future<LoginNext> _handle(
    SignInOutcome outcome, {
    SignupProvider? provider,
    required bool hadTicket,
  }) async {
    final flow = ref.read(signupFlowProvider.notifier);
    switch (outcome) {
      case SignedIn():
        flow.reset();
        await ref.read(authGateProvider.notifier).applySignIn(outcome);
        state = const LoginState();
        if (!outcome.profileLoaded) return LoginNext.launch;
        final profile = outcome.profile;
        if (profile == null) return LoginNext.consent;
        if (!profile.onboardingDone) return LoginNext.onboarding;
        await ref.read(postLoginRoutineProvider).run();
        return LoginNext.home;
      case SignInRejected(:final reason):
        ref.read(authGateProvider.notifier).endLogin();
        state = const LoginState();
        switch (reason) {
          case AuthRejection.signupPassRequired:
            if (hadTicket) {
              flow
                ..clearTicket()
                ..setNotice(AuthStrings.ageGateExpiredRetry);
            } else {
              flow
                ..setPendingProvider(provider)
                ..setNotice(AuthStrings.rejectSignupPassRequired);
            }
            return LoginNext.gate;
          case AuthRejection.ticketInvalid:
            flow
              ..clearTicket()
              ..setNotice(AuthStrings.rejectTicketInvalid);
            return LoginNext.gate;
          case AuthRejection.notApproved:
            flow
              ..reset()
              ..setNotice(AuthStrings.rejectNotApproved);
            return LoginNext.gate;
          case AuthRejection.emailTaken:
            // The e-mail exists after all → password screen, input kept.
            state = const LoginState(error: AuthStrings.rejectEmailTaken);
            return LoginNext.password;
          default:
            state = LoginState(error: AuthStrings.forRejection(reason));
            return LoginNext.none;
        }
    }
  }
}

String providerLabel(SignupProvider p) => switch (p) {
      SignupProvider.apple => AuthStrings.providerApple,
      SignupProvider.google => AuthStrings.providerGoogle,
      SignupProvider.kakao => AuthStrings.providerKakao,
      SignupProvider.email => AuthStrings.emailLabel,
    };
