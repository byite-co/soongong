import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/contracts/billing_gateway.dart';
import 'package:soongong/core/domain/entities/entities.dart';
import 'package:soongong/core/domain/enums.dart';
import 'package:soongong/core/domain/ids.dart';
import 'package:soongong/core/domain/local_date.dart';

import 'db_test_helpers.dart';

void main() {
  late TestHarness h;

  setUp(() => h = TestHarness());
  tearDown(() => h.close());

  group('PlannerRepository', () {
    test('items by day include bands; updateItem uses Value patches; setDone',
        () async {
      final d = LocalDate.parse('2026-09-30');
      final todo = await h.planner.createItem(kind: PlannerKind.todo, title: '단어 30개', date: d, subjectId: 'eng', targetMinutes: 30);
      final study = await h.planner.createItem(kind: PlannerKind.study, title: '문제집', date: d, rangeText: 'p.10–20');
      final band = await h.planner.createItem(
        kind: PlannerKind.event,
        title: '중간고사',
        date: LocalDate.parse('2026-10-05'),
        bandStart: LocalDate.parse('2026-10-05'),
        bandEnd: LocalDate.parse('2026-10-08'),
      );
      expect(todo.sortOrder, 0);
      expect(study.sortOrder, 1);
      expect(study.readingRangeText, 'p.10–20');
      expect(todo.readingRangeText, '단어 30개');
      expect(band.isBand, isTrue);

      expect((await h.planner.watchItemsOn(d).first).map((i) => i.id), <String>[todo.id, study.id]);
      expect((await h.planner.watchItemsOn(LocalDate.parse('2026-10-07')).first).map((i) => i.id), <String>[band.id]);
      expect((await h.planner.getItemsBetween(LocalDate.parse('2026-10-01'), LocalDate.parse('2026-10-31'))).map((i) => i.id), <String>[band.id]);

      await h.planner.updateItem(todo.id, subjectId: const Value(null), targetMinutes: const Value(45), date: Value(LocalDate.parse('2026-10-01')));
      final moved = (await h.planner.getItem(todo.id))!;
      expect(moved.subjectId, isNull);
      expect(moved.targetMinutes, 45);
      expect(moved.date.key, '2026-10-01');
      expect(moved.title, '단어 30개', reason: 'absent fields untouched');

      await h.planner.setDone(todo.id, done: true);
      expect((await h.planner.getItem(todo.id))!.isDone, isTrue);
      expect((await h.planner.getItem(todo.id))!.doneAt, kT0);
      await h.planner.setDone(todo.id, done: false);
      expect((await h.planner.getItem(todo.id))!.doneAt, isNull);
      expect((await h.raw('planner_items', todo.id))!['client_rev'], 4);
    });

    test('recurrences: create / update / active flag / soft delete', () async {
      final r = await h.planner.createRecurrence(
        title: '학원',
        weekdayMask: Recurrence.maskOf(<int>[2, 4]),
        startTime: LocalTime.parse('19:00'),
        endTime: LocalTime.parse('21:00'),
        subjectId: 'math',
      );
      expect(r.occursOnWeekday(DateTime.tuesday), isTrue);
      expect(r.active, isTrue);
      await h.planner.updateRecurrence(r.id, endsOn: Value(LocalDate.parse('2026-12-31')), active: const Value(false));
      final u = (await h.planner.getRecurrence(r.id))!;
      expect(u.endsOn!.key, '2026-12-31');
      expect(u.active, isFalse);
      expect((await h.planner.getRecurrences()).length, 1);
      await h.planner.softDeleteRecurrence(r.id);
      expect(await h.planner.watchRecurrences().first, isEmpty);
      await h.planner.undoDeleteRecurrence(r.id);
      expect((await h.planner.watchRecurrences().first).length, 1);
    });
  });

  group('SettingsRepository', () {
    test('defaults, typed setters, ignored bad values, single row per key',
        () async {
      expect(await h.settings.get(), const AppSettings());
      await h.settings.setDailyGoalMinutes(180);
      await h.settings.setWeekStart(7);
      await h.settings.setNotifReviewTime(LocalTime.parse('21:30'));
      await h.settings.setTheme(ThemeSetting.dark);
      await h.settings.setSensitivityLevel(9);
      final s = await h.settings.watch().first;
      expect(s.dailyGoalMinutes, 180);
      expect(s.weekStart, 7);
      expect(s.notifReviewTime, LocalTime.parse('21:30'));
      expect(s.theme, ThemeSetting.dark);
      expect(s.sensitivityLevel, 2);
      expect(s.seatDetectionEnabled, isTrue);

      await h.settings.setDailyGoalMinutes(180); // unchanged → no write
      await h.settings.setDailyGoalMinutes(90);
      final rows = await h.db.select(h.db.settings).get();
      expect(rows.where((r) => r.key == SettingKeys.dailyGoalMinutes).length, 1);
      expect(rows.firstWhere((r) => r.key == SettingKeys.dailyGoalMinutes).clientRev, 2);
      await h.settings.setNotifReviewTime(null);
      expect((await h.settings.get()).notifReviewTime, isNull);
      expect(await h.settings.getRaw(SettingKeys.notifReviewTime), isNull);

      // Another device wrote the same key: the deterministic id makes the
      // pull replace our row instead of violating UNIQUE (user_id, key).
      final serverId = settingId('u1', SettingKeys.weekStart);
      expect((await h.raw('settings', serverId))!['value_json'], '7');
      await h.settings.applyServer(<Map<String, Object?>>[
        serverRow(serverId, userId: 'u1', content: <String, Object?>{'key': SettingKeys.weekStart, 'value_json': '"monday"'}),
      ]);
      expect((await h.settings.get()).weekStart, 1, reason: 'invalid value ignored → default');
      expect((await h.db.select(h.db.settings).get()).where((r) => r.key == SettingKeys.weekStart).length, 1);
    });
  });

  group('ledger caches (D18 · D16 · D24)', () {
    test('subscription: SDK keeps ledger grace; ledger overrides', () async {
      expect(await h.subscription.get(), isNull);
      await h.subscription.applyLedger(<String, Object?>{
        'status': 'grace',
        'entitled': true,
        'expires_at': '2026-09-01T00:00:00.000Z',
        'grace_expires_at': '2026-09-17T00:00:00.000Z',
        'period_type': 'NORMAL',
        'will_renew': true,
        'trial_used': true,
      });
      var s = (await h.subscription.watch().first)!;
      expect(s.status, EntitlementStatus.grace);
      expect(s.graceExpiresAt, DateTime.utc(2026, 9, 17));
      expect(s.source, SubscriptionSource.ledger);

      await h.subscription.applySdk(
        const Entitlement(status: EntitlementStatus.premium, entitled: true, trialUsed: true),
      );
      s = (await h.subscription.get())!;
      expect(s.status, EntitlementStatus.premium);
      expect(s.source, SubscriptionSource.sdk);
      expect(s.graceExpiresAt, DateTime.utc(2026, 9, 17), reason: 'ledger-only field kept');
      expect(s.lastCheckedAt, kT0);
      expect(await h.outbox(), isEmpty);
    });

    test('quota: ledger `limit` maps to quota_limit; remaining is derived', () async {
      expect(await h.quota.get('2026-09'), isNull);
      await h.quota.applyLedger(<String, Object?>{'month': '2026-09', 'used': 5, 'reserved': 1, 'limit': 20});
      final q = (await h.quota.watch('2026-09').first)!;
      expect(q.limit, 20);
      expect(q.remaining, 14);
      await h.quota.applyLedger(<String, Object?>{'month': '2026-09', 'used': 6, 'reserved': 0, 'quota_limit': 20});
      expect((await h.quota.get('2026-09'))!.used, 6);
      expect(await h.outbox(), isEmpty);
    });
  });

  group('ActivityRepository', () {
    test('touch is idempotent with a deterministic id (D24)', () async {
      final d = LocalDate.parse('2026-09-30');
      expect(await h.activity.touch(d), isTrue);
      expect(await h.activity.touch(d), isFalse);
      final rows = await h.activity.getAll();
      expect(rows.length, 1);
      expect(rows.single.date, d);
      expect((await h.outbox('activity_days')).length, 1);

      final other = TestHarness(userId: 'u1', deviceId: 'dev-b');
      addTearDown(other.close);
      await other.activity.touch(d);
      expect((await other.activity.getAll()).single.id, rows.single.id, reason: 'two devices agree');
      expect((await h.activity.watchBetween(d.addDays(-1), d).first).length, 1);
    });
  });
}
