// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subjects_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(subjectsList)
final subjectsListProvider = SubjectsListProvider._();

final class SubjectsListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subject>>,
          List<Subject>,
          Stream<List<Subject>>
        >
    with $FutureModifier<List<Subject>>, $StreamProvider<List<Subject>> {
  SubjectsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectsListHash();

  @$internal
  @override
  $StreamProviderElement<List<Subject>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subject>> create(Ref ref) {
    return subjectsList(ref);
  }
}

String _$subjectsListHash() => r'6df856ffa2bcbb099aebf1db65f0ace6e11e9f4e';

@ProviderFor(subjectsWeekSegments)
final subjectsWeekSegmentsProvider = SubjectsWeekSegmentsProvider._();

final class SubjectsWeekSegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  SubjectsWeekSegmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectsWeekSegmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectsWeekSegmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<SessionSegment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SessionSegment>> create(Ref ref) {
    return subjectsWeekSegments(ref);
  }
}

String _$subjectsWeekSegmentsHash() =>
    r'b48b61a16e4dfa6c66ca05293ab41704cda83c45';

/// Subject id → 순공 seconds this week (null subject keyed by '').

@ProviderFor(subjectsWeekSeated)
final subjectsWeekSeatedProvider = SubjectsWeekSeatedProvider._();

/// Subject id → 순공 seconds this week (null subject keyed by '').

final class SubjectsWeekSeatedProvider
    extends
        $FunctionalProvider<
          Map<String, int>,
          Map<String, int>,
          Map<String, int>
        >
    with $Provider<Map<String, int>> {
  /// Subject id → 순공 seconds this week (null subject keyed by '').
  SubjectsWeekSeatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectsWeekSeatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectsWeekSeatedHash();

  @$internal
  @override
  $ProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, int> create(Ref ref) {
    return subjectsWeekSeated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$subjectsWeekSeatedHash() =>
    r'd24c83fc2bce2222eab6dae9930a0d599e59689d';
