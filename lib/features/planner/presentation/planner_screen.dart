// PlannerScreen (S07, PRD 4.2 · prototype 08/09 · nodes planner · planFold ·
// addSheet · datePick · plan3d · repeatSheet · editItem · editCancel ·
// editDelete · bandEdit · discard · t7 · s10).
//
// Month header with 이전/다음 (D26), the 6-week grid, a date tap or an
// upward drag folds the grid to the selected week and opens the day detail
// (공부 · 할 일 · 추가 자습 · 일정), a horizontal swipe toggles the 3D view
// (D26), the + button opens the register sheet. Writes go through
// PlannerController; deletions show the 5-second undo toast (D22).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/planner_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../reading/reading_routes.dart';
import '../../timetable/domain/recurrence_expander.dart';
import '../application/planner_providers.dart';
import '../domain/month_aggregate.dart';
import '../domain/month_grid.dart';
import '../domain/planner_draft.dart';
import 'month_grid_view.dart';
import 'planner_item_sheet.dart';

/// Widget keys for tests.
abstract final class PlannerKeys {
  static const Key prev = Key('planner-prev');
  static const Key next = Key('planner-next');
  static const Key today = Key('planner-today');
  static const Key toggle3d = Key('planner-3d');
  static const Key fab = Key('planner-fab');
  static const Key grid = Key('planner-grid');
  static const Key detail = Key('planner-detail');
  static const Key handle = Key('planner-handle');
  static Key item(String id) => Key('planner-item-$id');
  static Key done(String id) => Key('planner-done-$id');
  static Key capture(String id) => Key('planner-capture-$id');
  static Key record(String id) => Key('planner-record-$id');
  static Key band(String id) => Key('planner-detail-band-$id');
  static Key recurrence(String id) => Key('planner-detail-rec-$id');
}

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key, this.initialDate});

  /// `?date=yyyy-MM-dd` — opens that month with the day selected.
  final String? initialDate;

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> with SingleTickerProviderStateMixin {
  late String _monthKey;
  LocalDate? _selected;
  bool _collapsed = false;
  bool _mode3d = false;
  final Set<String> _busy = <String>{};
  late final AnimationController _extrude = AnimationController(vsync: this, duration: AppPlanner.transition);
  bool _initialised = false;

  @override
  void dispose() {
    _extrude.dispose();
    super.dispose();
  }

  void _initFrom(LocalDate today) {
    if (_initialised) return;
    _initialised = true;
    final initial = LocalDate.tryParse(widget.initialDate);
    _monthKey = (initial ?? today).monthKey;
    if (initial != null) {
      _selected = initial;
      _collapsed = true;
    }
  }

  // -------------------------------------------------------------------
  // State changes

  void _goMonth(MonthGrid next) => setState(() {
        _monthKey = next.key;
        if (_selected != null && !next.contains(_selected!)) {
          _selected = null;
          _collapsed = false;
        }
      });

  void _pickDay(LocalDate d, {required bool tablet}) => setState(() {
        if (tablet) {
          _selected = d;
          return;
        }
        if (_selected == d && _collapsed) {
          _collapsed = false;
          return;
        }
        _selected = d;
        _collapsed = true;
      });

  void _setCollapsed(bool v, LocalDate today) => setState(() {
        _collapsed = v;
        if (v) _selected ??= today;
      });

  void _toggle3d() {
    setState(() => _mode3d = !_mode3d);
    final reduced = AppMotion.reduced(context);
    if (reduced) {
      _extrude.value = _mode3d ? 1 : 0;
    } else if (_mode3d) {
      _extrude.forward();
    } else {
      _extrude.reverse();
    }
  }

  Future<void> _toggleDone(PlannerItem item) async {
    if (_busy.contains(item.id)) return;
    setState(() => _busy.add(item.id));
    try {
      await ref.read(plannerControllerProvider).setDone(item.id, done: !item.isDone);
    } on Object {
      if (mounted) showAppToast(context, message: PlannerStrings.doneFailed);
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  Future<void> _openSheet(PlannerDraft draft, DraftTarget target) async {
    final result = await showPlannerItemSheet(
      context,
      initial: draft,
      target: target,
      onOpenPaywall: () => context.push(AppPaths.settings),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case PlannerSheetSaved(:final draft, :final isNew):
        final date = draft.isPeriod ? draft.bandStart : draft.date;
        final grid = ref.read(plannerGridProvider(_monthKey));
        setState(() {
          if (!draft.isRepeat) {
            if (!grid.contains(date) || !grid.inMonth(date)) _monthKey = date.monthKey;
            _selected = date;
            _collapsed = true; // prototype `doAdd`: the saved day stays open
          }
        });
        showAppToast(context, message: isNew ? PlannerStrings.added : PlannerStrings.saved);
      case PlannerSheetDeleted(:final pending):
        showUndoToast(
          context,
          message: PlannerStrings.deleted,
          onUndo: () async {
            final restored = await pending.undo();
            if (mounted && restored) showAppToast(context, message: PlannerStrings.restored);
          },
        );
    }
  }

  void _add(LocalDate date) => _openSheet(PlannerDraft.create(date: date), const NewEntry());

  void _editItem(PlannerItem item) => _openSheet(
        PlannerDraft.fromItem(item),
        item.isBand ? ExistingBand(item.id) : ExistingItem(item.id),
      );

  void _editRecurrence(Recurrence r, LocalDate date) =>
      _openSheet(PlannerDraft.fromRecurrence(r, date: date), ExistingRecurrence(r.id));

  void _openRecords(List<StudySession> sessions) {
    if (sessions.length == 1) {
      context.push('/session/${sessions.single.id}');
      return;
    }
    unawaited(
      showAppSheet<void>(
        context,
        title: PlannerStrings.sessionsTitle,
        builder: (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final s in sessions)
              _SessionRow(
                session: s,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/session/${s.id}');
                },
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = ref.watch(plannerTodayProvider);
    _initFrom(today);
    final state = ref.watch(plannerMonthProvider(_monthKey));
    final grid = ref.watch(plannerGridProvider(_monthKey));
    final density = ref.watch(plannerDensityProvider);
    final entitled = ref.watch(plannerEntitledProvider);
    final subjects = <String, Subject>{
      for (final s in ref.watch(plannerSubjectsProvider).value ?? const <Subject>[]) s.id: s,
    };
    final tablet = context.isTablet;
    final selected = tablet ? (_selected ?? today) : _selected;

    final body = switch (state) {
      PlannerMonthLoading() => const StatePanel.loading(),
      PlannerMonthError() => StatePanel.error(
          title: PlannerStrings.loadFailed,
          onAction: () => ref.invalidate(plannerMonthProvider(_monthKey)),
        ),
      PlannerMonthReady(:final aggregate) => tablet
          ? _tabletBody(c, aggregate, density, today, selected!, subjects, entitled)
          : _phoneBody(c, aggregate, density, today, selected, subjects, entitled),
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Header(
                  grid: grid,
                  today: today,
                  aggregate: state is PlannerMonthReady ? state.aggregate : null,
                  mode3d: _mode3d,
                  onPrev: () => _goMonth(grid.previous()),
                  onNext: () => _goMonth(grid.next()),
                  onToday: () {
                    _goMonth(MonthGrid.of(today.year, today.month, weekStart: grid.weekStart));
                    setState(() => _selected = today);
                  },
                  onToggle3d: _toggle3d,
                ),
                // Always the same height so the body's constraints never
                // change when the 3D legend appears (no fold jump).
                SizedBox(
                  height: _Legend.height,
                  child: AnimatedOpacity(
                    opacity: _mode3d ? 1 : 0,
                    duration: AppMotion.of(context, AppMotion.fade),
                    child: _mode3d ? _Legend(entitled: entitled) : const SizedBox.shrink(),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
            Positioned(
              right: AppSpacing.page,
              bottom: AppSpacing.s16,
              child: _Fab(onTap: () => _add(selected ?? today)),
            ),
          ],
        ),
      ),
    );
  }

  static const double _weekdayHeaderHeight = 28;

  Widget _weekdayHeader(AppColors c, MonthGrid grid) => Container(
        height: _weekdayHeaderHeight,
        padding: const EdgeInsets.fromLTRB(AppSpacing.s12, AppSpacing.s10, AppSpacing.s12, 0),
        child: Row(
          children: <Widget>[
            for (final w in grid.columnWeekdays)
              Expanded(
                child: Text(
                  PlannerStrings.weekdayOf(w),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: w == DateTime.sunday
                        ? const Color(0xFFC0392B)
                        : w == DateTime.saturday
                            ? c.priTx
                            : c.tx3,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _grid(MonthAggregate aggregate, density, LocalDate today, LocalDate? selected, Map<String, Subject> subjects, bool entitled, {required bool tablet}) {
    final collapsedRow = !tablet && _collapsed && selected != null ? aggregate.grid.rowOf(selected) : null;
    return AnimatedBuilder(
      animation: _extrude,
      builder: (context, _) => MonthGridView(
        aggregate: aggregate,
        density: density,
        today: today,
        selected: selected,
        subjects: subjects,
        collapsedRow: collapsedRow == -1 ? null : collapsedRow,
        extrusion: _extrude.value,
        entitled: entitled,
        onPickDay: (d) => _pickDay(d, tablet: tablet),
      ),
    );
  }

  Widget _phoneBody(AppColors c, MonthAggregate aggregate, density, LocalDate today, LocalDate? selected, Map<String, Subject> subjects, bool entitled) {
    final folded = _collapsed && selected != null && aggregate.grid.rowOf(selected) != -1;
    return LayoutBuilder(
      builder: (context, constraints) {
        const handleH = 32.0;
        final full = constraints.maxHeight - handleH - _weekdayHeaderHeight;
        const foldedH = 64.0;
        final gridH = folded ? foldedH : full;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _weekdayHeader(c, aggregate.grid),
            GestureDetector(
              key: PlannerKeys.grid,
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) _setCollapsed(true, today);
                if (v > 200) _setCollapsed(false, today);
              },
              onHorizontalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0).abs() > 200) _toggle3d();
              },
              child: AnimatedContainer(
                duration: AppMotion.of(context, AppPlanner.fold),
                curve: AppMotion.meterCurve,
                height: gridH,
                padding: EdgeInsets.fromLTRB(AppSpacing.s12, _mode3d ? AppPlanner.columnMax : 0, AppSpacing.s12, 0),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                child: _grid(aggregate, density, today, selected, subjects, entitled, tablet: false),
              ),
            ),
            Semantics(
              button: true,
              label: folded ? PlannerStrings.unfold : PlannerStrings.fold,
              child: GestureDetector(
                key: PlannerKeys.handle,
                behavior: HitTestBehavior.opaque,
                onTap: () => _setCollapsed(!folded, today),
                onVerticalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v < -200) _setCollapsed(true, today);
                  if (v > 200) _setCollapsed(false, today);
                },
                child: SizedBox(
                  height: handleH,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.tx3.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (folded)
              Expanded(
                child: _DayDetail(
                  key: PlannerKeys.detail,
                  date: selected,
                  today: today,
                  aggregate: aggregate,
                  subjects: subjects,
                  entitled: entitled,
                  busy: _busy,
                  onToggleDone: _toggleDone,
                  onEditItem: _editItem,
                  onEditRecurrence: (r) => _editRecurrence(r, selected),
                  onOpenRecords: _openRecords,
                  onAdd: () => _add(selected),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tabletBody(AppColors c, MonthAggregate aggregate, density, LocalDate today, LocalDate selected, Map<String, Subject> subjects, bool entitled) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _weekdayHeader(c, aggregate.grid),
              Expanded(
                child: GestureDetector(
                  key: PlannerKeys.grid,
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragEnd: (d) {
                    if ((d.primaryVelocity ?? 0).abs() > 200) _toggle3d();
                  },
                  child: Container(
                    padding: EdgeInsets.fromLTRB(AppSpacing.s12, _mode3d ? AppPlanner.columnMax : 0, AppSpacing.s12, AppSpacing.s12),
                    decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
                    child: _grid(aggregate, density, today, selected, subjects, entitled, tablet: true),
                  ),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: c.line),
        SizedBox(
          width: 360,
          child: _DayDetail(
            key: PlannerKeys.detail,
            date: selected,
            today: today,
            aggregate: aggregate,
            subjects: subjects,
            entitled: entitled,
            busy: _busy,
            onToggleDone: _toggleDone,
            onEditItem: _editItem,
            onEditRecurrence: (r) => _editRecurrence(r, selected),
            onOpenRecords: _openRecords,
            onAdd: () => _add(selected),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header · legend · FAB

class _Header extends StatelessWidget {
  const _Header({
    required this.grid,
    required this.today,
    required this.aggregate,
    required this.mode3d,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onToggle3d,
  });

  final MonthGrid grid;
  final LocalDate today;
  final MonthAggregate? aggregate;
  final bool mode3d;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onToggle3d;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isCurrent = grid.inMonth(today);
    Widget nav(Key key, IconData icon, String label, VoidCallback onTap) => SizedBox(
          width: AppSpacing.touchTarget,
          height: AppSpacing.touchTarget,
          child: IconButton(
            key: key,
            onPressed: onTap,
            tooltip: label,
            icon: LucideIcon(icon, color: c.tx2),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s8, AppSpacing.s8, AppSpacing.page, 0),
      child: Row(
        children: <Widget>[
          nav(PlannerKeys.prev, LucideIcons.chevronLeft, PlannerStrings.prevMonth, onPrev),
          Text(
            PlannerStrings.monthTitle(grid.year, grid.month),
            style: AppTypography.heading.copyWith(color: c.tx, fontSize: 20),
          ),
          nav(PlannerKeys.next, LucideIcons.chevronRight, PlannerStrings.nextMonth, onNext),
          if (!isCurrent)
            Semantics(
              button: true,
              label: PlannerStrings.goToday,
              child: GestureDetector(
                key: PlannerKeys.today,
                behavior: HitTestBehavior.opaque,
                onTap: onToday,
                child: Container(
                  height: AppSpacing.touchTarget,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
                  alignment: Alignment.center,
                  child: Text(
                    PlannerStrings.goToday,
                    style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.priTx),
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (aggregate != null)
            Flexible(
              child: Text(
                PlannerStrings.planned(aggregate!.doneCount, aggregate!.plannedCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: c.tx2),
              ),
            ),
          // `kPlannerSuggestionsEnabled` (PRD 4.3 P1 제안 받기): hidden slot.
          if (kPlannerSuggestionsEnabled) ...<Widget>[
            const SizedBox(width: AppSpacing.s8),
            Text(PlannerStrings.suggest, style: AppTypography.caption.copyWith(color: c.priTx)),
          ],
          const SizedBox(width: AppSpacing.s8),
          Semantics(
            button: true,
            toggled: mode3d,
            label: PlannerStrings.toggle3d,
            child: GestureDetector(
              key: PlannerKeys.toggle3d,
              behavior: HitTestBehavior.opaque,
              onTap: onToggle3d,
              child: Container(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                decoration: BoxDecoration(
                  color: mode3d ? c.priWeak : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                ),
                child: Center(child: LucideIcon(LucideIcons.box, color: mode3d ? c.priTx : c.tx3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entitled});

  static const double height = 26;

  final bool entitled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: AppSpacing.s4),
            Text(label, style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 11)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s6, AppSpacing.page, 0),
      child: Wrap(
        spacing: AppSpacing.s12,
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          item(c.isDark ? AppPlanner.columnFrontDark : AppPlanner.columnFront, PlannerStrings.legendSeated),
          if (entitled) item(c.isDark ? AppPlanner.plannedFrontDark : AppPlanner.plannedFront, PlannerStrings.legendPlanned),
          item(c.acc, PlannerStrings.legendToday),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: PlannerStrings.add,
      child: GestureDetector(
        key: PlannerKeys.fab,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: c.pri, shape: BoxShape.circle, boxShadow: c.shadow),
          child: Center(child: LucideIcon(LucideIcons.plus, color: c.onPri)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day detail (planFold)

class _DayDetail extends StatelessWidget {
  const _DayDetail({
    super.key,
    required this.date,
    required this.today,
    required this.aggregate,
    required this.subjects,
    required this.entitled,
    required this.busy,
    required this.onToggleDone,
    required this.onEditItem,
    required this.onEditRecurrence,
    required this.onOpenRecords,
    required this.onAdd,
  });

  final LocalDate date;
  final LocalDate today;
  final MonthAggregate aggregate;
  final Map<String, Subject> subjects;
  final bool entitled;
  final Set<String> busy;
  final ValueChanged<PlannerItem> onToggleDone;
  final ValueChanged<PlannerItem> onEditItem;
  final ValueChanged<Recurrence> onEditRecurrence;
  final ValueChanged<List<StudySession>> onOpenRecords;
  final VoidCallback onAdd;

  Color _color(AppColors c, String? subjectId, {Color? fallback}) {
    final s = subjectId == null ? null : subjects[subjectId];
    return s != null ? c.subject(s.colorIndex) : (fallback ?? c.tx3);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final day = aggregate.dayOf(date);
    final isPast = !date.isAfter(today);
    final study = day.study.toList();
    final todos = day.todos.toList();
    final self = day.self.toList();
    final events = day.events.toList();
    final bands = aggregate.bands.where((b) => date >= b.bandStart! && date <= b.bandEnd!).toList();
    final recs = day.recurrences;
    final empty = study.isEmpty && todos.isEmpty && self.isEmpty && events.isEmpty && bands.isEmpty && recs.isEmpty;

    final summary = isPast
        ? (day.hasSeated ? PlannerStrings.seatedSummary(PlannerStrings.hm(day.seatedSeconds)) : PlannerStrings.noRecord)
        : PlannerStrings.plannedCount(day.plannableCount);
    final plannedMin = day.plannedMinutes;
    final actualMin = study.fold<int>(0, (a, i) => a + aggregate.actualMinutes(i));
    final studySum = entitled
        ? (isPast ? PlannerStrings.studyPlannedActual(plannedMin, actualMin) : PlannerStrings.studyPlanned(plannedMin))
        : (isPast ? PlannerStrings.studyActual(actualMin) : PlannerStrings.plannedCount(study.length));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                PlannerStrings.dayTitle(date.month, date.day, PlannerStrings.weekdayOf(date.weekday)),
                style: AppTypography.heading.copyWith(color: c.tx),
              ),
              if (date == today) ...<Widget>[
                const SizedBox(width: AppSpacing.s8),
                Text(PlannerStrings.today, style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.accTx)),
              ],
              const Spacer(),
              Text(summary, style: AppTypography.label.copyWith(color: c.tx2)),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: <Widget>[
                for (final b in bands)
                  _BandRow(
                    key: PlannerKeys.band(b.id),
                    item: b,
                    color: _color(c, b.subjectId, fallback: c.tx),
                    onTap: () => onEditItem(b),
                  ),
                if (study.isNotEmpty) ...<Widget>[
                  _SectionLabel('${PlannerStrings.sectionStudy} · $studySum'),
                  for (final it in study)
                    _ItemRow(
                      item: it,
                      color: _color(c, it.subjectId),
                      subjectName: it.subjectId == null ? null : subjects[it.subjectId]?.name,
                      busy: busy.contains(it.id),
                      sessions: aggregate.sessionsByItem[it.id] ?? const <StudySession>[],
                      actualMinutes: aggregate.actualMinutes(it),
                      entitled: entitled,
                      showCapture: true,
                      onToggle: () => onToggleDone(it),
                      onTap: () => onEditItem(it),
                      onOpenRecords: onOpenRecords,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s8),
                    child: Row(
                      children: <Widget>[
                        LucideIcon.small(LucideIcons.camera, color: c.tx3),
                        const SizedBox(width: AppSpacing.s6),
                        Expanded(
                          child: Text(
                            entitled ? PlannerStrings.captureHint : PlannerStrings.captureHintLocked,
                            style: AppTypography.caption.copyWith(color: c.tx3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (todos.isNotEmpty) ...<Widget>[
                  const _SectionLabel(PlannerStrings.sectionTodo),
                  for (final it in todos)
                    _ItemRow(
                      item: it,
                      color: _color(c, it.subjectId),
                      subjectName: it.subjectId == null ? null : subjects[it.subjectId]?.name,
                      busy: busy.contains(it.id),
                      sessions: aggregate.sessionsByItem[it.id] ?? const <StudySession>[],
                      actualMinutes: aggregate.actualMinutes(it),
                      entitled: entitled,
                      showCapture: false,
                      onToggle: () => onToggleDone(it),
                      onTap: () => onEditItem(it),
                      onOpenRecords: onOpenRecords,
                    ),
                ],
                if (self.isNotEmpty) ...<Widget>[
                  _SectionLabel(
                    '${PlannerStrings.sectionSelf} · ${PlannerStrings.selfSum(self.fold<int>(0, (a, i) => a + aggregate.actualMinutes(i)))}',
                    color: c.accTx,
                  ),
                  for (final it in self)
                    _ItemRow(
                      item: it,
                      color: _color(c, it.subjectId, fallback: c.acc),
                      subjectName: it.subjectId == null ? null : subjects[it.subjectId]?.name,
                      busy: busy.contains(it.id),
                      sessions: aggregate.sessionsByItem[it.id] ?? const <StudySession>[],
                      actualMinutes: aggregate.actualMinutes(it),
                      entitled: entitled,
                      showCapture: false,
                      onToggle: () => onToggleDone(it),
                      onTap: () => onEditItem(it),
                      onOpenRecords: onOpenRecords,
                    ),
                ],
                if (events.isNotEmpty || recs.isNotEmpty) ...<Widget>[
                  const _SectionLabel(PlannerStrings.sectionEvents),
                  for (final it in events)
                    _ItemRow(
                      item: it,
                      color: _color(c, it.subjectId, fallback: c.tx),
                      subjectName: it.subjectId == null ? null : subjects[it.subjectId]?.name,
                      busy: false,
                      sessions: const <StudySession>[],
                      actualMinutes: 0,
                      entitled: entitled,
                      showCapture: false,
                      onToggle: null,
                      onTap: () => onEditItem(it),
                      onOpenRecords: onOpenRecords,
                    ),
                  for (final r in recs)
                    _RecurrenceRow(
                      key: PlannerKeys.recurrence(r.recurrence.id),
                      instance: r,
                      color: _color(c, r.subjectId, fallback: c.tx),
                      onTap: () => onEditRecurrence(r.recurrence),
                    ),
                ],
                if (empty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s14),
                    child: Row(
                      children: <Widget>[
                        Container(width: 3, height: 20, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: AppSpacing.s10),
                        Expanded(child: Text(PlannerStrings.empty, style: AppTypography.body.copyWith(color: c.tx3))),
                        TextButton(
                          onPressed: onAdd,
                          child: Text(
                            PlannerStrings.emptyAction,
                            style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx),
                          ),
                        ),
                      ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s14, bottom: AppSpacing.s2),
      child: Text(text, style: AppTypography.caption.copyWith(color: color ?? c.tx3)),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.color,
    required this.subjectName,
    required this.busy,
    required this.sessions,
    required this.actualMinutes,
    required this.entitled,
    required this.showCapture,
    required this.onToggle,
    required this.onTap,
    required this.onOpenRecords,
  });

  final PlannerItem item;
  final Color color;
  final String? subjectName;
  final bool busy;
  final List<StudySession> sessions;
  final int actualMinutes;
  final bool entitled;
  final bool showCapture;
  final VoidCallback? onToggle;
  final VoidCallback onTap;
  final ValueChanged<List<StudySession>> onOpenRecords;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isTodo = item.kind == PlannerKind.todo;
    final isSelf = item.kind == PlannerKind.self;
    final value = switch (item.kind) {
      PlannerKind.study => sessions.isEmpty
          ? (item.targetMinutes == null ? null : PlannerStrings.targetMinutes(item.targetMinutes!))
          : (entitled && item.targetMinutes != null
              ? '$actualMinutes/${item.targetMinutes}${PlannerStrings.targetCustomUnit}'
              : PlannerStrings.targetMinutes(actualMinutes)),
      PlannerKind.self => sessions.isEmpty ? null : PlannerStrings.targetMinutes(actualMinutes),
      PlannerKind.event => item.startTime == null ? null : PlannerStrings.recurrenceTime(item.startTime!.key, item.endTime?.key ?? ''),
      PlannerKind.todo => null,
    };
    return Opacity(
      opacity: item.isDone ? 0.55 : 1,
      child: Container(
        key: PlannerKeys.item(item.id),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
        child: Row(
          children: <Widget>[
            if (onToggle != null)
              Semantics(
                button: true,
                label: PlannerStrings.toggleDone,
                checked: item.isDone,
                child: GestureDetector(
                  key: PlannerKeys.done(item.id),
                  behavior: HitTestBehavior.opaque,
                  onTap: busy ? null : onToggle,
                  child: SizedBox(
                    width: AppSpacing.touchTarget,
                    height: AppSpacing.touchTarget,
                    child: Center(
                      child: busy
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.tx3))
                          : Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: item.isDone ? (isSelf ? c.acc : color) : Colors.transparent,
                                borderRadius: BorderRadius.circular(isTodo ? AppRadius.pill : 6),
                                border: Border.all(color: item.isDone ? (isSelf ? c.acc : color) : c.line, width: 1.5),
                              ),
                              child: item.isDone ? Icon(Icons.check, size: 12, color: isSelf ? AppAccent.onOrange : Colors.white) : null,
                            ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: AppSpacing.touchTarget),
            if (!isTodo) ...<Widget>[
              Container(width: 3, height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: AppSpacing.s10),
            ],
            Expanded(
              child: Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(color: c.tx, height: 1.3),
                        ),
                        if (subjectName != null || (item.rangeText != null && item.rangeText!.isNotEmpty))
                          Text(
                            <String>[?subjectName, ?item.rangeText].where((s) => s.isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(color: c.tx3),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (value != null)
              sessions.isEmpty
                  ? Text(value, style: AppTypography.withWeight(AppTypography.caption, 500).copyWith(color: isSelf ? c.accTx : c.tx3))
                  : Semantics(
                      button: true,
                      label: PlannerStrings.sessionDetail,
                      child: GestureDetector(
                        key: PlannerKeys.record(item.id),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onOpenRecords(sessions),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10, horizontal: AppSpacing.s4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(value, style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: isSelf ? c.accTx : c.priTx)),
                              LucideIcon.small(LucideIcons.chevronRight, color: c.tx3),
                            ],
                          ),
                        ),
                      ),
                    ),
            if (showCapture)
              Semantics(
                button: true,
                label: PlannerStrings.captureSemantics,
                child: GestureDetector(
                  key: PlannerKeys.capture(item.id),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push(readingCaptureFromPlanner(item.id)),
                  child: SizedBox(
                    width: AppSpacing.touchTarget,
                    height: AppSpacing.touchTarget,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        LucideIcon(LucideIcons.camera, color: c.tx3, size: 18),
                        if (!entitled)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: c.pri, shape: BoxShape.circle),
                              child: Icon(Icons.lock, size: 8, color: c.onPri),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BandRow extends StatelessWidget {
  const _BandRow({super.key, required this.item, required this.color, required this.onTap});

  final PlannerItem item;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String fmt(LocalDate d) => '${d.month}/${d.day}';
    final range = item.bandStart == item.bandEnd ? fmt(item.bandStart!) : PlannerStrings.bandRange(fmt(item.bandStart!), fmt(item.bandEnd!));
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: <Widget>[
              Container(
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.center,
                child: Text(
                  item.title,
                  style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: Colors.white, height: 1.2),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(child: Text(range, style: AppTypography.caption.copyWith(color: c.tx3))),
              LucideIcon.small(LucideIcons.chevronRight, color: c.tx3),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({super.key, required this.instance, required this.color, required this.onTap});

  final RecurrenceInstance instance;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: <Widget>[
              const SizedBox(width: AppSpacing.touchTarget),
              Container(
                width: 3,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(child: Text(instance.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(color: c.tx, height: 1.3))),
              Text(
                PlannerStrings.recurrenceTime(instance.start.key, instance.end.key),
                style: AppTypography.caption.copyWith(color: c.tx3, fontFeatures: AppTypography.tabularFigures),
              ),
              const SizedBox(width: AppSpacing.s4),
              LucideIcon.small(LucideIcons.repeat, color: c.tx3),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final StudySession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final start = session.startedAt.toLocal();
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${start.month}/${start.day} ${LocalTime.of(start).key}',
                  style: AppTypography.body.copyWith(color: c.tx),
                ),
              ),
              Text(PlannerStrings.hm(session.seatedSeconds), style: AppTypography.label.copyWith(color: c.tx2)),
              const SizedBox(width: AppSpacing.s4),
              LucideIcon.small(LucideIcons.chevronRight, color: c.tx3),
            ],
          ),
        ),
      ),
    );
  }
}
