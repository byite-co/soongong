import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/utils/device_id.dart';

void main() {
  test('creates a uuid v4 once and returns the same id afterwards', () async {
    final store = InMemoryKeyValueStore();
    final ids = DeviceIdStore(store: store);
    final first = await ids.getOrCreate();
    final second = await ids.getOrCreate();
    expect(first, second);
    expect(
      first,
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
    );
    expect(await store.read(DeviceIdStore.key), first);
  });

  test('falls back to a volatile id when storage throws', () async {
    final ids = DeviceIdStore(store: _ThrowingStore());
    final id = await ids.getOrCreate();
    expect(id, isNotEmpty);
  });
}

class _ThrowingStore implements SecureKeyValueStore {
  @override
  Future<String?> read(String key) async => throw StateError('no keychain');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('no keychain');
}
