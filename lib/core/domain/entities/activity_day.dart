import 'package:freezed_annotation/freezed_annotation.dart';

import '../local_date.dart';
import 'sync_stamp.dart';

part 'activity_day.freezed.dart';

/// `activity_days` (§2.15, D15). Deterministic id (uuid v5 of
/// `user_id|date`, D24) so two devices merge through CAS.
@freezed
abstract class ActivityDay with _$ActivityDay {
  const factory ActivityDay({
    required String id,
    required SyncStamp stamp,
    required LocalDate date,
  }) = _ActivityDay;
}
