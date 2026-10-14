// Contract providers (S01). Every provider currently returns the Fake; the
// implementing sessions (S04 SeatEngine · S06 ReadingEngine · S12
// BillingGateway · S13 SyncEngine) replace the body or override the provider
// in bootstrap — the provider names are the stable seam.
//
// S04: `seatEngineProvider` returns the real camera engine in the prod
// flavor, and in dev whenever the dev menu's "구현: 실제 카메라" switch is on
// (default Fake, so emulators, widget tests and other sessions keep working
// without a camera).

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth/auth_gate.dart';
import '../../data/engines/remote_reading_engine.dart';
import '../../data/engines/seat_engine_impl.dart';
import '../../data/network/connectivity_network_status.dart';
import '../../data/notifications/local_notification_gateway.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/temp/temp_providers.dart';
import '../config/app_config.dart';
import '../dev/dev_fake_settings.dart';
import 'contracts.dart';
import 'fakes/fakes.dart';

part 'providers.g.dart';

/// deviceId (uuid v4) — overridden with the real value in bootstrap.dart.
@Riverpod(keepAlive: true)
String deviceId(Ref ref) =>
    throw UnimplementedError('deviceIdProvider is overridden in bootstrap()');

@Riverpod(keepAlive: true)
SeatEngine seatEngine(Ref ref) {
  final useReal =
      AppConfig.isProd ||
      ref.watch(devFakeSettingsControllerProvider.select((s) => s.seatReal));
  if (useReal) {
    final engine = SeatEngineImpl.camera();
    ref.onDispose(engine.dispose);
    return engine;
  }
  final fake = FakeSeatEngine();
  ref.listen<DevFakeSettings>(devFakeSettingsControllerProvider, (_, s) {
    fake
      ..scenario = s.seat
      ..afterSeconds = s.seatAfterSeconds;
  }, fireImmediately: true);
  ref.onDispose(fake.dispose);
  return fake;
}

@Riverpod(keepAlive: true)
ReadingEngine readingEngine(Ref ref) {
  if (!AppConfig.devOcrEnabled || !AppConfig.hasBackendConfig) {
    return const UnavailableReadingEngine();
  }
  final reading = ref.watch(readingRepositoryProvider);
  final wrongs = ref.watch(wrongsRepositoryProvider);
  final ownership = ref.watch(tempOwnershipProvider);
  var alive = true;
  ref.onDispose(() => alive = false);
  bool current() {
    if (!alive) return false;
    final gate = ref.read(authGateProvider);
    return gate is AuthGateSignedIn &&
        gate.profile?.readingConsentActive == true;
  }

  return RemoteReadingEngine.client(
    Supabase.instance.client,
    reading,
    wrongs,
    alive: current,
    ownsFile: (path) => ownership.ownsFile(reading.writer, path),
  );
}

@Riverpod(keepAlive: true)
BillingGateway billingGateway(Ref ref) {
  final fake = FakeBillingGateway();
  ref.listen<DevFakeSettings>(devFakeSettingsControllerProvider, (prev, s) {
    fake.delay = Duration(milliseconds: s.delayMs);
    if (prev == null || prev.billing != s.billing) fake.force(s.billing);
  }, fireImmediately: true);
  ref.onDispose(fake.dispose);
  return fake;
}

/// S09: the device notification gateway. The real plugin-backed gateway is
/// the default (dev builds on devices get real notifications); widget tests
/// override this provider with `FakeNotificationGateway`.
@Riverpod(keepAlive: true)
NotificationGateway notificationGateway(Ref ref) => LocalNotificationGateway();

@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final fake = FakeSyncEngine();
  ref.listen<DevFakeSettings>(devFakeSettingsControllerProvider, (_, s) {
    fake
      ..delay = Duration(milliseconds: s.delayMs)
      ..offline = s.syncOffline;
  }, fireImmediately: true);
  ref.onDispose(fake.dispose);
  return fake;
}

/// S09b: device network state (문의 전송 비활성). Tests override with
/// `FakeNetworkStatus`.
@Riverpod(keepAlive: true)
NetworkStatus networkStatus(Ref ref) => ConnectivityNetworkStatus();
