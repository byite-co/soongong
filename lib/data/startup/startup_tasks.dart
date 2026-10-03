// Startup tasks (S02), run from bootstrap before the first frame:
//   1. D22 settlement of pending deletes (expired → commit, else restore)
//   2. dev flavor: default subject seed
//   3. D15 `activity_days` upsert for today
// A failure is logged and never blocks the app from starting.
// S05: when nobody is signed in (gate, consent, onboarding pending) the user
// writes (settlement · activity day) are skipped — they run after login.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/domain/local_date.dart';
import '../../core/logging/app_logger.dart';
import '../auth/auth_gate.dart';
import '../repositories/repositories.dart';
import '../seed/dev_seeder.dart';

Future<void> runStartupTasks(ProviderContainer container) async {
  try {
    if (AppConfig.isDev) {
      await container.read(devSeederProvider).seedSubjects();
    }
    if (!container.read(authGateProvider).hasUser) {
      appLog.i('startup · no signed-in user, user writes deferred');
      return;
    }
    final settled = await container.read(deleteSettlerProvider).settle();
    if (settled.toCommit.isNotEmpty || settled.toRestore.isNotEmpty) {
      appLog.i(
        'startup · pending deletes committed=${settled.toCommit.length} '
        'restored=${settled.toRestore.length}',
      );
    }
    final today = LocalDate.of(container.read(appClockProvider).now());
    await container.read(activityRepositoryProvider).touch(today);
  } catch (e, st) {
    appLog.e('startup tasks failed', error: e, stackTrace: st);
  }
}
