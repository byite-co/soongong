// S09e regressions (GPT independent re-review of PR #8 at S09d head
// `ce92f25`): P1-2 an open `purge-all` request whose answer was lost was
// cleared by elapsed time (151 s, taken for "the Edge Function limit")
// although the server had given no verdict — now it is settled only by
// server evidence: the profile, or the same id re-sent (the server replays /
// supersedes it, never purges twice); P1-1 (client side of the receipts
// contract) a replayed or superseded answer carries the account's CURRENT
// epoch and the device converges forward, never back. The `repro` tests
// failed before the S09e fix (the intent was cleared, writes let through);
// the server-side P1-1 reproduction is pgTAP `10_purge_request.sql`, P3 is
// `photo_retention_test.dart` (a Windows-only failure).

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/data/auth/auth_gate.dart';
import 'package:soongong/data/auth/auth_models.dart';
import 'package:soongong/data/db/app_database.dart';
import 'package:soongong/data/repositories/local_purge.dart';
import 'package:soongong/data/repositories/repositories.dart';
import 'package:soongong/features/privacy/application/privacy_providers.dart';
import 'package:soongong/features/settings/application/settings_providers.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_auth_backend.dart';

const AuthSession kU1 = AuthSession(userId: 'u-1', email: 'a@x.io');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppHarness h;

  tearDown(() => h.dispose());

  Future<void> signedIn(FakeAuthBackend backend, {AppDatabase? db, DateTime? now}) async {
    h = AppHarness(backend: backend, db: db, now: now);
    h.container.listen(authGateProvider, (_, _) {});
    await h.settle(40);
    expect(h.container.read(currentUserIdProvider), 'u-1');
  }

  List<RecordedCall> sent(FakeAuthBackend b) => b.calls.where((c) => c.name == 'purge-all').toList();
  Future<PurgeStage> stage() async => (await h.container.read(localPurgeProvider).state()).stage;
  Future<int> epoch() => h.container.read(syncWriterProvider).purgeEpoch();

  group('P1-2 an open request is settled by server evidence only', () {
    test('repro: lost answer · profile unchanged · 151 s (and far more) later → the intent is kept and writes stay refused; the same id is re-sent, never a new one; served → done', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      final settings = h.container.read(settingsControllerProvider);
      backend.responses['purge-all'] = Exception('connection reset');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      final id = sent(backend).single.body['request_id'] as String;
      expect(sent(backend).single.body['expected_epoch'], 0, reason: 'formed against the profile epoch read right before');

      for (final step in const <Duration>[Duration(seconds: 151), Duration(seconds: 250), Duration(days: 10)]) {
        h.clock.advance(step);
        expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllUnconfirmed>(), reason: 'S09e: elapsed time ($step) is not evidence about the server');
        expect(await stage(), PurgeStage.requested);
        expect(await settings.setTheme(ThemeSetting.dark), isFalse, reason: 'the barrier holds');
      }
      expect(sent(backend).map((c) => c.body['request_id']).toSet(), <String>{id}, reason: 'every send carries the same id');
      expect(sent(backend).map((c) => c.body['expected_epoch']).toSet(), <int>{0});
      expect(sent(backend).length, 4, reason: 'one send per user action / recovery run — no loop');

      backend.responses['purge-all'] = <String, dynamic>{'epoch': 1, 'replayed': false, 'superseded': false};
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllDone>());
      expect(await stage(), PurgeStage.none);
      expect(await epoch(), 1);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
    });

    test('150 s response timeout, server success within 400 s: the profile settles it when the server is done — one purge, no extra send', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      backend.responses['purge-all'] = Exception('504 gateway timeout'); // the request idle timeout, not the worker's end
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      final id = sent(backend).single.body['request_id'] as String;
      h.clock.advance(const Duration(seconds: 151));
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllUnconfirmed>(), reason: 'still executing: the profile has no verdict yet');
      final sends = sent(backend).length;

      // the worker finishes at ~300 s: the profile carries our id and the new epoch
      h.clock.advance(const Duration(seconds: 150));
      backend.profileRow = <String, dynamic>{...kProfileRowOnboardingDone, 'purge_epoch': 1, 'purge_request_id': id};
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllDone>());
      expect(sent(backend).length, sends, reason: 'settled from the profile: nothing more sent');
      expect(await epoch(), 1);
      expect(await stage(), PurgeStage.none);
    });

    test('app restart with the request open (device clock moved back): the new process re-sends the same id and expected epoch', () async {
      final db = AppDatabase.inMemory();
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend, db: db);
      backend.responses['purge-all'] = Exception('connection reset');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      final id = sent(backend).single.body['request_id'] as String;
      await h.dispose(); // the process ends; the database (the open request) stays

      final backend2 = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      backend2.responses['purge-all'] = Exception('connection reset');
      await signedIn(backend2, db: db, now: kHarnessNow.subtract(const Duration(days: 1)));
      final settings = h.container.read(settingsControllerProvider);
      expect(await stage(), PurgeStage.requested, reason: 'the intent survived the restart');
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllUnconfirmed>());
      expect(sent(backend2).single.body, <String, dynamic>{'request_id': id, 'expected_epoch': 0}, reason: 'the stored id + epoch, not new ones');
      expect(await settings.setTheme(ThemeSetting.dark), isFalse);

      backend2.responses['purge-all'] = <String, dynamic>{'epoch': 1, 'replayed': true, 'superseded': false};
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllDone>(), reason: 'the server had served the first send: replay');
      expect(await stage(), PurgeStage.none);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
      await h.dispose();
      await db.close();
      h = AppHarness(backend: FakeAuthBackend()); // for the shared tearDown
    });

    test('confirmed rejection on the re-send (403) → intent cleared, writes resume, nothing more sent', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final settings = h.container.read(settingsControllerProvider);
      backend.responses['purge-all'] = Exception('connection reset');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      backend.responses['purge-all'] = const EdgeFunctionException(403, 'no_profile');
      expect(await h.container.read(privacyActionsProvider).resume(), isNull, reason: 'the server answered: not served');
      expect(await stage(), PurgeStage.none);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
      expect(await h.container.read(privacyActionsProvider).resume(), isNull);
      expect(sent(backend).length, 2);
    });

    test('offline when the user confirms: no request is formed — nothing stored, nothing sent, writes allowed', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      final settings = h.container.read(settingsControllerProvider);
      backend.profileError = Exception('offline');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllFailed>());
      expect(await stage(), PurgeStage.none);
      expect(sent(backend), isEmpty);
      expect(await settings.setTheme(ThemeSetting.dark), isTrue);
      expect(await h.container.read(privacyActionsProvider).resume(), isNull);
    });

    test('a request is formed against the profile epoch of that moment', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: <String, dynamic>{...kProfileRowOnboardingDone, 'purge_epoch': 4});
      await signedIn(backend);
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 5, 'replayed': false, 'superseded': false};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(sent(backend).single.body['expected_epoch'], 4);
      expect(await epoch(), 5);
    });
  });

  group('P1-1 client side: replay and superseded answers converge forward', () {
    test('a replayed answer carries the current epoch (2) although the request saw 0 → the device converges to 2', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      backend.responses['purge-all'] = Exception('connection reset');
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllUnconfirmed>());
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 2, 'replayed': true, 'superseded': false}; // R2 ran in between
      expect(await h.container.read(privacyActionsProvider).resume(), isA<DeleteAllDone>());
      expect(await epoch(), 2);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
    });

    test('a superseded answer (another purge ran after the profile read) completes the local purge at the current epoch — no new id', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      await h.container.read(subjectRepositoryProvider).create(name: '수학', colorIndex: 0);
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 7, 'replayed': false, 'superseded': true};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(await epoch(), 7);
      expect(await stage(), PurgeStage.none);
      expect(sent(backend).length, 1);
      expect((await h.container.read(subjectRepositoryProvider).getAll()).map((s) => s.isDefault), <bool>[true]);
    });

    test('the stored epoch never moves backwards: an answer with an older epoch leaves it where it is', () async {
      final backend = FakeAuthBackend(session: kU1, profileRow: kProfileRowOnboardingDone);
      await signedIn(backend);
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 9, 'replayed': false, 'superseded': false};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(await epoch(), 9);
      backend.responses['purge-all'] = <String, dynamic>{'epoch': 3, 'replayed': true, 'superseded': false};
      expect(await h.container.read(privacyActionsProvider).deleteAll(), isA<DeleteAllDone>());
      expect(await epoch(), 9, reason: 'clamped: the local generation is never rolled back');
      expect(await stage(), PurgeStage.none);
    });
  });
}
