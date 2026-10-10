// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive: the controller is used across async gaps from modals.

@ProviderFor(accountController)
final accountControllerProvider = AccountControllerProvider._();

/// keepAlive: the controller is used across async gaps from modals.

final class AccountControllerProvider
    extends
        $FunctionalProvider<
          AccountController,
          AccountController,
          AccountController
        >
    with $Provider<AccountController> {
  /// keepAlive: the controller is used across async gaps from modals.
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

String _$accountControllerHash() => r'4a58bd1aae3438e74122498e3f95565ad4271063';
