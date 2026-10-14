import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../strings/common_strings.dart';
import 'app_theme.dart';

/// Shared by startup and the routed app; no database/auth/settings providers.
abstract final class AppPresentation {
  static const locale = Locale('ko');
  static const supportedLocales = <Locale>[Locale('ko'), Locale('en')];
  static const delegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

class StartupApp extends StatelessWidget {
  const StartupApp({super.key, required this.home});
  final Widget home;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: CommonStrings.appName,
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(Brightness.light),
    darkTheme: buildAppTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    themeAnimationDuration: Duration.zero,
    locale: AppPresentation.locale,
    supportedLocales: AppPresentation.supportedLocales,
    localizationsDelegates: AppPresentation.delegates,
    home: home,
  );
}
