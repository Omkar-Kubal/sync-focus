import 'dart:async';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfocus/firebase_options.dart';

class CrashReporter {
  const CrashReporter._();

  static bool _isInitialized = false;

  static bool get isEnabled => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    _isInitialized = true;
  }

  static Future<void> runAppGuarded(FutureOr<void> Function() appRunner) async {
    await runZonedGuarded<Future<void>>(
      () async {
        try {
          await initialize();
        } on Object catch (error, stackTrace) {
          if (kDebugMode) {
            debugPrint('Firebase initialization failed: $error\n$stackTrace');
          }
        }

        _installGlobalHandlers();
        await appRunner();
      },
      (error, stackTrace) {
        unawaited(_recordFatalError(error, stackTrace));
      },
    );
  }

  static void _installGlobalHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(_recordFlutterError(details));
    };

    ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(_recordFatalError(error, stackTrace));
      return true;
    };
  }

  static Future<void> _recordFlutterError(FlutterErrorDetails details) async {
    if (!isEnabled) return;
    try {
      await FirebaseCrashlytics.instance.recordFlutterError(details);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Crashlytics Flutter report failed: $error\n$stackTrace');
      }
    }
  }

  static Future<void> _recordFatalError(
    Object error,
    StackTrace stackTrace,
  ) async {
    if (kDebugMode) debugPrint('Uncaught application error: $error');
    await _recordError(
      error,
      stackTrace,
      'Uncaught application error',
      fatal: true,
    );
  }

  static Future<void> recordError(
    Object error, [
    StackTrace? stackTrace,
    String? hint,
  ]) => _recordError(error, stackTrace, hint, fatal: false);

  static Future<void> _recordError(
    Object error,
    StackTrace? stackTrace,
    String? hint, {
    required bool fatal,
  }) async {
    if (kDebugMode) {
      debugPrint('CrashReporter: $error');
      if (hint != null) debugPrint('CrashReporter hint: $hint');
    }

    if (!isEnabled) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: hint,
        fatal: fatal,
      );
    } on Object catch (reportingError, reportingStackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Crashlytics error report failed: $reportingError\n'
          '$reportingStackTrace',
        );
      }
    }
  }
}
