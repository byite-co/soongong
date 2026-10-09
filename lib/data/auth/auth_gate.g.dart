// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthGate)
final authGateProvider = AuthGateProvider._();

final class AuthGateProvider
    extends $NotifierProvider<AuthGate, AuthGateState> {
  AuthGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authGateHash();

  @$internal
  @override
  AuthGate create() => AuthGate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthGateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthGateState>(value),
    );
  }
}

String _$authGateHash() => r'0a3a78f30f7ca4c2dc0b8cb29965c156544b5e82';

abstract class _$AuthGate extends $Notifier<AuthGateState> {
  AuthGateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthGateState, AuthGateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthGateState, AuthGateState>,
              AuthGateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
