// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_scheduler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_settings)
final _settingsProvider = _SettingsProvider._();

final class _SettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppSettings>,
          AppSettings,
          Stream<AppSettings>
        >
    with $FutureModifier<AppSettings>, $StreamProvider<AppSettings> {
  _SettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_settingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_settingsHash();

  @$internal
  @override
  $StreamProviderElement<AppSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppSettings> create(Ref ref) {
    return _settings(ref);
  }
}

String _$_settingsHash() => r'778d30a616b127f9d3d063415a87f159609ffb15';

@ProviderFor(_recurrences)
final _recurrencesProvider = _RecurrencesProvider._();

final class _RecurrencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Recurrence>>,
          List<Recurrence>,
          Stream<List<Recurrence>>
        >
    with $FutureModifier<List<Recurrence>>, $StreamProvider<List<Recurrence>> {
  _RecurrencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_recurrencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_recurrencesHash();

  @$internal
  @override
  $StreamProviderElement<List<Recurrence>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Recurrence>> create(Ref ref) {
    return _recurrences(ref);
  }
}

String _$_recurrencesHash() => r'0b34d4bd8520d1214b78d67579a27b47014eae08';

@ProviderFor(_queue)
final _queueProvider = _QueueProvider._();

final class _QueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReviewEntry>>,
          List<ReviewEntry>,
          Stream<List<ReviewEntry>>
        >
    with
        $FutureModifier<List<ReviewEntry>>,
        $StreamProvider<List<ReviewEntry>> {
  _QueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_queueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_queueHash();

  @$internal
  @override
  $StreamProviderElement<List<ReviewEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ReviewEntry>> create(Ref ref) {
    return _queue(ref);
  }
}

String _$_queueHash() => r'89f77d26405229c59ccf81c6a93b6586a7b97c27';

@ProviderFor(_entitlement)
final _entitlementProvider = _EntitlementProvider._();

final class _EntitlementProvider
    extends
        $FunctionalProvider<
          AsyncValue<Entitlement>,
          Entitlement,
          Stream<Entitlement>
        >
    with $FutureModifier<Entitlement>, $StreamProvider<Entitlement> {
  _EntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_entitlementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_entitlementHash();

  @$internal
  @override
  $StreamProviderElement<Entitlement> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Entitlement> create(Ref ref) {
    return _entitlement(ref);
  }
}

String _$_entitlementHash() => r'9936e2aa1809d585f218324881b4ddcb9b948298';

@ProviderFor(notificationScheduler)
final notificationSchedulerProvider = NotificationSchedulerProvider._();

final class NotificationSchedulerProvider
    extends
        $FunctionalProvider<
          NotificationScheduler,
          NotificationScheduler,
          NotificationScheduler
        >
    with $Provider<NotificationScheduler> {
  NotificationSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSchedulerHash();

  @$internal
  @override
  $ProviderElement<NotificationScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationScheduler create(Ref ref) {
    return notificationScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationScheduler>(value),
    );
  }
}

String _$notificationSchedulerHash() =>
    r'fee5e869b34aa2087070ac2dac4a5b24a5ab95cf';

/// Device permission as last read; `refresh()` after the user returns from
/// the OS settings, `request()` from the sheet.

@ProviderFor(NotificationPermissionState)
final notificationPermissionStateProvider =
    NotificationPermissionStateProvider._();

/// Device permission as last read; `refresh()` after the user returns from
/// the OS settings, `request()` from the sheet.
final class NotificationPermissionStateProvider
    extends
        $NotifierProvider<NotificationPermissionState, NotificationPermission> {
  /// Device permission as last read; `refresh()` after the user returns from
  /// the OS settings, `request()` from the sheet.
  NotificationPermissionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPermissionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPermissionStateHash();

  @$internal
  @override
  NotificationPermissionState create() => NotificationPermissionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationPermission value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationPermission>(value),
    );
  }
}

String _$notificationPermissionStateHash() =>
    r'4cb3cf9e13011ee80b85676e05c0bacaa44b9885';

/// Device permission as last read; `refresh()` after the user returns from
/// the OS settings, `request()` from the sheet.

abstract class _$NotificationPermissionState
    extends $Notifier<NotificationPermission> {
  NotificationPermission build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<NotificationPermission, NotificationPermission>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotificationPermission, NotificationPermission>,
              NotificationPermission,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
