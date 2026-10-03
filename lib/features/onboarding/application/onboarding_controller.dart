// OnboardingController (S05 · PRD 4.4 · D6 ②): consent ② → `update-consent`
// (skip = reading stays off, no call), camera permission (denial never
// blocks), finish → `profile_set_onboarding_done()` RPC (D24). A failed RPC
// keeps the user on step 3 with a retry; nothing is written locally.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/strings/onboarding_strings.dart';
import '../../../data/auth/auth_gate.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import 'camera_permission.dart';

part 'onboarding_controller.g.dart';

class OnboardingState {
  const OnboardingState({
    this.consentChecked = false,
    this.busy = false,
    this.error,
    this.cameraResult,
  });

  final bool consentChecked;
  final bool busy;
  final String? error;
  final CameraPermissionResult? cameraResult;

  OnboardingState copyWith({
    bool? consentChecked,
    bool? busy,
    String? error,
    bool clearError = false,
    CameraPermissionResult? cameraResult,
  }) =>
      OnboardingState(
        consentChecked: consentChecked ?? this.consentChecked,
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
        cameraResult: cameraResult ?? this.cameraResult,
      );
}

@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() => const OnboardingState();

  void setConsentChecked(bool v) => state = state.copyWith(consentChecked: v, clearError: true);

  void clearError() => state = state.copyWith(clearError: true);

  /// Step 2 "동의하고 다음". true = recorded (go to step 3).
  Future<bool> grantReadingConsent() async {
    if (state.busy || !state.consentChecked) return false;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final profile = await ref.read(authRepositoryProvider).updateReadingConsent(granted: true);
      ref.read(authGateProvider.notifier).applyProfile(profile);
      state = state.copyWith(busy: false);
      return true;
    } on Object catch (e) {
      final reason = AuthRejectionMapper.fromError(e);
      appLog.w('onboarding: update-consent failed (${reason.name})');
      state = state.copyWith(busy: false, error: OnboardingStrings.consentSaveFailed);
      return false;
    }
  }

  /// Step 3. [requestCamera] false = "수동 타이머로 시작". true = onboarding
  /// done (go home); false = RPC failed, stay on step 3.
  Future<bool> finish({required bool requestCamera}) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, clearError: true);
    if (requestCamera && state.cameraResult == null) {
      final result = await ref.read(cameraPermissionProvider).request();
      state = state.copyWith(cameraResult: result);
      appLog.i('onboarding: camera permission ${result.name}');
    }
    try {
      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.setOnboardingDone() ?? await repo.fetchProfile();
      if (profile != null) ref.read(authGateProvider.notifier).applyProfile(profile);
      state = state.copyWith(busy: false);
      return true;
    } on Object catch (e) {
      final reason = AuthRejectionMapper.fromError(e);
      appLog.w('onboarding: set_onboarding_done failed (${reason.name})');
      state = state.copyWith(busy: false, error: OnboardingStrings.finishFailed);
      return false;
    }
  }
}
