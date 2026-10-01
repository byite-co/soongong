import 'package:freezed_annotation/freezed_annotation.dart';

import 'sync_stamp.dart';

part 'subject.freezed.dart';

/// `subjects` (docs/data-model.md §2.1). [colorIndex] 0–7 always shown with
/// the name (never colour alone).
@freezed
abstract class Subject with _$Subject {
  const factory Subject({
    required String id,
    required SyncStamp stamp,
    required String name,
    required int colorIndex,
    required int sortOrder,
    @Default(false) bool isDefault,
  }) = _Subject;
}
