// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev_seeder.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(devSeeder)
final devSeederProvider = DevSeederProvider._();

final class DevSeederProvider
    extends $FunctionalProvider<DevSeeder, DevSeeder, DevSeeder>
    with $Provider<DevSeeder> {
  DevSeederProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devSeederProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devSeederHash();

  @$internal
  @override
  $ProviderElement<DevSeeder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DevSeeder create(Ref ref) {
    return devSeeder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DevSeeder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DevSeeder>(value),
    );
  }
}

String _$devSeederHash() => r'8ceae49ced18acfe3983a092322588209a8e37c6';
