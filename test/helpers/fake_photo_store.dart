// S09b: a PhotoStore whose deletes fail for chosen paths (device photo
// deletion failure paths: 모든 기록 삭제 · 로그아웃 · 계정 삭제 · 목록 삭제).

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
