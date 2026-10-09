// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_permission.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cameraPermission)
final cameraPermissionProvider = CameraPermissionProvider._();

final class CameraPermissionProvider
    extends
        $FunctionalProvider<
          CameraPermission,
          CameraPermission,
          CameraPermission
        >
    with $Provider<CameraPermission> {
  CameraPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraPermissionHash();

  @$internal
  @override
  $ProviderElement<CameraPermission> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CameraPermission create(Ref ref) {
    return cameraPermission(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraPermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraPermission>(value),
    );
  }
}

String _$cameraPermissionHash() => r'8c1b15261c5e63d0927342795152f23e03106170';
