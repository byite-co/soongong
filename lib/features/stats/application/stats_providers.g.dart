// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Segments overlapping the range [from]..[to] of [key] — the previous
/// week is loaded for the comparison, so the family is keyed by the range.

@ProviderFor(statsSegments)
final statsSegmentsProvider = StatsSegmentsFamily._();

/// Segments overlapping the range [from]..[to] of [key] — the previous
/// week is loaded for the comparison, so the family is keyed by the range.

final class StatsSegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  /// Segments overlapping the range [from]..[to] of [key] — the previous
  /// week is loaded for the comparison, so the family is keyed by the range.
  StatsSegmentsProvider._({
    required StatsSegmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'statsSegmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$statsSegmentsHash();

  @override
  String toString() {
    return r'statsSegmentsProvider'
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
    return statsSegments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StatsSegmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$statsSegmentsHash() => r'79f65cd38f18e291e2741a04a2de99f41047790f';

/// Segments overlapping the range [from]..[to] of [key] — the previous
/// week is loaded for the comparison, so the family is keyed by the range.

final class StatsSegmentsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SessionSegment>>, String> {
  StatsSegmentsFamily._()
    : super(
        retry: null,
        name: r'statsSegmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Segments overlapping the range [from]..[to] of [key] — the previous
  /// week is loaded for the comparison, so the family is keyed by the range.

  StatsSegmentsProvider call(String rangeKey) =>
      StatsSegmentsProvider._(argument: rangeKey, from: this);

  @override
  String toString() => r'statsSegmentsProvider';
}

/// Whole-history segments: the recorded-day count behind the sparse state
/// and the "지금까지" total.

@ProviderFor(statsAllSegments)
final statsAllSegmentsProvider = StatsAllSegmentsProvider._();

/// Whole-history segments: the recorded-day count behind the sparse state
/// and the "지금까지" total.

final class StatsAllSegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  /// Whole-history segments: the recorded-day count behind the sparse state
  /// and the "지금까지" total.
  StatsAllSegmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsAllSegmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsAllSegmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<SessionSegment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SessionSegment>> create(Ref ref) {
    return statsAllSegments(ref);
  }
}

String _$statsAllSegmentsHash() => r'e6be20b4a2477e623afd0414c23a369b53b5b3af';

@ProviderFor(statsRecord)
final statsRecordProvider = StatsRecordProvider._();

final class StatsRecordProvider
    extends
        $FunctionalProvider<
          StatsRecordState,
          StatsRecordState,
          StatsRecordState
        >
    with $Provider<StatsRecordState> {
  StatsRecordProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsRecordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsRecordHash();

  @$internal
  @override
  $ProviderElement<StatsRecordState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatsRecordState create(Ref ref) {
    return statsRecord(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsRecordState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsRecordState>(value),
    );
  }
}

String _$statsRecordHash() => r'06dcf46168000395ea1f6797f7f31312d1ac4b4a';

@ProviderFor(statsView)
final statsViewProvider = StatsViewFamily._();

final class StatsViewProvider
    extends $FunctionalProvider<StatsViewState, StatsViewState, StatsViewState>
    with $Provider<StatsViewState> {
  StatsViewProvider._({
    required StatsViewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'statsViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$statsViewHash();

  @override
  String toString() {
    return r'statsViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<StatsViewState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatsViewState create(Ref ref) {
    final argument = this.argument as String;
    return statsView(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsViewState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatsViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$statsViewHash() => r'8800877322033deb9a142d0e7908a21eaa46f7ba';

final class StatsViewFamily extends $Family
    with $FunctionalFamilyOverride<StatsViewState, String> {
  StatsViewFamily._()
    : super(
        retry: null,
        name: r'statsViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StatsViewProvider call(String rangeKey) =>
      StatsViewProvider._(argument: rangeKey, from: this);

  @override
  String toString() => r'statsViewProvider';
}

/// Full entitlement (status matters: `expired` shows the read-only card).

@ProviderFor(statsEntitlement)
final statsEntitlementProvider = StatsEntitlementProvider._();

/// Full entitlement (status matters: `expired` shows the read-only card).

final class StatsEntitlementProvider
    extends
        $FunctionalProvider<
          AsyncValue<Entitlement>,
          Entitlement,
          Stream<Entitlement>
        >
    with $FutureModifier<Entitlement>, $StreamProvider<Entitlement> {
  /// Full entitlement (status matters: `expired` shows the read-only card).
  StatsEntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsEntitlementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsEntitlementHash();

  @$internal
  @override
  $StreamProviderElement<Entitlement> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Entitlement> create(Ref ref) {
    return statsEntitlement(ref);
  }
}

String _$statsEntitlementHash() => r'0f7052f56d0c5e5afafc62a63e66baf05613abd8';

@ProviderFor(statsWrongs)
final statsWrongsProvider = StatsWrongsProvider._();

final class StatsWrongsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WrongItem>>,
          List<WrongItem>,
          Stream<List<WrongItem>>
        >
    with $FutureModifier<List<WrongItem>>, $StreamProvider<List<WrongItem>> {
  StatsWrongsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsWrongsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsWrongsHash();

  @$internal
  @override
  $StreamProviderElement<List<WrongItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WrongItem>> create(Ref ref) {
    return statsWrongs(ref);
  }
}

String _$statsWrongsHash() => r'7c763da447cb8721a912287e0287d773672c3065';

@ProviderFor(statsSavedReadings)
final statsSavedReadingsProvider = StatsSavedReadingsProvider._();

final class StatsSavedReadingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReadingRequest>>,
          List<ReadingRequest>,
          Stream<List<ReadingRequest>>
        >
    with
        $FutureModifier<List<ReadingRequest>>,
        $StreamProvider<List<ReadingRequest>> {
  StatsSavedReadingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsSavedReadingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsSavedReadingsHash();

  @$internal
  @override
  $StreamProviderElement<List<ReadingRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReadingRequest>> create(Ref ref) {
    return statsSavedReadings(ref);
  }
}

String _$statsSavedReadingsHash() =>
    r'a43637c72f4d91651d0a0f391e2eb3f03912f178';

@ProviderFor(statsWrongsSection)
final statsWrongsSectionProvider = StatsWrongsSectionFamily._();

final class StatsWrongsSectionProvider
    extends $FunctionalProvider<WrongsState, WrongsState, WrongsState>
    with $Provider<WrongsState> {
  StatsWrongsSectionProvider._({
    required StatsWrongsSectionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'statsWrongsSectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$statsWrongsSectionHash();

  @override
  String toString() {
    return r'statsWrongsSectionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<WrongsState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WrongsState create(Ref ref) {
    final argument = this.argument as String;
    return statsWrongsSection(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WrongsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WrongsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StatsWrongsSectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$statsWrongsSectionHash() =>
    r'676e7b18d33712a42c70f8a8953bfb6c11316bd6';

final class StatsWrongsSectionFamily extends $Family
    with $FunctionalFamilyOverride<WrongsState, String> {
  StatsWrongsSectionFamily._()
    : super(
        retry: null,
        name: r'statsWrongsSectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StatsWrongsSectionProvider call(String rangeKey) =>
      StatsWrongsSectionProvider._(argument: rangeKey, from: this);

  @override
  String toString() => r'statsWrongsSectionProvider';
}
