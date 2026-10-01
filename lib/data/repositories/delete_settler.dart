// DeleteSettler (S02, D22): on app start, commit the pending deletes whose
// 5-second window has passed and restore the rest. No toast is re-shown.

import 'package:drift/drift.dart';

import '../../core/domain/delete_policy.dart';
import '../db/app_database.dart';
import 'planner_repository.dart';
import 'session_repository.dart';
import 'subject_repository.dart';
import 'write_context.dart';

class DeleteSettler {
  DeleteSettler({
    required this.db,
    required this.ctx,
    required this.subjects,
    required this.sessions,
    required this.planner,
  });

  final AppDatabase db;
  final WriteContext ctx;
  final SubjectRepository subjects;
  final SessionRepository sessions;
  final PlannerRepository planner;

  static const DeletePolicy _policy = DeletePolicy();

  Future<List<PendingDelete>> pending() async {
    final out = <PendingDelete>[];
    for (final table in <TableInfo<Table, Object?>>[
      db.subjects,
      db.sessions,
      db.plannerItems,
      db.recurrences,
    ]) {
      final rows = await db
          .customSelect(
            'SELECT id, pending_delete_until FROM "${table.actualTableName}" '
            'WHERE pending_delete_until IS NOT NULL AND deleted_at IS NULL',
            readsFrom: {table},
          )
          .get();
      for (final r in rows) {
        out.add(
          PendingDelete(
            table: table.actualTableName,
            id: r.read<String>('id'),
            pendingDeleteUntil: DateTime.parse(r.read<String>('pending_delete_until')),
          ),
        );
      }
    }
    return out;
  }

  Future<DeleteSettlement> settle({DateTime? now}) async {
    final at = (now ?? ctx.nowUtc()).toUtc();
    final settlement = _policy.settle(await pending(), at);
    for (final p in settlement.toCommit) {
      await _commit(p);
    }
    for (final p in settlement.toRestore) {
      await _restore(p);
    }
    return settlement;
  }

  Future<void> _commit(PendingDelete p) => switch (p.table) {
        'subjects' => subjects.commitDelete(p.id),
        'sessions' => sessions.commitDelete(p.id),
        'planner_items' => planner.commitDeleteItem(p.id),
        'recurrences' => planner.commitDeleteRecurrence(p.id),
        _ => Future<void>.value(),
      };

  Future<void> _restore(PendingDelete p) => switch (p.table) {
        'subjects' => subjects.undoDelete(p.id),
        'sessions' => sessions.undoDelete(p.id),
        'planner_items' => planner.undoDeleteItem(p.id),
        'recurrences' => planner.undoDeleteRecurrence(p.id),
        _ => Future<void>.value(),
      };
}
