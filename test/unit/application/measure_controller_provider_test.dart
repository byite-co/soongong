// [S06c] The measurement controller follows the account: when the signed-in
// user changes, Riverpod rebuilds `measureControllerProvider` (through the
// repository chain → `currentUserIdProvider`), the old controller is
// disposed, and its late async work can no longer write into the database
// the new account owns (D27 wipe).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/providers.dart';
import 'package:soongong/core/domain/clock.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/auth/auth_mode.dart';
import 'package:soongong/data/repositories/repository_providers.dart';
import 'package:soongong/features/measure/application/measure_controller.dart';

import '../../helpers/measure_fakes.dart';
import '../data/db_test_helpers.dart';

class _User extends Notifier<String> {
  @override
  String build() => 'u1';
  void switchTo(String id) => state = id;
}

final _userProvider = NotifierProvider<_User, String>(_User.new);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestHarness h;
  late TestMeasureEngine engine;
  late ProviderContainer container;

  setUp(() {
    h = TestHarness(userId: 'u1');
    engine = TestMeasureEngine();
    container = ProviderContainer(
      overrides: [
        deviceIdProvider.overrideWithValue('dev-a'),
        appDatabaseProvider.overrideWithValue(h.db),
        appClockProvider.overrideWithValue(h.clock),
        authModeProvider.overrideWithValue(AuthMode.localOnly),
        currentUserIdProvider.overrideWith((ref) => ref.watch(_userProvider)),
        seatEngineProvider.overrideWithValue(engine),
        measureDeviceProvider.overrideWithValue(TestMeasureDevice()),
        sleepAwareClockProvider.overrideWithValue(FakeSleepAwareClock()),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await engine.close();
    await h.close();
  });

  test('account switch rebuilds the controller, disposes the old one and blocks its late save', () async {
    final a = container.read(measureControllerProvider);
    expect(await a.start(mode: SessionMode.manual), isTrue);
    final id = a.sessionId!;
    await a.finish();
    expect((await h.sessions.get(id))!.status, SessionStatus.interrupted);

    // u2 signs in: AccountBinding wipes the database, the providers rebuild.
    await h.db.wipeAll();
    container.read(_userProvider.notifier).switchTo('u2');
    final b = container.read(measureControllerProvider);
    expect(identical(a, b), isFalse);
    expect(a.isDisposed, isTrue);
    expect(b.isDisposed, isFalse);

    // The old account's summary was still open: its save must not land in
    // u2's database (it would be pushed to the server as u2).
    expect(await a.save(), isFalse);
    expect(await h.sessions.getAll(), isEmpty, reason: 'u1 rows: nothing re-inserted');
    final rows = await h.db.customSelect('SELECT user_id FROM sessions').get();
    expect(rows, isEmpty);
    expect(await h.sessions.readSnapshot(), isNull);

    // The new controller measures for u2 as usual.
    expect(await b.start(mode: SessionMode.manual), isTrue);
    final u2 = await h.db.customSelect('SELECT user_id FROM sessions').get();
    expect(u2.map((r) => r.read<String>('user_id')), ['u2']);
  });
}
