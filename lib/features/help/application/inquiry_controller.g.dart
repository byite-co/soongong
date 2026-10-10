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
