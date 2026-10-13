import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soongong/data/photos/owned_picker_coordinator.dart';
import 'package:soongong/data/temp/owned_temp_store.dart';

const _scopeA = '20000000-0000-4000-8000-000000000001';
const _scopeB = '20000000-0000-4000-8000-000000000002';
const _channel = MethodChannel('co.byite.soongong/picker_owner');

class _Picker extends ImagePicker {
  Future<LostDataResponse> Function()? lost;
  Future<XFile?> Function()? select;
  int lostCalls = 0;
  int picks = 0;
  @override
  Future<LostDataResponse> retrieveLostData() async {
    lostCalls++;
    return lost == null ? LostDataResponse.empty() : lost!();
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    picks++;
    expect(requestFullMetadata, isFalse);
    return select?.call();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory sandbox;
  late Directory root;
  late OwnedTempStore store;
  late _Picker picker;
  late OwnedPickerCoordinator coordinator;
  late OwnedTempTask current;
  final methods = <String>[];
  Future<OwnedTempTask> create() async =>
      current = await store.create(_scopeB, 'picker');
  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('owned-picker-');
    root = Directory('${sandbox.path}/soongong-owned-v1')..createSync();
    store = OwnedTempStore(() async => root);
    picker = _Picker();
    methods.clear();
    coordinator = OwnedPickerCoordinator(
      store: store,
      picker: picker,
      android: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          methods.add(call.method);
          return switch (call.method) {
            'recover' ||
            'cancel' ||
            'status' => {'active': false, 'unknown': false},
            _ => null,
          };
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    sandbox.deleteSync(recursive: true);
  });

  for (final mode in ['none', 'multiple', 'exception']) {
    test(
      'PICK-05 single joined recovery consumes $mode without reading or restoring bytes',
      () async {
        final external = File('${sandbox.path}/original.jpg')
          ..writeAsBytesSync([9]);
        picker.lost = () async => switch (mode) {
          'none' => LostDataResponse.empty(),
          'multiple' => LostDataResponse(
            files: [XFile(external.path), XFile('${sandbox.path}/missing.jpg')],
          ),
          _ => LostDataResponse(
            exception: PlatformException(code: 'synthetic'),
          ),
        };
        final first = coordinator.recover();
        final second = coordinator.recover();
        expect(identical(first, second), isTrue);
        expect(
          await first,
          mode == 'none'
              ? PickerRecoveryState.none
              : PickerRecoveryState.reselect,
        );
        expect(await second, isNot(PickerRecoveryState.unavailable));
        expect(picker.lostCalls, 1);
        expect(picker.picks, 0);
        expect(external.readAsBytesSync(), [9]);
        expect(methods.where((m) => m == 'recover'), hasLength(1));
      },
    );
  }

  test(
    'PICK-05 thrown recovery is explicit and retries without a new selection',
    () async {
      picker.lost = () async => throw PlatformException(code: 'synthetic');
      expect(await coordinator.recover(), PickerRecoveryState.unavailable);
      picker.lost = () async => LostDataResponse.empty();
      expect(await coordinator.recover(), PickerRecoveryState.none);
      expect(picker.lostCalls, 2);
      expect(picker.picks, 0);
    },
  );

  for (final oldGeneration in [false, true]) {
    test(
      'PICK-06/07 restart discards ${oldGeneration ? 'purged generation' : 'account A'} before B selection',
      () async {
        final prior = OwnedTempStore(() async => root);
        final abandoned = await prior.create(_scopeA, 'picker');
        final photo = abandoned.file('photo.jpg')..writeAsBytesSync([1]);
        if (oldGeneration) await prior.markRevoked(_scopeA);
        picker.lost = () async => LostDataResponse(files: [XFile(photo.path)]);
        expect(await coordinator.recover(), PickerRecoveryState.reselect);
        expect(photo.existsSync(), isFalse);
        expect(picker.picks, 0);
        picker.select = () async =>
            XFile((current.file('photo.jpg')..writeAsBytesSync([2])).path);
        final fresh = (await coordinator.pick(
          ImageSource.gallery,
          createTask: create,
        ))!;
        expect(await fresh.readAsBytes(), [2]);
        await fresh.cleanup();
      },
    );
  }

  test(
    'PICK-08 pre-callback orphan with no lost data is recovered only under reserved root',
    () async {
      final abandoned = await OwnedTempStore(
        () async => root,
      ).create(_scopeA, 'picker');
      final orphan = abandoned.file('photo.jpg')..writeAsBytesSync([1]);
      File('${abandoned.directory.path}/marker.json').deleteSync();
      final other = File('${sandbox.path}/other-feature.tmp')
        ..writeAsBytesSync([8]);
      expect(await coordinator.recover(), PickerRecoveryState.none);
      expect(orphan.existsSync(), isFalse);
      expect(other.readAsBytesSync(), [8]);
    },
  );

  test(
    'PICK-09 recovery precedes new picker and overlapping request is refused',
    () async {
      final recovery = Completer<LostDataResponse>();
      final result = Completer<XFile?>();
      final entered = Completer<void>();
      picker.lost = () => recovery.future;
      picker.select = () {
        entered.complete();
        return result.future;
      };
      final pending = coordinator.pick(ImageSource.gallery, createTask: create);
      await Future<void>.delayed(Duration.zero);
      expect(picker.picks, 0);
      recovery.complete(LostDataResponse.empty());
      await entered.future;
      final photo = current.file('active.jpg')..writeAsBytesSync([3]);
      await expectLater(
        coordinator.pick(ImageSource.gallery, createTask: create),
        throwsStateError,
      );
      await store.sweep();
      expect(photo.readAsBytesSync(), [3]);
      result.complete(XFile(photo.path));
      final picked = (await pending)!;
      expect(await picked.readAsBytes(), [3]);
      await picked.cleanup();
      expect(photo.existsSync(), isFalse);
    },
  );

  test(
    'PICK-01/02 cancellation and read failure close owned file lifetime',
    () async {
      picker.select = () async => null;
      expect(
        await coordinator.pick(ImageSource.gallery, createTask: create),
        isNull,
      );
      expect(current.directory.existsSync(), isFalse);
      picker.select = () async =>
          XFile((current.file('photo.jpg')..writeAsBytesSync([4])).path);
      final picked = (await coordinator.pick(
        ImageSource.gallery,
        createTask: create,
      ))!;
      current.file('photo.jpg').deleteSync();
      await expectLater(
        picked.readAsBytes(),
        throwsA(isA<FileSystemException>()),
      );
      await picked.cleanup();
      await picked.cleanup();
      expect(current.directory.existsSync(), isFalse);
    },
  );

  test(
    'PICK-10 out-of-scope original cannot become OCR input or be deleted',
    () async {
      final original = File('${sandbox.path}/gallery-original.jpg')
        ..writeAsBytesSync([5]);
      picker.select = () async => XFile(original.path);
      await expectLater(
        coordinator.pick(ImageSource.gallery, createTask: create),
        throwsA(isA<TempStoreUnavailable>()),
      );
      expect(original.readAsBytesSync(), [5]);
      expect(current.directory.existsSync(), isFalse);
    },
  );
}
