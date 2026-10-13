// S09d · PhotoStore paths and failures: the store-relative path contract
// ('/'-separated, derived with package:path, never by string prefix) holds
// for Windows backslash paths as well as POSIX ones (the GPT Windows run
// listed nothing); a path outside the root is never produced; a store that
// cannot be opened or listed throws / reports incomplete instead of looking
// empty; and the sweep tells "nothing left" from "could not look".

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:soongong/data/photos/photo_store.dart';

void main() {
  group('relativeOf', () {
    test(
      'Windows: backslash paths under the root become forward-slash relative paths',
      () {
        expect(
          PhotoStore.relativeOf(
            r'C:\Users\me\photos',
            r'C:\Users\me\photos\cache\orphan.jpg',
            context: p.windows,
          ),
          'cache/orphan.jpg',
        );
        expect(
          PhotoStore.relativeOf(
            r'C:\Users\me\photos\',
            r'C:\Users\me\photos\req\1.compressed.jpg',
            context: p.windows,
          ),
          'req/1.compressed.jpg',
        );
        expect(
          PhotoStore.relativeOf(
            r'C:\Users\me\photos',
            r'C:\Users\me\photos\req\..\cache\x.jpg',
            context: p.windows,
          ),
          'cache/x.jpg',
          reason: 'normalized first',
        );
      },
    );

    test(
      'Windows: a path outside the root (sibling · parent · prefix-alike directory) is null',
      () {
        expect(
          PhotoStore.relativeOf(
            r'C:\Users\me\photos',
            r'C:\Users\me\photos2\x.jpg',
            context: p.windows,
          ),
          isNull,
          reason: 'string prefix would have matched',
        );
        expect(
          PhotoStore.relativeOf(
            r'C:\Users\me\photos',
            r'C:\Users\me\other\x.jpg',
            context: p.windows,
          ),
          isNull,
        );
        expect(
          PhotoStore.relativeOf(
            r'C:\Users\me\photos',
            r'C:\Users\me\photos\..\x.jpg',
            context: p.windows,
          ),
          isNull,
        );
        expect(
          PhotoStore.relativeOf(
            r'C:\Users\me\photos',
            r'C:\Users\me\photos',
            context: p.windows,
          ),
          isNull,
          reason: 'the root itself is not a file inside it',
        );
      },
    );

    test('POSIX: same contract', () {
      expect(
        PhotoStore.relativeOf(
          '/data/photos',
          '/data/photos/cache/orphan.jpg',
          context: p.posix,
        ),
        'cache/orphan.jpg',
      );
      expect(
        PhotoStore.relativeOf(
          '/data/photos',
          '/data/photos2/x.jpg',
          context: p.posix,
        ),
        isNull,
      );
      expect(
        PhotoStore.relativeOf(
          '/data/photos',
          '/data/photos/a/../../x.jpg',
          context: p.posix,
        ),
        isNull,
      );
    });
  });

  group('store failures are not an empty store', () {
    late Directory dir;
    final logs = <LogEvent>[];
    void onLog(LogEvent e) => logs.add(e);

    setUp(() {
      dir = Directory.systemTemp.createTempSync('soongong-store-');
      logs.clear();
      Logger.addLogListener(onLog);
    });
    tearDown(() {
      Logger.removeLogListener(onLog);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    File write(String rel) {
      final f = File(p.join(dir.path, p.joinAll(rel.split('/'))));
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(<int>[1]);
      return f;
    }

    test(
      'root lookup fails → listAll throws PhotoStoreUnavailable, sweep is incomplete with nothing deleted',
      () async {
        write('cache/private.jpg');
        final store = PhotoStore(
          () async => throw FileSystemException('store unavailable', dir.path),
        );
        await expectLater(
          store.listAll(),
          throwsA(isA<PhotoStoreUnavailable>()),
        );
        final sweep = await store.sweep();
        expect(sweep.complete, isFalse);
        expect(sweep.clean, isFalse);
        expect(
          File(p.join(dir.path, 'cache', 'private.jpg')).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'directory listing fails → listAll throws, sweep incomplete',
      () async {
        final store = _ListingFailsStore(() async => dir);
        write('cache/private.jpg');
        await expectLater(
          store.listAll(),
          throwsA(isA<PhotoStoreUnavailable>()),
        );
        expect((await store.sweep()).complete, isFalse);
      },
    );

    test(
      'a file that cannot be deleted is left; the sweep is still complete (every file was seen)',
      () async {
        write('cache/stuck.jpg');
        write('cache/ok.jpg');
        final store = _StuckStore(() async => dir, stuck: 'cache/stuck.jpg');
        final sweep = await store.sweep();
        expect(sweep.complete, isTrue);
        expect(sweep.left, <String>['cache/stuck.jpg']);
        expect(sweep.clean, isFalse);
        expect(File(p.join(dir.path, 'cache', 'ok.jpg')).existsSync(), isFalse);
      },
    );

    test(
      'stopped by proceed → incomplete, the unreached files listed',
      () async {
        write('a/1.jpg');
        write('b/2.jpg');
        final store = PhotoStore(() async => dir);
        final sweep = await store.sweep(proceed: () => false);
        expect(sweep.complete, isFalse);
        expect(sweep.left.toSet(), <String>{'a/1.jpg', 'b/2.jpg'});
      },
    );

    test(
      'an empty store is clean; a missing root directory is clean too',
      () async {
        final store = PhotoStore(() async => dir);
        expect(await store.listAll(), isEmpty);
        expect((await store.sweep()).clean, isTrue);
        dir.deleteSync(recursive: true);
        expect(await store.listAll(), isEmpty);
        expect((await store.sweep()).clean, isTrue);
      },
    );

    test(
      'derived siblings of a kept row file are kept; everything else goes; relative paths use /',
      () async {
        write('req/1.jpg');
        write('req/1.compressed.jpg');
        write('req/2.jpg');
        write('cache/x.jpg');
        final store = PhotoStore(() async => dir);
        expect((await store.listAll()).toSet(), <String>{
          'req/1.jpg',
          'req/1.compressed.jpg',
          'req/2.jpg',
          'cache/x.jpg',
        });
        final sweep = await store.sweep(keep: <String>{'req/1.jpg'});
        expect(sweep.clean, isTrue);
        expect((await store.listAll()).toSet(), <String>{
          'req/1.jpg',
          'req/1.compressed.jpg',
        });
      },
    );

    test(
      'failure logs carry the failure kind only — never the path (CLAUDE.md §7)',
      () async {
        final store = PhotoStore(
          () async => throw FileSystemException('store unavailable', dir.path),
        );
        await store.sweep();
        await store.delete('cache/private.jpg');
        await store.clearCache(now: DateTime.now());
        expect(logs, isNotEmpty);
        for (final e in logs) {
          expect(
            e.error,
            isNull,
            reason: 'the exception object (with its path) is not attached',
          );
          expect('${e.message}', isNot(contains(dir.path)));
          expect('${e.message}', isNot(contains('private.jpg')));
          expect('${e.message}', contains('FileSystemException'));
        }
      },
    );
  });
}

class _ListingFailsStore extends PhotoStore {
  _ListingFailsStore(super.root);

  @override
  Future<List<String>> listAll() async {
    await root();
    throw const PhotoStoreUnavailable('FileSystemException');
  }
}

class _StuckStore extends PhotoStore {
  _StuckStore(super.root, {required this.stuck});

  final String stuck;

  @override
  Future<bool> delete(String relativePath, {bool Function()? proceed}) async {
    if (relativePath == stuck) return false;
    return super.delete(relativePath, proceed: proceed);
  }
}
