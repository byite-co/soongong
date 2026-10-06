import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contracts/providers.dart';
import '../../../core/contracts/seat_engine.dart';
import '../../../core/domain/entities/entities.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/ids.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/common_strings.dart';
import '../../../core/strings/home_strings.dart';
import '../../../core/strings/measure_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/engines/seat/camera_permission.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../home/application/session_recovery.dart';
import '../../home/domain/recovery_candidate.dart';
import '../application/measure_controller.dart';
import '../domain/away_policy.dart';
import '../domain/seated_time_calculator.dart';
import '../domain/segment.dart';
import '../domain/sensitivity_policy.dart';

class MeasureSetupScreen extends ConsumerStatefulWidget {
  const MeasureSetupScreen({super.key, this.resumeId});
  final String? resumeId;
  @override
  ConsumerState<MeasureSetupScreen> createState() => _SetupState();
}

class _SetupState extends ConsumerState<MeasureSetupScreen> {
  late MeasureController controller;
  List<Subject> subjects = [];
  List<PlannerItem> items = [];
  String? subjectId;
  PlannerItem? task;
  bool camera = true, loading = true, loadFailed = false;

  /// An unfinished session of this device that still has to be resumed,
  /// finished or discarded before a new one can start (the home sheet may
  /// have been dismissed with 기록 유지).
  RecoveryCandidate? pending;
  @override
  void initState() {
    super.initState();
    controller = ref.read(measureControllerProvider);
    controller.resetSaved();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(MeasureSetupScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resumeId != widget.resumeId) unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      loadFailed = false;
    });
    try {
      subjects = await ref.read(subjectRepositoryProvider).getAll();
      items = await ref.read(plannerRepositoryProvider).getAllItems();
      await controller.prepare();
      camera =
          controller.preferences.seatDetectionEnabled &&
          controller.availability == SeatAvailability.ok;
      pending = null;
      if (widget.resumeId == null &&
          !controller.isLive &&
          !controller.hasDraft) {
        final sessions = ref.read(sessionRepositoryProvider);
        pending = RecoveryCandidate.detect(
          snapshot: await sessions.readSnapshot(),
          sessions: await sessions.getAll(),
          newId: newUuid,
          deviceId: ref.read(deviceIdProvider),
        );
      }
    } on Object {
      loadFailed = true;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _start() async {
    if (widget.resumeId != null) {
      try {
        await controller.recover(
          widget.resumeId!,
          continueSession: true,
          manual: !camera,
        );
      } on Object {
        if (mounted) setState(() => loadFailed = true);
        return;
      }
    } else {
      ref.read(recoveryPromptedProvider.notifier).mark();
      final success = await controller.start(
        mode: camera ? SessionMode.camera : SessionMode.manual,
        subjectId: subjectId,
        task: task,
      );
      if (!success) return;
    }
    if (mounted) context.go('/measure/focus');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final today = LocalDate.of(ref.read(appClockProvider).now());
      final available = items.where(
        (i) =>
            !i.isDone &&
            i.kind != PlannerKind.event &&
            i.subjectId == subjectId,
      );
      return FlowScaffold(
        title: MeasureStrings.setup,
        onBack: () => context.go('/home'),
        bottom: AppButton(
          label: MeasureStrings.start,
          variant: AppButtonVariant.accent,
          busy: controller.busy,
          onPressed:
              loading ||
                  loadFailed ||
                  pending != null ||
                  controller.hasDraft ||
                  controller.isLive
              ? null
              : _start,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (loading)
              const StatePanel.loading()
            else if (loadFailed)
              StatePanel.error(onAction: _load)
            else ...[
              if (controller.isLive || controller.hasDraft) ...[
                const Text(MeasureStrings.existing),
                AppButton(
                  label: controller.isLive
                      ? MeasureStrings.resume
                      : MeasureStrings.finishRecord,
                  onPressed: () => context.go(
                    controller.isLive ? '/measure/focus' : '/measure/summary',
                  ),
                ),
              ],
              if (pending != null)
                _PendingRecovery(
                  candidate: pending!,
                  today: today,
                  onChanged: _load,
                ),
              if (widget.resumeId == null) ...[
                const Text(MeasureStrings.subject),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text(MeasureStrings.noSubject),
                      selected: subjectId == null,
                      onSelected: (_) => setState(() {
                        subjectId = null;
                        task = null;
                      }),
                    ),
                    for (final subject in subjects)
                      ChoiceChip(
                        label: Text(subject.name),
                        selected: subjectId == subject.id,
                        onSelected: (_) => setState(() {
                          subjectId = subject.id;
                          task = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(MeasureStrings.linkedTask),
                for (final group in [
                  MeasureStrings.overdue,
                  MeasureStrings.today,
                  MeasureStrings.next,
                ]) ...[
                  if (available.any((i) => _group(i, today) == group))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(group, style: AppTypography.caption),
                    ),
                  for (final item in available.where(
                    (i) => _group(i, today) == group,
                  ))
                    ListTile(
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.date.key} · ${_plannerKind(item.kind)}',
                      ),
                      trailing: LucideIcon(
                        task?.id == item.id
                            ? LucideIcons.circleCheck
                            : LucideIcons.circle,
                      ),
                      onTap: () => setState(() => task = item),
                    ),
                ],
                ListTile(
                  title: const Text(MeasureStrings.noTask),
                  subtitle: Text(MeasureStrings.kind(SessionKind.self)),
                  trailing: LucideIcon(
                    task == null ? LucideIcons.circleCheck : LucideIcons.circle,
                  ),
                  onTap: () => setState(() => task = null),
                ),
              ],
              const SizedBox(height: 24),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(MeasureStrings.camera),
                      subtitle: const Text(MeasureStrings.cameraBody),
                      value: camera,
                      onChanged: controller.busy
                          ? null
                          : (on) async {
                              if (on) {
                                await controller.prepare(requestCamera: true);
                              }
                              if (mounted) {
                                setState(
                                  () => camera =
                                      on &&
                                      controller.availability ==
                                          SeatAvailability.ok,
                                );
                              }
                            },
                    ),
                    if (controller.availability ==
                        SeatAvailability.permissionDenied) ...[
                      const Text(MeasureStrings.permissionDenied),
                      TextButton(
                        onPressed: () async {
                          await CameraPermission.openSettings();
                        },
                        child: const Text(MeasureStrings.settings),
                      ),
                    ],
                    if (controller.availability ==
                            SeatAvailability.cameraBusy ||
                        controller.availability ==
                            SeatAvailability.unavailable) ...[
                      Text(
                        controller.availability == SeatAvailability.cameraBusy
                            ? MeasureStrings.cameraBusy
                            : MeasureStrings.unavailable,
                      ),
                      TextButton(
                        onPressed: () => setState(() => camera = false),
                        child: const Text(MeasureStrings.toManual),
                      ),
                    ],
                    Text(
                      camera
                          ? MeasureStrings.privacy
                          : MeasureStrings.manualBody,
                    ),
                  ],
                ),
              ),
              if (controller.failed)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(MeasureStrings.startFailed),
                ),
            ],
          ],
        ),
      );
    },
  );
  String _group(PlannerItem i, LocalDate today) =>
      i.date.key.compareTo(today.key) < 0
      ? MeasureStrings.overdue
      : i.date == today
      ? MeasureStrings.today
      : MeasureStrings.next;
  String _plannerKind(PlannerKind kind) => MeasureStrings.kind(switch (kind) {
    PlannerKind.study => SessionKind.study,
    PlannerKind.todo => SessionKind.todo,
    _ => SessionKind.self,
  });
}

class MeasureFocusScreen extends ConsumerStatefulWidget {
  const MeasureFocusScreen({super.key});
  @override
  ConsumerState<MeasureFocusScreen> createState() => _FocusState();
}

class _FocusState extends ConsumerState<MeasureFocusScreen> {
  late MeasureController controller;
  bool _longSheet = false;
  @override
  void initState() {
    super.initState();
    controller = ref.read(measureControllerProvider);
    controller.addListener(_changes);
  }

  @override
  void dispose() {
    controller.removeListener(_changes);
    super.dispose();
  }

  void _changes() {
    if (!controller.longAway || _longSheet || !mounted) return;
    _longSheet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showAppSheet<void>(
        context,
        title: MeasureStrings.longAway,
        builder: (sheet) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: MeasureStrings.keepGoing,
              onPressed: () => Navigator.pop(sheet),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(sheet);
                unawaited(_finish());
              },
              child: const Text(MeasureStrings.end),
            ),
          ],
        ),
      );
      controller.longAway = false;
      _longSheet = false;
    });
  }

  Future<void> _finish() async {
    await controller.finish();
    if (mounted && controller.phase == MeasurePhase.summary) {
      context.go('/measure/summary');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (!controller.isLive) {
        return _Missing(onHome: () => context.go('/home'));
      }
      final c = context.colors;
      final goal = controller.preferences.dailyGoalMinutes * 60;
      final progress = goal <= 0
          ? 0.0
          : (controller.todayTotal.inSeconds / goal).clamp(0.0, 1.0);
      return PopScope(
        canPop: false,
        // System back never ends a measurement (ending is irreversible): it
        // pauses a running one. 종료 is the explicit button.
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop &&
              !controller.paused &&
              !controller.busy &&
              !controller.cameraLost) {
            unawaited(controller.pause());
          }
        },
        child: FlowScaffold(
          title: MeasureStrings.focus,
          bottom: Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: controller.paused
                      ? MeasureStrings.resume
                      : MeasureStrings.pause,
                  onPressed: controller.busy || controller.cameraLost
                      ? null
                      : () => controller.paused
                            ? controller.resume()
                            : controller.pause(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: MeasureStrings.end,
                  onPressed: controller.busy ? null : _finish,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Chip(
                  label: Text(MeasureStrings.segment(controller.currentKind)),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          color: c.pri,
                          backgroundColor: c.line,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(MeasureStrings.pure),
                          Text(
                            _duration(controller.seated),
                            style: AppTypography.heading.copyWith(
                              fontSize: 36,
                              color: c.priTx,
                            ),
                          ),
                          Text(
                            MeasureStrings.todayTotal(
                              formatDuration(controller.todayTotal),
                              controller.preferences.dailyGoalMinutes,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (progress >= 1)
                const Center(child: Text(MeasureStrings.goalReached)),
              _SessionLabels(
                subjectId: controller.subjectId,
                taskId: controller.plannerItemId,
                kind: controller.kind,
              ),
              if (controller.lowPower) const Text(MeasureStrings.lowPower),
              if (controller.checkpointFailed) ...[
                const Text(MeasureStrings.checkpointFailed),
                TextButton(
                  onPressed: controller.checkpoint,
                  child: const Text(MeasureStrings.retry),
                ),
              ],
              if (controller.cameraLost)
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(MeasureStrings.lost, style: AppTypography.heading),
                      const SizedBox(height: 4),
                      Text(
                        controller.reconnectFailed
                            ? MeasureStrings.reconnectFailed
                            : MeasureStrings.lostBody(
                                formatDuration(controller.seated),
                              ),
                      ),
                      if (!controller.reconnectFailed)
                        TextButton(
                          onPressed: controller.busy ? null : controller.resume,
                          child: const Text(MeasureStrings.reconnect),
                        ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => controller.resume(manual: true),
                        child: const Text(MeasureStrings.manualContinue),
                      ),
                    ],
                  ),
                ),
              if (controller.currentKind == SegmentKind.away)
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        MeasureStrings.awayTitle,
                        style: AppTypography.heading,
                      ),
                      const SizedBox(height: 4),
                      const Text(MeasureStrings.awayBody),
                      const SizedBox(height: 4),
                      Text(
                        MeasureStrings.awayElapsed(
                          _duration(controller.openElapsed),
                        ),
                      ),
                    ],
                  ),
                ),
              if (controller.mode == SessionMode.manual)
                const Text(MeasureStrings.manualBody),
              const SizedBox(height: 24),
              const Text(
                MeasureStrings.background,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class MeasureSummaryScreen extends ConsumerStatefulWidget {
  const MeasureSummaryScreen({super.key});
  @override
  ConsumerState<MeasureSummaryScreen> createState() => _SummaryState();
}

class _SummaryState extends ConsumerState<MeasureSummaryScreen> {
  late final MeasureController controller;
  @override
  void initState() {
    super.initState();
    controller = ref.read(measureControllerProvider);
  }

  Future<void> _save() async {
    if (controller.seated < const Duration(minutes: 3)) {
      final confirmed = await showAppModal(
        context,
        title: MeasureStrings.shortTitle,
        body: MeasureStrings.shortBody,
        primaryLabel: MeasureStrings.save,
      );
      if (!confirmed || !mounted) return;
    }
    final router = GoRouter.of(context);
    final saved = await controller.save();
    if (!saved) return;
    if (!mounted) return;
    // Prototype `saveSession`: 저장 → 홈 (the ring updates there). The toast
    // carries the outcome; a sensitivity change links to the history.
    if (controller.sensitivityChanged) {
      showAppToast(
        context,
        message: MeasureStrings.sensitivity,
        actionLabel: MeasureStrings.history,
        onAction: () => router.push('/measure/corrections'),
      );
    } else {
      showAppToast(context, message: MeasureStrings.saved);
    }
    router.go('/home');
  }

  Future<void> _discard() async {
    final ok = await showAppModal(
      context,
      title: MeasureStrings.discardTitle,
      body: MeasureStrings.discardBody(
        seated: formatDuration(controller.seated),
        corrections: controller.correctedIds.length,
        linkedTask: controller.plannerItemId != null,
      ),
      primaryLabel: MeasureStrings.discard,
      destructive: true,
      onConfirm: controller.discard,
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.saveState is MeasureSaved) {
        // Shown for the frame between the save and the home navigation.
        return const FlowScaffold(
          title: MeasureStrings.summary,
          child: Text(MeasureStrings.saved, textAlign: TextAlign.center),
        );
      }
      if (!controller.hasDraft) {
        return _Missing(onHome: () => context.go('/home'));
      }
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !controller.busy) unawaited(_discard());
        },
        child: FlowScaffold(
          title: MeasureStrings.summary,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: controller.saveState is MeasureSaveFailed
                    ? MeasureStrings.retry
                    : MeasureStrings.save,
                busy: controller.busy,
                onPressed: controller.busy ? null : _save,
              ),
              TextButton(
                onPressed: controller.busy ? null : _discard,
                child: const Text(MeasureStrings.discard),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Total(controller.seated),
              _SessionLabels(
                subjectId: controller.subjectId,
                taskId: controller.plannerItemId,
                kind: controller.kind,
              ),
              if (controller.mode == SessionMode.manual ||
                  controller.segments.any((s) => s.kind == SegmentKind.manual))
                const Chip(label: Text(MeasureStrings.manual)),
              if (controller.saveState is MeasureSaving)
                const Text(MeasureStrings.saving),
              if (controller.saveState is MeasureSaveFailed)
                const Text(MeasureStrings.failed),
              if (controller.plannerItemId != null)
                CheckboxListTile(
                  title: const Text(MeasureStrings.completeTask),
                  value: controller.completeTask,
                  onChanged: controller.busy
                      ? null
                      : (v) => setState(
                          () => controller.completeTask = v ?? false,
                        ),
                ),
              _Timeline(
                segments: controller.segments,
                onCorrect: controller.busy
                    ? null
                    : (s) => _correctSheet(
                        context,
                        s,
                        () => controller.correct(s.id),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<SessionDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<SessionDetailScreen> {
  StudySession? session;
  List<Segment> original = [];
  final Set<String> corrections = {};
  bool loading = true,
      failed = false,
      saveFailed = false,
      deleteFailed = false,
      busy = false,
      editing = false,
      deleted = false;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(sessionRepositoryProvider);
      session = await repo.get(widget.id);
      original = (await repo.getSegments(widget.id))
          .map(
            (s) => Segment(
              id: s.id,
              kind: s.kind,
              startAt: s.startAt,
              endAt: s.endAt,
              corrected: s.corrected,
            ),
          )
          .toList();
      failed = false;
    } on Object {
      failed = true;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _cancel() async {
    if (corrections.isEmpty) {
      // Nothing changed: leave edit mode without a dialog (prototype
      // `sumDiscardTap` when not corrected).
      setState(() {
        editing = false;
        saveFailed = false;
      });
      return;
    }
    if (await showAppModal(
          context,
          title: MeasureStrings.cancelTitle,
          body: MeasureStrings.cancelBody(
            corrections.length,
            formatDuration(const SeatedTimeCalculator().seated(original)),
          ),
          primaryLabel: MeasureStrings.cancelChanges,
        ) &&
        mounted) {
      setState(() {
        corrections.clear();
        editing = false;
        saveFailed = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      busy = true;
      saveFailed = false;
    });
    final controller = ref.read(measureControllerProvider);
    try {
      await ref
          .read(sessionRepositoryProvider)
          .writer
          .runInTransaction(
            () => controller.persistCorrections(widget.id, corrections),
          );
      corrections.clear();
      editing = false;
      await _load();
      if (mounted) {
        showAppToast(
          context,
          message: controller.sensitivityChanged
              ? MeasureStrings.sensitivity
              : MeasureStrings.saved,
          actionLabel: MeasureStrings.history,
          onAction: () => context.push('/measure/corrections'),
        );
      }
    } on Object {
      saveFailed = true; // corrections stay selected; 변경 저장 retries
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _delete() async {
    final repo = ref.read(sessionRepositoryProvider);
    final ok = await showAppModal(
      context,
      title: MeasureStrings.delete,
      body: MeasureStrings.deleteBody,
      primaryLabel: MeasureStrings.delete,
      destructive: true,
      onConfirm: () => repo.softDelete(widget.id),
    );
    if (!ok || !mounted) return;
    setState(() => deleted = true);
    final id = widget.id;
    Timer(const Duration(seconds: 5), () async {
      try {
        final row = await repo.get(id);
        final until = row?.stamp.pendingDeleteUntil;
        if (until != null && !repo.ctx.clock.now().isBefore(until)) {
          await repo.commitDelete(id);
        }
      } on Object {
        if (mounted) setState(() => deleteFailed = true);
      }
    });
    showUndoToast(
      context,
      message: MeasureStrings.deleted,
      onUndo: () async {
        try {
          await repo.undoDelete(id);
          if (mounted) setState(() => deleted = false);
        } on Object {
          if (mounted) setState(() => deleteFailed = true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = original
        .map(
          (s) => corrections.contains(s.id)
              ? s.copyWith(kind: SegmentKind.seated, corrected: true)
              : s,
        )
        .toList();
    return PopScope(
      canPop: !editing && !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) unawaited(_cancel());
      },
      child: FlowScaffold(
        title: MeasureStrings.detail,
        onBack: busy
            ? null
            : () {
                if (editing) {
                  unawaited(_cancel());
                } else {
                  context.go('/home');
                }
              },
        bottom: loading || deleted || session == null
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: editing
                        ? (saveFailed
                              ? MeasureStrings.retry
                              : MeasureStrings.saveChanges)
                        : MeasureStrings.edit,
                    busy: busy,
                    onPressed: busy
                        ? null
                        : () {
                            if (editing) {
                              unawaited(_save());
                            } else {
                              setState(() => editing = true);
                            }
                          },
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : editing
                        ? _cancel
                        : _delete,
                    child: Text(
                      editing
                          ? MeasureStrings.cancelChanges
                          : MeasureStrings.delete,
                    ),
                  ),
                ],
              ),
        child: loading
            ? const StatePanel.loading()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (failed) ...[
                    const Text(MeasureStrings.loadFailed),
                    TextButton(
                      onPressed: _load,
                      child: const Text(MeasureStrings.retry),
                    ),
                  ],
                  if (saveFailed) const Text(MeasureStrings.failed),
                  if (deleteFailed) const Text(CommonStrings.deleteFailed),
                  if (deleted)
                    const Text(MeasureStrings.deleted)
                  else if (session == null)
                    const Text(MeasureStrings.missing)
                  else ...[
                    _Total(const SeatedTimeCalculator().seated(segments)),
                    _SessionLabels(
                      subjectId: session!.subjectId,
                      taskId: session!.plannerItemId,
                      kind: session!.kind,
                    ),
                    if (segments.any((s) => s.kind == SegmentKind.manual))
                      const Chip(label: Text(MeasureStrings.manual)),
                    _Timeline(
                      segments: segments,
                      onCorrect: !editing || busy
                          ? null
                          : (s) => _correctSheet(
                              context,
                              s,
                              () => setState(() => corrections.add(s.id)),
                            ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/measure/corrections'),
                      child: const Text(MeasureStrings.history),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class CorrectionHistoryScreen extends ConsumerStatefulWidget {
  const CorrectionHistoryScreen({super.key});
  @override
  ConsumerState<CorrectionHistoryScreen> createState() => _HistoryState();
}

/// userflow `corr` · `crEmpty`: the list of 되돌린 구간, the current away
/// threshold with the 2-week count (facts, PRD 7장 "정정 이력·감도"), and a
/// next action when empty. Streams are created once (not per build).
class _HistoryState extends ConsumerState<CorrectionHistoryScreen> {
  late final Stream<List<Correction>> _corrections = ref
      .read(sessionRepositoryProvider)
      .watchAllCorrections();
  late final Stream<AppSettings> _settings = ref
      .read(settingsRepositoryProvider)
      .watch();

  @override
  Widget build(BuildContext context) => FlowScaffold(
    title: MeasureStrings.historyTitle,
    onBack: () => context.canPop() ? context.pop() : context.go('/home'),
    child: StreamBuilder<List<Correction>>(
      stream: _corrections,
      builder: (context, snap) {
        if (snap.hasError) return const Text(MeasureStrings.loadFailed);
        if (!snap.hasData) return const StatePanel.loading();
        final rows = snap.data!;
        final now = ref.read(appClockProvider).now();
        final recent = SensitivityPolicy.countRecent(
          rows.map((c) => c.at),
          now,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<AppSettings>(
              stream: _settings,
              builder: (context, settings) {
                final prefs = settings.data;
                if (prefs == null) return const SizedBox.shrink();
                final threshold = AwayPolicy.thresholdFor(
                  prefs.sensitivityLevel,
                ).inSeconds;
                return _Card(
                  child: Text(
                    prefs.sensitivityAuto
                        ? MeasureStrings.sensitivityStatus(threshold, recent)
                        : MeasureStrings.sensitivityManual(threshold),
                  ),
                );
              },
            ),
            if (rows.isEmpty)
              StatePanel.empty(
                title: MeasureStrings.emptyHistory,
                body: MeasureStrings.emptyHistoryBody,
                actionLabel: MeasureStrings.pastRecords,
                onAction: () => context.go(AppPaths.stats),
              )
            else
              for (final c in rows)
                ListTile(
                  title: Text(
                    '${MeasureStrings.segment(c.fromKind)} → ${MeasureStrings.segment(c.toKind)}',
                  ),
                  subtitle: Text(
                    '${LocalDate.of(c.at.toLocal()).key} ${formatClock(c.at.toLocal())}',
                  ),
                  onTap: () => context.push('/session/${c.sessionId}'),
                ),
          ],
        );
      },
    ),
  );
}

class _SessionLabels extends ConsumerStatefulWidget {
  const _SessionLabels({
    required this.subjectId,
    required this.taskId,
    required this.kind,
  });
  final String? subjectId, taskId;
  final SessionKind kind;
  @override
  ConsumerState<_SessionLabels> createState() => _SessionLabelsState();
}

class _SessionLabelsState extends ConsumerState<_SessionLabels> {
  Future<Subject?>? _subject;
  Future<PlannerItem?>? _task;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(_SessionLabels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId ||
        oldWidget.taskId != widget.taskId) {
      _refresh();
    }
  }

  // One lookup per id: a new Future per build would reset the FutureBuilder
  // (placeholder flicker) on every 1-second tick of the focus screen.
  void _refresh() {
    final subjectId = widget.subjectId;
    final taskId = widget.taskId;
    _subject = subjectId == null
        ? null
        : ref.read(subjectRepositoryProvider).get(subjectId);
    _task = taskId == null
        ? null
        : ref.read(plannerRepositoryProvider).getItem(taskId);
  }

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(MeasureStrings.kind(widget.kind), style: AppTypography.heading),
        if (_subject != null)
          FutureBuilder<Subject?>(
            future: _subject,
            builder: (_, snap) =>
                Text(snap.data?.name ?? MeasureStrings.subject),
          ),
        if (_task != null)
          FutureBuilder<PlannerItem?>(
            future: _task,
            builder: (_, snap) =>
                Text(snap.data?.title ?? MeasureStrings.linkedTask),
          ),
      ],
    ),
  );
}

/// Setup-screen counterpart of the home recovery sheet (same handler, same
/// three choices) for a session left unfinished after 기록 유지.
class _PendingRecovery extends ConsumerStatefulWidget {
  const _PendingRecovery({
    required this.candidate,
    required this.today,
    required this.onChanged,
  });
  final RecoveryCandidate candidate;
  final LocalDate today;
  final Future<void> Function() onChanged;
  @override
  ConsumerState<_PendingRecovery> createState() => _PendingRecoveryState();
}

class _PendingRecoveryState extends ConsumerState<_PendingRecovery> {
  bool busy = false;

  String get _startedLabel {
    final t = widget.candidate.startedAt.toLocal();
    final day = LocalDate.of(t);
    if (day == widget.today) return '${HomeStrings.today} ${formatClock(t)}';
    if (day == widget.today.addDays(-1)) {
      return '${HomeStrings.yesterday} ${formatClock(t)}';
    }
    return '${HomeStrings.monthDay(t.month, t.day)} ${formatClock(t)}';
  }

  Future<void> _finish() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await ref.read(sessionRecoveryHandlerProvider).finish(widget.candidate);
      if (mounted) context.go('/measure/summary');
    } on Object {
      if (mounted) showAppToast(context, message: HomeStrings.recoverFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _discard() async {
    if (busy) return;
    final recorded = formatDuration(widget.candidate.recorded);
    final handler = ref.read(sessionRecoveryHandlerProvider);
    final ok = await showAppModal(
      context,
      title: HomeStrings.recoverDiscardTitle,
      body: HomeStrings.recoverDiscardBody(recorded),
      primaryLabel: CommonStrings.delete,
      destructive: true,
      onConfirm: () => handler.discard(widget.candidate),
    );
    if (!ok || !mounted) return;
    showAppToast(context, message: HomeStrings.recoverDiscarded(recorded));
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(HomeStrings.recoverTitle, style: AppTypography.heading),
        const SizedBox(height: 4),
        Text(
          HomeStrings.recoverBody(
            _startedLabel,
            formatDuration(widget.candidate.recorded),
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: HomeStrings.recoverResume,
          busy: busy,
          onPressed: busy
              ? null
              : () => context.go(
                  '${AppPaths.measureSetup}?resume=${widget.candidate.sessionId}',
                ),
        ),
        const SizedBox(height: 8),
        AppButton.secondary(
          label: HomeStrings.recoverFinish,
          onPressed: busy ? null : _finish,
        ),
        TextButton(
          onPressed: busy ? null : _discard,
          child: const Text(HomeStrings.recoverDiscard),
        ),
      ],
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.segments, this.onCorrect});
  final List<Segment> segments;
  final ValueChanged<Segment>? onCorrect;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      const Text(MeasureStrings.timeline),
      for (final s in segments)
        ListTile(
          leading: LucideIcon(
            LucideIcons.circle,
            color: s.kind.countsAsSeated
                ? context.colors.pri
                : context.colors.tx3,
          ),
          title: Text(
            '${MeasureStrings.segment(s.kind)}${s.corrected ? ' · ${MeasureStrings.corrected}' : ''}',
          ),
          subtitle: Text(
            '${formatClock(s.startAt.toLocal())}–${formatClock(s.endAt.toLocal())} · ${_duration(s.duration)}',
          ),
          trailing: s.kind == SegmentKind.away && onCorrect != null
              ? const LucideIcon(LucideIcons.pencil)
              : null,
          onTap: s.kind == SegmentKind.away && onCorrect != null
              ? () => onCorrect!(s)
              : null,
        ),
    ],
  );
}

Future<void> _correctSheet(
  BuildContext context,
  Segment segment,
  VoidCallback apply,
) => showAppSheet<void>(
  context,
  title: MeasureStrings.correct,
  builder: (sheet) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '${formatClock(segment.startAt.toLocal())}–${formatClock(segment.endAt.toLocal())}',
      ),
      const SizedBox(height: 16),
      AppButton(
        label: MeasureStrings.restore,
        onPressed: () {
          apply();
          Navigator.pop(sheet);
        },
      ),
    ],
  ),
);

class _Total extends StatelessWidget {
  const _Total(this.duration);
  final Duration duration;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Text(MeasureStrings.pure),
        Text(
          _duration(duration),
          style: AppTypography.heading.copyWith(
            fontSize: 36,
            color: context.colors.priTx,
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 12),
    child: Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colors.line),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

class _Missing extends StatelessWidget {
  const _Missing({required this.onHome});
  final VoidCallback onHome;
  @override
  Widget build(BuildContext context) => FlowScaffold(
    title: MeasureStrings.summary,
    child: Column(
      children: [
        const Text(MeasureStrings.missing),
        AppButton(label: MeasureStrings.home, onPressed: onHome),
      ],
    ),
  );
}

String _duration(Duration value) {
  final seconds = value.inSeconds;
  return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
