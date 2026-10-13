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

String _$authGateHash() => r'd001e20ad6d107485b9dcddc21bb1c6b92a030d2';

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
