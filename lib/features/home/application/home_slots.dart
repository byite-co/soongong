// Home card slots (S05): other lanes inject a card without touching the home
// screen — override the provider in `bootstrap()` or replace its body.
//   readingCardSlot       S10 · userflow `hbReading` `hbDone` (top of home)
//   subscriptionCardSlot  S12 · `s14` premium card · `roHome` read-only card
//   recoverySlot          S06 · optional card below the todo list
// null = not rendered.

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_slots.g.dart';

typedef HomeCardBuilder = Widget Function(BuildContext context);

@Riverpod(keepAlive: true)
HomeCardBuilder? readingCardSlot(Ref ref) => null;

@Riverpod(keepAlive: true)
HomeCardBuilder? subscriptionCardSlot(Ref ref) => null;

@Riverpod(keepAlive: true)
HomeCardBuilder? recoverySlot(Ref ref) => null;
