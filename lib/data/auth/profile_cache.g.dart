// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileCache)
final profileCacheProvider = ProfileCacheProvider._();

final class ProfileCacheProvider
    extends $FunctionalProvider<ProfileCache, ProfileCache, ProfileCache>
    with $Provider<ProfileCache> {
  ProfileCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileCacheHash();

  @$internal
  @override
  $ProviderElement<ProfileCache> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileCache create(Ref ref) {
    return profileCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileCache>(value),
    );
  }
}

String _$profileCacheHash() => r'ab0eebd15a03b51f0a9056308c510c7be6e1c917';
