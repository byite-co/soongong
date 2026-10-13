import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// Owned DB transactions and stream notifications can schedule fake-zone timers.
// Awaiting after a fixed number of pumps can leave those timers idle forever.
// Keep pumping until this exact future completes, with a named finite bound.
Future<T> completeWidgetFuture<T>(
  WidgetTester tester,
  Future<T> pending,
  String stage,
) async {
  var done = false;
  late T value;
  Object? failure;
  StackTrace? trace;
  unawaited(
    pending.then<void>(
      (result) {
        value = result;
        done = true;
      },
      onError: (Object error, StackTrace stack) {
        failure = error;
        trace = stack;
        done = true;
      },
    ),
  );
  for (var i = 0; i < 500 && !done; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(done, isTrue, reason: '$stage completes within 5 seconds of pumping');
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
  return value;
}
