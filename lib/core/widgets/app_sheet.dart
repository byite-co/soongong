// AppSheet (S01): bottom sheet (drag to close) that becomes a centred card
// on tablets. Sheets are not routes — call [showAppSheet] (CLAUDE.md §4).

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  bool isDismissible = true,
  bool enableDrag = true,
  bool tabletAsCard = true,
  bool useRootNavigator = true,
}) {
  final c = context.colors;
  final reduced = AppMotion.reduced(context);

  if (tabletAsCard && context.isTablet) {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: isDismissible,
      barrierLabel: 'sheet',
      barrierColor: c.scrim,
      transitionDuration: reduced ? Duration.zero : AppMotion.pop,
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(
            CurvedAnimation(parent: anim, curve: AppMotion.sheetCurve),
          ),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, _) => SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: AppLayout.sheetTabletWidth,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.86,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sheetTablet),
                  border: Border.all(color: c.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppSheet(title: title, showHandle: false, child: builder(ctx)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    backgroundColor: c.surface,
    barrierColor: c.scrim,
    elevation: 0,
    sheetAnimationStyle: reduced
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: AppMotion.sheetIn,
            curve: AppMotion.sheetCurve,
            reverseDuration: AppMotion.fade,
          ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      side: BorderSide(color: c.line),
    ),
    builder: (ctx) => AppSheet(
      title: title,
      showHandle: enableDrag,
      child: builder(ctx),
    ),
  );
}

/// Sheet body: optional drag handle, optional title, then [child].
/// Padding follows the prototype (`8px 20px 44px`).
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
  });

  final Widget child;
  final String? title;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.s8,
        AppSpacing.page,
        AppSpacing.sheetBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showHandle)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            )
          else
            const SizedBox(height: AppSpacing.s16),
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: Text(
                title!,
                style: AppTypography.heading.copyWith(color: c.tx),
              ),
            ),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}
