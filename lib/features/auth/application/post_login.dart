// PostLoginRoutine (S05, PRD 4.3c): after an existing account signs in and
// its onboarding is done — pull the account's records (`SyncEngine.pull(0)`,
// Fake until S13), refresh the entitlement (`BillingGateway.refresh`, Fake
// until S12), run the deferred startup writes, and queue ONE factual toast
// line for the home screen. Failures are logged, never shown as errors here.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/contracts/providers.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/strings/auth_strings.dart';
import '../../../data/repositories/repositories.dart';

part 'post_login.g.dart';

/// One-shot message the next screen shows as a toast (home reads it once).
@Riverpod(keepAlive: true)
class PendingToast extends _$PendingToast {
  @override
  String? build() => null;

  void set(String message) => state = message;

  String? take() {
    final m = state;
    state = null;
    return m;
  }
}

class PostLoginSummary {
  const PostLoginSummary({required this.sessions, required this.wrongs});

  final int sessions;
  final int wrongs;
}

class PostLoginRoutine {
  PostLoginRoutine(this._ref);

  final Ref _ref;

  Future<PostLoginSummary> run() async {
    try {
      await _ref.read(syncEngineProvider).pull(sinceSeq: 0);
    } on Object catch (e, st) {
      appLog.w('post-login: pull failed', error: e, stackTrace: st);
    }
    try {
      await _ref.read(billingGatewayProvider).refresh();
    } on Object catch (e, st) {
      appLog.w('post-login: billing refresh failed', error: e, stackTrace: st);
    }
    try {
      await _ref.read(deleteSettlerProvider).settle();
      final today = LocalDate.of(_ref.read(appClockProvider).now());
      await _ref.read(activityRepositoryProvider).touch(today);
    } on Object catch (e, st) {
      appLog.w('post-login: startup writes failed', error: e, stackTrace: st);
    }
    var sessions = 0;
    var wrongs = 0;
    try {
      sessions = (await _ref.read(sessionRepositoryProvider).getAll()).length;
      wrongs = (await _ref.read(wrongsRepositoryProvider).getAll()).length;
    } on Object catch (e, st) {
      appLog.w('post-login: counts failed', error: e, stackTrace: st);
    }
    final summary = PostLoginSummary(sessions: sessions, wrongs: wrongs);
    _ref.read(pendingToastProvider.notifier).set(AuthStrings.loadedSummary(sessions, wrongs));
    appLog.i('post-login: sessions=$sessions wrongs=$wrongs');
    return summary;
  }
}

@Riverpod(keepAlive: true)
PostLoginRoutine postLoginRoutine(Ref ref) => PostLoginRoutine(ref);
