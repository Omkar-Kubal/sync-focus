import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/progress/session_store.dart';

void main() {
  test('weekly summary totals the current Monday to Sunday and streak', () {
    final now = DateTime(2026, 11, 1, 12);
    final sessions = <FocusSession>[
      for (final (day, minutes) in [
        (26, 25),
        (27, 50),
        (29, 75),
        (30, 40),
        (31, 90),
      ])
        FocusSession(
          id: '$day',
          title: 'Day $day',
          durationMinutes: minutes,
          completedAt: DateTime(2026, 10, day, 12),
        ),
      FocusSession(
        id: 'sunday',
        title: 'Write project outline',
        durationMinutes: 45,
        completedAt: DateTime(2026, 11, 1, 11),
      ),
    ];

    final summary = ProgressSummary.fromSessions(sessions, now);
    expect(summary.weekStart, DateTime(2026, 10, 26));
    expect(summary.dailyMinutes, [25, 50, 0, 75, 40, 90, 45]);
    expect(summary.weeklyTotalMinutes, 325);
    expect(summary.currentStreakDays, 4);
    expect(summary.recent.first.title, 'Write project outline');
    expect(summary.recent.length, 5);
  });

  test('streak survives a quiet today and week crosses the year', () {
    final now = DateTime(2027, 1, 1, 9);
    final summary = ProgressSummary.fromSessions([
      FocusSession(
        id: 'last-year',
        title: 'Review notes',
        durationMinutes: 30,
        completedAt: DateTime(2026, 12, 31, 20),
      ),
    ], now);

    expect(summary.weekStart, DateTime(2026, 12, 28));
    expect(summary.weeklyTotalMinutes, 30);
    expect(summary.dailyMinutes, [0, 0, 0, 30, 0, 0, 0]);
    expect(summary.currentStreakDays, 1);
  });

  test('completed sessions persist locally and reload newest first', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SessionStore();
    await store.ready;
    await store.addCompleted('Review notes', 25, DateTime(2026, 10, 31, 9));
    await store.addCompleted('Write outline', 45, DateTime(2026, 11, 1, 10));

    final reloaded = SessionStore();
    await reloaded.ready;
    expect(reloaded.sessions.length, 2);
    expect(reloaded.sessions.first.title, 'Write outline');
    expect(reloaded.sessions.first.durationMinutes, 45);
    store.dispose();
    reloaded.dispose();
  });

  test(
    'a session write finishes safely after the screen store is disposed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SessionStore();
      await store.ready;
      final write = store.addCompleted(
        'Focus session',
        5,
        DateTime(2026, 11, 1),
      );
      store.dispose();
      await write;

      final reloaded = SessionStore();
      await reloaded.ready;
      expect(reloaded.sessions.single.durationMinutes, 5);
      reloaded.dispose();
    },
  );
}
