import 'package:syncfocus/features/focus/focus_timer_controller.dart';
import 'package:syncfocus/features/progress/session_store.dart';

/// Bridges one timer completion to one locally persisted focus session.
class FocusSessionRecorder {
  FocusSessionRecorder({required this.timer, required this.store})
    : _lastRevision = timer.completionRevision {
    timer.addListener(_onTimerChanged);
  }

  final FocusTimerController timer;
  final SessionStore store;
  int _lastRevision;
  Future<void> _lastWrite = Future<void>.value();

  Future<void> get lastWrite => _lastWrite;

  void _onTimerChanged() {
    if (timer.phase != FocusTimerPhase.complete ||
        timer.completedAt == null ||
        timer.completionRevision <= _lastRevision) {
      return;
    }
    _lastRevision = timer.completionRevision;
    final title = timer.taskTitle ?? 'Focus session';
    final tag = timer.taskTag;
    final minutes = timer.durationMinutes;
    final completedAt = timer.completedAt!;
    _lastWrite = _lastWrite.then(
      (_) => store.addCompleted(title, minutes, completedAt, tag: tag),
    );
  }

  void dispose() => timer.removeListener(_onTimerChanged);
}
