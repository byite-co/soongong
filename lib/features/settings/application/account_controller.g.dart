// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rebuilt when the account (write context) changes.

@ProviderFor(accountController)
final accountControllerProvider = AccountControllerProvider._();

/// Rebuilt when the account (write context) changes.

final class AccountControllerProvider
    extends
        $FunctionalProvider<
          AccountController,
          AccountController,
          AccountController
        >
    with $Provider<AccountController> {
  /// Rebuilt when the account (write context) changes.
  AccountControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountControllerHash();

  @$internal
  @override
  $ProviderElement<AccountController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountController create(Ref ref) {
    return accountController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountController>(value),
    );
  }
}

String _$accountControllerHash() => r'4c5f368cd392dfed0886e3f79894e7aa92d8bc6d';
