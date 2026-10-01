// WriteContext (S02): what every user write needs — the current user, this
// device, a clock and an id generator. Provided by `writeContextProvider`.

import '../../core/domain/clock.dart';
import '../../core/domain/ids.dart';

class WriteContext {
  const WriteContext({
    required this.userId,
    required this.deviceId,
    this.clock = const SystemClock(),
    this.newId = newUuid,
  });

  final String userId;
  final String deviceId;
  final Clock clock;
  final String Function() newId;

  /// Current time in UTC (the DB stores UTC only).
  DateTime nowUtc() => clock.now().toUtc();
}
