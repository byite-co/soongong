// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_purge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localPurge)
final localPurgeProvider = LocalPurgeProvider._();

final class LocalPurgeProvider
    extends $FunctionalProvider<LocalPurge, LocalPurge, LocalPurge>
    with $Provider<LocalPurge> {
  LocalPurgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localPurgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localPurgeHash();

  @$internal
  @override
  $ProviderElement<LocalPurge> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalPurge create(Ref ref) {
    return localPurge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalPurge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalPurge>(value),
    );
  }
}

String _$localPurgeHash() => r'76066fb51ba80b0f3b74a3f628f123d262b9e5f2';
