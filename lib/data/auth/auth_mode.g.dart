// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authMode)
final authModeProvider = AuthModeProvider._();

final class AuthModeProvider
    extends $FunctionalProvider<AuthMode, AuthMode, AuthMode>
    with $Provider<AuthMode> {
  AuthModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authModeHash();

  @$internal
  @override
  $ProviderElement<AuthMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthMode create(Ref ref) {
    return authMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthMode>(value),
    );
  }
}

String _$authModeHash() => r'd1861a8273fb1cc5958afa499ebcee68493dad19';
