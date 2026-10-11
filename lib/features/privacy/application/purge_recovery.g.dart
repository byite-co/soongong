// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purge_recovery.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PurgeRecoveryStatus)
final purgeRecoveryStatusProvider = PurgeRecoveryStatusProvider._();

final class PurgeRecoveryStatusProvider
    extends $NotifierProvider<PurgeRecoveryStatus, PurgeRecoveryState> {
  PurgeRecoveryStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purgeRecoveryStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purgeRecoveryStatusHash();

  @$internal
  @override
  PurgeRecoveryStatus create() => PurgeRecoveryStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurgeRecoveryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurgeRecoveryState>(value),
    );
  }
}

String _$purgeRecoveryStatusHash() =>
    r'034f8ee5e240c8c9350875320da3f2268c97314c';

abstract class _$PurgeRecoveryStatus extends $Notifier<PurgeRecoveryState> {
  PurgeRecoveryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PurgeRecoveryState, PurgeRecoveryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PurgeRecoveryState, PurgeRecoveryState>,
              PurgeRecoveryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(_snapshot)
final _snapshotProvider = _SnapshotProvider._();

final class _SnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionSnapshot?>,
          SessionSnapshot?,
          Stream<SessionSnapshot?>
        >
    with $FutureModifier<SessionSnapshot?>, $StreamProvider<SessionSnapshot?> {
  _SnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_snapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_snapshotHash();

  @$internal
  @override
  $StreamProviderElement<SessionSnapshot?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SessionSnapshot?> create(Ref ref) {
    return _snapshot(ref);
  }
}

String _$_snapshotHash() => r'a3932215fd79a34cb615a6938692ce9b727deb53';

@ProviderFor(_online)
final _onlineProvider = _OnlineProvider._();

final class _OnlineProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  _OnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_onlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_onlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return _online(ref);
  }
}

String _$_onlineHash() => r'0f28abe431e43b75f289a056c8e19b21247f3c6c';

@ProviderFor(purgeRecovery)
final purgeRecoveryProvider = PurgeRecoveryProvider._();

final class PurgeRecoveryProvider
    extends $FunctionalProvider<PurgeRecovery, PurgeRecovery, PurgeRecovery>
    with $Provider<PurgeRecovery> {
  PurgeRecoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'purgeRecoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$purgeRecoveryHash();

  @$internal
  @override
  $ProviderElement<PurgeRecovery> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PurgeRecovery create(Ref ref) {
    return purgeRecovery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PurgeRecovery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PurgeRecovery>(value),
    );
  }
}

String _$purgeRecoveryHash() => r'07aeee920fe4e713286c02661f7c8df6c07e6aab';
