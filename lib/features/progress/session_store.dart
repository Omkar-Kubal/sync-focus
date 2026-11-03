import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class FocusSession {
  const FocusSession({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.completedAt,
    this.tag = 'Focus',
  });

  final String id;
  final String title;
  final int durationMinutes;
  final DateTime completedAt;
  final String tag;

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'durationMinutes': durationMinutes,
    'completedAt': completedAt.toIso8601String(),
    'tag': tag,
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'] as String,
    title: json['title'] as String,
    durationMinutes: json['durationMinutes'] as int,
    completedAt: DateTime.parse(json['completedAt'] as String),
    tag: json['tag'] as String? ?? 'Focus',
  );
}

class ProgressSummary {
  const ProgressSummary({
    required this.weekStart,
    required this.dailyMinutes,
    required this.weeklyTotalMinutes,
    required this.currentStreakDays,
    required this.recent,
  });

  final DateTime weekStart;
  final List<int> dailyMinutes;
  final int weeklyTotalMinutes;
  final int currentStreakDays;
  final List<FocusSession> recent;

  factory ProgressSummary.fromSessions(
    Iterable<FocusSession> sessions,
    DateTime now,
  ) {
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final startDay = _calendarDay(weekStart);
    final today = _calendarDay(now);
    final daily = List<int>.filled(7, 0);
    final activeDays = <int>{};
    final sorted = sessions.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    for (final session in sorted) {
      final day = _calendarDay(session.completedAt);
      if (day <= today && session.durationMinutes > 0) activeDays.add(day);
      final index = day - startDay;
      if (index >= 0 && index < 7 && day <= today) {
        daily[index] += session.durationMinutes;
      }
    }

    var streakDay = activeDays.contains(today) ? today : today - 1;
    var streak = 0;
    while (activeDays.contains(streakDay)) {
      streak++;
      streakDay--;
    }

    return ProgressSummary(
      weekStart: weekStart,
      dailyMinutes: List.unmodifiable(daily),
      weeklyTotalMinutes: daily.fold(0, (sum, minutes) => sum + minutes),
      currentStreakDays: streak,
      recent: List.unmodifiable(sorted.take(5)),
    );
  }

  static int _calendarDay(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

class SessionStore extends ChangeNotifier {
  SessionStore() {
    ready = _read();
  }

  static const String _storageKey = 'sync_focus_sessions_v1';
  final List<FocusSession> _sessions = [];
  late final Future<void> ready;
  SharedPreferences? _preferences;
  bool _disposed = false;

  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  Future<void> _read() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    final raw = preferences.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _sessions.addAll(
          decoded.map(
            (item) => FocusSession.fromJson(item as Map<String, dynamic>),
          ),
        );
        _sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      } on FormatException {
        // Keep the Progress page usable if local data is damaged.
      } on TypeError {
        // Ignore an incompatible old local shape.
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> addCompleted(
    String title,
    int durationMinutes,
    DateTime completedAt, {
    String tag = 'Focus',
  }) async {
    await ready;
    if (durationMinutes <= 0) return;
    _sessions.insert(
      0,
      FocusSession(
        id: '${completedAt.microsecondsSinceEpoch}-${_sessions.length}',
        title: title.trim().isEmpty ? 'Focus session' : title.trim(),
        durationMinutes: durationMinutes,
        completedAt: completedAt,
        tag: tag.trim().isEmpty ? 'Focus' : tag.trim(),
      ),
    );
    _sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    if (!_disposed) notifyListeners();
    await _preferences!.setString(
      _storageKey,
      jsonEncode(_sessions.map((session) => session.toJson()).toList()),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
