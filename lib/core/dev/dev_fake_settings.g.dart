// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dev_fake_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DevFakeSettings _$DevFakeSettingsFromJson(Map<String, dynamic> json) =>
    _DevFakeSettings(
      seat:
          $enumDecodeNullable(_$FakeSeatScenarioEnumMap, json['seat']) ??
          FakeSeatScenario.alwaysSeated,
      seatAfterSeconds: (json['seatAfterSeconds'] as num?)?.toInt() ?? 10,
      seatReal: json['seatReal'] as bool? ?? false,
      reading:
          $enumDecodeNullable(_$FakeReadingScenarioEnumMap, json['reading']) ??
          FakeReadingScenario.success,
      delayMs: (json['delayMs'] as num?)?.toInt() ?? 600,
      billing:
          $enumDecodeNullable(_$EntitlementStatusEnumMap, json['billing']) ??
          EntitlementStatus.free,
      syncOffline: json['syncOffline'] as bool? ?? false,
    );

Map<String, dynamic> _$DevFakeSettingsToJson(_DevFakeSettings instance) =>
    <String, dynamic>{
      'seat': _$FakeSeatScenarioEnumMap[instance.seat]!,
      'seatAfterSeconds': instance.seatAfterSeconds,
      'seatReal': instance.seatReal,
      'reading': _$FakeReadingScenarioEnumMap[instance.reading]!,
      'delayMs': instance.delayMs,
      'billing': _$EntitlementStatusEnumMap[instance.billing]!,
      'syncOffline': instance.syncOffline,
    };

const _$FakeSeatScenarioEnumMap = {
  FakeSeatScenario.alwaysSeated: 'alwaysSeated',
  FakeSeatScenario.awayAfter: 'awayAfter',
  FakeSeatScenario.lostAfter: 'lostAfter',
  FakeSeatScenario.permissionDenied: 'permissionDenied',
  FakeSeatScenario.cameraBusy: 'cameraBusy',
};

const _$FakeReadingScenarioEnumMap = {
  FakeReadingScenario.success: 'success',
  FakeReadingScenario.successZeroWrong: 'successZeroWrong',
  FakeReadingScenario.takingLongThenSuccess: 'takingLongThenSuccess',
  FakeReadingScenario.fail: 'fail',
  FakeReadingScenario.sendFail: 'sendFail',
  FakeReadingScenario.cancelRace: 'cancelRace',
  FakeReadingScenario.saveConflict: 'saveConflict',
};

const _$EntitlementStatusEnumMap = {
  EntitlementStatus.free: 'free',
  EntitlementStatus.trial: 'trial',
  EntitlementStatus.premium: 'premium',
  EntitlementStatus.cancelPending: 'cancelPending',
  EntitlementStatus.grace: 'grace',
  EntitlementStatus.expired: 'expired',
  EntitlementStatus.pendingApproval: 'pendingApproval',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DevFakeSettingsController)
final devFakeSettingsControllerProvider = DevFakeSettingsControllerProvider._();

final class DevFakeSettingsControllerProvider
    extends $NotifierProvider<DevFakeSettingsController, DevFakeSettings> {
  DevFakeSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devFakeSettingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devFakeSettingsControllerHash();

  @$internal
  @override
  DevFakeSettingsController create() => DevFakeSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DevFakeSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DevFakeSettings>(value),
    );
  }
}

String _$devFakeSettingsControllerHash() =>
    r'bba5494bc88374cc4bf3948048df905350ac82dd';

abstract class _$DevFakeSettingsController extends $Notifier<DevFakeSettings> {
  DevFakeSettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DevFakeSettings, DevFakeSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DevFakeSettings, DevFakeSettings>,
              DevFakeSettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
