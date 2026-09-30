// Contract providers (S01). Every provider currently returns the Fake; the
// implementing sessions (S04 SeatEngine · S06 ReadingEngine · S12
// BillingGateway · S13 SyncEngine) replace the body or override the provider
// in bootstrap — the provider names are the stable seam.

import 'package:riverpod_annotation/riverpod_annotation.dart';

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
