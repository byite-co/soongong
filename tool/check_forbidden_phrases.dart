// Forbidden-phrase check (CLAUDE.md §1 · §7). Runs in CI:
//   dart run tool/check_forbidden_phrases.dart [extra paths...]
//
// Scope: `lib/core/strings/**` and `docs/store/**` only (reference documents
// are intentionally excluded). Matching is exact per word token (어절): a
// token is a maximal run of letters/digits, so `점수` matches but `점수를`
// does not, and stems such as `잘` or `아쉽` are deliberately NOT listed
// (`잘못` would be a false positive).
//
// Exit code 0 = clean, 1 = hits found.

import 'dart:io';

const List<String> forbiddenPhrases = <String>[
  '부족합니다',
  '부족해요',
  '잘했어요',
  '잘하셨어요',
  '훌륭해요',
  '분발하세요',
  '점수',
  '등급',
  '랭킹',
  '레벨',
  '칭찬',
  '아쉽네요',
  '아쉬워요',
  '권장합니다',
  '추천합니다',
  '해보세요',
];

const List<String> defaultScanRoots = <String>[
  'lib/core/strings',
  'docs/store',
];

const Set<String> scannedExtensions = <String>{
  '.dart',
  '.md',
  '.txt',
  '.json',
  '.yaml',
  '.yml',
  '.arb',
  '.csv',
};

final RegExp _token = RegExp(r'[\p{L}\p{N}_]+', unicode: true);

/// One forbidden phrase occurrence.
class ForbiddenHit {
  const ForbiddenHit({
    required this.path,
    required this.line,
    required this.phrase,
  });

  final String path;
  final int line; // 1-based
  final String phrase;

  @override
  String toString() => '$path:$line: 금지 문구 "$phrase"';
}

/// Scans [text] and returns every exact-token hit.
List<ForbiddenHit> scanText(String path, String text) {
  final forbidden = forbiddenPhrases.toSet();
  final hits = <ForbiddenHit>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    for (final m in _token.allMatches(lines[i])) {
      final token = m.group(0)!;
      if (forbidden.contains(token)) {
        hits.add(ForbiddenHit(path: path, line: i + 1, phrase: token));
      }
    }
  }
  return hits;
}

/// Collects scannable files below each root (missing roots are skipped).
List<File> collectFiles(List<String> roots) {
  final files = <File>[];
  for (final root in roots) {
    final type = FileSystemEntity.typeSync(root);
    if (type == FileSystemEntityType.file) {
      files.add(File(root));
      continue;
    }
    if (type != FileSystemEntityType.directory) continue;
    for (final e in Directory(root).listSync(recursive: true)) {
      if (e is! File) continue;
      final dot = e.path.lastIndexOf('.');
      final ext = dot == -1 ? '' : e.path.substring(dot);
      if (scannedExtensions.contains(ext)) files.add(e);
    }
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

List<ForbiddenHit> scanFiles(List<File> files) {
  final hits = <ForbiddenHit>[];
  for (final f in files) {
    hits.addAll(scanText(f.path, f.readAsStringSync()));
  }
  return hits;
}

void main(List<String> args) {
  final roots = <String>[...defaultScanRoots, ...args];
  final files = collectFiles(roots);
  final hits = scanFiles(files);
  if (hits.isEmpty) {
    stdout.writeln('check_forbidden_phrases: ${files.length} files clean.');
    exit(0);
  }
  for (final h in hits) {
    stderr.writeln(h);
  }
  stderr.writeln(
    'check_forbidden_phrases: ${hits.length} hit(s) in ${files.length} files.',
  );
  exit(1);
}
