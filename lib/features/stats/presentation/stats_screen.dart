// StatsScreen (`/stats`, S08, PRD 4.2 통계 · 4.3 오답 누적 · 4.4 구독 종료 ·
// prototype 10 · userflow t1 · s11 · s12 · statsP · statsF · cross):
// weekly/monthly 순공 from the clipped slices — summary (합계 · 기록일 ·
// 일평균 · 지난주 비교 facts), 과목색 stacked bars, 과목별 split (할 일 ·
// 자습), 시간대 histogram, 연속 착석 분포 and 평균 세션 길이 — plus the
// wrongs section (free teaser · premium store stream · expired read-only).
// Charts are CustomPainters with text value labels, no chart package.
// Fewer than 3 recorded days shows the sparse state; the cross view keeps
// its slot hidden (`kStatsCrossViewEnabled`). Facts only, no evaluation.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/common_strings.dart';
import '../../../core/strings/planner_strings.dart';
import '../../../core/strings/stats_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../billing/billing_routes.dart';
import '../../planner/application/planner_providers.dart';
import '../../planner/presentation/recurrence_editor.dart' show SegmentedChoice;
import '../../wrongs/wrongs_routes.dart';
import '../application/stats_providers.dart';
import '../domain/seated_aggregate.dart';

/// Widget keys for tests.
abstract final class StatsKeys {
  static const Key prev = Key('stats-prev');
  static const Key next = Key('stats-next');
  static const Key today = Key('stats-today');
  static const Key skeleton = Key('stats-skeleton');
  static const Key sparse = Key('stats-sparse');
  static const Key sparseStart = Key('stats-sparse-start');
  static const Key summary = Key('stats-summary');
  static const Key compare = Key('stats-compare');
  static const Key bars = Key('stats-bars');
  static const Key barTooltip = Key('stats-bar-tooltip');
  static const Key subjects = Key('stats-subjects');
  static const Key hours = Key('stats-hours');
  static const Key focus = Key('stats-focus');
  static const Key wrongs = Key('stats-wrongs');
  static const Key wrongsBadge = Key('stats-wrongs-badge');
  static const Key wrongsSeeAll = Key('stats-wrongs-see-all');
  static const Key wrongsResubscribe = Key('stats-wrongs-resubscribe');
  static const Key crossView = Key('stats-cross-view');
}

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsPeriod _period = StatsPeriod.week;
  int _offset = 0;

  /// Two columns from this body width (prototype t1: 340px + 1fr).
  static const double twoColumnMinWidth = 700;
  static const double leftWidth = 340;

  StatsRange _range(LocalDate today, int weekStart) => _period == StatsPeriod.week
      ? StatsRange.week(today.startOfWeek(weekStart)).shift(_offset)
      : StatsRange.month(today.year, today.month).shift(_offset);

  void _setPeriod(StatsPeriod p) => setState(() {
        _period = p;
        _offset = 0;
      });

  void _openPaywall() => unawaited(context.push(paywallPath));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = ref.watch(plannerTodayProvider);
    final weekStart = ref.watch(plannerWeekStartProvider);
    final range = _range(today, weekStart);
    final subjects = <String, Subject>{
      for (final s in ref.watch(plannerSubjectsProvider).value ?? const <Subject>[]) s.id: s,
    };
    final record = ref.watch(statsRecordProvider);

    final wrongs = _WrongsSection(
      rangeKey: range.key,
      period: _period,
      subjects: subjects,
      onOpenPaywall: _openPaywall,
      onSeeAll: () => context.push(wrongsPath),
    );

    final Widget body = switch (record) {
      StatsRecordLoading() => const _Skeleton(),
      StatsRecordError() => StatePanel.error(
          title: StatsStrings.loadFailed,
          onAction: () => ref.invalidate(statsRecordProvider),
        ),
      StatsRecordReady(:final isSparse, :final totalSeconds) when isSparse => ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24),
          children: <Widget>[
            wrongs,
            const SizedBox(height: AppSpacing.s16),
            _SparseCard(totalSeconds: totalSeconds, onStart: () => unawaited(context.push(AppPaths.measureSetup))),
          ],
        ),
      StatsRecordReady() => _StatsBody(
          range: range,
          offset: _offset,
          today: today,
          weekStart: weekStart,
          subjects: subjects,
          wrongs: wrongs,
        ),
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              period: _period,
              range: range,
              offset: _offset,
              onPeriod: _setPeriod,
              onPrev: () => setState(() => _offset--),
              onNext: () => setState(() => _offset++),
              onToday: () => setState(() => _offset = 0),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: title · 주간/월간 · range navigation

class _Header extends StatelessWidget {
  const _Header({
    required this.period,
    required this.range,
    required this.offset,
    required this.onPeriod,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final StatsPeriod period;
  final StatsRange range;
  final int offset;
  final ValueChanged<StatsPeriod> onPeriod;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = period == StatsPeriod.week
        ? StatsStrings.weekRange(range.from.month, range.from.day, range.to.month, range.to.day)
        : PlannerStrings.pickerMonth(range.from.year, range.from.month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s12, AppSpacing.s8, AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(StatsStrings.title, style: AppTypography.title.copyWith(color: c.tx))),
              SizedBox(
                width: 150,
                child: SegmentedChoice<StatsPeriod>(
                  value: period,
                  compact: true,
                  options: const <(StatsPeriod, String)>[
                    (StatsPeriod.week, StatsStrings.periodWeek),
                    (StatsPeriod.month, StatsStrings.periodMonth),
                  ],
                  onChanged: onPeriod,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(child: Text(label, style: AppTypography.label.copyWith(color: c.tx2))),
              if (offset != 0)
                TextButton(
                  key: StatsKeys.today,
                  onPressed: onToday,
                  child: Text(
                    StatsStrings.goToday,
                    style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx),
                  ),
                ),
              IconButton(
                key: StatsKeys.prev,
                tooltip: period == StatsPeriod.week ? StatsStrings.prevWeek : StatsStrings.prevMonth,
                onPressed: onPrev,
                icon: LucideIcon(LucideIcons.chevronLeft, color: c.tx2),
              ),
              IconButton(
                key: StatsKeys.next,
                tooltip: period == StatsPeriod.week ? StatsStrings.nextWeek : StatsStrings.nextMonth,
                onPressed: onNext,
                icon: LucideIcon(LucideIcons.chevronRight, color: c.tx2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body (range view)

class _StatsBody extends ConsumerWidget {
  const _StatsBody({
    required this.range,
    required this.offset,
    required this.today,
    required this.weekStart,
    required this.subjects,
    required this.wrongs,
  });

  final StatsRange range;
  final int offset;
  final LocalDate today;
  final int weekStart;
  final Map<String, Subject> subjects;
  final Widget wrongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statsViewProvider(range.key));
    switch (state) {
      case StatsViewLoading():
        return const _Skeleton();
      case StatsViewError():
        return StatePanel.error(
          title: StatsStrings.loadFailed,
          onAction: () => ref.invalidate(statsViewProvider(range.key)),
        );
      case StatsViewReady(:final aggregate, :final comparison):
        final summary = _SummaryCard(range: range, offset: offset, aggregate: aggregate, comparison: comparison);
        final bars = _BarsCard(range: range, aggregate: aggregate, today: today, weekStart: weekStart, subjects: subjects);
        final bySubject = _SubjectsCard(aggregate: aggregate, subjects: subjects);
        final hours = _HoursCard(aggregate: aggregate);
        final focus = _FocusCard(aggregate: aggregate);
        const cross = _CrossViewSlot();
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _StatsScreenState.twoColumnMinWidth) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: _StatsScreenState.leftWidth,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.s8, AppSpacing.s24),
                      children: <Widget>[
                        summary,
                        const SizedBox(height: AppSpacing.s12),
                        wrongs,
                        const SizedBox(height: AppSpacing.s12),
                        focus,
                        cross,
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.s8, 0, AppSpacing.page, AppSpacing.s24),
                      children: <Widget>[
                        bars,
                        const SizedBox(height: AppSpacing.s12),
                        bySubject,
                        const SizedBox(height: AppSpacing.s12),
                        hours,
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24),
              children: <Widget>[
                wrongs,
                const SizedBox(height: AppSpacing.s12),
                summary,
                const SizedBox(height: AppSpacing.s12),
                bars,
                const SizedBox(height: AppSpacing.s12),
                bySubject,
                const SizedBox(height: AppSpacing.s12),
                hours,
                const SizedBox(height: AppSpacing.s12),
                focus,
                cross,
              ],
            );
          },
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Shared card chrome

class _Card extends StatelessWidget {
  const _Card({super.key, required this.child, this.title, this.trailing});

  final Widget child;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.line),
        boxShadow: c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(title!, style: AppTypography.heading.copyWith(color: c.tx))),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          child,
        ],
      ),
    );
  }
}

String _hm(int seconds) => formatDuration(Duration(seconds: seconds));

/// Compact value label for bars (`1h28m` · `45m`); empty for zero.
String _compact(int seconds) {
  final m = seconds ~/ 60;
  if (m == 0) return seconds > 0 ? '<1m' : '';
  final h = m ~/ 60;
  final mm = m % 60;
  if (h == 0) return '${mm}m';
  return mm == 0 ? '${h}h' : '${h}h${mm}m';
}

// ---------------------------------------------------------------------------
// Summary card

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.range, required this.offset, required this.aggregate, required this.comparison});

  final StatsRange range;
  final int offset;
  final SeatedAggregate aggregate;
  final WeekComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isWeek = range.period == StatsPeriod.week;
    final title = isWeek
        ? offset == 0
            ? StatsStrings.thisWeekSeated
            : offset == -1
                ? StatsStrings.lastWeekSeated
                : StatsStrings.weekSeated(StatsStrings.weekRange(range.from.month, range.from.day, range.to.month, range.to.day))
        : offset == 0
            ? StatsStrings.thisMonthSeated
            : StatsStrings.monthSeated(range.from.year, range.from.month);

    final (String pillText, Color pillBg, Color pillFg) = _pill(c);

    return Container(
      key: StatsKeys.summary,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.line),
        boxShadow: c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTypography.label.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s4),
          Text(
            _hm(aggregate.totalSeconds),
            style: AppTypography.display.copyWith(color: c.tx, fontFeatures: AppTypography.tabularFigures),
          ),
          const SizedBox(height: AppSpacing.s8),
          Container(
            key: StatsKeys.compare,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
            decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(pillText, style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: pillFg)),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            aggregate.hasRecord
                ? '${StatsStrings.recordedDays(aggregate.recordedDays)} · ${StatsStrings.dailyAverage(_hm(aggregate.averagePerRecordedDay))}'
                : StatsStrings.noRecord,
            style: AppTypography.caption.copyWith(color: c.tx3),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _pill(AppColors c) {
    final cmp = comparison;
    if (cmp == null) {
      return (StatsStrings.monthRange(range.from.month, range.to.day), c.sunk, c.tx2);
    }
    if (!cmp.hasLast) return (StatsStrings.compareNone, c.sunk, c.tx2);
    final d = cmp.diffSeconds;
    final text = _hm(d.abs());
    if (d > 0) return (cmp.partial ? StatsStrings.compareMore(text) : StatsStrings.compareFullMore(text), c.okWeak, c.okTx);
    if (d < 0) return (cmp.partial ? StatsStrings.compareLess(text) : StatsStrings.compareFullLess(text), c.sunk, c.tx2);
    return (cmp.partial ? StatsStrings.compareSame : StatsStrings.compareFullSame, c.sunk, c.tx2);
  }
}

// ---------------------------------------------------------------------------
// Bars card (7 days · weeks of the month), stacked by subject colour

class _BarData {
  const _BarData({required this.label, required this.seconds, required this.segments, required this.future, required this.accent, required this.tooltipLabel});

  final String label;
  final int seconds;

  /// (colour, seconds) bottom-up.
  final List<(Color, int)> segments;
  final bool future;
  final bool accent;
  final String tooltipLabel;
}

class _BarsCard extends StatefulWidget {
  const _BarsCard({required this.range, required this.aggregate, required this.today, required this.weekStart, required this.subjects});

  final StatsRange range;
  final SeatedAggregate aggregate;
  final LocalDate today;
  final int weekStart;
  final Map<String, Subject> subjects;

  @override
  State<_BarsCard> createState() => _BarsCardState();
}

class _BarsCardState extends State<_BarsCard> {
  int? _selected;

  @override
  void didUpdateWidget(covariant _BarsCard old) {
    super.didUpdateWidget(old);
    if (old.range.key != widget.range.key) _selected = null;
  }

  Color _colorOf(AppColors c, String? subjectId) {
    final s = subjectId == null ? null : widget.subjects[subjectId];
    return s == null ? c.pri : c.subject(s.colorIndex);
  }

  List<_BarData> _bars(AppColors c) {
    final a = widget.aggregate;
    final order = a.bySubject.map((s) => s.subjectId).toList();
    List<(Color, int)> segmentsOf(Map<String?, int> by) => <(Color, int)>[
          for (final id in order)
            if ((by[id] ?? 0) > 0) (_colorOf(c, id), by[id]!),
        ];
    if (widget.range.period == StatsPeriod.week) {
      return <_BarData>[
        for (var i = 0; i < a.dayCount; i++)
          () {
            final d = a.from.addDays(i);
            return _BarData(
              label: PlannerStrings.weekdayOf(d.weekday),
              seconds: a.daily[i],
              segments: segmentsOf(a.dailyBySubject[i]),
              future: d.isAfter(widget.today),
              accent: d == widget.today,
              tooltipLabel: '${d.month}월 ${d.day}일 ${PlannerStrings.weekdayOf(d.weekday)}',
            );
          }(),
      ];
    }
    // Month: one bar per week (by the settings' week start) that touches the month.
    final weeks = <LocalDate, Map<String?, int>>{};
    final weekSeconds = <LocalDate, int>{};
    for (var i = 0; i < a.dayCount; i++) {
      final d = a.from.addDays(i);
      final w = d.startOfWeek(widget.weekStart);
      weekSeconds.update(w, (v) => v + a.daily[i], ifAbsent: () => a.daily[i]);
      final by = weeks.putIfAbsent(w, () => <String?, int>{});
      for (final e in a.dailyBySubject[i].entries) {
        by.update(e.key, (v) => v + e.value, ifAbsent: () => e.value);
      }
    }
    final starts = weeks.keys.toList()..sort();
    final todayWeek = widget.today.startOfWeek(widget.weekStart);
    return <_BarData>[
      for (final (i, w) in starts.indexed)
        _BarData(
          label: StatsStrings.weekOfMonth(i + 1),
          seconds: weekSeconds[w]!,
          segments: segmentsOf(weeks[w]!),
          future: w.isAfter(todayWeek),
          accent: w == todayWeek,
          tooltipLabel: StatsStrings.weekOfMonth(i + 1),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bars = _bars(c);
    final selected = _selected != null && _selected! < bars.length ? bars[_selected!] : null;
    final isWeek = widget.range.period == StatsPeriod.week;
    return _Card(
      key: StatsKeys.bars,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            label: isWeek ? StatsStrings.chartWeekSemantics : StatsStrings.chartMonthSemantics,
            child: SizedBox(
              height: 150,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null || bars.isEmpty) return;
                  final width = box.size.width - AppSpacing.s16 * 2;
                  final i = (d.localPosition.dx / width * bars.length).floor().clamp(0, bars.length - 1);
                  setState(() => _selected = _selected == i ? null : i);
                },
                child: CustomPaint(
                  painter: _BarsPainter(
                    bars: bars,
                    selected: _selected,
                    lineColor: c.line,
                    labelStyle: AppTypography.caption.copyWith(color: c.tx2, fontSize: 10, height: 1.2),
                    selectedOutline: c.tx,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Row(
            children: <Widget>[
              for (final b in bars)
                Expanded(
                  child: Text(
                    b.label,
                    textAlign: TextAlign.center,
                    style: AppTypography.withWeight(AppTypography.caption, b.accent ? 700 : 500)
                        .copyWith(color: b.accent ? c.accTx : c.tx3, fontSize: 11),
                  ),
                ),
            ],
          ),
          if (selected != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s8),
            Text(
              key: StatsKeys.barTooltip,
              selected.future && selected.seconds == 0
                  ? StatsStrings.barValue(selected.tooltipLabel, StatsStrings.futureDay)
                  : StatsStrings.barValue(selected.tooltipLabel, _hm(selected.seconds)),
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(color: c.tx2),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({
    required this.bars,
    required this.selected,
    required this.lineColor,
    required this.labelStyle,
    required this.selectedOutline,
  });

  final List<_BarData> bars;
  final int? selected;
  final Color lineColor;
  final TextStyle labelStyle;
  final Color selectedOutline;

  static const double labelHeight = 16;
  static const int minScaleSeconds = 3600;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final chartH = size.height - labelHeight;
    final maxSeconds = math.max(minScaleSeconds, bars.fold<int>(0, (m, b) => math.max(m, b.seconds)));
    final slot = size.width / bars.length;
    final barW = math.min(slot * 0.56, 36.0);
    final base = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), base);
    for (final (i, b) in bars.indexed) {
      final x = i * slot + (slot - barW) / 2;
      var y = size.height;
      final opacity = b.future ? 0.35 : 1.0;
      for (final (color, secs) in b.segments) {
        final h = secs / maxSeconds * chartH;
        final rect = Rect.fromLTWH(x, y - h, barW, h);
        canvas.drawRect(rect, Paint()..color = color.withValues(alpha: opacity));
        y -= h;
      }
      if (b.seconds == 0) {
        canvas.drawRect(Rect.fromLTWH(x, size.height - 2, barW, 2), Paint()..color = lineColor);
      }
      if (selected == i) {
        final h = b.seconds / maxSeconds * chartH;
        canvas.drawRect(
          Rect.fromLTWH(x - 1, size.height - math.max(h, 2) - 1, barW + 2, math.max(h, 2) + 2),
          Paint()
            ..color = selectedOutline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      final label = _compact(b.seconds);
      if (label.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: slot);
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, y - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.bars != bars || old.selected != selected || old.lineColor != lineColor || old.labelStyle != labelStyle;
}

// ---------------------------------------------------------------------------
// Subjects card

class _SubjectsCard extends StatelessWidget {
  const _SubjectsCard({required this.aggregate, required this.subjects});

  final SeatedAggregate aggregate;
  final Map<String, Subject> subjects;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = aggregate.totalSeconds;
    return _Card(
      key: StatsKeys.subjects,
      title: '${StatsStrings.bySubject} · ${StatsStrings.subjectTotal(_hm(total))}',
      child: aggregate.bySubject.isEmpty
          ? Text(StatsStrings.noRecord, style: AppTypography.label.copyWith(color: c.tx3))
          : Column(
              children: <Widget>[
                for (final s in aggregate.bySubject)
                  _SubjectRow(
                    name: s.subjectId == null ? PlannerStrings.noSubject : (subjects[s.subjectId!]?.name ?? PlannerStrings.noSubject),
                    color: s.subjectId == null || subjects[s.subjectId!] == null ? c.pri : c.subject(subjects[s.subjectId!]!.colorIndex),
                    seated: s,
                    total: total,
                  ),
              ],
            ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.name, required this.color, required this.seated, required this.total});

  final String name;
  final Color color;
  final SubjectSeated seated;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pct = total == 0 ? 0 : (seated.total * 100 / total).round();
    final plannedFrac = total == 0 ? 0.0 : seated.planned / total;
    final selfFrac = total == 0 ? 0.0 : seated.self / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.s8),
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.tx))),
              Text(_hm(seated.total), style: AppTypography.label.copyWith(color: c.tx, fontFeatures: AppTypography.tabularFigures)),
              const SizedBox(width: AppSpacing.s8),
              SizedBox(width: 36, child: Text(StatsStrings.percent(pct), textAlign: TextAlign.right, style: AppTypography.caption.copyWith(color: c.tx3))),
            ],
          ),
          const SizedBox(height: AppSpacing.s6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 6,
              child: Row(
                children: <Widget>[
                  Expanded(flex: (plannedFrac * 1000).round(), child: ColoredBox(color: color)),
                  Expanded(flex: (selfFrac * 1000).round(), child: ColoredBox(color: c.acc)),
                  Expanded(flex: math.max(1, 1000 - (plannedFrac * 1000).round() - (selfFrac * 1000).round()), child: ColoredBox(color: c.sunk)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            StatsStrings.subjectSplit(
              seated.planned > 0 ? _hm(seated.planned) : StatsStrings.none,
              seated.self > 0 ? _hm(seated.self) : StatsStrings.none,
            ),
            style: AppTypography.caption.copyWith(color: c.tx3),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hours card: 24 bars + five bands

class _HoursCard extends StatelessWidget {
  const _HoursCard({required this.aggregate});

  final SeatedAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bands = aggregate.hourBands;
    final maxBand = bands.fold<int>(0, math.max);
    return _Card(
      key: StatsKeys.hours,
      title: StatsStrings.hours,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            label: StatsStrings.hoursSemantics,
            child: SizedBox(
              height: 64,
              child: CustomPaint(
                painter: _HistogramPainter(values: aggregate.hourHistogram, color: c.pri, peak: c.acc, track: c.sunk),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: <Widget>[
              for (final h in const <int>[0, 6, 12, 18])
                Expanded(child: Text(StatsStrings.hourLabel(h), style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10))),
              Text(StatsStrings.hourLabel(24), style: AppTypography.caption.copyWith(color: c.tx3, fontSize: 10)),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          for (final (i, label) in StatsStrings.hourBands.indexed)
            _MeterRow(
              label: label,
              value: bands[i] > 0 ? _hm(bands[i]) : StatsStrings.none,
              fraction: maxBand == 0 ? 0 : bands[i] / maxBand,
              color: maxBand > 0 && bands[i] == maxBand ? c.acc : c.pri,
            ),
        ],
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  const _HistogramPainter({required this.values, required this.color, required this.peak, required this.track});

  final List<int> values;
  final Color color;
  final Color peak;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = values.fold<int>(0, math.max);
    final slot = size.width / values.length;
    final w = slot * 0.7;
    for (final (i, v) in values.indexed) {
      final x = i * slot + (slot - w) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - 2, w, 2), const Radius.circular(1)),
        Paint()..color = track,
      );
      if (maxV == 0 || v == 0) continue;
      final h = math.max(2.0, v / maxV * size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, w, h), const Radius.circular(2)),
        Paint()..color = v == maxV ? peak : color,
      );
    }
  }

  @override
  bool shouldRepaint(_HistogramPainter old) => old.values != values || old.color != color || old.peak != peak || old.track != track;
}

class _MeterRow extends StatelessWidget {
  const _MeterRow({required this.label, required this.value, required this.fraction, required this.color});

  final String label;
  final String value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: <Widget>[
          SizedBox(width: 112, child: Text(label, style: AppTypography.caption.copyWith(color: c.tx2))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: <Widget>[
                    Expanded(flex: (fraction * 1000).round(), child: ColoredBox(color: color)),
                    Expanded(flex: math.max(1, 1000 - (fraction * 1000).round()), child: ColoredBox(color: c.sunk)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          SizedBox(
            width: 72,
            child: Text(value, textAlign: TextAlign.right, style: AppTypography.caption.copyWith(color: c.tx, fontFeatures: AppTypography.tabularFigures)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Focus card: 연속 착석 분포 · 평균 세션 길이

class _FocusCard extends StatelessWidget {
  const _FocusCard({required this.aggregate});

  final SeatedAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = aggregate.focus;
    final maxCount = f.counts.fold<int>(0, math.max);
    const labels = <String>[StatsStrings.bucketUnder15, StatsStrings.bucket15To30, StatsStrings.bucket30To60, StatsStrings.bucketOver60];
    return _Card(
      key: StatsKeys.focus,
      title: StatsStrings.focus,
      child: f.runCount == 0
          ? Text(StatsStrings.noRuns, style: AppTypography.label.copyWith(color: c.tx3))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final (i, label) in labels.indexed)
                  _MeterRow(
                    label: label,
                    value: StatsStrings.runs(f.counts[i]),
                    fraction: maxCount == 0 ? 0 : f.counts[i] / maxCount,
                    color: c.pri,
                  ),
                const SizedBox(height: AppSpacing.s4),
                Text(StatsStrings.longestRun(_hm(f.longestSeconds)), style: AppTypography.label.copyWith(color: c.tx)),
                Text(
                  '${StatsStrings.averageSession(_hm(aggregate.averageSessionSeconds))} · ${StatsStrings.sessionCount(aggregate.sessionCount)}',
                  style: AppTypography.caption.copyWith(color: c.tx3),
                ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cross view slot (hidden, PRD 4.3 P1)

class _CrossViewSlot extends StatelessWidget {
  const _CrossViewSlot();

  @override
  Widget build(BuildContext context) {
    if (!kStatsCrossViewEnabled) return const SizedBox.shrink(key: StatsKeys.crossView);
    final c = context.colors;
    return Padding(
      key: StatsKeys.crossView,
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: _Card(child: Text(StatsStrings.crossHidden, style: AppTypography.label.copyWith(color: c.tx3))),
    );
  }
}

// ---------------------------------------------------------------------------
// Sparse (s11) · skeleton (s12)

class _SparseCard extends StatelessWidget {
  const _SparseCard({required this.totalSeconds, required this.onStart});

  final int totalSeconds;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: StatsKeys.sparse,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s32, AppSpacing.s20, AppSpacing.s24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: c.line),
        boxShadow: c.shadow,
      ),
      child: Column(
        children: <Widget>[
          LucideIcon(LucideIcons.chartColumn, size: AppIcon.sizeLarge, color: c.tx3),
          const SizedBox(height: AppSpacing.s14),
          Text(StatsStrings.sparseTitle, textAlign: TextAlign.center, style: AppTypography.heading.copyWith(color: c.tx)),
          const SizedBox(height: AppSpacing.s6),
          Text(StatsStrings.sparseBody, textAlign: TextAlign.center, style: AppTypography.label.copyWith(color: c.tx2)),
          const SizedBox(height: AppSpacing.s8),
          Text(StatsStrings.sparseSoFar(_hm(totalSeconds)), style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx)),
          const SizedBox(height: AppSpacing.s20),
          AppButton(
            key: StatsKeys.sparseStart,
            label: StatsStrings.sparseAction,
            size: AppButtonSize.small,
            expand: false,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget box(double h) => Container(
          height: h,
          margin: const EdgeInsets.only(bottom: AppSpacing.s12),
          decoration: BoxDecoration(color: c.skel, borderRadius: BorderRadius.circular(AppRadius.card)),
        );
    return Semantics(
      label: CommonStrings.loading,
      child: ListView(
        key: StatsKeys.skeleton,
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.s24),
        children: <Widget>[box(72), box(120), box(220), box(160)],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wrongs section (teaser · premium · expired)

class _WrongsSection extends ConsumerWidget {
  const _WrongsSection({
    required this.rangeKey,
    required this.period,
    required this.subjects,
    required this.onOpenPaywall,
    required this.onSeeAll,
  });

  final String rangeKey;
  final StatsPeriod period;
  final Map<String, Subject> subjects;
  final VoidCallback onOpenPaywall;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(statsWrongsSectionProvider(rangeKey));
    if (state is! WrongsReady) return const SizedBox.shrink(key: StatsKeys.wrongs);
    final facts = state.facts;

    final Widget trailing = switch (facts.kind) {
      WrongsCardKind.premium => TextButton(
          key: StatsKeys.wrongsSeeAll,
          onPressed: onSeeAll,
          child: Text(StatsStrings.seeAll, style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx)),
        ),
      WrongsCardKind.teaser => _Badge(key: StatsKeys.wrongsBadge, text: StatsStrings.premiumBadge, onTap: onOpenPaywall),
      WrongsCardKind.expired => const _Badge(key: StatsKeys.wrongsBadge, text: StatsStrings.readOnly),
    };

    final Widget body = switch (facts.kind) {
      WrongsCardKind.teaser => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpenPaywall,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(StatsStrings.wrongsTeaserTitle, style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx)),
              const SizedBox(height: AppSpacing.s4),
              Text(StatsStrings.wrongsTeaserBody, style: AppTypography.label.copyWith(color: c.tx2)),
              const SizedBox(height: AppSpacing.s12),
              PremiumLockHint(onOpenPaywall: onOpenPaywall),
            ],
          ),
        ),
      WrongsCardKind.expired => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(StatsStrings.wrongsExpired(facts.total, facts.ranges), style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx)),
            const SizedBox(height: AppSpacing.s4),
            Text(StatsStrings.wrongsExpiredBody, style: AppTypography.label.copyWith(color: c.tx2)),
            const SizedBox(height: AppSpacing.s12),
            AppButton.secondary(
              key: StatsKeys.wrongsResubscribe,
              label: StatsStrings.resubscribe,
              size: AppButtonSize.small,
              expand: false,
              onPressed: onOpenPaywall,
            ),
          ],
        ),
      WrongsCardKind.premium => facts.total == 0
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(StatsStrings.wrongsEmptyTitle, style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx)),
                const SizedBox(height: AppSpacing.s4),
                Text(StatsStrings.wrongsEmptyBody, style: AppTypography.label.copyWith(color: c.tx2)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${StatsStrings.wrongsOpen(facts.open)} · '
                  '${period == StatsPeriod.week ? StatsStrings.readingsThisWeek(facts.readingsInRange) : StatsStrings.readingsThisMonth(facts.readingsInRange)} · '
                  '${StatsStrings.wrongsResolved(facts.resolved)}',
                  style: AppTypography.label.copyWith(color: c.tx2),
                ),
                const SizedBox(height: AppSpacing.s10),
                for (final e in facts.openBySubject)
                  _MeterRow(
                    label: subjects[e.key]?.name ?? PlannerStrings.noSubject,
                    value: StatsStrings.wrongsCount(e.value),
                    fraction: facts.open == 0 ? 0 : e.value / facts.open,
                    color: subjects[e.key] == null ? c.pri : c.subject(subjects[e.key]!.colorIndex),
                  ),
              ],
            ),
    };

    return _Card(key: StatsKeys.wrongs, title: StatsStrings.wrongsTitle, trailing: trailing, child: body);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({super.key, required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
      decoration: BoxDecoration(color: onTap == null ? c.sunk : c.priWeak, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(text, style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: onTap == null ? c.tx2 : c.priTx)),
    );
    if (onTap == null) return badge;
    return Semantics(
      button: true,
      label: '$text · ${CommonStrings.premiumSeePlans}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10), child: badge),
      ),
    );
  }
}
