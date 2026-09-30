// App-wide logger (CLAUDE.md §7: no `print`; never log PII, photo paths or
// camera frame data).

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger appLog = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 100,
    colors: false,
    printEmojis: false,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);
