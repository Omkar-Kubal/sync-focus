import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/focus/focus_home_screen.dart';
import 'package:syncfocus/features/settings/settings_controller.dart';
import 'package:syncfocus/features/splash/splash_screen.dart';
import 'package:syncfocus/theme/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SettingsController _settings;
  late final ProBillingController _proBilling;

  @override
  void initState() {
    super.initState();
    _settings = SettingsController();
    unawaited(_settings.load());
    _proBilling = ProBillingController();
    unawaited(_proBilling.load());
  }

  @override
  void dispose() {
    _settings.dispose();
    _proBilling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_settings, _proBilling]),
    builder: (context, _) => MaterialApp(
      title: 'Sync Focus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: _settings.isAmoledBlack && _proBilling.isPro
          ? AppTheme.amoledBlack
          : AppTheme.dark,
      themeMode: _settings.isLightMode ? ThemeMode.light : ThemeMode.dark,
      home: SplashGate(
        home: FocusHomeShell(settings: _settings, proBilling: _proBilling),
      ),
    ),
  );
}
