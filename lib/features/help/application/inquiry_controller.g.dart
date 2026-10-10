// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inquiry_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive: `send` reads providers after awaiting the summary.

@ProviderFor(inquiryController)
final inquiryControllerProvider = InquiryControllerProvider._();

/// keepAlive: `send` reads providers after awaiting the summary.

final class InquiryControllerProvider
    extends
        $FunctionalProvider<
          InquiryController,
          InquiryController,
          InquiryController
        >
    with $Provider<InquiryController> {
  /// keepAlive: `send` reads providers after awaiting the summary.
  InquiryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inquiryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inquiryControllerHash();

  @$internal
  @override
  $ProviderElement<InquiryController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InquiryController create(Ref ref) {
    return inquiryController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InquiryController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InquiryController>(value),
    );
  }
}

String _$inquiryControllerHash() => r'9405d5bf6b9d27c410f082a8b685a119748c4f8c';

/// S09b: device network state for the 문의 form (offline → sending disabled).

@ProviderFor(networkOnline)
final networkOnlineProvider = NetworkOnlineProvider._();

/// S09b: device network state for the 문의 form (offline → sending disabled).

final class NetworkOnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// S09b: device network state for the 문의 form (offline → sending disabled).
  NetworkOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkOnlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkOnlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return networkOnline(ref);
  }
}

String _$networkOnlineHash() => r'1b4115aa9593c3aa491b58fcce8a3895854e0957';
