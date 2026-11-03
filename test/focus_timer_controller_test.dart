import 'package:flutter_test/flutter_test.dart';
import 'package:syncfocus/features/focus/focus_timer_controller.dart';

void main() {
  test(
    'task duration, manual override, countdown, and pause share one timer',
    () {
      var now = DateTime(2026, 11, 1, 12);
      final timer = FocusTimerController(now: () => now);
      addTearDown(timer.dispose);

      timer.assignTaskDuration('Write outline', 45);
      expect(timer.taskTitle, 'Write outline');
      expect(timer.displayTime, '45:00');

      timer.setDurationMinutes(30);
      expect(timer.displayTime, '30:00');
      expect(timer.taskTitle, 'Write outline');

      timer.start();
      now = now.add(const Duration(minutes: 6, seconds: 18));
      timer.refresh();
      expect(timer.displayTime, '23:42');

      timer.pause();
      now = now.add(const Duration(minutes: 1));
      timer.refresh();
      expect(timer.displayTime, '23:42');

      timer.start();
      now = now.add(const Duration(seconds: 2));
      timer.refresh();
      expect(timer.displayTime, '23:40');

      timer.reset();
      expect(timer.displayTime, '30:00');
      expect(timer.phase, FocusTimerPhase.ready);
    },
  );

  test('timer emits one completion event per finished session', () {
    var now = DateTime(2026, 11, 1, 12);
    final timer = FocusTimerController(now: () => now);
    addTearDown(timer.dispose);

    timer.setDurationMinutes(5);
    timer.start();
    timer.pause();
    timer.reset();
    expect(timer.completionRevision, 0);

    timer.start();
    now = now.add(const Duration(minutes: 5));
    timer.refresh();
    expect(timer.phase, FocusTimerPhase.complete);
    expect(timer.completionRevision, 1);
    expect(timer.completedAt, now);
    timer.refresh();
    expect(timer.completionRevision, 1);

    timer.start();
    now = now.add(const Duration(minutes: 6));
    timer.refresh();
    expect(timer.completionRevision, 2);
    expect(timer.completedAt, DateTime(2026, 11, 1, 12, 10));
  });

  test('a completed focus offers a separate break countdown', () {
    var now = DateTime(2026, 11, 1, 12);
    final timer = FocusTimerController(now: () => now);
    addTearDown(timer.dispose);

    timer.setDurationMinutes(5);
    timer.start();
    now = now.add(const Duration(minutes: 5));
    timer.refresh();

    expect(timer.phase, FocusTimerPhase.complete);
    expect(timer.startBreak(breakDurationMinutes: 10), isTrue);
    expect(timer.phase, FocusTimerPhase.breakRunning);
    expect(timer.displayTime, '10:00');
    expect(timer.completionRevision, 1);

    now = now.add(const Duration(minutes: 2, seconds: 15));
    timer.refresh();
    expect(timer.displayTime, '07:45');

    now = now.add(const Duration(minutes: 7, seconds: 45));
    timer.refresh();
    expect(timer.phase, FocusTimerPhase.breakComplete);
    expect(timer.completionRevision, 1);
    expect(timer.durationMinutes, 5);

    timer.start();
    expect(timer.phase, FocusTimerPhase.running);
    expect(timer.displayTime, '05:00');
  });

  test(
    'a paused break resumes and restored breaks keep their own duration',
    () {
      var now = DateTime(2026, 11, 1, 12);
      final timer = FocusTimerController(now: () => now);
      addTearDown(timer.dispose);

      timer.setDurationMinutes(5);
      timer.start();
      now = now.add(const Duration(minutes: 5));
      timer.refresh();
      timer.startBreak(breakDurationMinutes: 12);
      now = now.add(const Duration(minutes: 3));
      timer.refresh();
      timer.pause();

      expect(timer.phase, FocusTimerPhase.breakPaused);
      expect(timer.displayTime, '09:00');

      final restored = FocusTimerController(now: () => now);
      addTearDown(restored.dispose);
      restored.restoreSnapshot(
        durationMinutes: 5,
        breakDurationMinutes: 12,
        remainingSeconds: 9 * 60,
        phase: FocusTimerPhase.breakPaused,
      );
      expect(restored.displayTime, '09:00');
      restored.start();
      now = now.add(const Duration(minutes: 1));
      restored.refresh();
      expect(restored.displayTime, '08:00');
    },
  );
}
