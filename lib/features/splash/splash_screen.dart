import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_logo.dart';
import 'package:syncfocus/features/welcome/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.home});

  final Widget home;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  static const _welcomeSeenKey = 'welcome_screen.seen';
  static const _homeWelcomePendingKey = 'home_welcome_pending';

  Timer? _delay;
  bool _showHome = false;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _delay = Timer(const Duration(seconds: 3), () {
      unawaited(_chooseFirstScreen());
    });
  }

  Future<void> _chooseFirstScreen() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      final hasSeenWelcome = preferences.getBool(_welcomeSeenKey) ?? false;
      setState(() {
        _showWelcome = !hasSeenWelcome;
        _showHome = hasSeenWelcome;
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Sync Focus welcome startup',
          context: ErrorDescription('while reading welcome screen preference'),
        ),
      );
      if (!mounted) return;
      setState(() => _showWelcome = true);
    }
  }

  Future<void> _finishWelcome() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_welcomeSeenKey, true);
      await preferences.setBool(_homeWelcomePendingKey, true);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Sync Focus welcome startup',
          context: ErrorDescription('while saving welcome screen preference'),
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _showWelcome = false;
      _showHome = true;
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) return widget.home;
    if (_showWelcome) {
      return WelcomeScreen(onGetStarted: _finishWelcome);
    }
    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: Center(
        child: const AppLogo(
          key: Key('splash-logo'),
          size: 240,
          semanticLabel: 'Sync Focus',
        ),
      ),
    );
  }
}
