import 'dart:io';

import 'package:path/path.dart' as p;

/// Earlier builds shared these reserved temporary names without an ownership
/// ledger. Their presence is uncertainty, never permission to delete or adopt
/// them. Only immediate entries of the platform temporary/cache root are read.
class LegacyTempProbe {
  LegacyTempProbe(
    this.root, {
    required this.android,
    this.listDirectory,
    this.entryType,
  });

  final Future<Directory> Function() root;
  final bool android;
  final List<FileSystemEntity> Function(Directory directory)? listDirectory;
  final FileSystemEntityType Function(String path)? entryType;

  static final _records = RegExp(r'^soongong-\d{8}-\d{4}\.(json|zip)$');
  static final _seatLab = RegExp(r'^seat_lab_.*\.csv$');

  FileSystemEntityType _type(String path) =>
      entryType?.call(path) ??
      FileSystemEntity.typeSync(path, followLinks: false);

  Future<bool> isClean() async {
    try {
      final directory = await root();
      final absolute = p.normalize(p.absolute(directory.path));
      if (_type(absolute) != FileSystemEntityType.directory) return false;
      // Accept a platform ancestor alias such as iOS /var, but never follow
      // a link used as the temporary root or as one of its child entries.
      final canonical = Directory(directory.resolveSymbolicLinksSync());
      if (_type(canonical.path) != FileSystemEntityType.directory) return false;
      final entries =
          listDirectory?.call(canonical) ??
          canonical.listSync(followLinks: false);
      for (final entry in entries) {
        final path = p.normalize(p.absolute(entry.path));
        if (!p.equals(p.dirname(path), canonical.path) ||
            _type(path) == FileSystemEntityType.notFound) {
          return false;
        }
        final name = p.basename(path);
        if (name.startsWith('soongong-export-') ||
            _records.hasMatch(name) ||
            _seatLab.hasMatch(name) ||
            (android && name == 'share_plus')) {
          return false;
        }
      }
      return true;
    } on Object {
      return false;
    }
  }
}
