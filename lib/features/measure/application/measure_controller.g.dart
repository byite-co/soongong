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

@ProviderFor(sleepAwareClock)
final sleepAwareClockProvider = SleepAwareClockProvider._();

final class SleepAwareClockProvider
    extends
        $FunctionalProvider<SleepAwareClock, SleepAwareClock, SleepAwareClock>
    with $Provider<SleepAwareClock> {
  SleepAwareClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sleepAwareClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sleepAwareClockHash();

  @$internal
  @override
  $ProviderElement<SleepAwareClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SleepAwareClock create(Ref ref) {
    return sleepAwareClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SleepAwareClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SleepAwareClock>(value),
    );
  }
}

String _$sleepAwareClockHash() => r'd6878c472126ea395e8a5c37c6a1880ef875d32f';

/// Riverpod owns the lifetime; screens observe changes with ListenableBuilder.
/// Raw explicitly keeps the ChangeNotifier from being treated as provider state.

@ProviderFor(measureController)
final measureControllerProvider = MeasureControllerProvider._();

/// Riverpod owns the lifetime; screens observe changes with ListenableBuilder.
/// Raw explicitly keeps the ChangeNotifier from being treated as provider state.

final class MeasureControllerProvider
    extends
        $FunctionalProvider<
          Raw<MeasureController>,
          Raw<MeasureController>,
          Raw<MeasureController>
        >
    with $Provider<Raw<MeasureController>> {
  /// Riverpod owns the lifetime; screens observe changes with ListenableBuilder.
  /// Raw explicitly keeps the ChangeNotifier from being treated as provider state.
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
  $ProviderElement<Raw<MeasureController>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<MeasureController> create(Ref ref) {
    return measureController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<MeasureController> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<MeasureController>>(value),
    );
  }
}

String _$measureControllerHash() => r'626ccc7d663ca0771a49966a01d51febd89db59c';
