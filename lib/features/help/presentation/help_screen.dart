// HelpScreen (`/settings/help`, S09 · S09b, PRD 4.4 도움말 · 문의 예외 ·
// prototype N4 · N-문의 전송 실패 · 원본 §4.6-13): FAQ accordion (facts about
// what the app does) and the inquiry form — kind · body (≤ 2000) · optional
// reply email. Sending goes through `submit-inquiry`; offline disables
// sending and keeps the draft; a failure keeps the draft and names the
// fallback mailbox only when one is configured (`SUPPORT_EMAIL`), else says
// it is pending; the daily limit (10) is reported as a fact.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/strings/help_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_redirect.dart';
import '../../settings/application/settings_providers.dart';
import '../application/inquiry_controller.dart';

/// Widget keys for tests.
abstract final class HelpKeys {
  static Key faq(int index) => Key('help-faq-$index');
  static Key kind(int index) => Key('help-kind-$index');
  static const Key body = Key('help-body');
  static const Key email = Key('help-email');
  static const Key send = Key('help-send');
  static const Key notice = Key('help-notice');
  static const Key supportEmail = Key('help-support-email');
  static const Key offline = Key('help-offline');
}

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

enum _Notice { none, sent, rateLimited, failed, bodyEmpty, emailInvalid }

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final TextEditingController _body = TextEditingController();
  final TextEditingController _email = TextEditingController();
  int _kind = 0;
  int _openFaq = -1;
  bool _sending = false;
  _Notice _notice = _Notice.none;

  @override
  void dispose() {
    _body.dispose();
    _email.dispose();
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(AppPaths.settings);

  Future<void> _send() async {
    if (_sending) return;
    if (_body.text.trim().isEmpty) {
      setState(() => _notice = _Notice.bodyEmpty);
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !InquiryController.isValidEmail(email)) {
      setState(() => _notice = _Notice.emailInvalid);
      return;
    }
    setState(() {
      _sending = true;
      _notice = _Notice.none;
    });
    final outcome = await ref.read(inquiryControllerProvider).send(
          kind: HelpStrings.kinds[_kind],
          body: _body.text,
          replyEmail: email.isEmpty ? null : email,
        );
    if (!mounted) return;
    setState(() {
      _sending = false;
      switch (outcome) {
        case InquirySent():
          _notice = _Notice.sent;
          _body.clear();
        case InquiryRateLimited():
          _notice = _Notice.rateLimited;
        case InquiryFailed():
          _notice = _Notice.failed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final localOnly = ref.watch(accountInfoProvider).localOnly;
    final online = ref.watch(networkOnlineProvider).value ?? true;
    return FlowScaffold(
      title: HelpStrings.title,
      onBack: _back,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            HelpStrings.faqTitle,
            style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.tx3),
          ),
          const SizedBox(height: AppSpacing.s8),
          Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: c.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (var i = 0; i < HelpStrings.faq.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                  _FaqTile(
                    key: HelpKeys.faq(i),
                    entry: HelpStrings.faq[i],
                    open: _openFaq == i,
                    onTap: () => setState(() => _openFaq = _openFaq == i ? -1 : i),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            HelpStrings.inquiryTitle,
            style: AppTypography.withWeight(AppTypography.caption, 600).copyWith(color: c.tx3),
          ),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            children: <Widget>[
              for (var i = 0; i < HelpStrings.kinds.length; i++)
                _KindChip(
                  key: HelpKeys.kind(i),
                  label: HelpStrings.kinds[i],
                  selected: _kind == i,
                  onTap: () => setState(() => _kind = i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          AppTextField(
            key: HelpKeys.body,
            controller: _body,
            label: HelpStrings.bodyLabel,
            hint: HelpStrings.bodyPlaceholder,
            maxLength: HelpStrings.bodyMaxLength,
            minLines: 4,
            maxLines: 8,
            enabled: !_sending,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            highlightError: _notice == _Notice.bodyEmpty,
            onChanged: (_) {
              if (_notice == _Notice.bodyEmpty || _notice == _Notice.sent) setState(() => _notice = _Notice.none);
            },
            trailing: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _body,
              builder: (_, v, _) => Text(
                '${v.text.characters.length}/${HelpStrings.bodyMaxLength}',
                style: AppTypography.caption.copyWith(color: c.tx3, fontFeatures: AppTypography.tabularFigures),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          AppTextField(
            key: HelpKeys.email,
            controller: _email,
            label: HelpStrings.replyEmailLabel,
            hint: localOnly ? HelpStrings.replyEmailLocalHint : HelpStrings.replyEmailHint,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            enabled: !_sending,
            highlightError: _notice == _Notice.emailInvalid,
            onChanged: (_) {
              if (_notice == _Notice.emailInvalid) setState(() => _notice = _Notice.none);
            },
          ),
          if (_notice != _Notice.none) ...<Widget>[
            const SizedBox(height: AppSpacing.s12),
            switch (_notice) {
              _Notice.sent => const AppNotice(HelpStrings.sent, key: HelpKeys.notice),
              _Notice.rateLimited => const AppNotice.error(HelpStrings.sendRateLimited, key: HelpKeys.notice),
              _Notice.failed => const AppNotice.error(HelpStrings.sendFailed, key: HelpKeys.notice),
              _Notice.bodyEmpty => const AppNotice.error(HelpStrings.bodyEmpty, key: HelpKeys.notice),
              _Notice.emailInvalid => const AppNotice.error(HelpStrings.replyEmailInvalid, key: HelpKeys.notice),
              _Notice.none => const SizedBox.shrink(),
            },
            if (_notice == _Notice.failed) ...<Widget>[
              const SizedBox(height: AppSpacing.s8),
              Center(
                child: AppConfig.hasSupportEmail
                    ? SelectableText(
                        HelpStrings.supportAddress(AppConfig.supportEmail),
                        key: HelpKeys.supportEmail,
                        style: AppTypography.withWeight(AppTypography.label, 600).copyWith(color: c.priTx),
                      )
                    : Text(
                        HelpStrings.supportAddressPending,
                        key: HelpKeys.supportEmail,
                        style: AppTypography.caption.copyWith(color: c.tx3),
                      ),
              ),
            ],
          ],
          if (!online) ...<Widget>[
            const SizedBox(height: AppSpacing.s12),
            const AppNotice.error(HelpStrings.offline, key: HelpKeys.offline),
          ],
          const SizedBox(height: AppSpacing.s16),
          AppButton(
            key: HelpKeys.send,
            label: _notice == _Notice.failed ? HelpStrings.resend : HelpStrings.send,
            icon: LucideIcons.send,
            busy: _sending,
            busyLabel: HelpStrings.sending,
            onPressed: _notice == _Notice.rateLimited || !online ? null : () => unawaited(_send()),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({super.key, required this.entry, required this.open, required this.onTap});

  final FaqEntry entry;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      expanded: open,
      label: entry.question,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          excluding: !open,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(entry.question, style: AppTypography.body.copyWith(color: c.tx))),
                    const SizedBox(width: AppSpacing.s8),
                    LucideIcon.small(open ? LucideIcons.chevronUp : LucideIcons.chevronDown, color: c.tx3),
                  ],
                ),
                if (open)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s8),
                    child: Text(entry.answer, style: AppTypography.label.copyWith(color: c.tx2, height: 1.6)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({super.key, required this.label, required this.selected, required this.onTap});

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
