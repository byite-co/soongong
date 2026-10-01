// Startup tasks (S02), run from bootstrap before the first frame:
//   1. D22 settlement of pending deletes (expired → commit, else restore)
//   2. dev flavor: default subject seed
//   3. D15 `activity_days` upsert for today
// A failure is logged and never blocks the app from starting.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/domain/local_date.dart';
import '../../core/logging/app_logger.dart';
import '../repositories/repositories.dart';
import '../seed/dev_seeder.dart';

Future<void> runStartupTasks(ProviderContainer container) async {
  try {
    final settled = await container.read(deleteSettlerProvider).settle();
    if (settled.toCommit.isNotEmpty || settled.toRestore.isNotEmpty) {
      appLog.i(
        'startup · pending deletes committed=${settled.toCommit.length} '
        'restored=${settled.toRestore.length}',
      );
    }
    if (AppConfig.isDev) {
      await container.read(devSeederProvider).seedSubjects();
    }
    final today = LocalDate.of(container.read(appClockProvider).now());
    await container.read(activityRepositoryProvider).touch(today);
  } catch (e, st) {
    appLog.e('startup tasks failed', error: e, stackTrace: st);
  }
}
