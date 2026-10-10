// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settingsStream)
final settingsStreamProvider = SettingsStreamProvider._();

final class SettingsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppSettings>,
          AppSettings,
          Stream<AppSettings>
        >
    with $FutureModifier<AppSettings>, $StreamProvider<AppSettings> {
  SettingsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsStreamHash();

  @$internal
  @override
  $StreamProviderElement<AppSettings> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppSettings> create(Ref ref) {
    return settingsStream(ref);
  }
}

String _$settingsStreamHash() => r'72731dd2394562a903067ad16ea4a47c3f885e56';

/// `ThemeMode` for `MaterialApp` — system until the settings row loads.

@ProviderFor(appThemeMode)
final appThemeModeProvider = AppThemeModeProvider._();

/// `ThemeMode` for `MaterialApp` — system until the settings row loads.

final class AppThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  /// `ThemeMode` for `MaterialApp` — system until the settings row loads.
  AppThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return appThemeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appThemeModeHash() => r'8f68998a5c610738b18d04116b1ef846eaa9f5e1';

@ProviderFor(settingsEntitlement)
final settingsEntitlementProvider = SettingsEntitlementProvider._();

final class SettingsEntitlementProvider
    extends
        $FunctionalProvider<
          AsyncValue<Entitlement>,
          Entitlement,
          Stream<Entitlement>
        >
    with $FutureModifier<Entitlement>, $StreamProvider<Entitlement> {
  SettingsEntitlementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsEntitlementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsEntitlementHash();

  @$internal
  @override
  $StreamProviderElement<Entitlement> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Entitlement> create(Ref ref) {
    return settingsEntitlement(ref);
  }
}

String _$settingsEntitlementHash() =>
    r'890bbe26d04f82288aa9b760ef2753f62dad4112';

@ProviderFor(settingsWrongs)
final settingsWrongsProvider = SettingsWrongsProvider._();

final class SettingsWrongsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WrongItem>>,
          List<WrongItem>,
          Stream<List<WrongItem>>
        >
    with $FutureModifier<List<WrongItem>>, $StreamProvider<List<WrongItem>> {
  SettingsWrongsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsWrongsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsWrongsHash();

  @$internal
  @override
  $StreamProviderElement<List<WrongItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<WrongItem>> create(Ref ref) {
    return settingsWrongs(ref);
  }
}

String _$settingsWrongsHash() => r'c83eeeea3c067b131bd22be73f7da2ec14a5975c';

/// 요금제 row label — facts from the entitlement (D18) and the saved wrongs.

@ProviderFor(planLabel)
final planLabelProvider = PlanLabelProvider._();

/// 요금제 row label — facts from the entitlement (D18) and the saved wrongs.

final class PlanLabelProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 요금제 row label — facts from the entitlement (D18) and the saved wrongs.
  PlanLabelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planLabelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planLabelHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return planLabel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$planLabelHash() => r'ab8028c656a284723fdefeedf34d852e2ad5db57';

@ProviderFor(accountInfo)
final accountInfoProvider = AccountInfoProvider._();

final class AccountInfoProvider
    extends $FunctionalProvider<AccountInfo, AccountInfo, AccountInfo>
    with $Provider<AccountInfo> {
  AccountInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountInfoHash();

  @$internal
  @override
  $ProviderElement<AccountInfo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AccountInfo create(Ref ref) {
    return accountInfo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountInfo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountInfo>(value),
    );
  }
}

String _$accountInfoHash() => r'82e9217a680108d6113693c906677782a1eb39ed';

@ProviderFor(goalWindowSegments)
final goalWindowSegmentsProvider = GoalWindowSegmentsProvider._();

final class GoalWindowSegmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionSegment>>,
          List<SessionSegment>,
          Stream<List<SessionSegment>>
        >
    with
        $FutureModifier<List<SessionSegment>>,
        $StreamProvider<List<SessionSegment>> {
  GoalWindowSegmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalWindowSegmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalWindowSegmentsHash();

  @$internal
  @override
  $StreamProviderElement<List<SessionSegment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<SessionSegment>> create(Ref ref) {
    return goalWindowSegments(ref);
  }
}

String _$goalWindowSegmentsHash() =>
    r'fa71691188640c7a5503b54329e0208a8e0ff4e8';

@ProviderFor(settingsAllSessions)
final settingsAllSessionsProvider = SettingsAllSessionsProvider._();

final class SettingsAllSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudySession>>,
          List<StudySession>,
          Stream<List<StudySession>>
        >
    with
        $FutureModifier<List<StudySession>>,
        $StreamProvider<List<StudySession>> {
  SettingsAllSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsAllSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsAllSessionsHash();

  @$internal
  @override
  $StreamProviderElement<List<StudySession>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<StudySession>> create(Ref ref) {
    return settingsAllSessions(ref);
  }
}

String _$settingsAllSessionsHash() =>
    r'79f8ccac05dc49b0cfc94a11a7e0957b5f60aa9c';

/// Mean 순공 minutes per recorded day over the last 28 days, rounded to the
/// 30-minute step of the sheet; null when nothing was recorded.

@ProviderFor(goalSuggestionMinutes)
final goalSuggestionMinutesProvider = GoalSuggestionMinutesProvider._();

/// Mean 순공 minutes per recorded day over the last 28 days, rounded to the
/// 30-minute step of the sheet; null when nothing was recorded.

final class GoalSuggestionMinutesProvider
    extends $FunctionalProvider<int?, int?, int?>
    with $Provider<int?> {
  /// Mean 순공 minutes per recorded day over the last 28 days, rounded to the
  /// 30-minute step of the sheet; null when nothing was recorded.
  GoalSuggestionMinutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalSuggestionMinutesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalSuggestionMinutesHash();

  @$internal
  @override
  $ProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int? create(Ref ref) {
    return goalSuggestionMinutes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$goalSuggestionMinutesHash() =>
    r'91e83e588bb37d4c182db47618287cc9eb9796ce';

@ProviderFor(settingsController)
final settingsControllerProvider = SettingsControllerProvider._();

final class SettingsControllerProvider
    extends
        $FunctionalProvider<
          SettingsController,
          SettingsController,
          SettingsController
        >
    with $Provider<SettingsController> {
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  $ProviderElement<SettingsController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsController create(Ref ref) {
    return settingsController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsController>(value),
    );
  }
}

String _$settingsControllerHash() =>
    r'10ed54fc780b2b69425f0dc4a358e3d0b25c4527';
