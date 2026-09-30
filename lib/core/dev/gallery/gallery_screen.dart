// Widget gallery `/_gallery` (S01, dev flavor only). Tokens + shared widgets
// in light and dark — S14 QA tool.

import 'package:flutter/material.dart';

import '../../strings/common_strings.dart';
import '../../strings/gallery_strings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/widgets.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  Brightness? _override;

  @override
  Widget build(BuildContext context) {
    final b = _override ?? Theme.of(context).brightness;
    return Theme(
      data: buildAppTheme(b),
      child: Builder(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text(GalleryStrings.title),
            actions: <Widget>[
              IconButton(
                tooltip: GalleryStrings.toggleTheme,
                icon: LucideIcon(
                  b == Brightness.dark ? LucideIcons.sun : LucideIcons.moon,
                ),
                onPressed: () => setState(
                  () => _override =
                      b == Brightness.dark ? Brightness.light : Brightness.dark,
                ),
              ),
            ],
          ),
          body: const _GalleryBody(),
        ),
      ),
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const _GalleryBody();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.s8,
        AppSpacing.page,
        AppSpacing.sheetBottom,
      ),
      children: <Widget>[
        const _Section(GalleryStrings.sectionNeutral, child: _NeutralRow()),
        _Section(GalleryStrings.sectionAccent, child: _AccentRow(c)),
        _Section(GalleryStrings.sectionSubjects, child: _SubjectsRow(c)),
        _Section(GalleryStrings.sectionTypography, child: _TypographyColumn(c)),
        _Section(GalleryStrings.sectionSpacing, child: _SpacingRow(c)),
        const _Section(GalleryStrings.sectionButtons, child: _ButtonsColumn()),
        _Section(GalleryStrings.sectionChips, child: _ChipsRow(c)),
        _Section(GalleryStrings.sectionRing, child: _RingDemo(c)),
        const _Section(GalleryStrings.sectionStatePanel, child: _StateDemo()),
        const _Section(
          GalleryStrings.sectionSheetModalToast,
          child: _OverlayDemo(),
        ),
        _Section(
          GalleryStrings.sectionPremium,
          child: PremiumLockHint(onOpenPaywall: () {}),
        ),
        _Section(GalleryStrings.sectionIcons, child: _IconsRow(c)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTypography.withWeight(AppTypography.label, 600)
                .copyWith(color: c.tx3),
          ),
          const SizedBox(height: AppSpacing.s10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: c.line),
              boxShadow: c.shadow,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.r10),
            border: Border.all(color: c.line),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10),
        ),
      ],
    );
  }
}

class _NeutralRow extends StatelessWidget {
  const _NeutralRow();

  @override
  Widget build(BuildContext context) {
    const stops = <(int, Color)>[
      (50, AppNeutral.n50),
      (100, AppNeutral.n100),
      (200, AppNeutral.n200),
      (300, AppNeutral.n300),
      (400, AppNeutral.n400),
      (500, AppNeutral.n500),
      (600, AppNeutral.n600),
      (700, AppNeutral.n700),
      (800, AppNeutral.n800),
      (900, AppNeutral.n900),
      (950, AppNeutral.n950),
    ];
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: <Widget>[for (final (n, col) in stops) _Swatch(col, '$n')],
    );
  }
}

class _AccentRow extends StatelessWidget {
  const _AccentRow(this.c);

  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: <Widget>[
        _Swatch(c.pri, 'pri'),
        _Swatch(c.priWeak, 'pri-weak'),
        _Swatch(c.priTx, 'pri-tx'),
        _Swatch(c.acc, 'acc'),
        _Swatch(c.accWeak, 'acc-weak'),
        _Swatch(c.accTx, 'acc-tx'),
        _Swatch(c.ok, 'ok'),
        _Swatch(c.okWeak, 'ok-weak'),
        _Swatch(c.okTx, 'ok-tx'),
      ],
    );
  }
}

class _SubjectsRow extends StatelessWidget {
  const _SubjectsRow(this.c);

  final AppColors c;

  static const List<String> _names = <String>[
    GalleryStrings.subjectMath,
    GalleryStrings.subjectEnglish,
    GalleryStrings.subjectKorean,
    GalleryStrings.subjectScience,
    GalleryStrings.subjectSocial,
    GalleryStrings.subjectEtc,
    GalleryStrings.subjectSeven,
    GalleryStrings.subjectEight,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: <Widget>[
        for (var i = 0; i < AppSubjectColors.count; i++)
          SubjectChip(name: _names[i], color: c.subject(i)),
      ],
    );
  }
}

class _TypographyColumn extends StatelessWidget {
  const _TypographyColumn(this.c);

  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(GalleryStrings.typographyDisplay, style: AppTypography.display.copyWith(color: c.tx)),
        Text(GalleryStrings.typographyTitle, style: AppTypography.title.copyWith(color: c.tx)),
        Text(GalleryStrings.typographyHeading, style: AppTypography.heading.copyWith(color: c.tx)),
        Text(GalleryStrings.typographyBody, style: AppTypography.body.copyWith(color: c.tx)),
        Text(GalleryStrings.typographyLabel, style: AppTypography.label.copyWith(color: c.tx2)),
        Text(GalleryStrings.typographyCaption, style: AppTypography.caption.copyWith(color: c.tx3)),
      ],
    );
  }
}

class _SpacingRow extends StatelessWidget {
  const _SpacingRow(this.c);

  final AppColors c;

  @override
  Widget build(BuildContext context) {
    const spaces = <double>[
      AppSpacing.s4,
      AppSpacing.s8,
      AppSpacing.s12,
      AppSpacing.s16,
      AppSpacing.s20,
      AppSpacing.s24,
      AppSpacing.s32,
    ];
    const radii = <double>[
      AppRadius.r8,
      AppRadius.r10,
      AppRadius.r12,
      AppRadius.r14,
      AppRadius.r16,
      AppRadius.r20,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.s8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: <Widget>[
            for (final s in spaces)
              Container(width: s, height: s, color: c.priWeak),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s8,
          children: <Widget>[
            for (final r in radii)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.sunk,
                  borderRadius: BorderRadius.circular(r),
                  border: Border.all(color: c.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  r.toInt().toString(),
                  style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ButtonsColumn extends StatelessWidget {
  const _ButtonsColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(
          label: GalleryStrings.buttonPrimary,
          size: AppButtonSize.large,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: <Widget>[
            Expanded(
              child: AppButton.secondary(
                label: GalleryStrings.buttonSecondary,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: AppButton.destructive(
                label: GalleryStrings.buttonDestructive,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton(
          label: GalleryStrings.buttonBusy,
          size: AppButtonSize.small,
          onPressed: () => Future<void>.delayed(const Duration(seconds: 2)),
        ),
        const SizedBox(height: AppSpacing.s8),
        const AppButton(label: GalleryStrings.buttonDisabled, size: AppButtonSize.small),
      ],
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow(this.c);

  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final start = DateTime(2026, 8, 20, 19, 32);
    final end = DateTime(2026, 8, 20, 21, 3);
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SubjectChip(name: GalleryStrings.subjectMath, color: c.subject(0)),
        SubjectChip(
          name: GalleryStrings.subjectEnglish,
          color: c.subject(1),
          selected: true,
        ),
        TimeChip.duration(const Duration(hours: 1, minutes: 28)),
        TimeChip.duration(const Duration(minutes: 45), tone: TimeChipTone.primary),
        TimeChip.range(start, end, tone: TimeChipTone.accent),
      ],
    );
  }
}

class _RingDemo extends StatelessWidget {
  const _RingDemo(this.c);

  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RingClock(
        nowHour: 21.05,
        segments: <RingSegment>[
          RingSegment(startHour: 9, endHour: 10.5, color: c.ringFill),
          RingSegment(startHour: 14, endHour: 16, color: c.ringFill),
          RingSegment(startHour: 19.5, endHour: 21, color: c.ringFill),
          RingSegment(startHour: 21, endHour: 22, color: c.ringFill, ghost: true),
        ],
        outerSegments: <RingSegment>[
          RingSegment(startHour: 8, endHour: 15, color: c.subject(0)),
          RingSegment(startHour: 18, endHour: 19, color: c.acc),
        ],
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              GalleryStrings.ringCenterLabel,
              style: AppTypography.caption.copyWith(color: c.tx3),
            ),
            Text(
              GalleryStrings.ringCenterValue,
              style: AppTypography.withWeight(AppTypography.label, 700)
                  .copyWith(color: c.tx, fontFeatures: AppTypography.tabularFigures),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateDemo extends StatelessWidget {
  const _StateDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const StatePanel.loading(),
        const Divider(),
        StatePanel.empty(
          actionLabel: GalleryStrings.emptyAction,
          onAction: () {},
        ),
        const Divider(),
        StatePanel.error(onAction: () {}),
      ],
    );
  }
}

class _OverlayDemo extends StatelessWidget {
  const _OverlayDemo();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton.secondary(
          label: GalleryStrings.openSheet,
          size: AppButtonSize.small,
          onPressed: () => showAppSheet<void>(
            context,
            title: GalleryStrings.sheetTitle,
            builder: (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Text(
                GalleryStrings.sheetBody,
                style: AppTypography.body.copyWith(color: c.tx2),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton.secondary(
          label: GalleryStrings.openModal,
          size: AppButtonSize.small,
          onPressed: () => showAppModal(
            context,
            title: GalleryStrings.modalTitle,
            body: GalleryStrings.modalBody,
            primaryLabel: GalleryStrings.buttonPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton.secondary(
          label: GalleryStrings.openModalDestructive,
          size: AppButtonSize.small,
          onPressed: () => showAppModal(
            context,
            title: GalleryStrings.modalDestructiveTitle,
            body: GalleryStrings.modalDestructiveBody,
            primaryLabel: GalleryStrings.buttonDestructive,
            destructive: true,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton.secondary(
          label: GalleryStrings.showToast,
          size: AppButtonSize.small,
          onPressed: () =>
              showAppToast(context, message: GalleryStrings.toastPlain),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton.secondary(
          label: GalleryStrings.showToastUndo,
          size: AppButtonSize.small,
          onPressed: () => showUndoToast(
            context,
            message: GalleryStrings.toastSample,
            onUndo: () =>
                showAppToast(context, message: GalleryStrings.toastUndone),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        const AppToast(
          message: GalleryStrings.toastSample,
          icon: LucideIcons.rotateCcw,
          actionLabel: CommonStrings.undo,
        ),
      ],
    );
  }
}

class _IconsRow extends StatelessWidget {
  const _IconsRow(this.c);

  final AppColors c;

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      LucideIcons.house,
      LucideIcons.flame,
      LucideIcons.clock,
      LucideIcons.camera,
      LucideIcons.check,
      LucideIcons.x,
      LucideIcons.plus,
      LucideIcons.lock,
      LucideIcons.settings,
      LucideIcons.refreshCw,
      LucideIcons.chevronLeft,
      LucideIcons.circleAlert,
      LucideIcons.inbox,
      LucideIcons.wifiOff,
      LucideIcons.bookOpen,
      LucideIcons.timer,
    ];
    return Wrap(
      spacing: AppSpacing.s12,
      runSpacing: AppSpacing.s12,
      children: <Widget>[for (final i in icons) LucideIcon(i, color: c.tx)],
    );
  }
}
