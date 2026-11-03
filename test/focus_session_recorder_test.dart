import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/focus/focus_timer_controller.dart';
import 'package:syncfocus/features/progress/focus_session_recorder.dart';
import 'package:syncfocus/features/progress/session_store.dart';

void main() {
  test(
    'records a completed task once and skips paused or reset sessions',
    () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 11, 1, 12);
      final timer = FocusTimerController(now: () => now);
      final store = SessionStore();
      await store.ready;
      final recorder = FocusSessionRecorder(timer: timer, store: store);
      addTearDown(() {
        recorder.dispose();
        timer.dispose();
        store.dispose();
      });

      timer.assignTaskDuration('Write outline', 5);
      timer.start();
      timer.pause();
      timer.reset();
      expect(store.sessions, isEmpty);

      timer.start();
      now = now.add(const Duration(minutes: 5));
      timer.refresh();
      await recorder.lastWrite;
      expect(store.sessions.length, 1);
      expect(store.sessions.single.title, 'Write outline');
      expect(store.sessions.single.durationMinutes, 5);

      timer.start();
      now = now.add(const Duration(minutes: 5));
      timer.refresh();
      await recorder.lastWrite;
      expect(store.sessions.length, 2);

      timer.refresh();
      await recorder.lastWrite;
      expect(store.sessions.length, 2);
    },
  );
}
