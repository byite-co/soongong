import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_forbidden_phrases.dart';

void main() {
  group('scanText', () {
    test('flags exact word tokens only', () {
      const text = "static const a = '오늘 잘했어요';\n"
          "static const b = '점수를 매기지 않습니다';\n"
          "static const c = '잘못 감지된 구간';\n"
          "static const d = '점수·등급 없음';\n";
      final hits = scanText('x.dart', text);
      expect(hits.map((h) => '${h.line}:${h.phrase}'), <String>[
        '1:잘했어요',
        '4:점수',
        '4:등급',
      ]);
    });

    test('does not flag stems such as 잘 / 아쉽', () {
      expect(scanText('x', '잘 되었습니다 · 잘못 · 아쉽 · 아쉽지'), isEmpty);
    });

    test('every listed phrase is detected standalone', () {
      for (final p in forbiddenPhrases) {
        expect(scanText('x', 'a $p b').single.phrase, p);
      }
    });
  });

  test('committed string tables are clean', () {
    final files = collectFiles(defaultScanRoots);
    expect(files, isNotEmpty);
    expect(scanFiles(files), isEmpty);
  });
}
