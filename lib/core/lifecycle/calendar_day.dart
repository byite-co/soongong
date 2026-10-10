// CalendarDay (S08b): the local calendar date the screens key their ranges
// on (today column, current week, current month, 지난주 comparison). It is
// re-read from the wall clock (`appClockProvider`) when the app returns to
// the foreground and whenever a visible screen asks (`refresh()` from its
// minute tick — timetable · stats), so a screen left open across midnight
// moves to the new day within a minute. No long-lived timer lives here: a
// provider-owned timer would outlive the screens. This is calendar
// bookkeeping only — elapsed-time measurement keeps D23's monotonic clock.

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/repository_providers.dart';
import '../domain/local_date.dart';

part 'calendar_day.g.dart';

@riverpod
class CalendarDay extends _$CalendarDay {
  @override
  LocalDate build() {
    final observer = _ResumeObserver(refresh);
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
    return LocalDate.of(ref.watch(appClockProvider).now());
  }

  /// Re-reads the clock; emits only when the local date changed.
  void refresh() {
    final today = LocalDate.of(ref.read(appClockProvider).now());
    if (today != state) state = today;
  }
}

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
