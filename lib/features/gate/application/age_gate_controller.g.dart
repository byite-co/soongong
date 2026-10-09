// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'age_gate_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AgeGateController)
final ageGateControllerProvider = AgeGateControllerProvider._();

final class AgeGateControllerProvider
    extends $NotifierProvider<AgeGateController, AgeGateState> {
  AgeGateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ageGateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ageGateControllerHash();

  @$internal
  @override
  AgeGateController create() => AgeGateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgeGateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgeGateState>(value),
    );
  }
}

String _$ageGateControllerHash() => r'7d47adfc6c868078dc8f6e6423d8b246382649b2';

abstract class _$AgeGateController extends $Notifier<AgeGateState> {
  AgeGateState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AgeGateState, AgeGateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AgeGateState, AgeGateState>,
              AgeGateState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
