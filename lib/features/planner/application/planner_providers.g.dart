// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(plannerToday)
final plannerTodayProvider = PlannerTodayProvider._();

final class PlannerTodayProvider
    extends $FunctionalProvider<LocalDate, LocalDate, LocalDate>
    with $Provider<LocalDate> {
  PlannerTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerTodayHash();

  @$internal
  @override
  $ProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalDate create(Ref ref) {
    return plannerToday(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate>(value),
    );
  }
}

String _$plannerTodayHash() => r'f1a44ab4139f87045068eb90e31b03ecf50d4003';

@ProviderFor(plannerSettings)
final plannerSettingsProvider = PlannerSettingsProvider._();

final class PlannerSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppSettings>,
          AppSettings,
          Stream<AppSettings>
        >
    with $FutureModifier<AppSettings>, $StreamProvider<AppSettings> {
  PlannerSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerSettingsHash();

  @$internal
  @override
  $StreamProviderElement<AppSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppSettings> create(Ref ref) {
    return plannerSettings(ref);
  }
}

String _$plannerSettingsHash() => r'ff5fcf6a39c7453f1bcf8a4efb855787ee8622be';

/// Week start (1 = Monday … 7 = Sunday); Monday until settings load.

@ProviderFor(plannerWeekStart)
final plannerWeekStartProvider = PlannerWeekStartProvider._();

/// Week start (1 = Monday … 7 = Sunday); Monday until settings load.

final class PlannerWeekStartProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// Week start (1 = Monday … 7 = Sunday); Monday until settings load.
  PlannerWeekStartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerWeekStartProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerWeekStartHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return plannerWeekStart(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$plannerWeekStartHash() => r'0bc9c01ff372fad08e364fee9224e735dc95d509';

/// Premium entitlement from the BillingGateway stream (D18). false until
/// the first value arrives, so free rules never flash premium content.

@ProviderFor(plannerEntitlement)
final plannerEntitlementProvider = PlannerEntitlementProvider._();

/// Premium entitlement from the BillingGateway stream (D18). false until
/// the first value arrives, so free rules never flash premium content.

final class PlannerEntitlementProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Premium entitlement from the BillingGateway stream (D18). false until
  /// the first value arrives, so free rules never flash premium content.
  PlannerEntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerEntitlementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerEntitlementHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return plannerEntitlement(ref);
  }
}

String _$plannerEntitlementHash() =>
    r'8c0814d933ecbf142786de9ca1a64d58e27f3030';

@ProviderFor(plannerEntitled)
final plannerEntitledProvider = PlannerEntitledProvider._();

final class PlannerEntitledProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  PlannerEntitledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerEntitledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerEntitledHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return plannerEntitled(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$plannerEntitledHash() => r'809d7b31e83793cad5fe01000590c10c789c32ef';

@ProviderFor(plannerSubjects)
final plannerSubjectsProvider = PlannerSubjectsProvider._();

final class PlannerSubjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subject>>,
          List<Subject>,
          Stream<List<Subject>>
        >
    with $FutureModifier<List<Subject>>, $StreamProvider<List<Subject>> {
  PlannerSubjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerSubjectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerSubjectsHash();

  @$internal
  @override
  $StreamProviderElement<List<Subject>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subject>> create(Ref ref) {
    return plannerSubjects(ref);
  }
}

String _$plannerSubjectsHash() => r'b2b8b9963929b283d1256d0d7e126098ae66857e';

@ProviderFor(plannerRecurrences)
final plannerRecurrencesProvider = PlannerRecurrencesProvider._();

final class PlannerRecurrencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Recurrence>>,
          List<Recurrence>,
          Stream<List<Recurrence>>
        >
    with $FutureModifier<List<Recurrence>>, $StreamProvider<List<Recurrence>> {
  PlannerRecurrencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerRecurrencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerRecurrencesHash();

  @$internal
  @override
  $StreamProviderElement<List<Recurrence>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Recurrence>> create(Ref ref) {
    return plannerRecurrences(ref);
  }
}

String _$plannerRecurrencesHash() =>
    r'133222452fc03f693e70d159aa4a1d12cc32fda2';

/// Sessions of the whole history (item links · suggestion samples).

@ProviderFor(plannerAllSessions)
final plannerAllSessionsProvider = PlannerAllSessionsProvider._();

/// Sessions of the whole history (item links · suggestion samples).

final class PlannerAllSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudySession>>,
          List<StudySession>,
          Stream<List<StudySession>>
        >
    with
        $FutureModifier<List<StudySession>>,
        $StreamProvider<List<StudySession>> {
  /// Sessions of the whole history (item links · suggestion samples).
  PlannerAllSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerAllSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerAllSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<StudySession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StudySession>> create(Ref ref) {
    return plannerAllSessions(ref);
  }
}

String _$plannerAllSessionsHash() =>
    r'158bbf4b6cb65d230a7bab1c31faa1b2b27aa02c';

@ProviderFor(plannerDensitySegments)
final plannerDensitySegmentsProvider = PlannerDensitySegmentsProvider._();

final class PlannerDensitySegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  PlannerDensitySegmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerDensitySegmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerDensitySegmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<SessionSegment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SessionSegment>> create(Ref ref) {
    return plannerDensitySegments(ref);
  }
}

String _$plannerDensitySegmentsHash() =>
    r'ef090fe9157d22528b405e49325bc935561b73f6';

/// `DensityScale.none` until the window has loaded.

@ProviderFor(plannerDensity)
final plannerDensityProvider = PlannerDensityProvider._();

/// `DensityScale.none` until the window has loaded.

final class PlannerDensityProvider
    extends $FunctionalProvider<DensityScale, DensityScale, DensityScale>
    with $Provider<DensityScale> {
  /// `DensityScale.none` until the window has loaded.
  PlannerDensityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerDensityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerDensityHash();

  @$internal
  @override
  $ProviderElement<DensityScale> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DensityScale create(Ref ref) {
    return plannerDensity(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DensityScale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DensityScale>(value),
    );
  }
}

String _$plannerDensityHash() => r'54cb972945df8ce758692ef6680410506a9f4570';

@ProviderFor(plannerGrid)
final plannerGridProvider = PlannerGridFamily._();

final class PlannerGridProvider
    extends $FunctionalProvider<MonthGrid, MonthGrid, MonthGrid>
    with $Provider<MonthGrid> {
  PlannerGridProvider._({
    required PlannerGridFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'plannerGridProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerGridHash();

  @override
  String toString() {
    return r'plannerGridProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<MonthGrid> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MonthGrid create(Ref ref) {
    final argument = this.argument as String;
    return plannerGrid(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MonthGrid value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MonthGrid>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerGridProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerGridHash() => r'18e8bcc9243396df1903b9661ab5bf62076dd49d';

final class PlannerGridFamily extends $Family
    with $FunctionalFamilyOverride<MonthGrid, String> {
  PlannerGridFamily._()
    : super(
        retry: null,
        name: r'plannerGridProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlannerGridProvider call(String monthKey) =>
      PlannerGridProvider._(argument: monthKey, from: this);

  @override
  String toString() => r'plannerGridProvider';
}

@ProviderFor(plannerGridItems)
final plannerGridItemsProvider = PlannerGridItemsFamily._();

final class PlannerGridItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlannerItem>>,
          List<PlannerItem>,
          Stream<List<PlannerItem>>
        >
    with
        $FutureModifier<List<PlannerItem>>,
        $StreamProvider<List<PlannerItem>> {
  PlannerGridItemsProvider._({
    required PlannerGridItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'plannerGridItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerGridItemsHash();

  @override
  String toString() {
    return r'plannerGridItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<PlannerItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlannerItem>> create(Ref ref) {
    final argument = this.argument as String;
    return plannerGridItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerGridItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerGridItemsHash() => r'cca607e0ad573eb5048bc8d7854965b82d142f98';

final class PlannerGridItemsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<PlannerItem>>, String> {
  PlannerGridItemsFamily._()
    : super(
        retry: null,
        name: r'plannerGridItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlannerGridItemsProvider call(String monthKey) =>
      PlannerGridItemsProvider._(argument: monthKey, from: this);

  @override
  String toString() => r'plannerGridItemsProvider';
}

@ProviderFor(plannerGridSegments)
final plannerGridSegmentsProvider = PlannerGridSegmentsFamily._();

final class PlannerGridSegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  PlannerGridSegmentsProvider._({
    required PlannerGridSegmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'plannerGridSegmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerGridSegmentsHash();

  @override
  String toString() {
    return r'plannerGridSegmentsProvider'
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
    return plannerGridSegments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerGridSegmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerGridSegmentsHash() =>
    r'edeeaec9776622f1f8c61f1aa0641d21d8e8e0c4';

final class PlannerGridSegmentsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<SessionSegment>>, String> {
  PlannerGridSegmentsFamily._()
    : super(
        retry: null,
        name: r'plannerGridSegmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlannerGridSegmentsProvider call(String monthKey) =>
      PlannerGridSegmentsProvider._(argument: monthKey, from: this);

  @override
  String toString() => r'plannerGridSegmentsProvider';
}

/// Sessions that started the day before the grid or later (a session that
/// crossed midnight into the grid is included for its segments).

@ProviderFor(plannerGridSessions)
final plannerGridSessionsProvider = PlannerGridSessionsFamily._();

/// Sessions that started the day before the grid or later (a session that
/// crossed midnight into the grid is included for its segments).

final class PlannerGridSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudySession>>,
          List<StudySession>,
          Stream<List<StudySession>>
        >
    with
        $FutureModifier<List<StudySession>>,
        $StreamProvider<List<StudySession>> {
  /// Sessions that started the day before the grid or later (a session that
  /// crossed midnight into the grid is included for its segments).
  PlannerGridSessionsProvider._({
    required PlannerGridSessionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'plannerGridSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerGridSessionsHash();

  @override
  String toString() {
    return r'plannerGridSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<StudySession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StudySession>> create(Ref ref) {
    final argument = this.argument as String;
    return plannerGridSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerGridSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerGridSessionsHash() =>
    r'dbbc3c81efdc14fc3c86c2607f0e74e645ff4581';

/// Sessions that started the day before the grid or later (a session that
/// crossed midnight into the grid is included for its segments).

final class PlannerGridSessionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<StudySession>>, String> {
  PlannerGridSessionsFamily._()
    : super(
        retry: null,
        name: r'plannerGridSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Sessions that started the day before the grid or later (a session that
  /// crossed midnight into the grid is included for its segments).

  PlannerGridSessionsProvider call(String monthKey) =>
      PlannerGridSessionsProvider._(argument: monthKey, from: this);

  @override
  String toString() => r'plannerGridSessionsProvider';
}

/// One month's grid data (items · bands · recurrences · 순공 per day ·
/// linked sessions). Reused by S08.

@ProviderFor(plannerMonth)
final plannerMonthProvider = PlannerMonthFamily._();

/// One month's grid data (items · bands · recurrences · 순공 per day ·
/// linked sessions). Reused by S08.

final class PlannerMonthProvider
    extends
        $FunctionalProvider<
          PlannerMonthState,
          PlannerMonthState,
          PlannerMonthState
        >
    with $Provider<PlannerMonthState> {
  /// One month's grid data (items · bands · recurrences · 순공 per day ·
  /// linked sessions). Reused by S08.
  PlannerMonthProvider._({
    required PlannerMonthFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'plannerMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$plannerMonthHash();

  @override
  String toString() {
    return r'plannerMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<PlannerMonthState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlannerMonthState create(Ref ref) {
    final argument = this.argument as String;
    return plannerMonth(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlannerMonthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlannerMonthState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlannerMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$plannerMonthHash() => r'fd273df4a25aa0e1a5278662256a61c8acbb2b8f';

/// One month's grid data (items · bands · recurrences · 순공 per day ·
/// linked sessions). Reused by S08.

final class PlannerMonthFamily extends $Family
    with $FunctionalFamilyOverride<PlannerMonthState, String> {
  PlannerMonthFamily._()
    : super(
        retry: null,
        name: r'plannerMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One month's grid data (items · bands · recurrences · 순공 per day ·
  /// linked sessions). Reused by S08.

  PlannerMonthProvider call(String monthKey) =>
      PlannerMonthProvider._(argument: monthKey, from: this);

  @override
  String toString() => r'plannerMonthProvider';
}

/// Rebuilt when the repositories change (account switch, D27); the old
/// instance is disposed so its pending delete timers never commit.

@ProviderFor(plannerController)
final plannerControllerProvider = PlannerControllerProvider._();

/// Rebuilt when the repositories change (account switch, D27); the old
/// instance is disposed so its pending delete timers never commit.

final class PlannerControllerProvider
    extends
        $FunctionalProvider<
          PlannerController,
          PlannerController,
          PlannerController
        >
    with $Provider<PlannerController> {
  /// Rebuilt when the repositories change (account switch, D27); the old
  /// instance is disposed so its pending delete timers never commit.
  PlannerControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerControllerHash();

  @$internal
  @override
  $ProviderElement<PlannerController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlannerController create(Ref ref) {
    return plannerController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlannerController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlannerController>(value),
    );
  }
}

String _$plannerControllerHash() => r'26df7052061e2d8d5d99c302892146431e6ebede';
