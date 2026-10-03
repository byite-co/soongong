// GateScreen (`/gate`, userflow `ageGate`, S05 · D6): birth date wheels →
// `age-check` before any provider is touched. The chosen date exists only in
// this widget's state and the one repository call; nothing persists it.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/auth_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../auth/application/signup_flow.dart';
import '../../auth/domain/auth_redirect.dart';
import '../application/age_gate_controller.dart';
import '../domain/birth_date_input.dart';

class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key, this.initial});

  /// Wheel start position (tests); defaults to [BirthDateInput.initial].
  final BirthDateInput? initial;

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  late BirthDateInput _input;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _input = widget.initial ?? BirthDateInput.initial(ref.read(appClockProvider).now());
  }

  Future<void> _continue() async {
    final today = ref.read(appClockProvider).now();
    final date = _input.validate(today);
    if (date == null) {
      setState(() => _localError = AuthStrings.ageGateInvalidDate);
      return;
    }
    setState(() => _localError = null);
    final next = await ref.read(ageGateControllerProvider.notifier).submit(date);
    if (!mounted) return;
    switch (next) {
      case GateNext.none:
        break;
      case GateNext.blocked:
        context.go(AppPaths.gateBlocked);
      case GateNext.providers:
        context.go(AppPaths.login);
      case GateNext.signup:
        context.go(AppPaths.loginSignup);
    }
  }

  void _toLogin() {
    ref.read(signupFlowProvider.notifier).reset();
    context.go(AppPaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(ageGateControllerProvider);
    final notice = ref.watch(signupFlowProvider.select((s) => s.notice));
    final today = ref.read(appClockProvider).now();
    final error = _localError ?? state.error;

    return FlowScaffold(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppButton(
            label: AuthStrings.ageGateContinue,
            busy: state.busy,
            busyLabel: AuthStrings.ageGateChecking,
            onPressed: _continue,
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(AuthStrings.ageGateHaveAccount, style: AppTypography.label.copyWith(color: c.tx2)),
              TextButton(
                onPressed: state.busy ? null : _toLogin,
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
                  foregroundColor: c.priTx,
                ),
                child: Text(
                  AuthStrings.ageGateLogin,
                  style: AppTypography.withWeight(AppTypography.label, 600),
                ),
              ),
            ],
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: AppSpacing.s24),
          _AppMark(color: c),
          const SizedBox(height: AppSpacing.s20),
          Text(AuthStrings.ageGateTitle, style: AppTypography.title.copyWith(color: c.tx)),
          const SizedBox(height: AppSpacing.s8),
          Text(AuthStrings.ageGateHelp, style: AppTypography.label.copyWith(color: c.tx2)),
          if (notice != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s16),
            AppNotice(notice),
          ],
          const SizedBox(height: AppSpacing.s20),
          _BirthDateWheels(
            value: _input,
            today: today,
            enabled: !state.busy,
            onChanged: (v) => setState(() {
              _input = v;
              _localError = null;
            }),
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.s16),
            AppNotice.error(error),
          ],
        ],
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.color});

  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.pri,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Text(
        '순',
        style: AppTypography.withWeight(AppTypography.heading, 700).copyWith(color: color.onPri),
      ),
    );
  }
}

class _BirthDateWheels extends StatelessWidget {
  const _BirthDateWheels({
    required this.value,
    required this.today,
    required this.enabled,
    required this.onChanged,
  });

  final BirthDateInput value;
  final DateTime today;
  final bool enabled;
  final ValueChanged<BirthDateInput> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final minYear = BirthDateInput.minYear(today);
    final years = List<int>.generate(today.year - minYear + 1, (i) => today.year - i);
    final months = List<int>.generate(12, (i) => i + 1);
    final days = List<int>.generate(BirthDateInput.daysInMonth(value.year, value.month), (i) => i + 1);

    Widget wheel({
      required String unit,
      required List<int> items,
      required int selected,
      required ValueChanged<int> onSelected,
      required int flex,
    }) {
      final index = items.indexOf(selected).clamp(0, items.length - 1);
      return Expanded(
        flex: flex,
        child: Semantics(
          label: unit,
          value: '$selected$unit',
          child: SizedBox(
            height: 168,
            child: CupertinoPicker(
              key: ValueKey<String>('$unit-${items.length}-${items.first}'),
              itemExtent: 42,
              scrollController: FixedExtentScrollController(initialItem: index),
              onSelectedItemChanged: enabled ? (i) => onSelected(items[i]) : null,
              selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                background: c.priWeak.withValues(alpha: 0.6),
              ),
              children: <Widget>[
                for (final v in items)
                  Center(
                    child: Text(
                      '$v$unit',
                      style: AppTypography.withWeight(AppTypography.heading, 500)
                          .copyWith(color: c.tx, fontFeatures: AppTypography.tabularFigures),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: c.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
      child: Row(
        children: <Widget>[
          wheel(
            unit: AuthStrings.ageGateYear,
            items: years,
            selected: value.year,
            onSelected: (y) => onChanged(value.copyWith(year: y)),
            flex: 5,
          ),
          wheel(
            unit: AuthStrings.ageGateMonth,
            items: months,
            selected: value.month,
            onSelected: (m) => onChanged(value.copyWith(month: m)),
            flex: 3,
          ),
          wheel(
            unit: AuthStrings.ageGateDay,
            items: days,
            selected: value.day,
            onSelected: (d) => onChanged(value.copyWith(day: d)),
            flex: 3,
          ),
        ],
      ),
    );
  }
}
