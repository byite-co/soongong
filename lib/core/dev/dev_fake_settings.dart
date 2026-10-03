// Fake scenario settings chosen in the dev menu (S01). freezed + json so the
// codegen pipeline is exercised end-to-end.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../contracts/billing_gateway.dart';
import '../contracts/fakes/fakes.dart';

part 'dev_fake_settings.freezed.dart';
part 'dev_fake_settings.g.dart';

@freezed
abstract class DevFakeSettings with _$DevFakeSettings {
  const factory DevFakeSettings({
    @Default(FakeSeatScenario.alwaysSeated) FakeSeatScenario seat,
    @Default(10) int seatAfterSeconds,

    /// S04: `true` → `seatEngineProvider` returns the real camera engine
    /// (dev flavor only; prod always uses the real engine).
    @Default(false) bool seatReal,
    @Default(FakeReadingScenario.success) FakeReadingScenario reading,
    @Default(600) int delayMs,
    @Default(EntitlementStatus.free) EntitlementStatus billing,
    @Default(false) bool syncOffline,
  }) = _DevFakeSettings;

  factory DevFakeSettings.fromJson(Map<String, dynamic> json) =>
      _$DevFakeSettingsFromJson(json);
}

@Riverpod(keepAlive: true)
class DevFakeSettingsController extends _$DevFakeSettingsController {
  @override
  DevFakeSettings build() => const DevFakeSettings();

  void setSeat(FakeSeatScenario s) => state = state.copyWith(seat: s);
  void setSeatAfterSeconds(int s) => state = state.copyWith(seatAfterSeconds: s);
  void setSeatReal(bool v) => state = state.copyWith(seatReal: v);
  void setReading(FakeReadingScenario s) => state = state.copyWith(reading: s);
  void setDelayMs(int ms) => state = state.copyWith(delayMs: ms);
  void setBilling(EntitlementStatus s) => state = state.copyWith(billing: s);
  void setSyncOffline(bool v) => state = state.copyWith(syncOffline: v);
}
