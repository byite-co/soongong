// Root widget (S01): MaterialApp.router with light/dark themes, Korean
// localizations and the dev-menu gate.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/dev/dev_menu.dart';
import 'core/lifecycle/foreground_activity_hook.dart';
import 'core/router/app_router.dart';
import 'core/strings/common_strings.dart';
import 'core/theme/app_theme.dart';

class SoongongApp extends ConsumerWidget {
  const SoongongApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: CommonStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: const Locale('ko'),
      supportedLocales: const <Locale>[Locale('ko'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => DevMenuGate(
        navigatorKey: rootNavigatorKey,
        child: ForegroundActivityHook(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
