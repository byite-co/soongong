// TimeChip (S01): duration or clock range in a pill, tabular figures.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../utils/time_format.dart';

enum TimeChipTone { neutral, primary, accent }

class TimeChip extends StatelessWidget {
  const TimeChip({super.key, required this.text, this.tone = TimeChipTone.neutral});

  TimeChip.duration(
    Duration duration, {
    super.key,
    this.tone = TimeChipTone.neutral,
  }) : text = formatDuration(duration);

  TimeChip.range(
    DateTime start,
    DateTime end, {
    super.key,
    this.tone = TimeChipTone.neutral,
  }) : text = formatTimeRange(start, end);

  final String text;
  final TimeChipTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg) = switch (tone) {
      TimeChipTone.neutral => (c.sunk, c.tx2),
      TimeChipTone.primary => (c.priWeak, c.priTx),
      TimeChipTone.accent => (c.accWeak, c.accTx),
    };
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(
          color: fg,
          height: 1.2,
          fontFeatures: AppTypography.tabularFigures,
        ),
      ),
    );
  }
}
