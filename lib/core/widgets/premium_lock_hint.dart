// PremiumLockHint (S01): one-line lock hint + paywall entry callback.
// Owned here; reused by S07 · S08 · S09.

import 'package:flutter/material.dart';

import '../strings/common_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'lucide_icon.dart';

class PremiumLockHint extends StatelessWidget {
  const PremiumLockHint({
    super.key,
    required this.onOpenPaywall,
    this.message = CommonStrings.premiumLocked,
    this.actionLabel = CommonStrings.premiumSeePlans,
  });

  final VoidCallback onOpenPaywall;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$message · $actionLabel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpenPaywall,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: c.sunk,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Row(
            children: <Widget>[
              LucideIcon.small(LucideIcons.lock, color: c.tx3),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(color: c.tx2),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                actionLabel,
                style: AppTypography.withWeight(AppTypography.label, 600)
                    .copyWith(color: c.priTx),
              ),
              const SizedBox(width: AppSpacing.s2),
              LucideIcon.small(LucideIcons.chevronRight, color: c.priTx),
            ],
          ),
        ),
      ),
    );
  }
}
