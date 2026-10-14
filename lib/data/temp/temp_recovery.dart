import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../photos/owned_picker_coordinator.dart';
import 'owned_temp_store.dart';
import 'temp_providers.dart';

Future<TempCleanupResult> recoverTemporaryFiles(Ref ref) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final state = await ref.read(ownedPickerCoordinatorProvider).recover();
    if (state == PickerRecoveryState.unavailable) {
      return const TempCleanupResult(unknown: true);
    }
  }
  return ref.read(ownedTempStoreProvider).sweep();
}

Future<TempCleanupResult> recoverTemporaryFilesAtStartup(
  ProviderContainer container,
) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final state = await container
        .read(ownedPickerCoordinatorProvider)
        .recover();
    if (state == PickerRecoveryState.unavailable) {
      return const TempCleanupResult(unknown: true);
    }
  }
  return container.read(ownedTempStoreProvider).sweep();
}
