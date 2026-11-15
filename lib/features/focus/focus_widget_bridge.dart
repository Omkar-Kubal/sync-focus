import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/focus/focus_timer_controller.dart';
import 'package:syncfocus/features/settings/settings_controller.dart';

/// Synchronizes the Flutter timer with Android home-screen widgets.
class FocusWidgetBridge {
  FocusWidgetBridge({
    required this.timer,
    required this.settings,
    required this.proBilling,
    required this.onOpenFocus,
  });

  static const MethodChannel _channel = MethodChannel(
    'com.focusfirst/widgets',
  );

  final FocusTimerController timer;
  final SettingsController settings;
  final ProBillingController proBilling;
  final VoidCallback onOpenFocus;
  String? _lastSentFingerprint;
  String? _lastSentPhase;
  Timer? _pendingSync;
  Map<String, Object?>? _pendingSnapshot;
  String? _pendingFingerprint;
  bool _initialized = false;
  bool _disposed = false;

  Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleNativeCall);
    await refreshSnapshot();

    if (_disposed) return;
    _initialized = true;
    timer.addListener(_syncTimer);
    settings.addListener(_syncTimer);
    proBilling.addListener(_syncTimer);
    _syncTimer(force: true);
    await _consumePendingAction();
  }

  /// Reconciles Flutter with Android after a notification action, process
  /// recreation, or device reboot.
  Future<void> refreshSnapshot() async {
    try {
      final snapshot = await _channel.invokeMapMethod<String, Object?>(
        'getTimerSnapshot',
      );
      if (!_disposed && snapshot != null) _restore(snapshot);
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      debugPrint('Widget timer restore failed: ${error.message}');
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'widgetActionPending') {
      await _consumePendingAction();
    } else if (call.method == 'timerSnapshotChanged') {
      final rawSnapshot = call.arguments;
      if (rawSnapshot is Map) {
        _restore(
          rawSnapshot.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }
  }

  Future<void> _consumePendingAction() async {
    try {
      final action = await _channel.invokeMethod<String>(
        'consumePendingAction',
      );
      if (_disposed) return;
      if (action == 'open' || action == 'toggle') onOpenFocus();
      if (action == 'toggle') _toggleTimer();
    } on MissingPluginException {
      // iOS and non-Android previews do not provide the widget channel.
    } on PlatformException catch (error) {
      debugPrint('Widget timer action failed: ${error.message}');
    }
  }

  Future<void> consumePendingAction() => _consumePendingAction();

  void _toggleTimer() {
    if (_disposed) return;
    if (timer.phase == FocusTimerPhase.running ||
        timer.phase == FocusTimerPhase.breakRunning) {
      timer.pause();
    } else {
      timer.start();
    }
  }

  void _restore(Map<String, Object?> snapshot) {
    final phaseName = snapshot['phase'] as String?;
    final phase = FocusTimerPhase.values.firstWhere(
      (value) => value.name == phaseName,
      orElse: () => FocusTimerPhase.ready,
    );
    final durationSeconds = (snapshot['durationSeconds'] as num?)?.toInt();
    final remainingSeconds = (snapshot['remainingSeconds'] as num?)?.toInt();
    if (durationSeconds == null || remainingSeconds == null) return;

    timer.restoreSnapshot(
      durationMinutes:
          (snapshot['focusDurationMinutes'] as num?)?.toInt() ??
          (durationSeconds / 60).round(),
      remainingSeconds: remainingSeconds,
      phase: phase,
      breakDurationMinutes:
          ((snapshot['breakDurationSeconds'] as num?)?.toInt() ?? 5 * 60) ~/ 60,
      deadlineEpochMilliseconds: (snapshot['deadlineEpochMilliseconds'] as num?)
          ?.toInt(),
      taskTitle: snapshot['taskTitle'] as String?,
      taskTag: snapshot['taskTag'] as String? ?? 'Focus',
    );
  }

  Map<String, Object?> _snapshot() => {
    'phase': timer.phase.name,
    'durationSeconds': timer.currentDurationSeconds,
    'focusDurationMinutes': timer.durationMinutes,
    'breakDurationSeconds': settings.breakDurationMinutes * 60,
    'remainingSeconds': timer.remainingSeconds,
    'deadlineEpochMilliseconds': timer.deadlineEpochMilliseconds,
    'taskTitle': timer.taskTitle,
    'taskTag': timer.taskTag,
    'autoDndEnabled': settings.isDndEnabled && proBilling.isPro,
    'focusGuardEnabled': settings.isFocusGuardEnabled && proBilling.isPro,
    'blockedApps': settings.blockedApps.toList()..sort(),
    'ambientSound': settings.ambientSound.name,
  };

  void _syncTimer({bool force = false}) {
    if (!_initialized || _disposed) return;
    final snapshot = _snapshot();
    final remainingBucket =
        timer.phase == FocusTimerPhase.running ||
            timer.phase == FocusTimerPhase.breakRunning
        ? timer.remainingSeconds ~/ 60
        : timer.remainingSeconds;
    final fingerprint = [
      snapshot['phase'],
      snapshot['durationSeconds'],
      remainingBucket,
      snapshot['deadlineEpochMilliseconds'],
      snapshot['taskTitle'],
      snapshot['taskTag'],
      snapshot['breakDurationSeconds'],
      snapshot['autoDndEnabled'],
      snapshot['focusGuardEnabled'],
      (snapshot['blockedApps'] as List<String>).join(','),
      snapshot['ambientSound'],
    ].join('|');
    if (!force && fingerprint == _lastSentFingerprint) {
      _pendingSync?.cancel();
      _pendingSync = null;
      _pendingSnapshot = null;
      _pendingFingerprint = null;
      return;
    }

    final phaseChanged = snapshot['phase'] != _lastSentPhase;
    if (!force && !phaseChanged) {
      _pendingSnapshot = snapshot;
      _pendingFingerprint = fingerprint;
      _pendingSync?.cancel();
      _pendingSync = Timer(
        const Duration(milliseconds: 250),
        _flushPendingSync,
      );
      return;
    }
    _sendSnapshot(snapshot, fingerprint);
  }

  void _flushPendingSync() {
    final snapshot = _pendingSnapshot;
    final fingerprint = _pendingFingerprint;
    _pendingSnapshot = null;
    _pendingFingerprint = null;
    if (snapshot != null && fingerprint != null) {
      _sendSnapshot(snapshot, fingerprint);
    }
  }

  void _sendSnapshot(Map<String, Object?> snapshot, String fingerprint) {
    _pendingSync?.cancel();
    _pendingSync = null;
    _pendingSnapshot = null;
    _pendingFingerprint = null;
    _lastSentFingerprint = fingerprint;
    _lastSentPhase = snapshot['phase'] as String?;

    unawaited(
      _channel.invokeMethod<void>('updateTimerSnapshot', snapshot).catchError((
        Object error,
      ) {
        if (error is! MissingPluginException && error is! PlatformException) {
          debugPrint('Widget timer sync failed: $error');
        }
      }),
    );
  }

  void dispose() {
    _disposed = true;
    _pendingSync?.cancel();
    timer.removeListener(_syncTimer);
    settings.removeListener(_syncTimer);
    proBilling.removeListener(_syncTimer);
    _channel.setMethodCallHandler(null);
  }
}
