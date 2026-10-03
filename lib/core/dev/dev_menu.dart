// Dev menu (S01). dev flavor only: compiled out of prod via
// `const bool.fromEnvironment('DEV_MENU')` (see AppConfig.devToolsEnabled).
// Entered with a shake gesture; hosts the Fake scenario switches and a link
// to `/_gallery`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../data/export/export_service.dart';
import '../../data/export/share_export.dart';
import '../../data/repositories/repositories.dart';
import '../../data/seed/dev_seeder.dart';
import '../config/app_config.dart';
import '../contracts/billing_gateway.dart';
import '../contracts/fakes/fakes.dart';
import '../contracts/providers.dart';
import '../logging/app_logger.dart';
import '../strings/dev_strings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/widgets.dart';
import 'dev_fake_settings.dart';
import 'seat_lab/seat_lab_screen.dart';
import 'shake_detector.dart';

/// Raw compile-time flag. Prefer [AppConfig.devToolsEnabled], which also
/// excludes the prod flavor.
const bool kDevMenu = bool.fromEnvironment('DEV_MENU');

/// Wraps the app (MaterialApp.router `builder`). In prod this is a no-op
/// pass-through that the compiler removes.
class DevMenuGate extends StatefulWidget {
  const DevMenuGate({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<DevMenuGate> createState() => _DevMenuGateState();
}

class _DevMenuGateState extends State<DevMenuGate> {
  ShakeDetector? _detector;
  StreamSubscription<void>? _sub;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    if (!AppConfig.devToolsEnabled) return;
    final d = ShakeDetector();
    _detector = d;
    d.listen(
      accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
          .map((e) => (x: e.x, y: e.y, z: e.z))
          .handleError((Object _) {}),
    );
    _sub = d.onShake.listen((_) => _openMenu());
  }

  Future<void> _openMenu() async {
    if (_open) return;
    final ctx = widget.navigatorKey.currentContext;
    if (ctx == null) return;
    _open = true;
    try {
      await showDevMenu(ctx);
    } finally {
      _open = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _detector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> showDevMenu(BuildContext context) {
  if (!AppConfig.devToolsEnabled) return Future<void>.value();
  return showAppSheet<void>(
    context,
    title: DevStrings.title,
    builder: (_) => const DevMenuSheet(),
  );
}

class DevMenuSheet extends ConsumerWidget {
  const DevMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(devFakeSettingsControllerProvider);
    final ctl = ref.read(devFakeSettingsControllerProvider.notifier);
    String deviceId;
    try {
      deviceId = ref.read(deviceIdProvider);
    } on UnimplementedError {
      deviceId = '—';
    }

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.s16,
            bottom: AppSpacing.s8,
          ),
          child: Text(
            title,
            style: AppTypography.withWeight(AppTypography.label, 600)
                .copyWith(color: c.tx2),
          ),
        );

    Widget info(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Row(
            children: <Widget>[
              Text(k, style: AppTypography.caption.copyWith(color: c.tx3)),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  v,
                  style: AppTypography.caption.copyWith(color: c.tx),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

    Widget choices<T>({
      required List<(T, String)> items,
      required T value,
      required ValueChanged<T> onChanged,
    }) =>
        Wrap(
          spacing: AppSpacing.s6,
          runSpacing: AppSpacing.s6,
          children: <Widget>[
            for (final (v, label) in items)
              ChoiceChip(
                label: Text(label),
                selected: v == value,
                onSelected: (_) => onChanged(v),
                labelStyle: AppTypography.caption.copyWith(
                  color: v == value ? c.priTx : c.tx2,
                ),
                selectedColor: c.priWeak,
                backgroundColor: c.sunk,
                side: BorderSide(color: v == value ? c.pri : c.line),
                showCheckmark: false,
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(DevStrings.subtitle, style: AppTypography.caption.copyWith(color: c.tx3)),
        const SizedBox(height: AppSpacing.s8),
        info(DevStrings.flavorLabel, AppConfig.flavor.name),
        info(DevStrings.deviceIdLabel, deviceId),
        info(
          DevStrings.backendLabel,
          AppConfig.hasBackendConfig
              ? DevStrings.backendPresent
              : DevStrings.backendMissing,
        ),
        const SizedBox(height: AppSpacing.s12),
        AppButton.secondary(
          label: DevStrings.openGallery,
          size: AppButtonSize.small,
          onPressed: () {
            Navigator.of(context).pop();
            GoRouter.of(context).push('/_gallery');
          },
        ),
        section(DevStrings.sectionSeat),
        // S04: real engine switch + measurement harness.
        Row(
          children: <Widget>[
            Text(
              DevStrings.seatImplLabel,
              style: AppTypography.caption.copyWith(color: c.tx2),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: choices<bool>(
                value: s.seatReal,
                onChanged: ctl.setSeatReal,
                items: const <(bool, String)>[
                  (false, DevStrings.seatImplFake),
                  (true, DevStrings.seatImplReal),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        AppButton.secondary(
          label: DevStrings.openSeatLab,
          size: AppButtonSize.small,
          onPressed: () {
            Navigator.of(context).pop();
            GoRouter.of(context).push(seatLabPath);
          },
        ),
        const SizedBox(height: AppSpacing.s8),
        choices<FakeSeatScenario>(
          value: s.seat,
          onChanged: ctl.setSeat,
          items: const <(FakeSeatScenario, String)>[
            (FakeSeatScenario.alwaysSeated, DevStrings.seatAlwaysSeated),
            (FakeSeatScenario.awayAfter, DevStrings.seatAwayAfter),
            (FakeSeatScenario.lostAfter, DevStrings.seatLostAfter),
            (FakeSeatScenario.permissionDenied, DevStrings.seatPermissionDenied),
            (FakeSeatScenario.cameraBusy, DevStrings.seatCameraBusy),
          ],
        ),
        section(DevStrings.sectionReading),
        choices<FakeReadingScenario>(
          value: s.reading,
          onChanged: ctl.setReading,
          items: const <(FakeReadingScenario, String)>[
            (FakeReadingScenario.success, DevStrings.readingSuccess),
            (FakeReadingScenario.successZeroWrong, DevStrings.readingSuccessZeroWrong),
            (
              FakeReadingScenario.takingLongThenSuccess,
              DevStrings.readingTakingLongThenSuccess
            ),
            (FakeReadingScenario.fail, DevStrings.readingFail),
            (FakeReadingScenario.sendFail, DevStrings.readingSendFail),
            (FakeReadingScenario.cancelRace, DevStrings.readingCancelRace),
            (FakeReadingScenario.saveConflict, DevStrings.readingSaveConflict),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: <Widget>[
            Text(
              '${DevStrings.delayLabel} ${s.delayMs}',
              style: AppTypography.caption.copyWith(color: c.tx2),
            ),
            Expanded(
              child: Slider(
                value: s.delayMs.toDouble(),
                min: 0,
                max: 5000,
                divisions: 25,
                onChanged: (v) => ctl.setDelayMs(v.round()),
              ),
            ),
          ],
        ),
        section(DevStrings.sectionBilling),
        choices<EntitlementStatus>(
          value: s.billing,
          onChanged: ctl.setBilling,
          items: const <(EntitlementStatus, String)>[
            (EntitlementStatus.free, DevStrings.billingFree),
            (EntitlementStatus.trial, DevStrings.billingTrial),
            (EntitlementStatus.premium, DevStrings.billingPremium),
            (EntitlementStatus.cancelPending, DevStrings.billingCancelPending),
            (EntitlementStatus.grace, DevStrings.billingGrace),
            (EntitlementStatus.expired, DevStrings.billingExpired),
            (EntitlementStatus.pendingApproval, DevStrings.billingPendingApproval),
          ],
        ),
        section(DevStrings.sectionSync),
        choices<bool>(
          value: s.syncOffline,
          onChanged: ctl.setSyncOffline,
          items: const <(bool, String)>[
            (false, DevStrings.syncIdle),
            (true, DevStrings.syncOffline),
          ],
        ),
        section(DevStrings.sectionData),
        const _DataSection(),
      ],
    );
  }
}

/// S02: sample data in/out and JSON · CSV export. Every action is async and
/// the buttons lock while running (AppButton).
class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final outbox = ref.watch(_outboxCountProvider);

    Future<void> run(Future<void> Function() action, String doneMessage) async {
      try {
        await action();
        if (context.mounted) showAppToast(context, message: doneMessage);
      } catch (e, st) {
        appLog.w('dev data action failed', error: e, stackTrace: st);
        if (context.mounted) {
          showAppToast(context, message: DevStrings.exportFailed);
        }
      }
    }

    Future<void> export(ExportFormat format) => run(
          () async {
            final file = await ref.read(exportServiceProvider).build(format);
            await shareExportFile(file);
          },
          '${_label(format)} · ${DevStrings.exportDone}',
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          child: Text(
            '${DevStrings.outboxLabel} ${outbox.value ?? '—'}',
            style: AppTypography.caption.copyWith(color: c.tx2),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: <Widget>[
            AppButton.secondary(
              label: DevStrings.sampleInsert,
              size: AppButtonSize.small,
              expand: false,
              onPressed: () => run(
                () => ref.read(devSeederProvider).insertSampleData(),
                DevStrings.sampleInserted,
              ),
            ),
            AppButton.secondary(
              label: DevStrings.sampleClear,
              size: AppButtonSize.small,
              expand: false,
              onPressed: () => run(
                () => ref.read(devSeederProvider).clearSampleData(),
                DevStrings.sampleCleared,
              ),
            ),
            AppButton.secondary(
              label: DevStrings.exportJson,
              size: AppButtonSize.small,
              expand: false,
              onPressed: () => export(ExportFormat.json),
            ),
            AppButton.secondary(
              label: DevStrings.exportCsv,
              size: AppButtonSize.small,
              expand: false,
              onPressed: () => export(ExportFormat.csv),
            ),
          ],
        ),
      ],
    );
  }

  static String _label(ExportFormat f) => f == ExportFormat.json ? 'JSON' : 'CSV';
}

final _outboxCountProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.syncOutbox).watch().map((rows) => rows.length);
});
