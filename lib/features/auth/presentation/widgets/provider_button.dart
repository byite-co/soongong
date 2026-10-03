// ProviderButton (S05): the Apple / Google / Kakao / e-mail rows of the login
// screen. Label-only in this session (brand marks are SVG assets, S15 adds
// them per platform guide); colours follow each platform's button guide.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/auth/auth_models.dart';

class ProviderButton extends StatelessWidget {
  const ProviderButton({
    super.key,
    required this.provider,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final SignupProvider provider;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (Color bg, Color fg, Color border) = switch (provider) {
      SignupProvider.apple => dark
          ? (const Color(0xFFFFFFFF), const Color(0xFF000000), const Color(0xFFFFFFFF))
          : (const Color(0xFF000000), const Color(0xFFFFFFFF), const Color(0xFF000000)),
      SignupProvider.google => (c.surface, c.tx, c.line),
      SignupProvider.kakao => (const Color(0xFFFEE500), const Color(0xFF191919), const Color(0xFFFEE500)),
      SignupProvider.email => (c.surface, c.tx, c.line),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                height: AppLayout.buttonLarge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (provider == SignupProvider.email) ...<Widget>[
                      LucideIcon(LucideIcons.mail, size: AppIcon.sizeSmall + 2, color: fg),
                      const SizedBox(width: AppSpacing.s8),
                    ],
                    Text(
                      label,
                      style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
