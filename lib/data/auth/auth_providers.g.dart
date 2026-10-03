// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authBackend)
final authBackendProvider = AuthBackendProvider._();

final class AuthBackendProvider
    extends $FunctionalProvider<AuthBackend, AuthBackend, AuthBackend>
    with $Provider<AuthBackend> {
  AuthBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authBackendHash();

  @$internal
  @override
  $ProviderElement<AuthBackend> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthBackend create(Ref ref) {
    return authBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthBackend>(value),
    );
  }
}

String _$authBackendHash() => r'd104b974b79ec3e20832f2bee8001830a81065a9';

@ProviderFor(ageGateRepository)
final ageGateRepositoryProvider = AgeGateRepositoryProvider._();

final class AgeGateRepositoryProvider
    extends
        $FunctionalProvider<
          AgeGateRepository,
          AgeGateRepository,
          AgeGateRepository
        >
    with $Provider<AgeGateRepository> {
  AgeGateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ageGateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ageGateRepositoryHash();

  @$internal
  @override
  $ProviderElement<AgeGateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AgeGateRepository create(Ref ref) {
    return ageGateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgeGateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgeGateRepository>(value),
    );
  }
}

String _$ageGateRepositoryHash() => r'3a116afb162b77d8c1cd2cce114e9b52b4660086';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'a3359559ee4dc5d0ec002de71f9de05cb6124a1c';

/// Native provider tokens (S05). Tests override with [FakeSocialSignIn].

@ProviderFor(socialSignIn)
final socialSignInProvider = SocialSignInProvider._();

/// Native provider tokens (S05). Tests override with [FakeSocialSignIn].

final class SocialSignInProvider
    extends $FunctionalProvider<SocialSignIn, SocialSignIn, SocialSignIn>
    with $Provider<SocialSignIn> {
  /// Native provider tokens (S05). Tests override with [FakeSocialSignIn].
  SocialSignInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialSignInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialSignInHash();

  @$internal
  @override
  $ProviderElement<SocialSignIn> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SocialSignIn create(Ref ref) {
    return socialSignIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialSignIn value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialSignIn>(value),
    );
  }
}

String _$socialSignInHash() => r'0c8ce90c11452eb07054d3c9176fb10dcd70aaec';
