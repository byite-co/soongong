// InquiryController (S09): 문의 → `submit-inquiry` Edge Function (body ≤
// 2000 · optional reply email). The body carries the chosen kind and a
// one-line 7-day record summary (counts and time only — no photos, no
// free text of records). Failure keeps the draft on screen (PRD 4.4).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/strings/help_strings.dart';
import '../../../core/utils/time_format.dart';
import '../../../data/auth/auth_models.dart';
import '../../../data/auth/auth_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../stats/domain/seated_aggregate.dart';

part 'inquiry_controller.g.dart';

sealed class InquiryOutcome {
  const InquiryOutcome();
}

class InquirySent extends InquiryOutcome {
  const InquirySent();
}

class InquiryRateLimited extends InquiryOutcome {
  const InquiryRateLimited();
}

class InquiryFailed extends InquiryOutcome {
  const InquiryFailed(this.error);

  final Object error;
}

class InquiryController {
  InquiryController(this._ref, {required this.platform});

  final Ref _ref;
  final String platform;

  static final RegExp emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String s) => emailRe.hasMatch(s.trim());

  Future<String> summaryLine() async {
    final now = _ref.read(appClockProvider).now();
    final today = LocalDate.of(now);
    final sessions = _ref.read(sessionRepositoryProvider);
    final agg = SeatedAggregate.build(
      from: today.addDays(-6),
      to: today,
      segments: await sessions.getSegmentsOverlapping(today.addDays(-6), today),
      sessions: await sessions.getAll(),
    );
    return HelpStrings.summaryLine(
      agg.sessionCount,
      formatDuration(Duration(seconds: agg.totalSeconds)),
      platform,
      AppConfig.appVersion,
    );
  }

  Future<InquiryOutcome> send({required String kind, required String body, String? replyEmail}) async {
    try {
      final text = '${HelpStrings.bodyWithKind(kind, body.trim())}\n\n— ${await summaryLine()}';
      final clipped = text.length > HelpStrings.bodyMaxLength ? text.substring(0, HelpStrings.bodyMaxLength) : text;
      await _ref.read(authBackendProvider).invoke(
        'submit-inquiry',
        body: <String, dynamic>{
          'body': clipped,
          if (replyEmail != null && replyEmail.trim().isNotEmpty) 'reply_email': replyEmail.trim(),
        },
      );
      return const InquirySent();
    } on EdgeFunctionException catch (e) {
      if (e.status == 429 || e.code == 'rate_limited') return const InquiryRateLimited();
      return InquiryFailed(e);
    } on Object catch (e) {
      return InquiryFailed(e);
    }
  }
}

/// keepAlive: `send` reads providers after awaiting the summary.
@Riverpod(keepAlive: true)
InquiryController inquiryController(Ref ref) => InquiryController(ref, platform: AppConfig.platformLabel);
