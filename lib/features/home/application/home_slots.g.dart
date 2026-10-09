// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_slots.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(readingCardSlot)
final readingCardSlotProvider = ReadingCardSlotProvider._();

final class ReadingCardSlotProvider
    extends
        $FunctionalProvider<
          HomeCardBuilder?,
          HomeCardBuilder?,
          HomeCardBuilder?
        >
    with $Provider<HomeCardBuilder?> {
  ReadingCardSlotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingCardSlotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingCardSlotHash();

  @$internal
  @override
  $ProviderElement<HomeCardBuilder?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeCardBuilder? create(Ref ref) {
    return readingCardSlot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeCardBuilder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeCardBuilder?>(value),
    );
  }
}

String _$readingCardSlotHash() => r'13502702c332ea7c15433f18d1f58dfc059d57cd';

@ProviderFor(subscriptionCardSlot)
final subscriptionCardSlotProvider = SubscriptionCardSlotProvider._();

final class SubscriptionCardSlotProvider
    extends
        $FunctionalProvider<
          HomeCardBuilder?,
          HomeCardBuilder?,
          HomeCardBuilder?
        >
    with $Provider<HomeCardBuilder?> {
  SubscriptionCardSlotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionCardSlotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionCardSlotHash();

  @$internal
  @override
  $ProviderElement<HomeCardBuilder?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeCardBuilder? create(Ref ref) {
    return subscriptionCardSlot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeCardBuilder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeCardBuilder?>(value),
    );
  }
}

String _$subscriptionCardSlotHash() =>
    r'1f89f22aa90a967c7d41c3aff2443b97aee12165';

@ProviderFor(recoverySlot)
final recoverySlotProvider = RecoverySlotProvider._();

final class RecoverySlotProvider
    extends
        $FunctionalProvider<
          HomeCardBuilder?,
          HomeCardBuilder?,
          HomeCardBuilder?
        >
    with $Provider<HomeCardBuilder?> {
  RecoverySlotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recoverySlotProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recoverySlotHash();

  @$internal
  @override
  $ProviderElement<HomeCardBuilder?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeCardBuilder? create(Ref ref) {
    return recoverySlot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeCardBuilder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeCardBuilder?>(value),
    );
  }
}

String _$recoverySlotHash() => r'ca1090cad4be97986751101acc439fe846ecbd3e';
