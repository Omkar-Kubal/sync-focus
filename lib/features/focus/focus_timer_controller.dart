import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

enum FocusTimerPhase {
  ready,
  running,
  paused,
  complete,
  breakRunning,
  breakPaused,
  breakComplete,
}

/// UI timer state. A future task screen can preload [assignTaskDuration].
/// Android mirrors active timer state in its foreground service while the app
/// is backgrounded.
class FocusTimerController extends ChangeNotifier {
  FocusTimerController({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  Timer? _ticker;
  DateTime? _deadline;
  int _durationMinutes = 25;
  int _breakDurationMinutes = 5;
  int _remainingSeconds = 25 * 60;
  FocusTimerPhase _phase = FocusTimerPhase.ready;
  String? _taskTitle;
  String _taskTag = 'Focus';
  int _completionRevision = 0;
  DateTime? _completedAt;

  int get durationMinutes => _durationMinutes;
  int get breakDurationMinutes => _breakDurationMinutes;
  int get remainingSeconds => _remainingSeconds;
  FocusTimerPhase get phase => _phase;
  String? get taskTitle => _taskTitle;
  String get taskTag => _taskTag;
  int get completionRevision => _completionRevision;
  DateTime? get completedAt => _completedAt;
  int? get deadlineEpochMilliseconds => _deadline?.millisecondsSinceEpoch;
  bool get canEditDuration =>
      _phase == FocusTimerPhase.ready ||
      _phase == FocusTimerPhase.complete ||
      _phase == FocusTimerPhase.breakComplete;
  bool get isBreakPhase => switch (_phase) {
    FocusTimerPhase.breakRunning ||
    FocusTimerPhase.breakPaused ||
    FocusTimerPhase.breakComplete => true,
    _ => false,
  };
  int get currentDurationSeconds =>
      isBreakPhase ? _breakDurationMinutes * 60 : _durationMinutes * 60;
  double get remainingFraction => _remainingSeconds / currentDurationSeconds;

  String get displayTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void setDurationMinutes(int minutes) {
    if (!canEditDuration) return;
    _durationMinutes = minutes.clamp(5, 240).toInt();
    _remainingSeconds = _durationMinutes * 60;
    _phase = FocusTimerPhase.ready;
    _completedAt = null;
    notifyListeners();
  }

  void assignTaskDuration(String title, int minutes, {String tag = 'Focus'}) {
    if (!canEditDuration) return;
    _taskTitle = title;
    _taskTag = tag;
    setDurationMinutes(minutes);
  }

  void start() {
    if (_phase == FocusTimerPhase.running ||
        _phase == FocusTimerPhase.breakRunning) {
      return;
    }
    if (_phase == FocusTimerPhase.complete ||
        _phase == FocusTimerPhase.breakComplete) {
      _remainingSeconds = _durationMinutes * 60;
      _phase = FocusTimerPhase.ready;
    }
    _deadline = _now().add(Duration(seconds: _remainingSeconds));
    _phase = isBreakPhase
        ? FocusTimerPhase.breakRunning
        : FocusTimerPhase.running;
    _completedAt = null;
    _startTicker();
    notifyListeners();
  }

  /// Starts the selected break only after a completed focus session.
  bool startBreak({required int breakDurationMinutes}) {
    if (_phase != FocusTimerPhase.complete) return false;
    _breakDurationMinutes = breakDurationMinutes.clamp(1, 60).toInt();
    _remainingSeconds = _breakDurationMinutes * 60;
    _deadline = _now().add(Duration(seconds: _remainingSeconds));
    _phase = FocusTimerPhase.breakRunning;
    _completedAt = null;
    _startTicker();
    notifyListeners();
    return true;
  }

  /// Restores a previously saved timer snapshot from the Android widget store.
  ///
  /// A running timer is reconciled against its wall-clock deadline so the
  /// displayed time stays correct when Android recreates the app process.
  void restoreSnapshot({
    required int durationMinutes,
    required int remainingSeconds,
    required FocusTimerPhase phase,
    int breakDurationMinutes = 5,
    int? deadlineEpochMilliseconds,
    String? taskTitle,
    String taskTag = 'Focus',
  }) {
    _ticker?.cancel();
    _ticker = null;
    _durationMinutes = durationMinutes.clamp(5, 240).toInt();
    _breakDurationMinutes = breakDurationMinutes.clamp(1, 60).toInt();
    _taskTitle = taskTitle;
    _taskTag = taskTag;
    final phaseDurationSeconds = switch (phase) {
      FocusTimerPhase.breakRunning ||
      FocusTimerPhase.breakPaused ||
      FocusTimerPhase.breakComplete => _breakDurationMinutes * 60,
      _ => _durationMinutes * 60,
    };
    _remainingSeconds = remainingSeconds.clamp(0, phaseDurationSeconds).toInt();
    _phase = phase;
    _deadline = null;
    _completedAt = null;

    if (phase == FocusTimerPhase.running ||
        phase == FocusTimerPhase.breakRunning) {
      _deadline = deadlineEpochMilliseconds == null
          ? _now().add(Duration(seconds: _remainingSeconds))
          : DateTime.fromMillisecondsSinceEpoch(deadlineEpochMilliseconds);
      final milliseconds = _deadline!.difference(_now()).inMilliseconds;
      _remainingSeconds = math.max(0, (milliseconds / 1000).ceil());
      if (_remainingSeconds == 0) {
        final wasBreak = _phase == FocusTimerPhase.breakRunning;
        _phase = wasBreak
            ? FocusTimerPhase.breakComplete
            : FocusTimerPhase.complete;
        _completedAt = wasBreak ? null : _deadline;
        _deadline = null;
        if (!wasBreak) _completionRevision++;
      } else {
        _startTicker();
      }
    }

    notifyListeners();
  }

  void pause() {
    if (_phase != FocusTimerPhase.running &&
        _phase != FocusTimerPhase.breakRunning) {
      return;
    }
    final wasBreak = _phase == FocusTimerPhase.breakRunning;
    refresh();
    if (_phase != FocusTimerPhase.running &&
        _phase != FocusTimerPhase.breakRunning) {
      return;
    }
    _ticker?.cancel();
    _deadline = null;
    _phase = wasBreak ? FocusTimerPhase.breakPaused : FocusTimerPhase.paused;
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _deadline = null;
    _remainingSeconds = _durationMinutes * 60;
    _phase = FocusTimerPhase.ready;
    _completedAt = null;
    notifyListeners();
  }

  /// Reconcile elapsed wall time after a frame, app resume, or ticker event.
  void refresh() {
    if ((_phase != FocusTimerPhase.running &&
            _phase != FocusTimerPhase.breakRunning) ||
        _deadline == null) {
      return;
    }
    final milliseconds = _deadline!.difference(_now()).inMilliseconds;
    final next = math.max(0, (milliseconds / 1000).ceil());
    if (next == _remainingSeconds) return;
    _remainingSeconds = next;
    if (next == 0) {
      final wasBreak = _phase == FocusTimerPhase.breakRunning;
      _ticker?.cancel();
      _completedAt = wasBreak ? null : _deadline;
      _deadline = null;
      _phase = wasBreak
          ? FocusTimerPhase.breakComplete
          : FocusTimerPhase.complete;
      if (!wasBreak) _completionRevision++;
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => refresh(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
