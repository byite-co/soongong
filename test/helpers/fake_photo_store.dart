// S09b: a PhotoStore whose deletes fail for chosen paths (device photo
// deletion failure paths: 모든 기록 삭제 · 로그아웃 · 계정 삭제 · 목록 삭제).

import 'dart:async';

import 'package:soongong/data/photos/photo_store.dart';

class FailingPhotoStore extends PhotoStore {
  FailingPhotoStore(super.root, {Set<String> failing = const <String>{}}) : failing = <String>{...failing};

  /// Relative paths whose deletion reports failure (file untouched).
  final Set<String> failing;

  @override
  Future<bool> delete(String relativePath) async {
    if (failing.contains(relativePath)) return false;
    return super.delete(relativePath);
  }
}

/// S09c: a PhotoStore whose delete of a chosen path waits until the test
/// releases it — the caller (a wipe inside an owned transaction) then holds
/// the database lock while the test queues another write behind it.
class GatedPhotoStore extends PhotoStore {
  GatedPhotoStore(super.root);

  final Map<String, PhotoGate> _gates = <String, PhotoGate>{};

  /// Holds the next delete of [relativePath] until [PhotoGate.release].
  PhotoGate hold(String relativePath) => _gates[relativePath] = PhotoGate();

  @override
  Future<bool> delete(String relativePath) async {
    final g = _gates.remove(relativePath);
    if (g != null) {
      g._entered.complete();
      await g._release.future;
    }
    return super.delete(relativePath);
  }
}

class PhotoGate {
  final Completer<void> _entered = Completer<void>();
  final Completer<void> _release = Completer<void>();

  /// Completes when the held delete was reached.
  Future<void> get entered => _entered.future;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }
}
