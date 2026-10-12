// Contract providers (S01). Every provider currently returns the Fake; the
// implementing sessions (S04 SeatEngine · S06 ReadingEngine · S12
// BillingGateway · S13 SyncEngine) replace the body or override the provider
// in bootstrap — the provider names are the stable seam.
//
// S04: `seatEngineProvider` returns the real camera engine in the prod
// flavor, and in dev whenever the dev menu's "구현: 실제 카메라" switch is on
// (default Fake, so emulators, widget tests and other sessions keep working
// without a camera).

import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderListenableSelect;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/engines/seat_engine_impl.dart';
import '../../data/network/connectivity_network_status.dart';
import '../../data/notifications/local_notification_gateway.dart';
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
  final useReal = AppConfig.isProd ||
      ref.watch(devFakeSettingsControllerProvider.select((s) => s.seatReal));
  if (useReal) {
    final engine = SeatEngineImpl.camera();
    ref.onDispose(engine.dispose);
    return engine;
  }
  final fake = FakeSeatEngine();
  ref.listen<DevFakeSettings>(
    devFakeSettingsControllerProvider,
    (_, s) {
      fake
        ..scenario = s.seat
        ..afterSeconds = s.seatAfterSeconds;
    },
    fireImmediately: true,
  );
  ref.onDispose(fake.dispose);
  return fake;
}

@Riverpod(keepAlive: true)
ReadingEngine readingEngine(Ref ref) {
  final fake = FakeReadingEngine();
  ref.listen<DevFakeSettings>(
    devFakeSettingsControllerProvider,
    (_, s) {
      fake
        ..scenario = s.reading
        ..delay = Duration(milliseconds: s.delayMs);
    },
    fireImmediately: true,
  );
  return fake;
}

@Riverpod(keepAlive: true)
BillingGateway billingGateway(Ref ref) {
  final fake = FakeBillingGateway();
  ref.listen<DevFakeSettings>(
    devFakeSettingsControllerProvider,
    (prev, s) {
      fake.delay = Duration(milliseconds: s.delayMs);
      if (prev == null || prev.billing != s.billing) fake.force(s.billing);
    },
    fireImmediately: true,
  );
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
  ref.listen<DevFakeSettings>(
    devFakeSettingsControllerProvider,
    (_, s) {
      fake
        ..delay = Duration(milliseconds: s.delayMs)
        ..offline = s.syncOffline;
    },
    fireImmediately: true,
  );
  ref.onDispose(fake.dispose);
  return fake;
}

/// S09b: device network state (문의 전송 비활성). Tests override with
/// `FakeNetworkStatus`.
@Riverpod(keepAlive: true)
NetworkStatus networkStatus(Ref ref) => ConnectivityNetworkStatus();
