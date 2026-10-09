// HomeScreen (`/home`, userflow `home homeEmpty s1 s2 s3 s4 s14 t5 recover
// recoverConfirm`, S05 · PRD 4.2): header (date · gear → /settings), 24 h
// ring (순공 파랑 · 자습 주황 · 일정 바깥 링), today's 순공시간, 불꽃 연속 일수
// (D4), 남은 할 일 N개, 집중 시작 CTA, today's todo list, three card slots,
// and the session-recovery sheet. Facts only — no sums of planned time.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/common_strings.dart';
import '../../../core/strings/home_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/application/post_login.dart';
import '../../auth/domain/auth_redirect.dart';
import '../application/home_providers.dart';
import '../application/home_slots.dart';
import '../application/session_recovery.dart';
import '../domain/home_summary.dart';
import '../domain/recovery_candidate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _busyTodos = <String>{};
  bool _promptScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = ref.read(pendingToastProvider.notifier).take();
      if (message != null) showAppToast(context, message: message);
    });
    ref.listenManual<RecoveryCandidate?>(
      homeRecoveryCandidateProvider,
      (_, candidate) {
        if (candidate != null) _maybePrompt(candidate);
      },
      fireImmediately: true,
    );
  }

  void _maybePrompt(RecoveryCandidate candidate) {
    if (_promptScheduled || ref.read(recoveryPromptedProvider)) return;
    _promptScheduled = true;
    ref.read(recoveryPromptedProvider.notifier).mark();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showRecovery(candidate);
    });
  }

  Future<void> _showRecovery(RecoveryCandidate candidate) async {
    final handler = ref.read(sessionRecoveryHandlerProvider);
    final result = await showAppSheet<_RecoveryResult>(
      context,
      title: HomeStrings.recoverTitle,
      builder: (_) => _RecoverySheet(candidate: candidate, handler: handler, today: ref.read(homeTodayProvider)),
    );
    if (!mounted) return;
    final recorded = formatDuration(candidate.recorded);
    switch (result) {
      case null || _RecoveryKept():
        showAppToast(context, message: HomeStrings.recoverKept);
      case _RecoveryResumed(:final route):
        if (route != null) unawaited(context.push(route));
      case _RecoveryFinished():
        showAppToast(context, message: HomeStrings.recoverFinished(recorded));
      case _RecoveryDiscarded():
        showAppToast(context, message: HomeStrings.recoverDiscarded(recorded));
      case _RecoveryFailed():
        showAppToast(context, message: HomeStrings.recoverFailed);
    }
  }

  Future<void> _toggleDone(PlannerItem item) async {
    if (_busyTodos.contains(item.id)) return;
    setState(() => _busyTodos.add(item.id));
    try {
      await ref.read(plannerRepositoryProvider).setDone(item.id, done: !item.isDone);
    } on Object {
      if (mounted) showAppToast(context, message: HomeStrings.saveFailedRetry);
    } finally {
      if (mounted) setState(() => _busyTodos.remove(item.id));
    }
  }

  void _retry() {
    ref
      ..invalidate(homeRecentSessionsProvider)
      ..invalidate(homeAllSessionsProvider)
      ..invalidate(homeTodayItemsProvider)
      ..invalidate(homeRecurrencesProvider)
      ..invalidate(homeSubjectsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final view = ref.watch(homeViewProvider);
    final today = ref.watch(homeTodayProvider);
    final now = ref.read(appClockProvider).now();
    final readingCard = ref.watch(readingCardSlotProvider);
    final subscriptionCard = ref.watch(subscriptionCardSlotProvider);
    final recoveryCard = ref.watch(recoverySlotProvider);

    final Widget content = switch (view) {
      HomeLoading() => const Padding(
          padding: EdgeInsets.only(top: AppSpacing.s44),
          child: StatePanel.loading(),
        ),
      HomeError() => StatePanel.error(onAction: _retry),
      HomeReady(:final summary) => _HomeBody(
          summary: summary,
          now: now,
          busyTodos: _busyTodos,
          onToggleDone: _toggleDone,
          readingCard: readingCard,
          subscriptionCard: subscriptionCard,
          recoveryCard: recoveryCard,
        ),
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s8, AppSpacing.page, AppSpacing.s32),
          children: <Widget>[
            _Header(today: today),
            content,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.today});

  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                HomeStrings.today,
                style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.accTx),
              ),
              Text(
                HomeStrings.fullDate(today.year, today.month, today.day, today.weekday),
                style: AppTypography.heading.copyWith(color: c.tx),
              ),
            ],
          ),
        ),
        SizedBox(
          width: AppSpacing.touchTarget,
          height: AppSpacing.touchTarget,
          child: IconButton(
            onPressed: () => context.push(AppPaths.settings),
            tooltip: HomeStrings.settings,
            icon: LucideIcon(LucideIcons.settings, color: c.tx2),
          ),
        ),
      ],
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.summary,
    required this.now,
    required this.busyTodos,
    required this.onToggleDone,
    required this.readingCard,
    required this.subscriptionCard,
    required this.recoveryCard,
  });

  final HomeSummary summary;
  final DateTime now;
  final Set<String> busyTodos;
  final ValueChanged<PlannerItem> onToggleDone;
  final HomeCardBuilder? readingCard;
  final HomeCardBuilder? subscriptionCard;
  final HomeCardBuilder? recoveryCard;

  @override
  Widget build(BuildContext context) {
    final hero = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (readingCard != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          readingCard!(context),
        ],
        const SizedBox(height: AppSpacing.s16),
        _HeroCard(summary: summary, now: now),
        const SizedBox(height: AppSpacing.s12),
        _CtaButton(
          label: HomeStrings.startFocus,
          onPressed: () => context.push(AppPaths.measureSetup),
        ),
      ],
    );
    final todos = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.s24),
        _TodoSection(summary: summary, busyTodos: busyTodos, onToggleDone: onToggleDone),
        if (subscriptionCard != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s20),
          subscriptionCard!(context),
        ],
        if (recoveryCard != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          recoveryCard!(context),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppLayout.tabletBreakpoint) {
          // t5: ring | list
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 5, child: hero),
              const SizedBox(width: AppSpacing.s20),
              Expanded(flex: 6, child: todos),
            ],
          );
        }
        return Column(children: <Widget>[hero, todos]);
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary, required this.now});

  final HomeSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final inner = <RingSegment>[
      for (final a in summary.arcs)
        if (a.kind == HomeArcKind.study || a.kind == HomeArcKind.self)
          RingSegment(
            startHour: a.startHour,
            endHour: a.endHour,
            color: a.kind == HomeArcKind.self ? c.acc : c.pri,
          ),
    ];
    final outer = <RingSegment>[
      for (final a in summary.arcs)
        if (a.kind == HomeArcKind.event || a.kind == HomeArcKind.recurrence)
          RingSegment(
            startHour: a.startHour,
            endHour: a.endHour,
            color: c.tx2,
            ghost: a.kind == HomeArcKind.recurrence,
          ),
    ];

    final diff = summary.diffFromYesterday;
    final String sub1;
    if (!summary.hasSeatedToday && summary.seatedYesterday == Duration.zero) {
      sub1 = HomeStrings.emptyHint;
    } else if (diff == Duration.zero) {
      sub1 = HomeStrings.sameAsYesterday;
    } else if (diff.isNegative) {
      sub1 = HomeStrings.lessThanYesterday(formatDuration(-diff));
    } else {
      sub1 = HomeStrings.moreThanYesterday(formatDuration(diff));
    }
    final String? sub2 = summary.totalTodos == 0
        ? null
        : summary.remainingTodos > 0
            ? HomeStrings.remainingTodos(summary.remainingTodos)
            : HomeStrings.noTodosLeft;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.r20),
        border: Border.all(color: c.line),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              RingClock(
                segments: inner,
                outerSegments: outer,
                nowHour: hourOfDay(now),
                semanticsLabel: HomeStrings.ringSemantics,
                center: _StreakBadge(days: summary.streak.current),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(HomeStrings.studyTime, style: AppTypography.caption.copyWith(color: c.tx3)),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      formatDuration(summary.seatedToday),
                      style: AppTypography.display.copyWith(
                        color: c.tx,
                        fontFeatures: AppTypography.tabularFigures,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(sub1, style: AppTypography.caption.copyWith(color: c.tx2)),
                    if (sub2 != null)
                      Text(sub2, style: AppTypography.caption.copyWith(color: c.tx2)),
                  ],
                ),
              ),
            ],
          ),
          if (summary.subjectTotals.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.s12),
            Text(
              summary.subjectTotals
                  .map((t) => '${t.name} ${formatDuration(t.seated)}')
                  .join(' · '),
              style: AppTypography.caption.copyWith(color: c.tx2),
            ),
          ],
          const SizedBox(height: AppSpacing.s6),
          Text(
            summary.events.isEmpty
                ? HomeStrings.todayEventsNone
                : HomeStrings.todayEvents(summary.events.map((e) => e.label).join(' · ')),
            style: AppTypography.caption.copyWith(color: c.tx3),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: HomeStrings.streakDays(days),
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            LucideIcon(LucideIcons.flame, size: 22, color: days > 0 ? c.acc : c.tx3),
            Text(
              '$days',
              style: AppTypography.withWeight(AppTypography.heading, 700).copyWith(
                color: c.tx,
                fontFeatures: AppTypography.tabularFigures,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 집중 시작 — the one orange CTA (PRD 8장: 주황 = CTA · 자습 · 오늘).
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: c.acc,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: SizedBox(
              height: AppLayout.buttonLarge,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  LucideIcon(LucideIcons.play, size: AppIcon.sizeSmall + 2, color: c.onAcc),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    label,
                    style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.onAcc),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodoSection extends StatelessWidget {
  const _TodoSection({required this.summary, required this.busyTodos, required this.onToggleDone});

  final HomeSummary summary;
  final Set<String> busyTodos;
  final ValueChanged<PlannerItem> onToggleDone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(HomeStrings.todayTodos, style: AppTypography.heading.copyWith(color: c.tx)),
            if (summary.totalTodos > 0) ...<Widget>[
              const SizedBox(width: AppSpacing.s8),
              Text(
                HomeStrings.doneOfTotal(summary.doneTodos, summary.totalTodos),
                style: AppTypography.caption.copyWith(
                  color: c.tx3,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () => context.go(AppPaths.planner),
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
                foregroundColor: c.priTx,
              ),
              child: Text(
                HomeStrings.plannerLink,
                style: AppTypography.withWeight(AppTypography.label, 600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        if (summary.todos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: c.line),
            ),
            child: StatePanel.empty(
              title: HomeStrings.todosEmpty,
              icon: LucideIcons.listTodo,
              actionLabel: HomeStrings.addTodo,
              onAction: () => context.go(AppPaths.planner),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: <Widget>[
                for (var i = 0; i < summary.todos.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: c.line),
                  _TodoRow(
                    item: summary.todos[i],
                    busy: busyTodos.contains(summary.todos[i].id),
                    onToggle: () => onToggleDone(summary.todos[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.item, required this.busy, required this.onToggle});

  final PlannerItem item;
  final bool busy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final done = item.isDone;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
      child: Row(
        children: <Widget>[
          Semantics(
            checked: done,
            label: HomeStrings.toggleDone,
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: IconButton(
                onPressed: busy ? null : onToggle,
                icon: busy
                    ? SizedBox(
                        width: AppIcon.sizeSmall,
                        height: AppIcon.sizeSmall,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.pri),
                      )
                    : LucideIcon(
                        done ? LucideIcons.squareCheck : LucideIcons.square,
                        color: done ? c.priTx : c.tx3,
                      ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: AppTypography.body.copyWith(
                    color: done ? c.tx3 : c.tx,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (item.rangeText != null && item.rangeText!.trim().isNotEmpty)
                  Text(item.rangeText!, style: AppTypography.caption.copyWith(color: c.tx3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session recovery sheet (userflow `recover` · `recoverConfirm`)

sealed class _RecoveryResult {
  const _RecoveryResult();
}

class _RecoveryKept extends _RecoveryResult {
  const _RecoveryKept();
}

class _RecoveryResumed extends _RecoveryResult {
  const _RecoveryResumed(this.route);

  final String? route;
}

class _RecoveryFinished extends _RecoveryResult {
  const _RecoveryFinished();
}

class _RecoveryDiscarded extends _RecoveryResult {
  const _RecoveryDiscarded();
}

class _RecoveryFailed extends _RecoveryResult {
  const _RecoveryFailed();
}

class _RecoverySheet extends StatefulWidget {
  const _RecoverySheet({required this.candidate, required this.handler, required this.today});

  final RecoveryCandidate candidate;
  final SessionRecoveryHandler handler;
  final LocalDate today;

  @override
  State<_RecoverySheet> createState() => _RecoverySheetState();
}

class _RecoverySheetState extends State<_RecoverySheet> {
  bool _busy = false;

  String get _startedLabel {
    final t = widget.candidate.startedAt.toLocal();
    final day = LocalDate.of(t);
    if (day == widget.today) return '${HomeStrings.today} ${formatClock(t)}';
    if (day == widget.today.addDays(-1)) return '${HomeStrings.yesterday} ${formatClock(t)}';
    return '${HomeStrings.monthDay(t.month, t.day)} ${formatClock(t)}';
  }

  Future<void> _run(Future<_RecoveryResult> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    _RecoveryResult result;
    try {
      result = await action();
    } on Object {
      result = const _RecoveryFailed();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(result);
  }

  Future<void> _discard() async {
    if (_busy) return;
    final confirmed = await showAppModal(
      context,
      title: HomeStrings.recoverDiscardTitle,
      body: HomeStrings.recoverDiscardBody(formatDuration(widget.candidate.recorded)),
      primaryLabel: CommonStrings.delete,
      destructive: true,
      onConfirm: () => widget.handler.discard(widget.candidate),
    );
    if (!mounted || !confirmed) return;
    Navigator.of(context).pop(const _RecoveryDiscarded());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final recorded = formatDuration(widget.candidate.recorded);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          HomeStrings.recoverBody(_startedLabel, recorded),
          style: AppTypography.body.copyWith(color: c.tx2),
        ),
        const SizedBox(height: AppSpacing.s20),
        AppButton(
          label: HomeStrings.recoverResume,
          busy: _busy,
          onPressed: () => _run(() async => _RecoveryResumed(await widget.handler.resume(widget.candidate))),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton.secondary(
          label: HomeStrings.recoverFinish,
          onPressed: _busy
              ? null
              : () => _run(() async {
                    await widget.handler.finish(widget.candidate);
                    return const _RecoveryFinished();
                  }),
        ),
        const SizedBox(height: AppSpacing.s4),
        TextButton(
          onPressed: _busy ? null : _discard,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
            foregroundColor: c.accTx,
          ),
          child: Text(
            HomeStrings.recoverDiscard,
            style: AppTypography.withWeight(AppTypography.label, 600),
          ),
        ),
      ],
    );
  }
}
