import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soongong/core/theme/app_theme.dart';
import 'package:soongong/core/theme/tokens.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a);
  final lb = _lum(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('AppColors contrast (CLAUDE.md §6: text 4.5:1, secondary 3:1)', () {
    for (final c in <AppColors>[AppColors.light, AppColors.dark]) {
      test('${c.brightness.name}: tx / tx2 on bg and surface ≥ 4.5', () {
        for (final bg in <Color>[c.bg, c.surface, c.surface2, c.sunk]) {
          expect(contrast(c.tx, bg), greaterThanOrEqualTo(4.5));
          expect(contrast(c.tx2, bg), greaterThanOrEqualTo(4.5));
          expect(contrast(c.tx3, bg), greaterThanOrEqualTo(3.0));
        }
      });
      test('${c.brightness.name}: button text on pri / acc ≥ 4.5', () {
        expect(contrast(c.onPri, c.pri), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onAcc, c.acc), greaterThanOrEqualTo(4.5));
      });
      test('${c.brightness.name}: toast text and action on toast bg ≥ 4.5', () {
        expect(contrast(c.toastFg, c.toastBg), greaterThanOrEqualTo(4.5));
        expect(contrast(c.toastAction, c.toastBg), greaterThanOrEqualTo(4.5));
      });
      test('${c.brightness.name}: 8 distinct subject colors', () {
        expect(c.subjects.length, AppSubjectColors.count);
        expect(c.subjects.toSet().length, AppSubjectColors.count);
        expect(c.subject(9), c.subjects[1]); // wraps
      });
    }

    test('dark subject colors reach 4.5 on the dark background', () {
      for (final s in AppSubjectColors.dark) {
        expect(contrast(s, AppNeutral.n950), greaterThanOrEqualTo(4.5));
      }
    });

    test('light subject colors reach 3.0 (non-text UI) on white', () {
      for (final s in AppSubjectColors.light) {
        expect(contrast(s, const Color(0xFFFFFFFF)), greaterThanOrEqualTo(2.8));
      }
    });
  });

  group('AppTypography', () {
    test('six levels, weights within 400–700, Pretendard family', () {
      final styles = AppTypography.all;
      expect(styles.length, 6);
      for (final s in styles) {
        expect(s.fontFamily, AppTypography.fontFamily);
        expect(s.fontWeight!.value, inInclusiveRange(400, 700));
        expect(s.fontVariations, isNotEmpty);
        expect(s.fontVariations!.first.axis, 'wght');
      }
      expect(AppTypography.display.fontSize, 28);
      expect(AppTypography.caption.fontSize, 12);
    });

    test('withWeight keeps the variable axis in sync', () {
      final s = AppTypography.withWeight(AppTypography.body, 700);
      expect(s.fontWeight, FontWeight.w700);
      expect(s.fontVariations!.first.value, 700);
    });
  });

  group('AppShadow', () {
    test('never exceeds 0 1px 2px', () {
      for (final s in AppShadow.card) {
        expect(s.offset.dx, 0);
        expect(s.offset.dy, lessThanOrEqualTo(1));
        expect(s.blurRadius, lessThanOrEqualTo(2));
      }
      expect(AppColors.dark.shadow, isEmpty);
    });
  });

  group('buildAppTheme', () {
    test('both brightnesses expose AppColors and Pretendard', () {
      for (final b in Brightness.values) {
        final t = buildAppTheme(b);
        expect(t.brightness, b);
        expect(t.extension<AppColors>(), isNotNull);
        expect(t.extension<AppColors>()!.brightness, b);
        expect(t.textTheme.bodyLarge!.fontFamily, AppTypography.fontFamily);
        expect(t.scaffoldBackgroundColor, AppColors.of(b).bg);
      }
    });
  });
}
