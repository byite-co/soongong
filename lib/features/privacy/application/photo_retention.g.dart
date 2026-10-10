// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_retention.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rebuilt on account switch (the repository changes); keepAlive so the
/// lifecycle hook and the screens can use it across async gaps.

@ProviderFor(photoRetention)
final photoRetentionProvider = PhotoRetentionProvider._();

/// Rebuilt on account switch (the repository changes); keepAlive so the
/// lifecycle hook and the screens can use it across async gaps.

final class PhotoRetentionProvider
    extends $FunctionalProvider<PhotoRetention, PhotoRetention, PhotoRetention>
    with $Provider<PhotoRetention> {
  /// Rebuilt on account switch (the repository changes); keepAlive so the
  /// lifecycle hook and the screens can use it across async gaps.
  PhotoRetentionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoRetentionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoRetentionHash();

  @$internal
  @override
  $ProviderElement<PhotoRetention> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoRetention create(Ref ref) {
    return photoRetention(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoRetention value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoRetention>(value),
    );
  }
}

String _$photoRetentionHash() => r'aab5413119de4a75e4ebd74ce2aeca3ba0be8be9';
