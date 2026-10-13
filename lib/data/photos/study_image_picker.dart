import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class StudyPickedImage {
  Future<int> length();
  Future<Uint8List> readAsBytes();
  Future<void> cleanup();
}

/// Claims are ordered when requests start, not when the picker completes.
/// A late result may never delete a path reused by a newer selection.
class StudyImagePicker {
  StudyImagePicker({this.pickFile, this.temporaryDirectory});
  final Future<XFile?> Function(ImageSource)? pickFile;
  final Future<Directory> Function()? temporaryDirectory;
  final Map<String, int> _claims = {};
  int _sequence = 0;

  Future<StudyPickedImage?> pick(ImageSource source) async {
    final sequence = ++_sequence;
    final file = await (pickFile == null
        ? ImagePicker().pickImage(source: source, requestFullMetadata: false)
        : pickFile!(source));
    if (file == null) return null;
    final path = p.normalize(p.absolute(file.path));
    if ((_claims[path] ?? -1) < sequence) _claims[path] = sequence;
    return _PickedImage(file, () async {
      final temp = await (temporaryDirectory ?? getTemporaryDirectory)();
      if (_claims[path] != sequence || !p.isWithin(p.absolute(temp.path), path))
        return;
      // No await between ownership check and deletion. Do not follow a
      // symlink out of app cache, and never delete a user's original.
      final candidate = File(path);
      if (!candidate.existsSync()) return;
      final canonicalTemp = temp.resolveSymbolicLinksSync();
      if (!p.isWithin(canonicalTemp, candidate.resolveSymbolicLinksSync()))
        return;
      if (_claims[path] == sequence) candidate.deleteSync();
    });
  }
}

class _PickedImage implements StudyPickedImage {
  _PickedImage(this.file, this.remove);
  final XFile file;
  final Future<void> Function() remove;
  @override
  Future<int> length() => file.length();
  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();
  @override
  Future<void> cleanup() => remove();
}
