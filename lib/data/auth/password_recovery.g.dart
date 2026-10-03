// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_recovery.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PasswordRecovery)
final passwordRecoveryProvider = PasswordRecoveryProvider._();

final class PasswordRecoveryProvider
    extends $NotifierProvider<PasswordRecovery, bool> {
  PasswordRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordRecoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordRecoveryHash();

  @$internal
  @override
  PasswordRecovery create() => PasswordRecovery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$passwordRecoveryHash() => r'5bc21aa60defa9eaa4102a45152cabb4d0c3d027';

abstract class _$PasswordRecovery extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
