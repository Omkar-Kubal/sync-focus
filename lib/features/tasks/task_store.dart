import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class FocusTask {
  const FocusTask({
    required this.id,
    required this.title,
    required this.minutes,
    this.tag = 'Focus',
    this.completed = false,
  });

  final String id;
  final String title;
  final int minutes;
  final String tag;
  final bool completed;

  FocusTask copyWith({
    String? title,
    int? minutes,
    String? tag,
    bool? completed,
  }) => FocusTask(
    id: id,
    title: title ?? this.title,
    minutes: minutes ?? this.minutes,
    tag: tag ?? this.tag,
    completed: completed ?? this.completed,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'minutes': minutes,
    'tag': tag,
    'completed': completed,
  };

  factory FocusTask.fromJson(Map<String, dynamic> json) => FocusTask(
    id: json['id'] as String,
    title: json['title'] as String,
    minutes: json['minutes'] as int,
    tag: json['tag'] as String? ?? 'Focus',
    completed: json['completed'] as bool? ?? false,
  );
}

class TaskStore extends ChangeNotifier {
  TaskStore() {
    ready = _read();
  }

  static const int freeActiveLimit = 10;
  static const String _storageKey = 'sync_focus_tasks_v1';
  final List<FocusTask> _tasks = [];
  late final Future<void> ready;
  SharedPreferences? _preferences;

  List<FocusTask> get tasks => List.unmodifiable(_tasks);
  int get activeCount => _tasks.where((task) => !task.completed).length;
  bool get canAdd => activeCount < freeActiveLimit;

  Future<void> _read() async {
    final preferences = await SharedPreferences.getInstance();
    _preferences = preferences;
    final raw = preferences.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _tasks.addAll(
          decoded.map(
            (item) => FocusTask.fromJson(item as Map<String, dynamic>),
          ),
        );
      } on FormatException {
        // A damaged local list should not prevent the Tasks screen opening.
      } on TypeError {
        // Ignore data from an incompatible old shape.
      }
    }
    notifyListeners();
  }

  Future<bool> add(String title, int minutes) async {
    await ready;
    final cleanTitle = title.trim();
    if (!canAdd || cleanTitle.isEmpty || minutes < 5 || minutes > 240) {
      return false;
    }
    _tasks.insert(
      0,
      FocusTask(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: cleanTitle,
        minutes: minutes,
      ),
    );
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> update(FocusTask task, String title, int minutes) async {
    await ready;
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0 || title.trim().isEmpty || minutes < 5 || minutes > 240) {
      return;
    }
    _tasks[index] = _tasks[index].copyWith(
      title: title.trim(),
      minutes: minutes,
    );
    notifyListeners();
    await _save();
  }

  Future<void> toggleCompleted(FocusTask task) async {
    await ready;
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    if (_tasks[index].completed && !canAdd) return;
    _tasks[index] = _tasks[index].copyWith(completed: !_tasks[index].completed);
    notifyListeners();
    await _save();
  }

  Future<void> delete(FocusTask task) async {
    await ready;
    _tasks.removeWhere((item) => item.id == task.id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() => _preferences!.setString(
    _storageKey,
    jsonEncode(_tasks.map((task) => task.toJson()).toList()),
  );
}
