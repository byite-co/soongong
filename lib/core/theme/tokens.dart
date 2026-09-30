// Design tokens (S01). Single source of truth — CLAUDE.md §6.
//
// Every value here is extracted from the prototype
// (`docs/reference/final-src/soongong-prototype.dc.html`); the comparison table
// lives in `docs/design-tokens.md`. Do not add ad-hoc colors/sizes elsewhere.

import 'package:flutter/material.dart';

/// Neutral (achromatic) scale 50–900 (+950 for the dark background).
///
/// Light surfaces use 50–300, light text uses 600–900; the dark theme uses
/// 800–950 for surfaces and 50–500 for text.
abstract final class AppNeutral {
  static const Color n50 = Color(0xFFF7F7F9); // skel-hi (light)
  static const Color n100 = Color(0xFFF5F5F7); // bg (light)
  static const Color n200 = Color(0xFFEFEFF2); // sunk / skel (light)
  static const Color n300 = Color(0xFFE6E6EB); // line (light)
  static const Color n400 = Color(0xFFC9C9D2); // ring track r2 (light)
  static const Color n500 = Color(0xFF9D9DAB); // ring track r3 (light)
  static const Color n600 = Color(0xFF6E6E7A); // tx3 (light)
  static const Color n700 = Color(0xFF4E4E58); // tx2 (light)
  static const Color n800 = Color(0xFF1A1A21); // surface2 (dark)
  static const Color n900 = Color(0xFF111114); // tx (light)
  static const Color n950 = Color(0xFF0B0B0F); // bg (dark)

  /// Dark-theme surfaces that fall between 800 and 950.
  static const Color darkSunk = Color(0xFF101015);
  static const Color darkSurface = Color(0xFF141419);

  /// Dark-theme text.
  static const Color darkTx = Color(0xFFF4F4F6);
  static const Color darkTx2 = Color(0xFFB4B4BE);
  static const Color darkTx3 = Color(0xFF8C8C98);
}

/// The one blue (ring · 순공) and the one orange (CTA · 자습 · 오늘).
abstract final class AppAccent {
  static const Color blue = Color(0xFF3D5AFE);
  static const Color blueDark = Color(0xFF7A8CFF);
  static const Color blueText = Color(0xFF2F49E0);
  static const Color blueTextDark = Color(0xFF9DAAFF);
  static const Color blueWeak = Color(0xFFEEF1FF);
  static const Color blueWeakDark = Color(0x247A8CFF); // rgba(122,140,255,.14)
  static const Color blueFaint = Color(0x383D5AFE); // rgba(61,90,254,.22)
  static const Color blueFaintDark = Color(0x3D7A8CFF); // rgba(122,140,255,.24)

  static const Color orange = Color(0xFFFF6B3D);
  static const Color orangeDark = Color(0xFFFF7A4D);
  static const Color orangeText = Color(0xFFB8431A);
  static const Color orangeTextDark = Color(0xFFFFA07A);
  static const Color orangeWeak = Color(0xFFFFF1EA);
  static const Color orangeWeakDark = Color(0x24FF7A4D); // rgba(255,122,77,.14)

  /// Text placed on the orange CTA (prototype uses #1A0E08, not white).
  static const Color onOrange = Color(0xFF1A0E08);
  static const Color onBlue = Color(0xFFFFFFFF);

  /// Dark theme: white on #7A8CFF is only 2.6:1, so the CTA text uses the
  /// dark background colour (6.6:1). Documented in docs/design-tokens.md §7.
  static const Color onBlueDark = AppNeutral.n950;

  /// Toast action text. The prototype uses #8FA0FF on both toasts; on the
  /// dark toast (light #F4F4F6 background) that is only 2.3:1, so the dark
  /// theme uses [blueText] (6.1:1). Light toast keeps #8FA0FF (7.8:1).
  static const Color toastAction = Color(0xFF8FA0FF);
  static const Color toastActionDark = blueText;

  static const Color ok = Color(0xFF12A05C);
  static const Color okDark = Color(0xFF2BD48A);
  static const Color okText = Color(0xFF0B7A45);
  static const Color okTextDark = Color(0xFF5FE3A8);
  static const Color okWeak = Color(0xFFEAF6EF);
  static const Color okWeakDark = Color(0x1F2BD48A); // rgba(43,212,138,.12)
}

/// Eight subject colors (color-vision-checked light set from the prototype;
/// dark set lifted to ≥4.5:1 against the dark background, see
/// docs/design-tokens.md). Never distinguish subjects by color alone — a
/// SubjectChip always carries the name label.
abstract final class AppSubjectColors {
  static const List<Color> light = <Color>[
    Color(0xFF4059F0), // indigo   · 수학
    Color(0xFFD6428F), // pink     · 영어
    Color(0xFF45A52C), // green    · 국어
    Color(0xFF9A5505), // brown    · 과학
    Color(0xFF1E8A9E), // teal     · 사회
    Color(0xFF79809E), // slate    · 기타
    Color(0xFF7A3FCF), // purple
    Color(0xFFC0392B), // red
  ];

  static const List<Color> dark = <Color>[
    Color(0xFF6176F3),
    Color(0xFFD74691),
    Color(0xFF45A52C),
    Color(0xFFC26B06),
    Color(0xFF1E8A9E),
    Color(0xFF79809E),
    Color(0xFF9668D9),
    Color(0xFFD65548),
  ];

  static const int count = 8;
}

/// Spacing scale (px). Page gutter is 20; sheets end with 44 bottom padding.
abstract final class AppSpacing {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s44 = 44;

  /// Horizontal page gutter (prototype `padding: 0 20px`).
  static const double page = 20;

  /// Bottom padding of sheets / CTA bars (home indicator clearance).
  static const double sheetBottom = 44;

  /// Minimum touch target (CLAUDE.md §6).
  static const double touchTarget = 44;
}

/// Corner radii (px).
abstract final class AppRadius {
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r22 = 22;
  static const double r26 = 26;
  static const double pill = 999;

  static const double chip = r10;
  static const double buttonSmall = r12;
  static const double button = r14;
  static const double card = r14;
  static const double toast = r16;
  static const double sheet = r20;
  static const double sheetTablet = r26;
  static const double dialog = r20;
}

/// Text styles — 6 levels. Weight is applied through the `wght` axis of the
/// bundled Pretendard Variable font.
abstract final class AppTypography {
  static const String fontFamily = 'Pretendard';
  static const List<String> fontFamilyFallback = <String>[
    'Apple SD Gothic Neo',
    'Noto Sans KR',
    'sans-serif',
  ];

  static TextStyle _style({
    required double size,
    required int weight,
    required double letterSpacingEm,
    required double height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: size,
      fontWeight: weightOf(weight),
      fontVariations: <FontVariation>[FontVariation.weight(weight.toDouble())],
      letterSpacing: letterSpacingEm * size,
      height: height,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// Maps a numeric weight to [FontWeight] (400/500/600/700 are the only
  /// weights the design uses).
  static FontWeight weightOf(int w) => switch (w) {
        400 => FontWeight.w400,
        500 => FontWeight.w500,
        600 => FontWeight.w600,
        700 => FontWeight.w700,
        _ => FontWeight.w500,
      };

  /// Returns [base] at [weight], keeping the variable-font axis in sync.
  static TextStyle withWeight(TextStyle base, int weight) => base.copyWith(
        fontWeight: weightOf(weight),
        fontVariations: <FontVariation>[FontVariation.weight(weight.toDouble())],
      );

  /// 28 / 700 / -0.03em — large numbers (순공시간), hero.
  static final TextStyle display =
      _style(size: 28, weight: 700, letterSpacingEm: -0.03, height: 1.25);

  /// 22 / 700 / -0.03em — screen titles.
  static final TextStyle title =
      _style(size: 22, weight: 700, letterSpacingEm: -0.03, height: 1.25);

  /// 17 / 600 / -0.028em — section headings, dialog titles.
  static final TextStyle heading =
      _style(size: 17, weight: 600, letterSpacingEm: -0.028, height: 1.4);

  /// 15 / 500 / -0.02em — body, list rows; buttons use 600.
  static final TextStyle body =
      _style(size: 15, weight: 500, letterSpacingEm: -0.02, height: 1.6);

  /// 13 / 500 — secondary text, chips, dialog body.
  static final TextStyle label =
      _style(size: 13, weight: 500, letterSpacingEm: 0, height: 1.5);

  /// 12 / 500 — captions, meta rows.
  static final TextStyle caption =
      _style(size: 12, weight: 500, letterSpacingEm: 0, height: 1.5);

  static List<TextStyle> get all =>
      <TextStyle>[display, title, heading, body, label, caption];

  /// Tabular numerals for times/counters (prototype: font-variant-numeric).
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
}

/// Shadows: at most `0 1px 2px` (CLAUDE.md §6). None in dark.
abstract final class AppShadow {
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x0A000000), // rgba(0,0,0,.04)
    ),
  ];
  static const List<BoxShadow> none = <BoxShadow>[];
}

/// Motion. Honour `MediaQuery.disableAnimations` via [reduced].
abstract final class AppMotion {
  static const Duration sheetIn = Duration(milliseconds: 280);
  static const Duration toastIn = Duration(milliseconds: 220);
  static const Duration fade = Duration(milliseconds: 160);
  static const Duration pop = Duration(milliseconds: 200);
  static const Duration meter = Duration(milliseconds: 320);
  static const Duration ringIn = Duration(milliseconds: 600);
  static const Curve sheetCurve = Cubic(0, 0.9, 0.3, 1);
  static const Curve meterCurve = Cubic(0.2, 0.8, 0.25, 1);

  /// Undo window for destructive toasts (D22).
  static const Duration undoWindow = Duration(seconds: 5);

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Icons: Lucide, 24px grid, stroke 1.75.
abstract final class AppIcon {
  static const double size = 24;
  static const double sizeSmall = 16;
  static const double sizeLarge = 32;
  static const double strokeWidth = 1.75;
}

/// Layout breakpoints and fixed sizes.
abstract final class AppLayout {
  /// Tablet: sheets become centered cards.
  static const double tabletBreakpoint = 600;
  static const double sheetTabletWidth = 520;
  static const double dialogMaxWidth = 420;
  static const double dialogHorizontalInset = 32;

  static const double buttonLarge = 54;
  static const double buttonMedium = 46;
  static const double buttonSmall = 42;
  static const double chipHeight = 32;
}

/// 24-hour ring geometry (home · measure). 0h at top, 6h right, 12h bottom.
abstract final class AppRing {
  static const double size = 152;
  static const double outerRadius = 70;
  static const double outerStroke = 4;
  static const double innerRadius = 58;
  static const double innerStroke = 10;
  static const double tickRadius = 2.2;
  static const double outerTrackOpacity = 0.22;
  static const double innerTrackOpacity = 0.30;
  static const double ghostOpacity = 0.30;
  static const double handWidth = 3.5;
  static const double handHaloWidth = 7;
  static const double handKnobRadius = 3.2;
}
