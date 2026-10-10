// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Segments overlapping the week starting on [weekKey] (`yyyy-MM-dd`).

@ProviderFor(timetableSegments)
final timetableSegmentsProvider = TimetableSegmentsFamily._();

/// Segments overlapping the week starting on [weekKey] (`yyyy-MM-dd`).

final class TimetableSegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  /// Segments overlapping the week starting on [weekKey] (`yyyy-MM-dd`).
  TimetableSegmentsProvider._({
    required TimetableSegmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'timetableSegmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timetableSegmentsHash();

  @override
  String toString() {
    return r'timetableSegmentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<SessionSegment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SessionSegment>> create(Ref ref) {
    final argument = this.argument as String;
    return timetableSegments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TimetableSegmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timetableSegmentsHash() => r'd74af3d88ac51a1b13248f27f809e06e4d46a063';

/// Segments overlapping the week starting on [weekKey] (`yyyy-MM-dd`).

final class TimetableSegmentsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SessionSegment>>, String> {
  TimetableSegmentsFamily._()
    : super(
        retry: null,
        name: r'timetableSegmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Segments overlapping the week starting on [weekKey] (`yyyy-MM-dd`).

  TimetableSegmentsProvider call(String weekKey) =>
      TimetableSegmentsProvider._(argument: weekKey, from: this);

  @override
  String toString() => r'timetableSegmentsProvider';
}

@ProviderFor(timetableWeek)
final timetableWeekProvider = TimetableWeekFamily._();

final class TimetableWeekProvider
    extends
        $FunctionalProvider<
          TimetableWeekState,
          TimetableWeekState,
          TimetableWeekState
        >
    with $Provider<TimetableWeekState> {
  TimetableWeekProvider._({
    required TimetableWeekFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'timetableWeekProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$timetableWeekHash();

  @override
  String toString() {
    return r'timetableWeekProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TimetableWeekState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TimetableWeekState create(Ref ref) {
    final argument = this.argument as String;
    return timetableWeek(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TimetableWeekState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TimetableWeekState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimetableWeekProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$timetableWeekHash() => r'cd4adf724306ec42903be3406a26f0e8311d4edc';

final class TimetableWeekFamily extends $Family
    with $FunctionalFamilyOverride<TimetableWeekState, String> {
  TimetableWeekFamily._()
    : super(
        retry: null,
        name: r'timetableWeekProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TimetableWeekProvider call(String weekKey) =>
      TimetableWeekProvider._(argument: weekKey, from: this);

  @override
  String toString() => r'timetableWeekProvider';
}
