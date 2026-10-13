import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../repositories/repository_providers.dart';
import 'legacy_temp_probe.dart';
import 'owned_temp_store.dart';
import 'temp_ownership.dart';

final ownedTempStoreProvider = Provider<OwnedTempStore>(
  (ref) => OwnedTempStore(
    () async {
      final temporary = await getTemporaryDirectory();
      return Directory(p.join(temporary.path, 'soongong-owned-v1'));
    },
    legacyClean: LegacyTempProbe(
      getTemporaryDirectory,
      android: Platform.isAndroid,
    ).isClean,
  ),
);

final tempOwnershipProvider = Provider<TempOwnership>((ref) {
  final ownership = TempOwnership(
    ref.watch(appDatabaseProvider),
    ref.watch(ownedTempStoreProvider),
  );
  ref.onDispose(ownership.dispose);
  return ownership;
});

final tempInvalidationProvider = StreamProvider<String>(
  (ref) => ref.watch(tempOwnershipProvider).invalidations,
);
