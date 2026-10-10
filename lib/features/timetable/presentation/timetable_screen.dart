// TimetableScreen (`/timetable`, S08, PRD 4.2 · prototype 14 · userflow tt ·
// t6 · evEdit · evScope): a week of 00–24 h × 7 day columns. 순공 blocks
// are the saved sessions' seated/manual runs clipped to each local day
// (subject colour, 자습 orange), recurrences are dashed blocks, a block tap
// opens the session detail, a horizontal swipe or the arrows move the week,
// today's column carries the current-time line, the week starts on the
// settings' weekday. Recurrences are edited/deleted as a whole through S07's
// sheet and `PlannerController` (5-second undo, D22); tablets show the
// recurrence list in a second column.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/lifecycle/calendar_day.dart';
import '../../../core/strings/planner_strings.dart';
import '../../../core/strings/timetable_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../billing/billing_routes.dart';
import '../../planner/application/planner_controller.dart';
import '../../planner/application/planner_providers.dart';
import '../../planner/domain/planner_draft.dart';
import '../../planner/presentation/planner_item_sheet.dart';
import '../application/timetable_providers.dart';
import '../domain/recurrence_expander.dart';
import '../domain/week_timetable.dart';

/// Widget keys for tests.
abstract final class TimetableKeys {
  static const Key prev = Key('timetable-prev');
  static const Key next = Key('timetable-next');
  static const Key thisWeek = Key('timetable-this-week');
  static const Key pager = Key('timetable-pager');
  static const Key grid = Key('timetable-grid');
  static const Key empty = Key('timetable-empty');
  static const Key emptyStart = Key('timetable-empty-start');
  static const Key emptyAdd = Key('timetable-empty-add');
  static const Key nowLine = Key('timetable-now');
  static const Key noRecord = Key('timetable-no-record');
  static const Key addInPlanner = Key('timetable-add-in-planner');
  static Key column(LocalDate day) => Key('timetable-col-${day.key}');
  static Key block(String sessionId, LocalDate day, int index) => Key('timetable-block-$sessionId-${day.key}-$index');
  static Key recurrenceBlock(String id, LocalDate day) => Key('timetable-rec-block-$id-${day.key}');
  static Key recurrenceRow(String id) => Key('timetable-rec-$id');
  static Key recurrenceDelete(String id) => Key('timetable-rec-delete-$id');
}

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  /// Page index of the current week; earlier weeks are lower pages.
  static const int _base = 5000;
  static const Duration _tickEvery = Duration(minutes: 1);

  late final PageController _pager = PageController(initialPage: _base);
  int _offset = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The current-time line moves once a minute, and the calendar day is
    // re-read so a screen left open across midnight shows the new week ([S08b]).
    _tick = Timer.periodic(_tickEvery, (_) {
      if (!mounted) return;
      ref.read(calendarDayProvider.notifier).refresh();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pager.dispose();
    super.dispose();
  }

  LocalDate _weekStartAt(int offset) {
    final today = ref.read(plannerTodayProvider);
    final weekStart = ref.read(plannerWeekStartProvider);
    return today.startOfWeek(weekStart).addDays(7 * offset);
  }

  void _goOffset(int offset) {
    final page = _base + offset;
    if (AppMotion.reduced(context)) {
      _pager.jumpToPage(page);
    } else {
      unawaited(_pager.animateToPage(page, duration: AppMotion.pop, curve: Curves.easeOut));
    }
  }

  // -------------------------------------------------------------------
  // Recurrences (whole-recurrence edit / delete, PRD 4.2)

  void _openPaywall() => unawaited(context.push(paywallPath));

  void _undoToast(String title, PendingDelete pending) => showUndoToast(
        context,
        message: TimetableStrings.deletedAll(title),
        onUndo: () async {
          final restored = await pending.undo();
          if (mounted && restored) showAppToast(context, message: TimetableStrings.restored);
        },
      );

  Future<void> _editRecurrence(Recurrence r) async {
    final today = ref.read(plannerTodayProvider);
    final result = await showPlannerItemSheet(
      context,
      initial: PlannerDraft.fromRecurrence(r, date: today),
      target: ExistingRecurrence(r.id),
      onOpenPaywall: _openPaywall,
    );
    if (!mounted || result == null) return;
    switch (result) {
      case PlannerSheetSaved(:final draft):
        showAppToast(context, message: TimetableStrings.changedAll(draft.trimmedTitle));
      case PlannerSheetDeleted(:final pending):
        _undoToast(r.title, pending);
    }
  }

  Future<void> _deleteRecurrence(Recurrence r) async {
    PendingDelete? pending;
    final ok = await showAppModal(
      context,
      title: TimetableStrings.deleteTitle,
      body: TimetableStrings.deleteBody,
      primaryLabel: TimetableStrings.deleteAll,
      destructive: true,
      onConfirm: () async {
        pending = await ref.read(plannerControllerProvider).delete(ExistingRecurrence(r.id));
      },
    );
    final p = pending;
    if (!mounted || !ok || p == null) return;
    _undoToast(r.title, p);
  }

  Future<void> _addRecurrence() async {
    final today = ref.read(plannerTodayProvider);
    final draft = PlannerDraft.create(date: today, kind: PlannerKind.event).copyWith(eventMode: DraftEventMode.repeat);
    final result = await showPlannerItemSheet(context, initial: draft, onOpenPaywall: _openPaywall);
    if (!mounted || result == null) return;
    if (result is PlannerSheetSaved) showAppToast(context, message: PlannerStrings.added);
  }

  void _openSession(String id) => unawaited(context.push('/session/$id'));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = ref.watch(plannerTodayProvider);
    final weekStartDay = ref.watch(plannerWeekStartProvider);
    final weekStart = today.startOfWeek(weekStartDay).addDays(7 * _offset);
    final subjects = <String, Subject>{
      for (final s in ref.watch(plannerSubjectsProvider).value ?? const <Subject>[]) s.id: s,
    };
    final recurrences = ref.watch(plannerRecurrencesProvider).value ?? const <Recurrence>[];
    final state = ref.watch(timetableWeekProvider(weekStart.key));
    final total = state is TimetableWeekReady ? state.week.totalSeconds : null;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              weekStart: weekStart,
              offset: _offset,
              totalSeconds: total,
              onPrev: () => _goOffset(_offset - 1),
              onNext: () => _goOffset(_offset + 1),
              onThisWeek: () => _goOffset(0),
            ),
            Expanded(
              child: PageView.builder(
                key: TimetableKeys.pager,
                controller: _pager,
                onPageChanged: (i) => setState(() => _offset = i - _base),
                itemBuilder: (_, i) => _WeekPage(
                  weekStart: _weekStartAt(i - _base),
                  today: today,
                  now: ref.read(appClockProvider).now(),
                  weekStartDay: weekStartDay,
                  subjects: subjects,
                  recurrences: recurrences,
                  onTapBlock: _openSession,
                  onEditRecurrence: _editRecurrence,
                  onDeleteRecurrence: _deleteRecurrence,
                  // Sync callbacks: an async one would keep the AppButton busy
                  // while the sheet / pushed route is open.
                  onAddRecurrence: () => unawaited(_addRecurrence()),
                  onAddInPlanner: () => context.go(AppPaths.planner),
                  onStartFocus: () => unawaited(context.push(AppPaths.measureSetup)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header

class _Header extends StatelessWidget {
  const _Header({
    required this.weekStart,
    required this.offset,
    required this.totalSeconds,
    required this.onPrev,
    required this.onNext,
    required this.onThisWeek,
  });

  final LocalDate weekStart;
  final int offset;
  final int? totalSeconds;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onThisWeek;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final end = weekStart.addDays(6);
    final range = TimetableStrings.weekRange(weekStart.month, weekStart.day, end.month, end.day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s12, AppSpacing.s8, AppSpacing.s6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(TimetableStrings.title, style: AppTypography.title.copyWith(color: c.tx)),
                const SizedBox(height: AppSpacing.s2),
                Wrap(
                  spacing: AppSpacing.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(range, style: AppTypography.label.copyWith(color: c.tx2)),
                    if (totalSeconds != null && totalSeconds! > 0)
                      Text(
                        TimetableStrings.weekSeated(formatDuration(Duration(seconds: totalSeconds!))),
                        style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (offset != 0)
            TextButton(
              key: TimetableKeys.thisWeek,
              onPressed: onThisWeek,
              child: Text(
                TimetableStrings.thisWeek,
                style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx),
              ),
            ),
          IconButton(
            key: TimetableKeys.prev,
            tooltip: TimetableStrings.prevWeek,
            onPressed: onPrev,
            icon: LucideIcon(LucideIcons.chevronLeft, color: c.tx2),
          ),
          IconButton(
            key: TimetableKeys.next,
            tooltip: TimetableStrings.nextWeek,
            onPressed: onNext,
            icon: LucideIcon(LucideIcons.chevronRight, color: c.tx2),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One week page

class _WeekPage extends ConsumerWidget {
  const _WeekPage({
    required this.weekStart,
    required this.today,
    required this.now,
    required this.weekStartDay,
    required this.subjects,
    required this.recurrences,
    required this.onTapBlock,
    required this.onEditRecurrence,
    required this.onDeleteRecurrence,
    required this.onAddRecurrence,
    required this.onAddInPlanner,
    required this.onStartFocus,
  });

  final LocalDate weekStart;
  final LocalDate today;
  final DateTime now;
  final int weekStartDay;
  final Map<String, Subject> subjects;
  final List<Recurrence> recurrences;
  final ValueChanged<String> onTapBlock;
  final ValueChanged<Recurrence> onEditRecurrence;
  final ValueChanged<Recurrence> onDeleteRecurrence;
  final VoidCallback onAddRecurrence;
  final VoidCallback onAddInPlanner;
  final VoidCallback onStartFocus;

  /// Two columns (grid · recurrences) from this body width.
  static const double twoColumnMinWidth = 700;
  static const double sideWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timetableWeekProvider(weekStart.key));
    switch (state) {
      case TimetableWeekLoading():
        return const StatePanel.loading();
      case TimetableWeekError():
        return StatePanel.error(
          title: TimetableStrings.loadFailed,
          onAction: () => ref.invalidate(timetableWeekProvider(weekStart.key)),
        );
      case TimetableWeekReady(:final week):
        // The grid shows whenever there is anything to place on it — 순공
        // blocks or recurrence instances (S08 original: 반복 일정 in the
        // grid); the empty card only when the week has neither ([S08b]).
        final gridOrEmpty = week.hasBlocks || week.hasRecurrences
            ? _WeekGrid(
                week: week,
                today: today,
                now: now,
                subjects: subjects,
                onTapBlock: onTapBlock,
                onTapRecurrence: onEditRecurrence,
              )
            : _EmptyCard(onStart: onStartFocus, onAdd: onAddRecurrence);
        final noRecord = week.hasBlocks || !week.hasRecurrences
            ? null
            : _NoRecordRow(onStart: onStartFocus, onAdd: onAddRecurrence);
        final side = _RecurrenceSection(
          recurrences: recurrences,
          subjects: subjects,
          weekStartDay: weekStartDay,
          onEdit: onEditRecurrence,
          onDelete: onDeleteRecurrence,
          onAddInPlanner: onAddInPlanner,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= twoColumnMinWidth) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.s8, AppSpacing.s24),
                      children: <Widget>[gridOrEmpty, const SizedBox(height: AppSpacing.s10), const _Legend(), ?noRecord],
                    ),
                  ),
                  SizedBox(
                    width: sideWidth,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s8, 0, AppSpacing.page, AppSpacing.s24),
                      children: <Widget>[side],
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24),
              children: <Widget>[
                gridOrEmpty,
                const SizedBox(height: AppSpacing.s10),
                const _Legend(),
                ?noRecord,
                const SizedBox(height: AppSpacing.s24),
                side,
              ],
            );
          },
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Week grid (prototype: 26px hour gutter · 7 columns · 456px · lines every 3 h)

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.week,
    required this.today,
    required this.now,
    required this.subjects,
    required this.onTapBlock,
    required this.onTapRecurrence,
  });

  final WeekTimetable week;
  final LocalDate today;
  final DateTime now;
  final Map<String, Subject> subjects;
  final ValueChanged<String> onTapBlock;
  final ValueChanged<Recurrence> onTapRecurrence;

  static const double hourGutter = 26;
  static const double gridHeight = 456;
  static const double dayHeaderHeight = 34;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: TimetableKeys.grid,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s10, AppSpacing.s10, AppSpacing.s10, AppSpacing.s12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.line),
        boxShadow: c.shadow,
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: dayHeaderHeight,
            child: Row(
              children: <Widget>[
                const SizedBox(width: hourGutter),
                for (final day in week.days) Expanded(child: _DayHeader(day: day, isToday: day == today)),
              ],
            ),
          ),
          SizedBox(
            height: gridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(width: hourGutter, child: _HourGutter()),
                for (final day in week.days)
                  Expanded(
                    child: _DayColumn(
                      day: day,
                      isToday: day == today,
                      now: now,
                      blocks: week.blocks[day] ?? const <TimetableBlock>[],
                      recurrences: week.recurrences[day] ?? const <RecurrenceInstance>[],
                      seated: week.seatedOn(day),
                      subjects: subjects,
                      onTapBlock: onTapBlock,
                      onTapRecurrence: onTapRecurrence,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.isToday});

  final LocalDate day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = isToday
        ? c.accTx
        : day.weekday == DateTime.sunday
            ? const Color(0xFFC0392B)
            : day.weekday == DateTime.saturday
                ? c.priTx
                : c.tx3;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(TimetableStrings.weekdayOf(day.weekday), style: AppTypography.caption.copyWith(color: color, fontSize: 11, height: 1.2)),
        Text(
          '${day.day}',
          style: AppTypography.withWeight(AppTypography.caption, isToday ? 700 : 600).copyWith(color: isToday ? c.accTx : c.tx, height: 1.2),
        ),
      ],
    );
  }
}

class _HourGutter extends StatelessWidget {
  const _HourGutter();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (var i = 0; i <= 8; i++)
              Positioned(
                top: i / 8 * h - 6,
                left: 0,
                child: Text(
                  TimetableStrings.hourLabel(i * 3),
                  style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10, height: 1.2),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.isToday,
    required this.now,
    required this.blocks,
    required this.recurrences,
    required this.seated,
    required this.subjects,
    required this.onTapBlock,
    required this.onTapRecurrence,
  });

  final LocalDate day;
  final bool isToday;
  final DateTime now;
  final List<TimetableBlock> blocks;
  final List<RecurrenceInstance> recurrences;
  final int seated;
  final Map<String, Subject> subjects;
  final ValueChanged<String> onTapBlock;
  final ValueChanged<Recurrence> onTapRecurrence;

  static const double minBlockFraction = 0.02;

  /// Top and height of a block inside the 00–24 column: the minimum height
  /// never pushes the block past the day's end (a 23:59 session stays
  /// visible and tappable, [S08b]).
  static (double, double) place(double startMinutes, double endMinutes, double h) {
    final height = math.max((endMinutes - startMinutes) / 1440 * h, h * minBlockFraction);
    final top = math.min(startMinutes / 1440 * h, h - height);
    return (math.max(0, top), height);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: TimetableStrings.daySemantics('${day.month}월 ${day.day}일', formatDuration(Duration(seconds: seated))),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          final nowMinutes = now.hour * 60 + now.minute + now.second / 60;
          return Stack(
            key: TimetableKeys.column(day),
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isToday ? c.accWeak : c.sunk,
                    border: Border(right: BorderSide(color: c.line, width: 0.5)),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: _HourLinesPainter(color: c.line))),
              for (final inst in recurrences)
                Positioned(
                  top: place(inst.start.minutesOfDay.toDouble(), inst.end.minutesOfDay.toDouble(), h).$1,
                  height: place(inst.start.minutesOfDay.toDouble(), inst.end.minutesOfDay.toDouble(), h).$2,
                  left: 1,
                  right: 1,
                  child: _RecurrenceBlock(
                    key: TimetableKeys.recurrenceBlock(inst.recurrence.id, day),
                    instance: inst,
                    color: _subjectColor(c, inst.subjectId),
                    onTap: () => onTapRecurrence(inst.recurrence),
                  ),
                ),
              for (final (i, b) in blocks.indexed)
                Positioned(
                  top: place(b.startMinutes, b.endMinutes, h).$1,
                  height: place(b.startMinutes, b.endMinutes, h).$2,
                  left: 2,
                  right: 2,
                  child: _SessionBlock(
                    key: TimetableKeys.block(b.sessionId, day, i),
                    block: b,
                    color: b.isSelf ? c.acc : _subjectColor(c, b.subjectId),
                    name: _blockName(b),
                    onTap: () => onTapBlock(b.sessionId),
                  ),
                ),
              if (isToday)
                Positioned(
                  key: TimetableKeys.nowLine,
                  top: nowMinutes / 1440 * h - 1,
                  left: 0,
                  right: 0,
                  child: Semantics(
                    label: '${TimetableStrings.nowLine} ${formatClock(now)}',
                    child: Container(height: 2, color: c.acc),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _subjectColor(AppColors c, String? subjectId) {
    final s = subjectId == null ? null : subjects[subjectId];
    return s == null ? c.pri : c.subject(s.colorIndex);
  }

  String _blockName(TimetableBlock b) {
    final s = b.subjectId == null ? null : subjects[b.subjectId!];
    if (s == null) return b.isSelf ? TimetableStrings.blockSelf : TimetableStrings.blockStudy;
    return s.name.length > 2 ? s.name.substring(0, 2) : s.name;
  }
}

class _HourLinesPainter extends CustomPainter {
  const _HourLinesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    for (var i = 1; i < 8; i++) {
      final y = i / 8 * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HourLinesPainter old) => old.color != color;
}

class _SessionBlock extends StatelessWidget {
  const _SessionBlock({
    super.key,
    required this.block,
    required this.color,
    required this.name,
    required this.onTap,
  });

  final TimetableBlock block;
  final Color color;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = TimetableStrings.blockSemantics(
      name,
      formatClock(block.start),
      block.endMinutes >= 1440 ? '24:00' : formatClock(block.end),
      formatDuration(Duration(seconds: block.seconds)),
    );
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => Container(
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.r8 / 2)),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.symmetric(vertical: 1),
            clipBehavior: Clip.hardEdge,
            child: constraints.maxHeight >= 16
                ? Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: AppTypography.withWeight(AppTypography.caption, 600)
                        .copyWith(color: AppAccent.onBlue, fontSize: 10, height: 1.2),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _RecurrenceBlock extends StatelessWidget {
  const _RecurrenceBlock({super.key, required this.instance, required this.color, required this.onTap});

  final RecurrenceInstance instance;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: TimetableStrings.recurrenceSemantics(instance.title, instance.start.key, instance.end.key),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              border: Border(left: BorderSide(color: color, width: 2)),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppRadius.r8 / 2)),
            ),
            padding: const EdgeInsets.fromLTRB(3, 1, 1, 1),
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.topLeft,
            child: constraints.maxHeight >= 14
                ? Text(
                    instance.title,
                    maxLines: constraints.maxHeight >= 28 ? 2 : 1,
                    overflow: TextOverflow.clip,
                    style: AppTypography.caption.copyWith(color: c.tx2, fontSize: 9, height: 1.2),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend · empty state

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(Widget swatch, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            swatch,
            const SizedBox(width: AppSpacing.s6),
            Text(label, style: AppTypography.caption.copyWith(color: c.tx3)),
          ],
        );
    Widget square(Color color) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        );
    return Wrap(
      spacing: AppSpacing.s14,
      runSpacing: AppSpacing.s6,
      children: <Widget>[
        item(square(c.pri), TimetableStrings.legendSeated),
        item(square(c.acc), TimetableStrings.legendSelf),
        item(
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: c.pri.withValues(alpha: 0.16),
              border: Border(left: BorderSide(color: c.pri, width: 2)),
            ),
          ),
          TimetableStrings.legendRecurrence,
        ),
        item(square(c.accWeak), TimetableStrings.legendToday),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onStart, required this.onAdd});

  final VoidCallback onStart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: TimetableKeys.empty,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s32, AppSpacing.s20, AppSpacing.s24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.line),
        boxShadow: c.shadow,
      ),
      child: Column(
        children: <Widget>[
          LucideIcon(LucideIcons.table, size: AppIcon.sizeLarge, color: c.tx3),
          const SizedBox(height: AppSpacing.s14),
          Text(TimetableStrings.emptyTitle, textAlign: TextAlign.center, style: AppTypography.heading.copyWith(color: c.tx)),
          const SizedBox(height: AppSpacing.s6),
          Text(TimetableStrings.emptyBody, textAlign: TextAlign.center, style: AppTypography.label.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s20),
          Wrap(
            spacing: AppSpacing.s10,
            runSpacing: AppSpacing.s10,
            alignment: WrapAlignment.center,
            children: <Widget>[
              AppButton(
                key: TimetableKeys.emptyStart,
                label: TimetableStrings.emptyStart,
                size: AppButtonSize.small,
                expand: false,
                onPressed: onStart,
              ),
              AppButton.secondary(
                key: TimetableKeys.emptyAdd,
                label: TimetableStrings.emptyAddRecurrence,
                size: AppButtonSize.small,
                expand: false,
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Under the grid of a week that has recurrences but no 순공: the empty
/// card's facts and next actions in one row ([S08b]).
class _NoRecordRow extends StatelessWidget {
  const _NoRecordRow({required this.onStart, required this.onAdd});

  final VoidCallback onStart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      key: TimetableKeys.noRecord,
      padding: const EdgeInsets.only(top: AppSpacing.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(TimetableStrings.emptyTitle, style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.tx)),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s10,
            runSpacing: AppSpacing.s10,
            children: <Widget>[
              AppButton(
                key: TimetableKeys.emptyStart,
                label: TimetableStrings.emptyStart,
                size: AppButtonSize.small,
                expand: false,
                onPressed: onStart,
              ),
              AppButton.secondary(
                key: TimetableKeys.emptyAdd,
                label: TimetableStrings.emptyAddRecurrence,
                size: AppButtonSize.small,
                expand: false,
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recurrence section (prototype 반복 일정 · 플래너에서 추가)

class _RecurrenceSection extends StatelessWidget {
  const _RecurrenceSection({
    required this.recurrences,
    required this.subjects,
    required this.weekStartDay,
    required this.onEdit,
    required this.onDelete,
    required this.onAddInPlanner,
  });

  final List<Recurrence> recurrences;
  final Map<String, Subject> subjects;
  final int weekStartDay;
  final ValueChanged<Recurrence> onEdit;
  final ValueChanged<Recurrence> onDelete;
  final VoidCallback onAddInPlanner;

  String _days(Recurrence r) {
    final order = List<int>.generate(7, (i) => (weekStartDay - 1 + i) % 7 + 1);
    return order.where(r.occursOnWeekday).map(PlannerStrings.weekdayOf).join('·');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(TimetableStrings.recurrencesTitle, style: AppTypography.heading.copyWith(color: c.tx))),
            TextButton(
              key: TimetableKeys.addInPlanner,
              onPressed: onAddInPlanner,
              child: Text(
                TimetableStrings.addInPlanner,
                style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        if (recurrences.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: Text(TimetableStrings.recurrencesEmpty, style: AppTypography.label.copyWith(color: c.tx3)),
          )
        else
          for (final r in recurrences)
            _RecurrenceRow(
              key: TimetableKeys.recurrenceRow(r.id),
              recurrence: r,
              color: r.subjectId != null && subjects[r.subjectId!] != null ? c.subject(subjects[r.subjectId!]!.colorIndex) : c.tx2,
              summary: TimetableStrings.recurrenceSummary(_days(r), r.startTime.key, r.endTime.key),
              onTap: () => onEdit(r),
              onDelete: () => onDelete(r),
            ),
      ],
    );
  }
}

class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({
    super.key,
    required this.recurrence,
    required this.color,
    required this.summary,
    required this.onTap,
    required this.onDelete,
  });

  final Recurrence recurrence;
  final Color color;
  final String summary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '${recurrence.title} · $summary · ${TimetableStrings.editRecurrence}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s8),
          padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s6, AppSpacing.s4, AppSpacing.s6),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: <Widget>[
              CustomPaint(size: const Size(14, 14), painter: _DashedSquarePainter(color: color)),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recurrence.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx, height: 1.3),
                    ),
                    Text(summary, style: AppTypography.caption.copyWith(color: c.tx3)),
                  ],
                ),
              ),
              IconButton(
                key: TimetableKeys.recurrenceDelete(recurrence.id),
                tooltip: TimetableStrings.deleteRecurrence,
                onPressed: onDelete,
                icon: LucideIcon(LucideIcons.x, color: c.tx3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedSquarePainter extends CustomPainter {
  const _DashedSquarePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 3.0;
    const gap = 2.0;
    final rect = Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final end = math.min(d + dash, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedSquarePainter old) => old.color != color;
}
