// Deterministic ids (S02, D24). `activity_days.id` = uuid v5 so two devices
// produce the same row id for the same (user, date) and merge through CAS.

import 'package:uuid/uuid.dart';

import 'local_date.dart';

/// Namespace for `activity_days` (docs/data-model.md §2.15). Fixed forever.
const String activityDayNamespace = '6f0b3a2e-3c5b-4b7e-9a1d-2f4a8c1e5d70';

String activityDayId(String userId, LocalDate date) =>
    const Uuid().v5(activityDayNamespace, '$userId|${date.key}');

/// Namespace for `settings` rows (one row per (user, key); two devices must
/// produce the same id so a pull never violates `UNIQUE (user_id, key)`).
const String settingNamespace = '7a1c6d2b-0e4f-4c3a-8b5d-9e2f1a3c4d5e';

String settingId(String userId, String key) =>
    const Uuid().v5(settingNamespace, '$userId|$key');

String newUuid() => const Uuid().v4();
