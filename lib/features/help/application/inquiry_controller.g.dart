// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inquiry_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// S09c: the fallback mailbox (`SUPPORT_EMAIL` dart-define, empty = not
/// decided). Tests override it.

@ProviderFor(supportEmail)
final supportEmailProvider = SupportEmailProvider._();

/// S09c: the fallback mailbox (`SUPPORT_EMAIL` dart-define, empty = not
/// decided). Tests override it.

final class SupportEmailProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// S09c: the fallback mailbox (`SUPPORT_EMAIL` dart-define, empty = not
  /// decided). Tests override it.
  SupportEmailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportEmailProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportEmailHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return supportEmail(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$supportEmailHash() => r'1224e8587e3e316ad639bc25adda421dfd6ddbee';

@ProviderFor(launchMail)
final launchMailProvider = LaunchMailProvider._();

final class LaunchMailProvider
    extends $FunctionalProvider<LaunchMail, LaunchMail, LaunchMail>
    with $Provider<LaunchMail> {
  LaunchMailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launchMailProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launchMailHash();

  @$internal
  @override
  $ProviderElement<LaunchMail> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LaunchMail create(Ref ref) {
    return launchMail(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaunchMail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaunchMail>(value),
    );
  }
}

String _$launchMailHash() => r'dc19b86475bdab63a9cf68b1f70e322a671dc6c2';

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
