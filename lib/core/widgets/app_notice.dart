// AppNotice (S05): one factual sentence in a soft box — `info` (blue-weak)
// for context ("생년월일을 확인했습니다 …"), `error` (orange-weak) for a failure
// whose input is kept (CLAUDE.md §5). Announced to screen readers.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

enum AppNoticeTone { info, error }

class AppNotice extends StatelessWidget {
  const AppNotice(this.text, {super.key, this.tone = AppNoticeTone.info});

  const AppNotice.error(this.text, {super.key}) : tone = AppNoticeTone.error;

  final String text;
  final AppNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final error = tone == AppNoticeTone.error;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s12),
        decoration: BoxDecoration(
          color: error ? c.accWeak : c.priWeak,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Text(
          text,
          style: AppTypography.label.copyWith(color: error ? c.accTx : c.priTx),
        ),
      ),
    );
  }
}
