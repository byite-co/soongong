// FlowScaffold (S05): page frame for the gate · login · consent · onboarding
// flows — optional 52 px header (back + title), body centred at ≤ 600 dp on
// tablets (userflow `t4`), optional bottom action area.

import 'package:flutter/material.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'lucide_icon.dart';

class FlowScaffold extends StatelessWidget {
  const FlowScaffold({
    super.key,
    required this.child,
    this.title,
    this.onBack,
    this.bottom,
    this.maxWidth = AppLayout.tabletBreakpoint,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onBack;
  final Widget? bottom;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showHeader = title != null || onBack != null;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (showHeader)
              SizedBox(
                height: 52,
                child: Row(
                  children: <Widget>[
                    if (onBack != null)
                      SizedBox(
                        width: AppSpacing.touchTarget + AppSpacing.s4,
                        height: AppSpacing.touchTarget,
                        child: IconButton(
                          onPressed: onBack,
                          tooltip: CommonStrings.back,
                          icon: LucideIcon(LucideIcons.chevronLeft, color: c.tx),
                        ),
                      )
                    else
                      const SizedBox(width: AppSpacing.touchTarget + AppSpacing.s4),
                    Expanded(
                      child: Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        style: AppTypography.heading.copyWith(color: c.tx),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.touchTarget + AppSpacing.s4),
                  ],
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.s12,
                      AppSpacing.page,
                      AppSpacing.s24,
                    ),
                    children: <Widget>[child],
                  ),
                ),
              ),
            ),
            if (bottom != null)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.s8,
                      AppSpacing.page,
                      AppSpacing.s16,
                    ),
                    child: bottom,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
