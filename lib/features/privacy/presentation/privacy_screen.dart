// PrivacyScreen (`/settings/privacy`, S09 · S09b, PRD 4.4 카메라와 개인정보
// · 7장 · D14 · prototype 11 · N6 · N7 · expSheet · delDlg · delAllDlg):
// what the camera does (hero · how), what is stored (the D14 table, vendor
// terms pending), the camera toggle, the corrections fact + 감도 자동 조정
// toggle (§4.5-9), the reading row (premium; consent ② wording reused),
// the device photos (list · delete one / all, 30-day rule), 내 기록
// 내보내기 (CSV · JSON share) and 모든 기록 삭제 (two confirmations, nothing
// deleted before the last one; entry blocked while measuring). Expired
// photos are purged when the screen opens.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/consent_strings.dart';
import '../../../core/strings/privacy_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/export/export_service.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../billing/billing_routes.dart';
import '../../measure/domain/away_policy.dart';
import '../../settings/application/settings_providers.dart';
import '../application/photo_retention.dart';
import '../application/privacy_providers.dart';

/// S06 정정 이력 화면 (`measure_routes.dart`).
const String kCorrectionsPath = '/measure/corrections';

/// Widget keys for tests.
abstract final class PrivacyKeys {
  static const Key heroOn = Key('privacy-hero-on');
  static const Key heroOff = Key('privacy-hero-off');
  static const Key cameraSwitch = Key('privacy-camera-switch');
  static const Key corrections = Key('privacy-corrections');
  static const Key sensitivitySwitch = Key('privacy-sensitivity-switch');
  static const Key storedTable = Key('privacy-stored-table');
  static const Key readingAction = Key('privacy-reading-action');
  static const Key photosOpen = Key('privacy-photos-open');
  static const Key photosDeleteAll = Key('privacy-photos-delete-all');
  static const Key photosEmpty = Key('privacy-photos-empty');
  static Key photoDelete(String id) => Key('privacy-photo-delete-$id');
  static const Key export = Key('privacy-export');
  static const Key exportCsv = Key('privacy-export-csv');
  static const Key exportJson = Key('privacy-export-json');
  static const Key exportError = Key('privacy-export-error');
  static const Key deleteAll = Key('privacy-delete-all');
}

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _cameraBusy = false;
  bool _sensitivityBusy = false;
  bool _photosBusy = false;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(photoRetentionProvider).purgeExpired());
  }

  void _back() => context.canPop() ? context.pop() : context.go(AppPaths.settings);

  Future<void> _setCamera(bool on) async {
    if (_cameraBusy) return;
    setState(() => _cameraBusy = true);
    final ok = await ref.read(settingsControllerProvider).setSeatDetection(on: on);
    if (!mounted) return;
    setState(() => _cameraBusy = false);
    if (!ok) showAppToast(context, message: PrivacyStrings.loadFailed);
  }

  Future<void> _setSensitivityAuto(bool on) async {
    if (_sensitivityBusy) return;
    setState(() => _sensitivityBusy = true);
    final ok = await ref.read(settingsControllerProvider).setSensitivityAuto(on: on);
    if (!mounted) return;
    setState(() => _sensitivityBusy = false);
    if (!ok) showAppToast(context, message: PrivacyStrings.loadFailed);
  }

  Future<void> _openPhotos() => showAppSheet<void>(
        context,
        title: PrivacyStrings.photosSheetTitle,
        builder: (_) => const _PhotosSheet(),
      );

  Future<void> _deleteAllPhotos(List<PhotoRow> rows) async {
    if (_photosBusy || rows.isEmpty) return;
    PhotoDeleteResult? result;
    final ok = await showAppModal(
      context,
      title: PrivacyStrings.deletePhotosTitle(rows.length),
      body: PrivacyStrings.deletePhotoBody,
      primaryLabel: PrivacyStrings.deletePhotoConfirm,
      destructive: true,
      onConfirm: () async {
        setState(() => _photosBusy = true);
        try {
          result = await ref.read(photoRetentionProvider).deleteMany(rows.map((r) => r.photo));
        } finally {
          if (mounted) setState(() => _photosBusy = false);
        }
      },
    );
    final r = result;
    if (!mounted || !ok || r == null) return;
    showAppToast(
      context,
      message: r.allDone
          ? PrivacyStrings.photosDeleted(r.deleted.length)
          : PrivacyStrings.photosPartial(r.total, r.deleted.length, r.failed.length),
    );
  }

  Future<void> _openExport() => showAppSheet<void>(
        context,
        title: PrivacyStrings.export,
        builder: (_) => const _ExportSheet(),
      );

  /// delDlg (impact: the five groups + what stays) → delAllDlg (final) →
  /// execute. Nothing is deleted before the final confirmation; a running
  /// measurement blocks the entry (PRD 4.4 측정 중에는 진입 불가).
  Future<void> _deleteAll() async {
    if (await ref.read(sessionRepositoryProvider).readSnapshot() != null) {
      if (mounted) showAppToast(context, message: PrivacyStrings.deleteAllBlocked);
      return;
    }
    if (!mounted) return;
    final body = <String>[
      PrivacyStrings.deleteAllBody,
      ...PrivacyStrings.deleteAllItems,
      PrivacyStrings.deleteAllKeeps,
    ].join('\n');
    final next = await showAppModal(
      context,
      title: PrivacyStrings.deleteAllTitle,
      body: body,
      primaryLabel: PrivacyStrings.deleteAllNext,
    );
    if (!next || !mounted) return;
    DeleteAllOutcome? outcome;
    await showAppModal(
      context,
      title: PrivacyStrings.deleteAllFinalTitle,
      body: PrivacyStrings.deleteAllFinalBody,
      primaryLabel: PrivacyStrings.deleteAllConfirm,
      destructive: true,
      onConfirm: () async {
        final o = await ref.read(privacyActionsProvider).deleteAll();
        outcome = o;
        if (o is DeleteAllFailed) throw o.error;
      },
    );
    if (!mounted) return;
    switch (outcome) {
      case DeleteAllDone():
        showAppToast(context, message: PrivacyStrings.deleteAllDone);
      case DeleteAllPartial(:final failedPhotos):
        showAppToast(context, message: PrivacyStrings.deleteAllPartial(failedPhotos));
      case DeleteAllBlocked():
        showAppToast(context, message: PrivacyStrings.deleteAllBlocked);
      case DeleteAllFailed():
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(settingsStreamProvider);
    final entitled = ref.watch(privacyEntitlementProvider).value?.entitled ?? false;
    final corrections = ref.watch(recentCorrectionsProvider).value ?? 0;
    final rows = ref.watch(photoRowsProvider) ?? const <PhotoRow>[];

    return FlowScaffold(
      title: PrivacyStrings.title,
      onBack: _back,
      child: switch (settings) {
        AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Hero(on: value.seatDetectionEnabled),
              const SizedBox(height: AppSpacing.s20),
              const _SectionTitle(PrivacyStrings.howTitle),
              const _HowRow(icon: LucideIcons.cpu, title: PrivacyStrings.how1Title, body: PrivacyStrings.how1Body),
              const _HowRow(icon: LucideIcons.eyeOff, title: PrivacyStrings.how2Title, body: PrivacyStrings.how2Body),
              const _HowRow(icon: LucideIcons.clock, title: PrivacyStrings.how3Title, body: PrivacyStrings.how3Body),
              const SizedBox(height: AppSpacing.s20),
              const _SectionTitle(PrivacyStrings.storedTitle),
              const _StoredTable(),
              const SizedBox(height: AppSpacing.s20),
              AppListSection(
                title: PrivacyStrings.settingsTitle,
                children: <Widget>[
                  AppListRow(
                    label: PrivacyStrings.cameraToggle,
                    hint: PrivacyStrings.cameraToggleHint,
                    trailing: Semantics(
                      label: PrivacyStrings.cameraToggle,
                      child: Switch(
                        key: PrivacyKeys.cameraSwitch,
                        value: value.seatDetectionEnabled,
                        activeTrackColor: c.pri,
                        onChanged: _cameraBusy ? null : (on) => unawaited(_setCamera(on)),
                      ),
                    ),
                  ),
                  AppListRow(
                    key: PrivacyKeys.corrections,
                    label: PrivacyStrings.corrections,
                    hint: PrivacyStrings.correctionsStatus(corrections, AwayPolicy.thresholdFor(value.sensitivityLevel).inSeconds),
                    value: PrivacyStrings.correctionsOpen,
                    onTap: () => context.push(kCorrectionsPath),
                  ),
                  AppListRow(
                    label: PrivacyStrings.sensitivityAuto,
                    hint: PrivacyStrings.sensitivityAutoHint,
                    trailing: Semantics(
                      label: PrivacyStrings.sensitivityAuto,
                      child: Switch(
                        key: PrivacyKeys.sensitivitySwitch,
                        value: value.sensitivityAuto,
                        activeTrackColor: c.pri,
                        onChanged: _sensitivityBusy ? null : (on) => unawaited(_setSensitivityAuto(on)),
                      ),
                    ),
                  ),
                  _ReadingRow(entitled: entitled, onOpenPaywall: () => context.push(paywallPath)),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppButton.secondary(
                      key: PrivacyKeys.photosOpen,
                      label: PrivacyStrings.photosButton(rows.length),
                      size: AppButtonSize.small,
                      onPressed: () => unawaited(_openPhotos()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: AppButton.destructive(
                      key: PrivacyKeys.photosDeleteAll,
                      label: PrivacyStrings.photosDeleteAll,
                      size: AppButtonSize.small,
                      busy: _photosBusy,
                      onPressed: rows.isEmpty ? null : () => unawaited(_deleteAllPhotos(rows)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              AppListSection(
                children: <Widget>[
                  AppListRow(
                    key: PrivacyKeys.export,
                    label: PrivacyStrings.export,
                    leading: LucideIcon.small(LucideIcons.download, color: c.tx2),
                    onTap: () => unawaited(_openExport()),
                  ),
                  AppListRow(
                    key: PrivacyKeys.deleteAll,
                    label: PrivacyStrings.deleteAll,
                    leading: LucideIcon.small(LucideIcons.trash2, color: c.accTx),
                    destructive: true,
                    onTap: () => unawaited(_deleteAll()),
                  ),
                ],
              ),
              Text(PrivacyStrings.footer, style: AppTypography.caption.copyWith(color: c.tx3, height: 1.6)),
            ],
          ),
        AsyncError() => StatePanel.error(
            title: PrivacyStrings.loadFailed,
            onAction: () => ref.invalidate(settingsStreamProvider),
          ),
        _ => const StatePanel.loading(),
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: on ? PrivacyKeys.heroOn : PrivacyKeys.heroOff,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: on ? c.priWeak : c.sunk,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LucideIcon(on ? LucideIcons.shieldCheck : LucideIcons.cameraOff, color: on ? c.priTx : c.tx2),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  on ? PrivacyStrings.heroOnTitle : PrivacyStrings.heroOffTitle,
                  style: AppTypography.heading.copyWith(color: c.tx),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  on ? PrivacyStrings.heroOnBody : PrivacyStrings.heroOffBody,
                  style: AppTypography.label.copyWith(color: c.tx2, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.s4, bottom: AppSpacing.s8),
        child: Text(
          text,
          style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: context.colors.tx3),
        ),
      );
}

class _HowRow extends StatelessWidget {
  const _HowRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LucideIcon(icon, color: c.tx2),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppTypography.withWeight(AppTypography.body, 600).copyWith(color: c.tx)),
                Text(body, style: AppTypography.label.copyWith(color: c.tx2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// D14 table — data · location · retention, row by row (the decided table,
/// vendor terms shown as pending).
class _StoredTable extends StatelessWidget {
  const _StoredTable();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const rows = PrivacyStrings.d14Rows;
    return Column(
      key: PrivacyKeys.storedTable,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: BorderSide(color: c.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(PrivacyStrings.storedColumns, style: AppTypography.caption.copyWith(color: c.tx3)),
                ),
              ),
              for (final (data, location, retention) in rows) ...<Widget>[
                Divider(height: 1, thickness: 1, color: c.line),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(data, style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.tx)),
                      Text(location, style: AppTypography.caption.copyWith(color: c.priTx)),
                      Text(retention, style: AppTypography.caption.copyWith(color: c.tx2, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(PrivacyStrings.storedVendorPending, style: AppTypography.caption.copyWith(color: c.accTx)),
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.entitled, required this.onOpenPaywall});

  final bool entitled;
  final VoidCallback onOpenPaywall;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(PrivacyStrings.reading, style: AppTypography.body.copyWith(color: c.tx))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s2),
                decoration: BoxDecoration(
                  color: c.accWeak,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  PrivacyStrings.premiumBadge,
                  style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.accTx),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            entitled ? PrivacyStrings.readingStatusOn : PrivacyStrings.readingStatusOff,
            style: AppTypography.caption.copyWith(color: c.tx2),
          ),
          const SizedBox(height: AppSpacing.s4),
          for (final line in ConsentStrings.readingLines)
            Text(line, style: AppTypography.caption.copyWith(color: c.tx3, height: 1.5)),
          if (!entitled) ...<Widget>[
            const SizedBox(height: AppSpacing.s8),
            AppButton.secondary(
              key: PrivacyKeys.readingAction,
              label: PrivacyStrings.unlock,
              size: AppButtonSize.small,
              expand: false,
              onPressed: onOpenPaywall,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// N6 보관 중 사진

enum _PhotoState { idle, deleting, failed }

class _PhotosSheet extends ConsumerStatefulWidget {
  const _PhotosSheet();

  @override
  ConsumerState<_PhotosSheet> createState() => _PhotosSheetState();
}

class _PhotosSheetState extends ConsumerState<_PhotosSheet> {
  final Map<String, _PhotoState> _states = <String, _PhotoState>{};

  Future<void> _delete(PhotoRow row) async {
    if (_states[row.photo.id] == _PhotoState.deleting) return;
    final ok = await showAppModal(
      context,
      title: PrivacyStrings.deletePhotoTitle,
      body: PrivacyStrings.deletePhotoBody,
      primaryLabel: PrivacyStrings.deletePhotoConfirm,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _states[row.photo.id] = _PhotoState.deleting);
    final done = await ref.read(photoRetentionProvider).deleteOne(row.photo);
    if (!mounted) return;
    setState(() => _states[row.photo.id] = done ? _PhotoState.idle : _PhotoState.failed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = ref.watch(photoRowsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(PrivacyStrings.photosSheetHint, style: AppTypography.label.copyWith(color: c.tx2, height: 1.6)),
        const SizedBox(height: AppSpacing.s12),
        if (rows == null)
          const StatePanel.loading()
        else if (rows.isEmpty)
          const StatePanel.empty(key: PrivacyKeys.photosEmpty, title: PrivacyStrings.photosEmpty, icon: LucideIcons.images)
        else
          for (final r in rows) _PhotoTile(row: r, state: _states[r.photo.id] ?? _PhotoState.idle, onDelete: () => unawaited(_delete(r))),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.row, required this.state, required this.onDelete});

  final PhotoRow row;
  final _PhotoState state;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final taken = row.photo.takenAt.toLocal();
    final expires = row.photo.expiresAt.toLocal();
    final label = switch (state) {
      _PhotoState.idle => PrivacyStrings.photoDelete,
      _PhotoState.deleting => PrivacyStrings.photoDeleting,
      _PhotoState.failed => PrivacyStrings.photoDeleteFailed,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        children: <Widget>[
          LucideIcon(LucideIcons.image, color: c.tx3),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(row.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body.copyWith(color: c.tx)),
                Text(
                  '${PrivacyStrings.photoShot(PrivacyStrings.monthDayTime(taken.month, taken.day, formatClock(taken)))} · '
                  '${PrivacyStrings.photoExpires(PrivacyStrings.monthDay(expires.month, expires.day))}',
                  style: AppTypography.caption.copyWith(color: c.tx3),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          AppButton.secondary(
            key: PrivacyKeys.photoDelete(row.photo.id),
            label: label,
            size: AppButtonSize.small,
            expand: false,
            busy: state == _PhotoState.deleting,
            busyLabel: PrivacyStrings.photoDeleting,
            onPressed: state == _PhotoState.deleting ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// expSheet 내 기록 내보내기

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet();

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  ExportFormat? _running;
  ExportFormat? _failed;

  Future<void> _export(ExportFormat f) async {
    if (_running != null) return;
    setState(() {
      _running = f;
      _failed = null;
    });
    try {
      await ref.read(privacyActionsProvider).export(f);
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() {
          _running = null;
          _failed = f;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(PrivacyStrings.exportHint, style: AppTypography.label.copyWith(color: c.tx2, height: 1.6)),
        const SizedBox(height: AppSpacing.s16),
        AppButton(
          key: PrivacyKeys.exportCsv,
          label: _failed == ExportFormat.csv ? PrivacyStrings.exportRetry : PrivacyStrings.exportCsv,
          icon: LucideIcons.fileText,
          busy: _running == ExportFormat.csv,
          busyLabel: PrivacyStrings.exporting,
          onPressed: _running != null ? null : () => unawaited(_export(ExportFormat.csv)),
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton.secondary(
          key: PrivacyKeys.exportJson,
          label: _failed == ExportFormat.json ? PrivacyStrings.exportRetry : PrivacyStrings.exportJson,
          icon: LucideIcons.fileJson,
          busy: _running == ExportFormat.json,
          busyLabel: PrivacyStrings.exporting,
          onPressed: _running != null ? null : () => unawaited(_export(ExportFormat.json)),
        ),
        if (_failed != null) ...<Widget>[
          const SizedBox(height: AppSpacing.s12),
          const AppNotice.error(PrivacyStrings.exportFailed, key: PrivacyKeys.exportError),
        ],
      ],
    );
  }
}
