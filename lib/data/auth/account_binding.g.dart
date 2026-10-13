// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_binding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountBinding)
final accountBindingProvider = AccountBindingProvider._();

final class AccountBindingProvider
    extends $FunctionalProvider<AccountBinding, AccountBinding, AccountBinding>
    with $Provider<AccountBinding> {
  AccountBindingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountBindingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountBindingHash();

  @$internal
  @override
  $ProviderElement<AccountBinding> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountBinding create(Ref ref) {
    return accountBinding(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountBinding value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountBinding>(value),
    );
  }
}

String _$accountBindingHash() => r'e6bd0cef4089c1ec701c1ccab689b8671c3446e6';
