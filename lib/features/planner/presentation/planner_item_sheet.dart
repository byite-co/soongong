// PlannerItemSheet (S07): the one register/edit sheet for 공부 · 할 일 ·
// 추가 자습 · 일정(기간 / 반복) — prototype `addSheet` / `editItem` /
// `bandEdit` / `repeatSheet` / `datePick`. Saves through PlannerController
// with the 3-state rule (저장 중 → 성공 / 실패 · 입력 유지, CLAUDE.md §5);
// closing with changes asks first (`discard` / `editCancel`); deleting asks,
// then returns the pending delete so the screen can show the 5-second undo.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/common_strings.dart';
import '../../../core/strings/planner_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/planner_controller.dart';
import '../application/planner_providers.dart';
import '../domain/planner_draft.dart';
import '../domain/target_time_suggestion.dart';
import 'mini_date_picker.dart';
import 'recurrence_editor.dart';

sealed class PlannerSheetResult {
  const PlannerSheetResult();
}

class PlannerSheetSaved extends PlannerSheetResult {
  const PlannerSheetSaved({required this.id, required this.draft, required this.target});

  final String id;
  final PlannerDraft draft;
  final DraftTarget target;

  bool get isNew => target is NewEntry;
}

class PlannerSheetDeleted extends PlannerSheetResult {
  const PlannerSheetDeleted({required this.pending});

  final PendingDelete pending;
}

/// Widget keys for tests.
abstract final class PlannerSheetKeys {
  static const Key title = Key('planner-sheet-title');
  static const Key range = Key('planner-sheet-range');
  static const Key customTarget = Key('planner-sheet-custom-target');
  static const Key newSubjectName = Key('planner-sheet-new-subject');
  static const Key save = Key('planner-sheet-save');
  static const Key delete = Key('planner-sheet-delete');
  static const Key close = Key('planner-sheet-close');
  static const Key dateButton = Key('planner-sheet-date');
  static const Key error = Key('planner-sheet-error');
}

Future<PlannerSheetResult?> showPlannerItemSheet(
  BuildContext context, {
  required PlannerDraft initial,
  DraftTarget target = const NewEntry(),
  VoidCallback? onOpenPaywall,
}) =>
    showAppSheet<PlannerSheetResult>(
      context,
      enableDrag: false, // a drag-close would bypass the "변경 취소" confirmation
      builder: (_) => PlannerItemSheet(
        initial: initial,
        target: target,
        onOpenPaywall: onOpenPaywall,
      ),
    );

class PlannerItemSheet extends ConsumerStatefulWidget {
  const PlannerItemSheet({
    super.key,
    required this.initial,
    this.target = const NewEntry(),
    this.onOpenPaywall,
  });

  final PlannerDraft initial;
  final DraftTarget target;
  final VoidCallback? onOpenPaywall;

  @override
  ConsumerState<PlannerItemSheet> createState() => _PlannerItemSheetState();
}

class _PlannerItemSheetState extends ConsumerState<PlannerItemSheet> {
  late PlannerDraft _draft = widget.initial;
  late final TextEditingController _title = TextEditingController(text: widget.initial.title);
  late final TextEditingController _range = TextEditingController(text: widget.initial.rangeText);
  late final TextEditingController _customTarget = TextEditingController(
    text: widget.initial.targetMinutes != null && !PlannerDraft.targetChips.contains(widget.initial.targetMinutes)
        ? '${widget.initial.targetMinutes}'
        : '',
  );
  final TextEditingController _newSubjectName = TextEditingController();

  bool _saving = false;
  bool _addingSubject = false;
  String? _error;
  bool _dateOpen = false;
  bool _newSubjectOpen = false;
  int _newSubjectColor = 6;
  bool _customTargetOpen = false;

  /// Once the user touched the target the premium suggestion stops filling it.
  bool _targetTouched = false;
  _PeriodField? _periodPicker;

  bool get _isNew => widget.target is NewEntry;
  bool get _isBandEdit => widget.target is ExistingBand;
  bool get _isRecurrenceEdit => widget.target is ExistingRecurrence;

  @override
  void initState() {
    super.initState();
    _customTargetOpen = _customTarget.text.isNotEmpty;
    _targetTouched = !_isNew;
  }

  @override
  void dispose() {
    _title.dispose();
    _range.dispose();
    _customTarget.dispose();
    _newSubjectName.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Draft helpers

  TargetTimeSuggestion? _suggestion(bool entitled, List<StudySession> sessions) {
    if (!entitled || _draft.kind != PlannerKind.study || _draft.subjectId == null) return null;
    return const TargetTimePolicy().recentAverage(sessions, subjectId: _draft.subjectId!);
  }

  /// The draft the save persists: typed text plus the premium suggestion
  /// when the user has not chosen a target themselves (PRD 4.3 N1).
  PlannerDraft _effective(TargetTimeSuggestion? suggestion) {
    var d = _draft.copyWith(title: _title.text, rangeText: _range.text);
    if (d.hasTarget && !_targetTouched && suggestion != null) {
      d = d.copyWith(targetMinutes: suggestion.minutes);
    }
    return d;
  }

  bool _dirty(PlannerDraft effective) =>
      _isNew ? effective.hasInput : effective.differsFrom(widget.initial);

  void _set(PlannerDraft next) => setState(() {
        _draft = next;
        _error = null;
      });

  String _errorText(DraftError e) => switch (e) {
        DraftError.titleEmpty => PlannerStrings.titleEmpty,
        DraftError.rangeTooLong => PlannerStrings.rangeTooLong(PlannerDraft.rangeMaxLength),
        DraftError.targetInvalid => PlannerStrings.targetInvalid,
        DraftError.bandOrder => PlannerStrings.bandOrder,
        DraftError.noWeekday => PlannerStrings.noWeekday,
        DraftError.timeOrder => PlannerStrings.timeOrder,
      };

  // -------------------------------------------------------------------
  // Actions

  Future<void> _save(PlannerDraft effective) async {
    if (_saving) return;
    final errors = effective.validate();
    if (errors.isNotEmpty) {
      setState(() => _error = _errorText(errors.first));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final outcome = await ref.read(plannerControllerProvider).save(effective, widget.target);
    if (!mounted) return;
    switch (outcome) {
      case PlannerSaved(:final id):
        Navigator.of(context).pop(PlannerSheetSaved(id: id, draft: effective, target: widget.target));
      case PlannerSaveFailed(:final error):
        setState(() {
          _saving = false;
          _error = error is DraftInvalid ? _errorText(error.errors.first) : PlannerStrings.saveFailed;
        });
    }
  }

  Future<void> _requestClose(PlannerDraft effective) async {
    if (_saving) return;
    if (!_dirty(effective)) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await showAppModal(
      context,
      title: _isNew ? PlannerStrings.discardTitle : PlannerStrings.cancelEditTitle,
      body: _isNew ? PlannerStrings.discardBody : PlannerStrings.cancelEditBody,
      primaryLabel: _isNew ? PlannerStrings.discardDo : PlannerStrings.cancelEditDo,
      secondaryLabel: _isNew ? PlannerStrings.discardKeep : PlannerStrings.cancelEditKeep,
      destructive: true,
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (_saving) return;
    final (title, body) = switch (widget.target) {
      ExistingBand() => (PlannerStrings.deleteBandTitle, PlannerStrings.deleteBandBody),
      ExistingRecurrence() => (PlannerStrings.deleteRecurrenceTitle, PlannerStrings.deleteRecurrenceBody),
      _ => (PlannerStrings.deleteItemTitle, PlannerStrings.deleteItemBody),
    };
    PendingDelete? pending;
    final ok = await showAppModal(
      context,
      title: title,
      body: body,
      primaryLabel: CommonStrings.delete,
      destructive: true,
      onConfirm: () async {
        pending = await ref.read(plannerControllerProvider).delete(widget.target);
      },
    );
    if (!ok || pending == null || !mounted) return;
    Navigator.of(context).pop(PlannerSheetDeleted(pending: pending!));
  }

  Future<void> _addSubject() async {
    final name = _newSubjectName.text.trim();
    if (name.isEmpty || _addingSubject) return;
    setState(() => _addingSubject = true);
    try {
      final s = await ref.read(plannerControllerProvider).addSubject(name: name, colorIndex: _newSubjectColor);
      if (!mounted) return;
      _newSubjectName.clear();
      setState(() {
        _addingSubject = false;
        _newSubjectOpen = false;
        _draft = _draft.copyWith(subjectId: s.id);
        _error = null;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _addingSubject = false;
          _error = PlannerStrings.saveFailed;
        });
      }
    }
  }

  void _pickTarget(int? minutes, {bool custom = false}) {
    _targetTouched = true;
    if (custom && minutes != null && _customTarget.text != '$minutes') {
      _customTarget.text = '$minutes';
    }
    setState(() {
      _customTargetOpen = custom;
      _draft = _draft.copyWith(targetMinutes: minutes);
      _error = null;
    });
  }

  // -------------------------------------------------------------------
  // Build

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entitled = ref.watch(plannerEntitledProvider);
    final today = ref.watch(plannerTodayProvider);
    final weekStart = ref.watch(plannerWeekStartProvider);
    final subjects = ref.watch(plannerSubjectsProvider).value ?? const <Subject>[];
    final sessions = ref.watch(plannerAllSessionsProvider).value ?? const <StudySession>[];
    final suggestion = _suggestion(entitled, sessions);
    final effective = _effective(suggestion);
    final dirty = _dirty(effective);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !dirty && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose(effective);
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _header(c, today, effective),
              if (_dateOpen && !effective.isEvent) ...<Widget>[
                const SizedBox(height: AppSpacing.s12),
                MiniDatePicker(
                  selected: _draft.date,
                  today: today,
                  weekStart: weekStart,
                  onPick: (d) => setState(() {
                    _draft = _draft.copyWith(date: d);
                    _dateOpen = false;
                  }),
                ),
              ],
              const SizedBox(height: AppSpacing.s14),
              if (_isNew || widget.target is ExistingItem) _kinds(effective),
              if (_isRecurrenceEdit) const AppNotice(PlannerStrings.repeatWholeOnly),
              const SizedBox(height: AppSpacing.s10),
              Text(_hint(effective, entitled), style: AppTypography.caption.copyWith(color: c.tx3)),
              const SizedBox(height: AppSpacing.s14),
              AppTextField(
                key: PlannerSheetKeys.title,
                controller: _title,
                label: PlannerStrings.titleLabel,
                hint: _placeholder(effective),
                maxLength: PlannerDraft.titleMaxLength,
                textInputAction: TextInputAction.done,
                highlightError: _error == PlannerStrings.titleEmpty,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.s16),
              _subjects(c, subjects),
              if (effective.hasRange) ...<Widget>[
                const SizedBox(height: AppSpacing.s16),
                AppTextField(
                  key: PlannerSheetKeys.range,
                  controller: _range,
                  label: PlannerStrings.range,
                  hint: PlannerStrings.rangePlaceholder,
                  maxLength: PlannerDraft.rangeMaxLength,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _error = null),
                  trailing: Text(
                    PlannerStrings.rangeCount(_range.text.characters.length, PlannerDraft.rangeMaxLength),
                    style: AppTypography.caption.copyWith(color: c.tx3),
                  ),
                ),
              ],
              if (effective.hasTarget) ...<Widget>[
                const SizedBox(height: AppSpacing.s16),
                _target(c, effective, entitled, suggestion),
              ],
              if (effective.isEvent) ...<Widget>[
                const SizedBox(height: AppSpacing.s16),
                _event(c, effective, today, weekStart),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.s12),
                AppNotice.error(_error!, key: PlannerSheetKeys.error),
              ],
              const SizedBox(height: AppSpacing.s20),
              AppButton(
                key: PlannerSheetKeys.save,
                label: _primaryLabel(effective),
                busy: _saving,
                busyLabel: PlannerStrings.btnSaving,
                size: AppButtonSize.large,
                variant: effective.kind == PlannerKind.self ? AppButtonVariant.accent : AppButtonVariant.primary,
                onPressed: effective.trimmedTitle.isEmpty ? null : () => _save(effective),
              ),
              if (!_isNew) ...<Widget>[
                const SizedBox(height: AppSpacing.s6),
                AppButton.secondary(
                  key: PlannerSheetKeys.delete,
                  label: _deleteLabel,
                  size: AppButtonSize.small,
                  // Sync callback: the button must not show its busy state
                  // while the confirmation modal waits for the user.
                  onPressed: _saving ? null : () => unawaited(_delete()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppColors c, LocalDate today, PlannerDraft effective) {
    final showDate = !effective.isEvent;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(_sheetTitle(effective), style: AppTypography.heading.copyWith(color: c.tx)),
        ),
        if (showDate)
          Semantics(
            button: true,
            child: GestureDetector(
              key: PlannerSheetKeys.dateButton,
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _dateOpen = !_dateOpen),
              child: Container(
                constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget - 8),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
                decoration: BoxDecoration(
                  color: c.sunk,
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LucideIcon.small(LucideIcons.calendar, color: c.tx2),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      _draft.date == today
                          ? PlannerStrings.dateButtonToday(_draft.date.month, _draft.date.day)
                          : PlannerStrings.dateButton(_draft.date.month, _draft.date.day),
                      style: AppTypography.label.copyWith(color: c.tx2),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    LucideIcon.small(_dateOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: c.tx2),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(width: AppSpacing.s4),
        Semantics(
          button: true,
          label: CommonStrings.close,
          child: GestureDetector(
            key: PlannerSheetKeys.close,
            behavior: HitTestBehavior.opaque,
            onTap: () => _requestClose(effective),
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: Center(child: LucideIcon(LucideIcons.x, color: c.tx2)),
            ),
          ),
        ),
      ],
    );
  }

  String _sheetTitle(PlannerDraft d) {
    if (_isBandEdit) return PlannerStrings.sheetEditBand;
    if (_isRecurrenceEdit) return PlannerStrings.sheetEditRecurrence;
    if (!_isNew) return PlannerStrings.sheetEdit;
    return switch (d.kind) {
      PlannerKind.self => PlannerStrings.sheetAddSelf,
      PlannerKind.event => PlannerStrings.sheetAddEvent,
      _ => PlannerStrings.sheetAdd,
    };
  }

  String _hint(PlannerDraft d, bool entitled) => switch (d.kind) {
        PlannerKind.study => entitled ? PlannerStrings.hintStudy : PlannerStrings.hintStudyLocked,
        PlannerKind.todo => PlannerStrings.hintTodo,
        PlannerKind.self => PlannerStrings.hintSelf,
        PlannerKind.event => PlannerStrings.hintEvent,
      };

  String _placeholder(PlannerDraft d) => switch (d.kind) {
        PlannerKind.study => PlannerStrings.placeholderStudy,
        PlannerKind.todo => PlannerStrings.placeholderTodo,
        PlannerKind.self => PlannerStrings.placeholderSelf,
        PlannerKind.event => PlannerStrings.placeholderEvent,
      };

  String _primaryLabel(PlannerDraft d) {
    if (!_isNew) return PlannerStrings.btnSave;
    return switch (d.kind) {
      PlannerKind.self => PlannerStrings.btnAddSelf,
      PlannerKind.event => d.isPeriod ? PlannerStrings.btnAddPeriod : PlannerStrings.btnAddRepeat,
      _ => PlannerStrings.btnAdd,
    };
  }

  String get _deleteLabel => switch (widget.target) {
        ExistingBand() => PlannerStrings.deleteBand,
        ExistingRecurrence() => PlannerStrings.deleteRecurrence,
        _ => PlannerStrings.deleteItem,
      };

  Widget _kinds(PlannerDraft effective) {
    final c = context.colors;
    final options = <(PlannerKind, String)>[
      (PlannerKind.study, PlannerStrings.kindStudy),
      (PlannerKind.todo, PlannerStrings.kindTodo),
      (PlannerKind.self, PlannerStrings.kindSelf),
      if (_isNew) (PlannerKind.event, PlannerStrings.kindEvent),
    ];
    return SegmentedChoice<PlannerKind>(
      value: effective.kind,
      options: options,
      onChanged: (k) => _set(_draft.withKind(k)),
      leading: (k, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: switch (k) {
            PlannerKind.study => c.pri,
            PlannerKind.todo => c.tx2,
            PlannerKind.self => c.acc,
            PlannerKind.event => c.tx,
          },
          borderRadius: BorderRadius.circular(k == PlannerKind.todo ? AppRadius.pill : 2),
        ),
      ),
    );
  }

  Widget _subjects(AppColors c, List<Subject> subjects) {
    final brightness = c.brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(PlannerStrings.subject, style: AppTypography.caption.copyWith(color: c.tx3)),
        Wrap(
          spacing: AppSpacing.s8,
          children: <Widget>[
            SubjectChip(
              name: PlannerStrings.noSubject,
              color: c.tx3,
              selected: _draft.subjectId == null,
              onTap: () => _set(_draft.copyWith(subjectId: null)),
            ),
            for (final s in subjects)
              SubjectChip.index(
                name: s.name,
                colorIndex: s.colorIndex,
                brightness: brightness,
                selected: _draft.subjectId == s.id,
                onTap: () => _set(_draft.copyWith(subjectId: s.id)),
              ),
            Semantics(
              button: true,
              label: PlannerStrings.addSubject,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _newSubjectOpen = !_newSubjectOpen),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: _newSubjectOpen ? c.pri : c.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        LucideIcon.small(LucideIcons.plus, color: c.tx3),
                        const SizedBox(width: AppSpacing.s4),
                        Text(
                          PlannerStrings.addSubject,
                          style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.tx2, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_newSubjectOpen)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.s4),
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: c.sunk,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  key: PlannerSheetKeys.newSubjectName,
                  controller: _newSubjectName,
                  label: PlannerStrings.addSubject,
                  hint: PlannerStrings.subjectNamePlaceholder,
                  maxLength: 20,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addSubject(),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.s10),
                Row(
                  children: <Widget>[
                    for (var i = 0; i < AppSubjectColors.count; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: AppSpacing.s6),
                      Semantics(
                        button: true,
                        selected: _newSubjectColor == i,
                        label: '${PlannerStrings.subjectColor} ${i + 1}',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _newSubjectColor = i),
                          child: SizedBox(
                            width: 32,
                            height: AppSpacing.touchTarget,
                            child: Center(
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: c.subject(i),
                                  shape: BoxShape.circle,
                                  border: _newSubjectColor == i ? Border.all(color: c.tx, width: 2) : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    AppButton(
                      label: PlannerStrings.subjectAddConfirm,
                      size: AppButtonSize.small,
                      expand: false,
                      busy: _addingSubject,
                      onPressed: _newSubjectName.text.trim().isEmpty ? null : _addSubject,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _target(AppColors c, PlannerDraft effective, bool entitled, TargetTimeSuggestion? suggestion) {
    final selected = effective.targetMinutes;
    final isChip = selected != null && PlannerDraft.targetChips.contains(selected) && !_customTargetOpen;
    final subjectName = _subjectName(effective.subjectId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(PlannerStrings.target, style: AppTypography.caption.copyWith(color: c.tx3)),
        Wrap(
          spacing: AppSpacing.s8,
          children: <Widget>[
            for (final m in PlannerDraft.targetChips)
              _Chip(
                label: PlannerStrings.targetMinutes(m),
                selected: isChip && selected == m,
                onTap: () => _pickTarget(m),
              ),
            _Chip(
              label: selected != null && !isChip
                  ? '${PlannerStrings.targetCustom} · ${PlannerStrings.targetMinutes(selected)}'
                  : PlannerStrings.targetCustom,
              selected: _customTargetOpen || (selected != null && !isChip),
              onTap: () => _pickTarget(selected ?? int.tryParse(_customTarget.text), custom: true),
            ),
          ],
        ),
        if (_customTargetOpen) ...<Widget>[
          const SizedBox(height: AppSpacing.s6),
          AppTextField(
            key: PlannerSheetKeys.customTarget,
            controller: _customTarget,
            label: PlannerStrings.targetCustom,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            suffixText: PlannerStrings.targetCustomUnit,
            autofocus: true,
            onChanged: (v) => _pickTarget(int.tryParse(v), custom: true),
          ),
        ],
        if (effective.kind == PlannerKind.study) ...<Widget>[
          const SizedBox(height: AppSpacing.s10),
          if (!entitled)
            PremiumLockHint(
              message: PlannerStrings.expectedLocked,
              actionLabel: PlannerStrings.premium,
              onOpenPaywall: widget.onOpenPaywall ?? () {},
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s10),
              decoration: BoxDecoration(
                color: c.sunk,
                borderRadius: BorderRadius.circular(AppRadius.r10),
              ),
              child: Row(
                children: <Widget>[
                  LucideIcon.small(LucideIcons.clock, color: c.tx3),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: Text(
                      suggestion != null && subjectName != null
                          ? PlannerStrings.expected(subjectName, suggestion.minutes)
                          : PlannerStrings.expectedFirst,
                      style: AppTypography.caption.copyWith(color: c.tx2),
                    ),
                  ),
                  if (suggestion != null)
                    Text(PlannerStrings.expectedBasis, style: AppTypography.caption.copyWith(color: c.tx3)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  String? _subjectName(String? id) {
    if (id == null) return null;
    final subjects = ref.read(plannerSubjectsProvider).value ?? const <Subject>[];
    for (final s in subjects) {
      if (s.id == id) return s.name;
    }
    return null;
  }

  Widget _event(AppColors c, PlannerDraft effective, LocalDate today, int weekStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_isNew) ...<Widget>[
          Text(PlannerStrings.eventKind, style: AppTypography.caption.copyWith(color: c.tx3)),
          const SizedBox(height: AppSpacing.s8),
          SegmentedChoice<DraftEventMode>(
            value: effective.eventMode,
            options: const <(DraftEventMode, String)>[
              (DraftEventMode.period, PlannerStrings.eventPeriod),
              (DraftEventMode.repeat, PlannerStrings.eventRepeat),
            ],
            onChanged: (m) => _set(_draft.copyWith(eventMode: m)),
          ),
          const SizedBox(height: AppSpacing.s14),
        ],
        if (effective.isPeriod) _period(c, effective, today, weekStart),
        if (effective.isRepeat)
          RecurrenceEditor(
            value: RecurrenceFields(
              weekdays: _draft.weekdays,
              startTime: _draft.startTime,
              endTime: _draft.endTime,
              endOption: _draft.endOption,
              endsOn: _draft.endsOn,
            ),
            weekStart: weekStart,
            today: today,
            onChanged: (f) => _set(
              _draft.copyWith(
                weekdays: f.weekdays,
                startTime: f.startTime,
                endTime: f.endTime,
                endOption: f.endOption,
                endsOn: f.endsOn,
              ),
            ),
          ),
      ],
    );
  }

  Widget _period(AppColors c, PlannerDraft effective, LocalDate today, int weekStart) {
    final start = _draft.bandStart;
    final end = _draft.bandEnd;
    String fmt(LocalDate d) => '${d.month}/${d.day}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: StepperField(
                label: PlannerStrings.periodStart,
                text: fmt(start),
                decSemantics: PlannerStrings.dayBefore,
                incSemantics: PlannerStrings.dayAfter,
                onDec: () => _set(_draft.copyWith(bandStart: start.addDays(-1))),
                onInc: () {
                  final n = start.addDays(1);
                  _set(_draft.copyWith(bandStart: n, bandEnd: n.isAfter(end) ? n : end));
                },
                onTapValue: () => setState(() => _periodPicker = _periodPicker == _PeriodField.start ? null : _PeriodField.start),
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: StepperField(
                label: PlannerStrings.periodEnd,
                text: fmt(end),
                decSemantics: PlannerStrings.dayBefore,
                incSemantics: PlannerStrings.dayAfter,
                onDec: () {
                  final n = end.addDays(-1);
                  _set(_draft.copyWith(bandEnd: n, bandStart: n.isBefore(start) ? n : start));
                },
                onInc: () => _set(_draft.copyWith(bandEnd: end.addDays(1))),
                onTapValue: () => setState(() => _periodPicker = _periodPicker == _PeriodField.end ? null : _PeriodField.end),
              ),
            ),
          ],
        ),
        if (_periodPicker != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s10),
          MiniDatePicker(
            selected: _periodPicker == _PeriodField.start ? start : end,
            today: today,
            weekStart: weekStart,
            onPick: (d) {
              if (_periodPicker == _PeriodField.start) {
                _set(_draft.copyWith(bandStart: d, bandEnd: d.isAfter(end) ? d : end));
              } else {
                _set(_draft.copyWith(bandEnd: d, bandStart: d.isBefore(start) ? d : start));
              }
              setState(() => _periodPicker = null);
            },
          ),
        ],
        const SizedBox(height: AppSpacing.s10),
        Text(
          PlannerStrings.periodLength(start.daysUntil(end) + 1),
          style: AppTypography.caption.copyWith(color: c.tx3),
        ),
      ],
    );
  }
}

enum _PeriodField { start, end }

/// Target-time chip (prototype 36 px chip inside a 44 px touch band).
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
          child: Container(
            height: AppLayout.chipHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
            decoration: BoxDecoration(
              color: selected ? c.priWeak : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: selected ? c.pri : c.line, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.withWeight(AppTypography.label, 500).copyWith(color: selected ? c.priTx : c.tx2),
            ),
          ),
        ),
      ),
    );
  }
}
