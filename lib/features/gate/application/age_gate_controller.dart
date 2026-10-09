// AgeGateController (S05 · D6 step 1): birth date → `age-check` FIRST; only a
// ticket lets the user reach a provider. The date is a method argument and
// is dropped after the call — no state, log or metric keeps it.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../data/auth/auth_mode.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../../auth/application/signup_flow.dart';

part 'age_gate_controller.g.dart';

enum GateNext {
  /// Stay (error shown, input kept).
  none,

  /// 만 14세 미만 → `/gate/blocked`, no provider call.
  blocked,

  /// Ticket issued → `/login` (provider choice).
  providers,

  /// Ticket issued and an e-mail is pending → `/login/signup`.
  signup,
}

class AgeGateState {
  const AgeGateState({this.busy = false, this.error});

  final bool busy;
  final String? error;
}

@riverpod
class AgeGateController extends _$AgeGateController {
  @override
  AgeGateState build() => const AgeGateState();

  Future<GateNext> submit(DateTime birthDate) async {
    if (state.busy) return GateNext.none;
    if (ref.read(authModeProvider) != AuthMode.backend) {
      state = const AgeGateState(error: AuthStrings.backendMissing);
      return GateNext.none;
    }
    state = const AgeGateState(busy: true);
    final outcome = await ref.read(ageGateRepositoryProvider).check(birthDate);
    final flow = ref.read(signupFlowProvider.notifier);
    switch (outcome) {
      case AgeTicketIssued(:final ticket, :final expiresAt):
        flow
          ..ticketIssued(ticket, expiresAt)
          ..setNotice(AuthStrings.ageGateVerified);
        state = const AgeGateState();
        return ref.read(signupFlowProvider).pendingEmail != null ? GateNext.signup : GateNext.providers;
      case AgeBlocked():
        flow.reset();
        state = const AgeGateState();
        return GateNext.blocked;
      case AgeGateFailed(:final reason):
        state = AgeGateState(error: AuthStrings.forRejection(reason));
        return GateNext.none;
    }
  }
}
