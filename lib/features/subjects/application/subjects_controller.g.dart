// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Rebuilt when the repositories change (account switch, D27).

@ProviderFor(subjectsController)
final subjectsControllerProvider = SubjectsControllerProvider._();

/// Rebuilt when the repositories change (account switch, D27).

final class SubjectsControllerProvider
    extends
        $FunctionalProvider<
          SubjectsController,
          SubjectsController,
          SubjectsController
        >
    with $Provider<SubjectsController> {
  /// Rebuilt when the repositories change (account switch, D27).
  SubjectsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectsControllerHash();

  @$internal
  @override
  $ProviderElement<SubjectsController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubjectsController create(Ref ref) {
    return subjectsController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubjectsController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubjectsController>(value),
    );
  }
}

String _$subjectsControllerHash() =>
    r'8c3f527af9ddf22876b18c50e55a5279b31f5fc3';
