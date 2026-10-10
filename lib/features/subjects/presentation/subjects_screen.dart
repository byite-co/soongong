// SubjectsScreen (`/settings/subjects`, S09, PRD 4.4 과목 관리 · prototype
// 13 · N11 · B8 · subjDelN): rows (colour dot + name + 이번 주 순공 fact),
// add/edit sheet (name ≤ 20 · one of the 8 colours, unique), delete with
// the 5-second undo (D22; records move to 기타 on commit). 기타 cannot be
// deleted. At most 8 subjects — one per colour (PRD §8: colours stay
// distinguishable and always carry a name label).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/entities/entities.dart';
import '../../../core/strings/subjects_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_redirect.dart';
import '../application/subjects_controller.dart';
import '../application/subjects_providers.dart';
import '../domain/subject_draft.dart';

/// Widget keys for tests.
abstract final class SubjectsKeys {
  static const Key add = Key('subjects-add');
  static const Key colorsFull = Key('subjects-colors-full');
  static Key row(String id) => Key('subjects-row-$id');
  static const Key sheetName = Key('subjects-sheet-name');
  static Key color(int index) => Key('subjects-sheet-color-$index');
  static const Key save = Key('subjects-sheet-save');
  static const Key delete = Key('subjects-sheet-delete');
  static const Key error = Key('subjects-sheet-error');
}

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  void _back() => context.canPop() ? context.pop() : context.go(AppPaths.settings);

  Future<void> _openSheet(List<Subject> live, {Subject? existing}) async {
    final result = await showAppSheet<_SheetResult>(
      context,
      title: existing == null ? SubjectsStrings.sheetAdd : SubjectsStrings.sheetEdit,
      builder: (_) => _SubjectSheet(live: live, existing: existing),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case _SheetSaved(:final created):
        showAppToast(context, message: created ? SubjectsStrings.added : SubjectsStrings.saved);
      case _SheetDeleted(:final name, :final pending):
        showUndoToast(
          context,
          message: SubjectsStrings.deleted(name),
          onUndo: () => unawaited(_undo(pending)),
        );
    }
  }

  Future<void> _undo(PendingSubjectDelete pending) async {
    final ok = await pending.undo();
    if (!mounted) return;
    showAppToast(context, message: ok ? SubjectsStrings.restored : SubjectsStrings.deleteFailed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final subjects = ref.watch(subjectsListProvider);
    final seated = ref.watch(subjectsWeekSeatedProvider);

    return FlowScaffold(
      title: SubjectsStrings.title,
      onBack: _back,
      bottom: switch (subjects) {
        AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (SubjectDraft.firstFreeColor(value) == null) ...<Widget>[
                Text(
                  SubjectsStrings.colorsFull(SubjectDraft.colorCount),
                  key: SubjectsKeys.colorsFull,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: c.tx3),
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
              AppButton(
                key: SubjectsKeys.add,
                label: SubjectsStrings.add,
                icon: LucideIcons.plus,
                onPressed: SubjectDraft.firstFreeColor(value) == null ? null : () => unawaited(_openSheet(value)),
              ),
            ],
          ),
        _ => null,
      },
      child: switch (subjects) {
        AsyncData(:final value) => AppListSection(
            children: <Widget>[
              for (final s in value)
                AppListRow(
                  key: SubjectsKeys.row(s.id),
                  label: s.name,
                  hint: s.isDefault ? SubjectsStrings.defaultBadge : null,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: c.subject(s.colorIndex), shape: BoxShape.circle),
                  ),
                  value: switch (seated[s.id]) {
                    final int sec when sec > 0 => SubjectsStrings.thisWeek(formatDuration(Duration(seconds: sec))),
                    _ => SubjectsStrings.noRecord,
                  },
                  onTap: () => unawaited(_openSheet(value, existing: s)),
                ),
            ],
          ),
        AsyncError() => StatePanel.error(
            title: SubjectsStrings.loadFailed,
            onAction: () => ref.invalidate(subjectsListProvider),
          ),
        _ => const StatePanel.loading(),
      },
    );
  }
}

sealed class _SheetResult {
  const _SheetResult();
}

class _SheetSaved extends _SheetResult {
  const _SheetSaved({required this.created});

  final bool created;
}

class _SheetDeleted extends _SheetResult {
  const _SheetDeleted({required this.name, required this.pending});

  final String name;
  final PendingSubjectDelete pending;
}

// ---------------------------------------------------------------------------
// N11 과목 추가 / 편집

class _SubjectSheet extends ConsumerStatefulWidget {
  const _SubjectSheet({required this.live, this.existing});

  final List<Subject> live;
  final Subject? existing;

  @override
  ConsumerState<_SubjectSheet> createState() => _SubjectSheetState();
}

class _SubjectSheetState extends ConsumerState<_SubjectSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late int _color = widget.existing?.colorIndex ?? SubjectDraft.firstFreeColor(widget.live) ?? 0;
  bool _saving = false;
  String? _error;

  Set<int> get _taken => SubjectDraft.takenColors(widget.live, editingId: widget.existing?.id);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _errorText(SubjectDraftError e) => switch (e) {
        SubjectDraftError.nameEmpty => SubjectsStrings.nameEmpty,
        SubjectDraftError.nameTooLong => SubjectsStrings.nameTooLong,
        SubjectDraftError.nameDuplicate => SubjectsStrings.nameDuplicate,
        SubjectDraftError.colorTaken => SubjectsStrings.colorTaken,
      };

  Future<void> _save() async {
    if (_saving) return;
    final draft = SubjectDraft(name: _name.text, colorIndex: _color);
    final local = draft.validate(widget.live, editingId: widget.existing?.id);
    if (local.isNotEmpty) {
      setState(() => _error = _errorText(local.first));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final outcome = await ref.read(subjectsControllerProvider).save(draft, id: widget.existing?.id);
    if (!mounted) return;
    switch (outcome) {
      case SubjectSaved():
        Navigator.of(context).pop(_SheetSaved(created: widget.existing == null));
      case SubjectSaveInvalid(:final errors):
        setState(() {
          _saving = false;
          _error = _errorText(errors.first);
        });
      case SubjectSaveFailed():
        setState(() {
          _saving = false;
          _error = SubjectsStrings.saveFailed;
        });
    }
  }

  Future<void> _delete() async {
    final s = widget.existing;
    if (s == null || s.isDefault || _saving) return;
    PendingSubjectDelete? pending;
    final ok = await showAppModal(
      context,
      title: SubjectsStrings.deleteTitle(s.name),
      body: SubjectsStrings.deleteBody,
      primaryLabel: SubjectsStrings.deleteConfirm,
      destructive: true,
      onConfirm: () async {
        pending = await ref.read(subjectsControllerProvider).delete(s.id);
      },
    );
    if (!mounted || !ok || pending == null) return;
    Navigator.of(context).pop(_SheetDeleted(name: s.name, pending: pending!));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final existing = widget.existing;
    final taken = _taken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          key: SubjectsKeys.sheetName,
          controller: _name,
          label: SubjectsStrings.name,
          hint: SubjectsStrings.namePlaceholder,
          maxLength: SubjectsStrings.nameMaxLength,
          autofocus: existing == null,
          enabled: !_saving,
          textInputAction: TextInputAction.done,
          highlightError: _error == SubjectsStrings.nameEmpty || _error == SubjectsStrings.nameDuplicate,
          onChanged: (_) => setState(() => _error = null),
          onSubmitted: (_) => unawaited(_save()),
          trailing: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _name,
            builder: (_, v, _) => Text(
              '${v.text.characters.length}/${SubjectsStrings.nameMaxLength}',
              style: AppTypography.caption.copyWith(color: c.tx3, fontFeatures: AppTypography.tabularFigures),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(SubjectsStrings.color, style: AppTypography.caption.copyWith(color: c.tx2)),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s10,
          runSpacing: AppSpacing.s6,
          children: <Widget>[
            for (var i = 0; i < SubjectDraft.colorCount; i++)
              _Swatch(
                key: SubjectsKeys.color(i),
                color: c.subject(i),
                selected: i == _color,
                taken: taken.contains(i),
                onTap: taken.contains(i) || _saving
                    ? null
                    : () => setState(() {
                          _color = i;
                          _error = null;
                        }),
              ),
          ],
        ),
        if (taken.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s4),
            child: Text(
              '${SubjectsStrings.colorTaken}: ${taken.length}',
              style: AppTypography.caption.copyWith(color: c.tx3),
            ),
          ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          AppNotice.error(_error!, key: SubjectsKeys.error),
        ],
        const SizedBox(height: AppSpacing.s16),
        AppButton(
          key: SubjectsKeys.save,
          label: existing == null ? SubjectsStrings.create : SubjectsStrings.save,
          busy: _saving,
          busyLabel: SubjectsStrings.saving,
          onPressed: () => unawaited(_save()),
        ),
        if (existing != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s8),
          if (existing.isDefault)
            Text(
              SubjectsStrings.defaultCannotDelete,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: c.tx3),
            )
          else
            Semantics(
              button: true,
              label: SubjectsStrings.deleteRow,
              child: GestureDetector(
                key: SubjectsKeys.delete,
                behavior: HitTestBehavior.opaque,
                onTap: _saving ? null : () => unawaited(_delete()),
                child: Container(
                  height: AppSpacing.touchTarget,
                  alignment: Alignment.center,
                  child: Text(
                    SubjectsStrings.deleteRow,
                    style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.accTx),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// One of the 8 subject colours; a taken one is shown struck and disabled.
class _Swatch extends StatelessWidget {
  const _Swatch({super.key, required this.color, required this.selected, required this.taken, this.onTap});

  final Color color;
  final bool selected;
  final bool taken;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: onTap != null,
      selected: selected,
      enabled: !taken,
      label: taken ? SubjectsStrings.colorTaken : SubjectsStrings.color,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.touchTarget,
          height: AppSpacing.touchTarget,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: taken ? color.withValues(alpha: 0.35) : color,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? c.tx : Colors.transparent, width: 2.5),
              ),
              child: taken
                  ? LucideIcon.small(LucideIcons.x, color: c.surface)
                  : selected
                      ? LucideIcon.small(LucideIcons.check, color: c.surface)
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
