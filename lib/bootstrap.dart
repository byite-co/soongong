// bootstrap (S01 · S02): ProviderContainer, logger, deviceId (secure
// storage), error handlers, startup tasks (D22 settlement · dev seed · D15
// activity day). Called from main.dart.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/contracts/providers.dart';
import 'core/logging/app_logger.dart';
import 'core/utils/device_id.dart';
import 'data/startup/startup_tasks.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    appLog.e(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    appLog.e('Uncaught error', error: error, stackTrace: stack);
    return true;
  };

  final deviceId = await DeviceIdStore().getOrCreate();

  appLog.i(
    'bootstrap · flavor=${AppConfig.flavor.name} '
    'devTools=${AppConfig.devToolsEnabled} '
    'backend=${AppConfig.hasBackendConfig} '
    'mode=${kReleaseMode ? 'release' : kProfileMode ? 'profile' : 'debug'}',
  );

  final container = ProviderContainer(
    overrides: [deviceIdProvider.overrideWithValue(deviceId)],
  );
  await runStartupTasks(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SoongongApp(),
    ),
  );
}
