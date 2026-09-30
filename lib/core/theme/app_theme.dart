// Light / dark ThemeData built from tokens.dart (S01).

import 'package:flutter/material.dart';

import 'tokens.dart';

/// Semantic colors, one instance per brightness. Read with `context.colors`.
///
/// Field names mirror the prototype CSS variables so screens can be ported
/// 1:1 (`--bg` → [bg], `--pri-weak` → [priWeak], …).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.sunk,
    required this.tx,
    required this.tx2,
    required this.tx3,
    required this.line,
    required this.pri,
    required this.priWeak,
    required this.priTx,
    required this.priFaint,
    required this.onPri,
    required this.acc,
    required this.accWeak,
    required this.accTx,
    required this.onAcc,
    required this.ok,
    required this.okWeak,
    required this.okTx,
    required this.grid,
    required this.skel,
    required this.skelHi,
    required this.scrim,
    required this.shadow,
    required this.ringTrack1,
    required this.ringTrack2,
    required this.ringTrack3,
    required this.ringFill,
    required this.toastBg,
    required this.toastFg,
    required this.toastAction,
    required this.subjects,
  });

  final Brightness brightness;

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color sunk;

  final Color tx;
  final Color tx2;
  final Color tx3;
  final Color line;

  final Color pri;
  final Color priWeak;
  final Color priTx;
  final Color priFaint;
  final Color onPri;

  final Color acc;
  final Color accWeak;
  final Color accTx;
  final Color onAcc;

  final Color ok;
  final Color okWeak;
  final Color okTx;

  final Color grid;
  final Color skel;
  final Color skelHi;
  final Color scrim;

  final List<BoxShadow> shadow;

  final Color ringTrack1;
  final Color ringTrack2;
  final Color ringTrack3;
  final Color ringFill;

  final Color toastBg;
  final Color toastFg;
  final Color toastAction;

  /// Eight subject colors for this brightness.
  final List<Color> subjects;

  bool get isDark => brightness == Brightness.dark;

  /// Subject color by palette index (wraps around).
  Color subject(int index) => subjects[index % subjects.length];

  static const AppColors light = AppColors(
    brightness: Brightness.light,
    bg: AppNeutral.n100,
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    sunk: AppNeutral.n200,
    tx: AppNeutral.n900,
    tx2: AppNeutral.n700,
    tx3: AppNeutral.n600,
    line: AppNeutral.n300,
    pri: AppAccent.blue,
    priWeak: AppAccent.blueWeak,
    priTx: AppAccent.blueText,
    priFaint: AppAccent.blueFaint,
    onPri: AppAccent.onBlue,
    acc: AppAccent.orange,
    accWeak: AppAccent.orangeWeak,
    accTx: AppAccent.orangeText,
    onAcc: AppAccent.onOrange,
    ok: AppAccent.ok,
    okWeak: AppAccent.okWeak,
    okTx: AppAccent.okText,
    grid: Color(0xFFEBEBEF),
    skel: AppNeutral.n200,
    skelHi: AppNeutral.n50,
    scrim: Color(0x6B111114), // rgba(17,17,20,.42)
    shadow: AppShadow.card,
    ringTrack1: Color(0xFFE4E4E9),
    ringTrack2: AppNeutral.n400,
    ringTrack3: AppNeutral.n500,
    ringFill: AppAccent.blue,
    toastBg: AppNeutral.n900,
    toastFg: AppNeutral.n100,
    toastAction: Color(0xFF8FA0FF),
    subjects: AppSubjectColors.light,
  );

  static const AppColors dark = AppColors(
    brightness: Brightness.dark,
    bg: AppNeutral.n950,
    surface: AppNeutral.darkSurface,
    surface2: AppNeutral.n800,
    sunk: AppNeutral.darkSunk,
    tx: AppNeutral.darkTx,
    tx2: AppNeutral.darkTx2,
    tx3: AppNeutral.darkTx3,
    line: Color(0x14FFFFFF), // rgba(255,255,255,.08)
    pri: AppAccent.blueDark,
    priWeak: AppAccent.blueWeakDark,
    priTx: AppAccent.blueTextDark,
    priFaint: AppAccent.blueFaintDark,
    onPri: AppAccent.onBlueDark,
    acc: AppAccent.orangeDark,
    accWeak: AppAccent.orangeWeakDark,
    accTx: AppAccent.orangeTextDark,
    onAcc: AppAccent.onOrange,
    ok: AppAccent.okDark,
    okWeak: AppAccent.okWeakDark,
    okTx: AppAccent.okTextDark,
    grid: Color(0x0FFFFFFF), // rgba(255,255,255,.06)
    skel: AppNeutral.darkSunk,
    skelHi: Color(0xFF1B1B22),
    scrim: Color(0xA8000000), // rgba(0,0,0,.66)
    shadow: AppShadow.none,
    ringTrack1: Color(0xFF1C1C24),
    ringTrack2: Color(0xFF2A2A36),
    ringTrack3: Color(0xFF454560),
    ringFill: AppAccent.blueDark,
    toastBg: AppNeutral.darkTx,
    toastFg: AppNeutral.n950,
    toastAction: Color(0xFF8FA0FF),
    subjects: AppSubjectColors.dark,
  );

  static AppColors of(Brightness b) =>
      b == Brightness.dark ? AppColors.dark : AppColors.light;

  @override
  AppColors copyWith({Brightness? brightness}) =>
      brightness == null ? this : AppColors.of(brightness);

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      AppColors.of(Theme.of(this).brightness);

  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= AppLayout.tabletBreakpoint;
}

/// Builds the app theme for [brightness]. Both themes are required (§6).
ThemeData buildAppTheme(Brightness brightness) {
  final c = AppColors.of(brightness);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.pri,
    onPrimary: c.onPri,
    secondary: c.acc,
    onSecondary: c.onAcc,
    error: c.accTx,
    onError: c.surface,
    surface: c.surface,
    onSurface: c.tx,
    surfaceContainerHighest: c.sunk,
    onSurfaceVariant: c.tx2,
    outline: c.line,
    outlineVariant: c.line,
    shadow: const Color(0xFF000000),
    scrim: c.scrim,
    inverseSurface: c.toastBg,
    onInverseSurface: c.toastFg,
  );

  final text = TextTheme(
    displaySmall: AppTypography.display.copyWith(color: c.tx),
    headlineSmall: AppTypography.title.copyWith(color: c.tx),
    titleLarge: AppTypography.title.copyWith(color: c.tx),
    titleMedium: AppTypography.heading.copyWith(color: c.tx),
    titleSmall: AppTypography.body.copyWith(color: c.tx),
    bodyLarge: AppTypography.body.copyWith(color: c.tx),
    bodyMedium: AppTypography.label.copyWith(color: c.tx),
    bodySmall: AppTypography.caption.copyWith(color: c.tx2),
    labelLarge: AppTypography.body.copyWith(color: c.tx),
    labelMedium: AppTypography.label.copyWith(color: c.tx2),
    labelSmall: AppTypography.caption.copyWith(color: c.tx3),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: AppTypography.fontFamily,
    fontFamilyFallback: AppTypography.fontFamilyFallback,
    textTheme: text,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    splashFactory: NoSplash.splashFactory,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    extensions: <ThemeExtension<dynamic>>[c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.tx,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.heading.copyWith(color: c.tx),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      modalBarrierColor: c.scrim,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      elevation: 0,
      barrierColor: c.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
    ),
    iconTheme: IconThemeData(color: c.tx, size: AppIcon.size),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.pri,
      linearTrackColor: c.sunk,
      circularTrackColor: c.sunk,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: c.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.sunk,
      hintStyle: AppTypography.withWeight(AppTypography.body, 600)
          .copyWith(color: c.tx3),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
