// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'9f3be49e3b43a89a323badf0e3359f660f50a15f';

@ProviderFor(currentUserId)
final currentUserIdProvider = CurrentUserIdProvider._();

final class CurrentUserIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  CurrentUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return currentUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$currentUserIdHash() => r'bb84a3f94186f13d895db8269ad78bf21281e13b';

@ProviderFor(appClock)
final appClockProvider = AppClockProvider._();

final class AppClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  AppClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appClockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return appClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$appClockHash() => r'3fa7bd7e45140c409a6e7e22995d679c79d52e7a';

@ProviderFor(writeContext)
final writeContextProvider = WriteContextProvider._();

final class WriteContextProvider
    extends $FunctionalProvider<WriteContext, WriteContext, WriteContext>
    with $Provider<WriteContext> {
  WriteContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'writeContextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$writeContextHash();

  @$internal
  @override
  $ProviderElement<WriteContext> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WriteContext create(Ref ref) {
    return writeContext(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WriteContext value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WriteContext>(value),
    );
  }
}

String _$writeContextHash() => r'047e5e92550e982b147956b531b17c3bbdb4612f';

@ProviderFor(syncWriter)
final syncWriterProvider = SyncWriterProvider._();

final class SyncWriterProvider
    extends $FunctionalProvider<SyncWriter, SyncWriter, SyncWriter>
    with $Provider<SyncWriter> {
  SyncWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncWriterHash();

  @$internal
  @override
  $ProviderElement<SyncWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncWriter create(Ref ref) {
    return syncWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncWriter>(value),
    );
  }
}

String _$syncWriterHash() => r'81a2940f8dd7de7d40e895924e5ee5969c2580eb';

@ProviderFor(subjectRepository)
final subjectRepositoryProvider = SubjectRepositoryProvider._();

final class SubjectRepositoryProvider
    extends
        $FunctionalProvider<
          SubjectRepository,
          SubjectRepository,
          SubjectRepository
        >
    with $Provider<SubjectRepository> {
  SubjectRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subjectRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subjectRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubjectRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubjectRepository create(Ref ref) {
    return subjectRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubjectRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubjectRepository>(value),
    );
  }
}

String _$subjectRepositoryHash() => r'44208acd7138767c4a72d8ca1d498a9a34d6bcb0';

@ProviderFor(sessionRepository)
final sessionRepositoryProvider = SessionRepositoryProvider._();

final class SessionRepositoryProvider
    extends
        $FunctionalProvider<
          SessionRepository,
          SessionRepository,
          SessionRepository
        >
    with $Provider<SessionRepository> {
  SessionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SessionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionRepository create(Ref ref) {
    return sessionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionRepository>(value),
    );
  }
}

String _$sessionRepositoryHash() => r'f5e7e63782ca5b7de7ab35f9d77daa2701d885b0';

@ProviderFor(plannerRepository)
final plannerRepositoryProvider = PlannerRepositoryProvider._();

final class PlannerRepositoryProvider
    extends
        $FunctionalProvider<
          PlannerRepository,
          PlannerRepository,
          PlannerRepository
        >
    with $Provider<PlannerRepository> {
  PlannerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plannerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plannerRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlannerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlannerRepository create(Ref ref) {
    return plannerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlannerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlannerRepository>(value),
    );
  }
}

String _$plannerRepositoryHash() => r'99f8752c0336ef65a2fb14c38cf435f237fb1cad';

@ProviderFor(readingRepository)
final readingRepositoryProvider = ReadingRepositoryProvider._();

final class ReadingRepositoryProvider
    extends
        $FunctionalProvider<
          ReadingRepository,
          ReadingRepository,
          ReadingRepository
        >
    with $Provider<ReadingRepository> {
  ReadingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readingRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReadingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReadingRepository create(Ref ref) {
    return readingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadingRepository>(value),
    );
  }
}

String _$readingRepositoryHash() => r'4f5b3cebd394a73676dd36213227a54caaca1b47';

@ProviderFor(wrongsRepository)
final wrongsRepositoryProvider = WrongsRepositoryProvider._();

final class WrongsRepositoryProvider
    extends
        $FunctionalProvider<
          WrongsRepository,
          WrongsRepository,
          WrongsRepository
        >
    with $Provider<WrongsRepository> {
  WrongsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wrongsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wrongsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WrongsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WrongsRepository create(Ref ref) {
    return wrongsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WrongsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WrongsRepository>(value),
    );
  }
}

String _$wrongsRepositoryHash() => r'24cd2a58fdca12c434f97741a29821696d04d2a3';

@ProviderFor(reviewRepository)
final reviewRepositoryProvider = ReviewRepositoryProvider._();

final class ReviewRepositoryProvider
    extends
        $FunctionalProvider<
          ReviewRepository,
          ReviewRepository,
          ReviewRepository
        >
    with $Provider<ReviewRepository> {
  ReviewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReviewRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReviewRepository create(Ref ref) {
    return reviewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewRepository>(value),
    );
  }
}

String _$reviewRepositoryHash() => r'73bebb7d1959bbd232f58330eee0007253624f24';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'8a55ba6f1000c2ab13c6e76605595f4a11b7505f';

@ProviderFor(subscriptionRepository)
final subscriptionRepositoryProvider = SubscriptionRepositoryProvider._();

final class SubscriptionRepositoryProvider
    extends
        $FunctionalProvider<
          SubscriptionRepository,
          SubscriptionRepository,
          SubscriptionRepository
        >
    with $Provider<SubscriptionRepository> {
  SubscriptionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubscriptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionRepository create(Ref ref) {
    return subscriptionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionRepository>(value),
    );
  }
}

String _$subscriptionRepositoryHash() =>
    r'd017776001d5661129aec252c6e857a22075cd08';

@ProviderFor(quotaRepository)
final quotaRepositoryProvider = QuotaRepositoryProvider._();

final class QuotaRepositoryProvider
    extends
        $FunctionalProvider<QuotaRepository, QuotaRepository, QuotaRepository>
    with $Provider<QuotaRepository> {
  QuotaRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quotaRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quotaRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuotaRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QuotaRepository create(Ref ref) {
    return quotaRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuotaRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuotaRepository>(value),
    );
  }
}

String _$quotaRepositoryHash() => r'570d32bb8954fdf01cdc96c00c8b15c367f1458e';

@ProviderFor(activityRepository)
final activityRepositoryProvider = ActivityRepositoryProvider._();

final class ActivityRepositoryProvider
    extends
        $FunctionalProvider<
          ActivityRepository,
          ActivityRepository,
          ActivityRepository
        >
    with $Provider<ActivityRepository> {
  ActivityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityRepositoryHash();

  @$internal
  @override
  $ProviderElement<ActivityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActivityRepository create(Ref ref) {
    return activityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityRepository>(value),
    );
  }
}

String _$activityRepositoryHash() =>
    r'1a296fae7a674401dece24db2986558b3ee48908';

@ProviderFor(deleteSettler)
final deleteSettlerProvider = DeleteSettlerProvider._();

final class DeleteSettlerProvider
    extends $FunctionalProvider<DeleteSettler, DeleteSettler, DeleteSettler>
    with $Provider<DeleteSettler> {
  DeleteSettlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteSettlerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteSettlerHash();

  @$internal
  @override
  $ProviderElement<DeleteSettler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteSettler create(Ref ref) {
    return deleteSettler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteSettler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteSettler>(value),
    );
  }
}

String _$deleteSettlerHash() => r'ae95ae6a0b3a04e9709c62052b34736a6f479a26';
