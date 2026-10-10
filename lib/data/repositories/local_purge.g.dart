// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_purge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive: watched by the keepAlive `privacyActionsProvider`.

@ProviderFor(localPurge)
final localPurgeProvider = LocalPurgeProvider._();

/// keepAlive: watched by the keepAlive `privacyActionsProvider`.

final class LocalPurgeProvider
    extends $FunctionalProvider<LocalPurge, LocalPurge, LocalPurge>
    with $Provider<LocalPurge> {
  /// keepAlive: watched by the keepAlive `privacyActionsProvider`.
  LocalPurgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localPurgeProvider',
        isAutoDispose: false,
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

String _$localPurgeHash() => r'667db3a29d6ad2d58e6ed75dc93ddd0bfe1396d2';
