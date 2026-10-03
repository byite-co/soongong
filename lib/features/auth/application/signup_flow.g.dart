// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignupFlow)
final signupFlowProvider = SignupFlowProvider._();

final class SignupFlowProvider
    extends $NotifierProvider<SignupFlow, SignupFlowState> {
  SignupFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signupFlowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signupFlowHash();

  @$internal
  @override
  SignupFlow create() => SignupFlow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignupFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignupFlowState>(value),
    );
  }
}

String _$signupFlowHash() => r'9301e4e57dd17918b162d50d527820c6858d2c22';

abstract class _$SignupFlow extends $Notifier<SignupFlowState> {
  SignupFlowState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SignupFlowState, SignupFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignupFlowState, SignupFlowState>,
              SignupFlowState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
