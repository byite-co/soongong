// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measure_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(measureDevice)
final measureDeviceProvider = MeasureDeviceProvider._();

final class MeasureDeviceProvider
    extends $FunctionalProvider<MeasureDevice, MeasureDevice, MeasureDevice>
    with $Provider<MeasureDevice> {
  MeasureDeviceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'measureDeviceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measureDeviceHash();

  @$internal
  @override
  $ProviderElement<MeasureDevice> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MeasureDevice create(Ref ref) {
    return measureDevice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeasureDevice value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeasureDevice>(value),
    );
  }
}

String _$measureDeviceHash() => r'e15c6d5038a9910952cc60fc8d5f0e8d1610206c';

@ProviderFor(measureController)
final measureControllerProvider = MeasureControllerProvider._();

final class MeasureControllerProvider
    extends
        $FunctionalProvider<
          MeasureController,
          MeasureController,
          MeasureController
        >
    with $Provider<MeasureController> {
  MeasureControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'measureControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$measureControllerHash();

  @$internal
  @override
  $ProviderElement<MeasureController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeasureController create(Ref ref) {
    return measureController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeasureController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeasureController>(value),
    );
  }
}

String _$measureControllerHash() => r'c056c9cb6521a8d58b0abdfc5c9dfb5597b2fa52';
