// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeToday)
final homeTodayProvider = HomeTodayProvider._();

final class HomeTodayProvider
    extends $FunctionalProvider<LocalDate, LocalDate, LocalDate>
    with $Provider<LocalDate> {
  HomeTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTodayHash();

  @$internal
  @override
  $ProviderElement<LocalDate> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalDate create(Ref ref) {
    return homeToday(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalDate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalDate>(value),
    );
  }
}

String _$homeTodayHash() => r'c85b1be6bad9661eb6499e14b4524b9ee2b79efa';

@ProviderFor(homeRecentSessions)
final homeRecentSessionsProvider = HomeRecentSessionsProvider._();

final class HomeRecentSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudySession>>,
          List<StudySession>,
          Stream<List<StudySession>>
        >
    with
        $FutureModifier<List<StudySession>>,
        $StreamProvider<List<StudySession>> {
  HomeRecentSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRecentSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRecentSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<StudySession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StudySession>> create(Ref ref) {
    return homeRecentSessions(ref);
  }
}

String _$homeRecentSessionsHash() =>
    r'ba9dd2343427fcd458ce7579a88713b63717d3ee';

@ProviderFor(homeAllSessions)
final homeAllSessionsProvider = HomeAllSessionsProvider._();

final class HomeAllSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudySession>>,
          List<StudySession>,
          Stream<List<StudySession>>
        >
    with
        $FutureModifier<List<StudySession>>,
        $StreamProvider<List<StudySession>> {
  HomeAllSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeAllSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeAllSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<StudySession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StudySession>> create(Ref ref) {
    return homeAllSessions(ref);
  }
}

String _$homeAllSessionsHash() => r'6bd56b8fc1fd014595024974301ff1c2d31d0d9d';

/// Segments overlapping yesterday..today (the ring and the two totals never
/// need older ones; a session that started yesterday and crossed midnight
/// is included because its segments overlap today).

@ProviderFor(homeSegments)
final homeSegmentsProvider = HomeSegmentsProvider._();

/// Segments overlapping yesterday..today (the ring and the two totals never
/// need older ones; a session that started yesterday and crossed midnight
/// is included because its segments overlap today).

final class HomeSegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  /// Segments overlapping yesterday..today (the ring and the two totals never
  /// need older ones; a session that started yesterday and crossed midnight
  /// is included because its segments overlap today).
  HomeSegmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeSegmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeSegmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<SessionSegment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SessionSegment>> create(Ref ref) {
    return homeSegments(ref);
  }
}

String _$homeSegmentsHash() => r'5e65548d83bdaa2d1231221434af387429876ffb';

@ProviderFor(homeTodayItems)
final homeTodayItemsProvider = HomeTodayItemsProvider._();

final class HomeTodayItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlannerItem>>,
          List<PlannerItem>,
          Stream<List<PlannerItem>>
        >
    with
        $FutureModifier<List<PlannerItem>>,
        $StreamProvider<List<PlannerItem>> {
  HomeTodayItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTodayItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTodayItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<PlannerItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlannerItem>> create(Ref ref) {
    return homeTodayItems(ref);
  }
}

String _$homeTodayItemsHash() => r'05b0f16d0290d4a8ef239e4d79de97b48e2f46c4';

@ProviderFor(homeRecurrences)
final homeRecurrencesProvider = HomeRecurrencesProvider._();

final class HomeRecurrencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Recurrence>>,
          List<Recurrence>,
          Stream<List<Recurrence>>
        >
    with $FutureModifier<List<Recurrence>>, $StreamProvider<List<Recurrence>> {
  HomeRecurrencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRecurrencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRecurrencesHash();

  @$internal
  @override
  $StreamProviderElement<List<Recurrence>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Recurrence>> create(Ref ref) {
    return homeRecurrences(ref);
  }
}

String _$homeRecurrencesHash() => r'ecab1cb6e8eaae59774945f04e519b2c024173f2';

@ProviderFor(homeSubjects)
final homeSubjectsProvider = HomeSubjectsProvider._();

final class HomeSubjectsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Subject>>,
          List<Subject>,
          Stream<List<Subject>>
        >
    with $FutureModifier<List<Subject>>, $StreamProvider<List<Subject>> {
  HomeSubjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeSubjectsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeSubjectsHash();

  @$internal
  @override
  $StreamProviderElement<List<Subject>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Subject>> create(Ref ref) {
    return homeSubjects(ref);
  }
}

String _$homeSubjectsHash() => r'135a7377af6dc7e2ec4743e7b006b518857ee22b';

@ProviderFor(homeSnapshot)
final homeSnapshotProvider = HomeSnapshotProvider._();

final class HomeSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<SessionSnapshot?>,
          SessionSnapshot?,
          Stream<SessionSnapshot?>
        >
    with $FutureModifier<SessionSnapshot?>, $StreamProvider<SessionSnapshot?> {
  HomeSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeSnapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeSnapshotHash();

  @$internal
  @override
  $StreamProviderElement<SessionSnapshot?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SessionSnapshot?> create(Ref ref) {
    return homeSnapshot(ref);
  }
}

String _$homeSnapshotHash() => r'dd75f641b450715e4a6f2c17ea300ae64bc7003d';

@ProviderFor(homeView)
final homeViewProvider = HomeViewProvider._();

final class HomeViewProvider
    extends $FunctionalProvider<HomeViewState, HomeViewState, HomeViewState>
    with $Provider<HomeViewState> {
  HomeViewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeViewHash();

  @$internal
  @override
  $ProviderElement<HomeViewState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeViewState create(Ref ref) {
    return homeView(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeViewState>(value),
    );
  }
}

String _$homeViewHash() => r'25506ebdbf00938457430ddd25ccf5c0a5c70058';

/// null while loading or when nothing is unfinished.

@ProviderFor(homeRecoveryCandidate)
final homeRecoveryCandidateProvider = HomeRecoveryCandidateProvider._();

/// null while loading or when nothing is unfinished.

final class HomeRecoveryCandidateProvider
    extends
        $FunctionalProvider<
          RecoveryCandidate?,
          RecoveryCandidate?,
          RecoveryCandidate?
        >
    with $Provider<RecoveryCandidate?> {
  /// null while loading or when nothing is unfinished.
  HomeRecoveryCandidateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeRecoveryCandidateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeRecoveryCandidateHash();

  @$internal
  @override
  $ProviderElement<RecoveryCandidate?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecoveryCandidate? create(Ref ref) {
    return homeRecoveryCandidate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecoveryCandidate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecoveryCandidate?>(value),
    );
  }
}

String _$homeRecoveryCandidateHash() =>
    r'998c884691513e153f87c905627f2c443ff2ffa8';
