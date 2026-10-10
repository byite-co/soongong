// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(photoStore)
final photoStoreProvider = PhotoStoreProvider._();

final class PhotoStoreProvider
    extends $FunctionalProvider<PhotoStore, PhotoStore, PhotoStore>
    with $Provider<PhotoStore> {
  PhotoStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoStoreHash();

  @$internal
  @override
  $ProviderElement<PhotoStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoStore create(Ref ref) {
    return photoStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoStore>(value),
    );
  }
}

String _$photoStoreHash() => r'10aba8401c58f1ba808e7128bcd1f65b9ff3670d';
