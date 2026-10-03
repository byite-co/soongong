// SignupFlow (S05): in-memory state carried across the gate → provider →
// consent screens. Holds the age ticket (10 min), the pending e-mail of the
// email path, the provider whose hook rejection sent the user to the gate,
// and one factual sentence to show on arrival. Never persisted.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/auth/auth_models.dart';

part 'signup_flow.g.dart';

class SignupFlowState {
  const SignupFlowState({
    this.ticket,
    this.ticketExpiresAt,
    this.pendingEmail,
    this.pendingProvider,
    this.notice,
  });

  final String? ticket;
  final DateTime? ticketExpiresAt;
  final String? pendingEmail;
  final SignupProvider? pendingProvider;

  /// One sentence shown at the top of the gate / login screen.
  final String? notice;

  bool get hasTicket => ticket != null;

  bool hasValidTicket(DateTime now) =>
      ticket != null && ticketExpiresAt != null && now.toUtc().isBefore(ticketExpiresAt!.toUtc());

  /// The ticket if still valid, else null.
  String? validTicket(DateTime now) => hasValidTicket(now) ? ticket : null;

  SignupFlowState copyWith({
    String? ticket,
    DateTime? ticketExpiresAt,
    String? pendingEmail,
    SignupProvider? pendingProvider,
    String? notice,
    bool clearTicket = false,
    bool clearPendingEmail = false,
    bool clearPendingProvider = false,
    bool clearNotice = false,
  }) =>
      SignupFlowState(
        ticket: clearTicket ? null : (ticket ?? this.ticket),
        ticketExpiresAt: clearTicket ? null : (ticketExpiresAt ?? this.ticketExpiresAt),
        pendingEmail: clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
        pendingProvider: clearPendingProvider ? null : (pendingProvider ?? this.pendingProvider),
        notice: clearNotice ? null : (notice ?? this.notice),
      );
}

@Riverpod(keepAlive: true)
class SignupFlow extends _$SignupFlow {
  @override
  SignupFlowState build() => const SignupFlowState();

  void ticketIssued(String ticket, DateTime expiresAt) =>
      state = state.copyWith(ticket: ticket, ticketExpiresAt: expiresAt);

  void clearTicket() => state = state.copyWith(clearTicket: true);

  void setPendingEmail(String? email) => state = email == null
      ? state.copyWith(clearPendingEmail: true)
      : state.copyWith(pendingEmail: email.trim());

  void setPendingProvider(SignupProvider? provider) => state = provider == null
      ? state.copyWith(clearPendingProvider: true)
      : state.copyWith(pendingProvider: provider);

  void setNotice(String? notice) =>
      state = notice == null ? state.copyWith(clearNotice: true) : state.copyWith(notice: notice);

  /// Everything forgotten (sign-in done, blocked, or "close").
  void reset() => state = const SignupFlowState();
}
