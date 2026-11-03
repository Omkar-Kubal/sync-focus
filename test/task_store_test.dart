import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/tasks/task_store.dart';

void main() {
  test('tasks persist and completing one frees a Free task slot', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TaskStore();
    await store.ready;

    for (var i = 0; i < TaskStore.freeActiveLimit; i++) {
      expect(await store.add('Task $i', 25), isTrue);
    }
    expect(await store.add('One too many', 25), isFalse);

    await store.toggleCompleted(store.tasks.first);
    expect(await store.add('Now there is room', 45), isTrue);

    final reloaded = TaskStore();
    await reloaded.ready;
    expect(reloaded.tasks.length, 11);
    expect(reloaded.activeCount, 10);
    expect(reloaded.tasks.first.title, 'Now there is room');
    expect(reloaded.tasks.first.minutes, 45);
    expect(reloaded.tasks.first.tag, 'Focus');
    store.dispose();
    reloaded.dispose();
  });
}
