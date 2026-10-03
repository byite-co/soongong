// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// deviceId (uuid v4) — overridden with the real value in bootstrap.dart.

@ProviderFor(deviceId)
final deviceIdProvider = DeviceIdProvider._();

/// deviceId (uuid v4) — overridden with the real value in bootstrap.dart.

final class DeviceIdProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// deviceId (uuid v4) — overridden with the real value in bootstrap.dart.
  DeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return deviceId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$deviceIdHash() => r'dbef293a9997eaa6ddc9c82fe516f1fcaa231039';

@ProviderFor(seatEngine)
final seatEngineProvider = SeatEngineProvider._();

final class SeatEngineProvider
    extends $FunctionalProvider<SeatEngine, SeatEngine, SeatEngine>
    with $Provider<SeatEngine> {
  SeatEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seatEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seatEngineHash();

  @$internal
  @override
  $ProviderElement<SeatEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SeatEngine create(Ref ref) {
    return seatEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeatEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeatEngine>(value),
    );
  }
}

String _$seatEngineHash() => r'3a1b52a92e8fbeab6d1671eccc1850fac0ffac91';

@ProviderFor(readingEngine)
final readingEngineProvider = ReadingEngineProvider._();

final class ReadingEngineProvider
    extends $FunctionalProvider<ReadingEngine, ReadingEngine, ReadingEngine>
    with $Provider<ReadingEngine> {
  ReadingEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingEngineHash();

  @$internal
  @override
  $ProviderElement<ReadingEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReadingEngine create(Ref ref) {
    return readingEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingEngine>(value),
    );
  }
}

String _$readingEngineHash() => r'83f9ae9ecbd8c59ef8345f1a3b887ee76caaa7b9';

@ProviderFor(billingGateway)
final billingGatewayProvider = BillingGatewayProvider._();

final class BillingGatewayProvider
    extends $FunctionalProvider<BillingGateway, BillingGateway, BillingGateway>
    with $Provider<BillingGateway> {
  BillingGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingGatewayHash();

  @$internal
  @override
  $ProviderElement<BillingGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BillingGateway create(Ref ref) {
    return billingGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingGateway>(value),
    );
  }
}

String _$billingGatewayHash() => r'c0af888c38a4123d8321f76584cf494e5dc88bf0';

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

final class SyncEngineProvider
    extends $FunctionalProvider<SyncEngine, SyncEngine, SyncEngine>
    with $Provider<SyncEngine> {
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEngine create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine>(value),
    );
  }
}

String _$syncEngineHash() => r'957a9638da6001921491c73228bce8c5c8be6050';
