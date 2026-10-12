// S09c: the in-app "저장되는 데이터" table (`PrivacyStrings.d14Rows`) is the
// D14 table of docs/decisions.md, row for row — same count and order, the
// same data label, the same location kind, and every retention figure
// (N년 · N일 · N시간 · N분) of the decision present in the UI wording. The
// vendor row is the one row whose terms D14 itself leaves open ("미결"), so
// its figures are not required. Internal table names (`subscription_state`
// …) are not shown in the UI.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/strings/privacy_strings.dart';

void main() {
  late List<List<String>> doc;

  setUpAll(() {
    final lines = File('docs/decisions.md').readAsLinesSync();
    final start = lines.indexWhere((l) => l.startsWith('## D14.'));
    expect(start, greaterThan(0), reason: 'D14 section present');
    doc = <List<String>>[];
    var inTable = false;
    for (final l in lines.skip(start + 1)) {
      if (l.startsWith('## ')) break;
      if (l.startsWith('|')) {
        inTable = true;
        final cells = l.split('|').map((c) => c.trim()).toList()
          ..removeAt(0)
          ..removeLast();
        if (cells.first == '데이터' || cells.first.startsWith('---')) continue;
        doc.add(cells);
      } else if (inTable && l.trim().isEmpty) {
        break;
      }
    }
  });

  String label(String cell) {
    final cut = cell.indexOf(RegExp(r'[(`]'));
    return (cut < 0 ? cell : cell.substring(0, cut)).trim();
  }

  test('row count and order match D14', () {
    expect(doc.length, 17, reason: 'D14 has 17 rows');
    expect(PrivacyStrings.d14Rows.length, doc.length);
    for (var i = 0; i < doc.length; i++) {
      expect(PrivacyStrings.d14Rows[i].$1, startsWith(label(doc[i][0])), reason: 'row ${i + 1} data label');
    }
  });

  test('location kind and retention figures match D14 (vendor terms pending excluded)', () {
    final figure = RegExp(r'\d+\s*(년|일|시간|분)');
    for (var i = 0; i < doc.length; i++) {
      final (_, uiWhere, uiHow) = PrivacyStrings.d14Rows[i];
      final where = doc[i][1].replaceAll('`', '').replaceAll('*', '');
      final how = doc[i][2].replaceAll('`', '').replaceAll('*', '');
      final kind = where.split(RegExp(r'[\s(→/]')).first;
      expect(uiWhere, contains(kind), reason: 'row ${i + 1} location kind "$kind"');
      if (how.contains('미결')) continue;
      for (final m in figure.allMatches(how)) {
        expect(uiHow.replaceAll(' ', ''), contains(m.group(0)!.replaceAll(' ', '')), reason: 'row ${i + 1} retention figure "${m.group(0)}"');
      }
    }
  });

  test('no internal table names leak into the UI', () {
    final all = PrivacyStrings.d14Rows.map((r) => '${r.$1} ${r.$2} ${r.$3}').join('\n');
    for (final internal in <String>['subscription_state', 'subscription_events', 'activity_days', 'metrics_weekly', 'sync_mutations', 'reading_jobs', 'signup_passes', 'result_json']) {
      expect(all, isNot(contains(internal)));
    }
  });
}
