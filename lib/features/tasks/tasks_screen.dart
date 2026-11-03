import 'package:flutter/material.dart';
import 'package:syncfocus/features/tasks/task_editor_sheet.dart';
import 'package:syncfocus/features/tasks/task_store.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_typography.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.store, required this.onFocus});

  final TaskStore store;
  final ValueChanged<FocusTask> onFocus;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final tasks = store.tasks;
      final active = tasks.where((task) => !task.completed).toList();
      final completed = tasks.where((task) => task.completed).toList();
      return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 12),
              children: [
                Text(
                  'Tasks',
                  style: AppTypography.heroMetric.copyWith(
                    color: context.palette.ink,
                    fontSize: 40,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose what gets your next focus session',
                  style: AppTypography.body.copyWith(
                    color: context.palette.body,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: active.isEmpty ? 48 : 20),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        AppIcon(
                          icon: AppIcons.tasks,
                          size: 36,
                          color: context.palette.mutedSoft,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A clear space for what matters',
                          style: AppTypography.cardTitle.copyWith(
                            color: context.palette.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add a task and give it focus time.',
                          style: AppTypography.body.copyWith(
                            color: context.palette.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (var i = 0; i < active.length; i++) ...[
                  _TaskRow(
                    task: active[i],
                    onToggle: () => store.toggleCompleted(active[i]),
                    onEdit: () => _showTaskEditor(context, store, active[i]),
                    onFocus: () => onFocus(active[i]),
                  ),
                  if (i != active.length - 1)
                    Divider(height: 1, color: context.palette.hairline),
                ],
                if (completed.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Completed',
                    style: AppTypography.cardTitle.copyWith(
                      color: context.palette.body,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final task in completed)
                    _TaskRow(
                      task: task,
                      onToggle: () => store.toggleCompleted(task),
                      onEdit: () => _showTaskEditor(context, store, task),
                      onFocus: () => onFocus(task),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  if (store.canAdd) {
                    _showTaskEditor(context, store, null);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Complete a task to make room for another.',
                        ),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: context.palette.onPrimary,
                  shape: const StadiumBorder(),
                ),
                icon: AppIcon(
                  icon: AppIcons.add,
                  size: 23,
                  color: context.palette.onPrimary,
                ),
                label: Text(
                  'Add task',
                  style: AppTypography.cardTitle.copyWith(
                    color: context.palette.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onFocus,
  });

  final FocusTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 86,
    child: Row(
      children: [
        Semantics(
          label: task.completed
              ? 'Mark ${task.title} incomplete'
              : 'Complete ${task.title}',
          button: true,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 44,
              height: 48,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.completed
                        ? context.palette.ink
                        : context.palette.canvas,
                    border: Border.all(
                      color: task.completed
                          ? context.palette.ink
                          : context.palette.mutedSoft,
                      width: 1.5,
                    ),
                  ),
                  child: task.completed
                      ? Center(
                          child: AppIcon(
                            icon: AppIcons.confirm,
                            size: 17,
                            color: context.palette.onPrimary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle.copyWith(
                    color: task.completed
                        ? context.palette.muted
                        : context.palette.ink,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${task.minutes} min',
                  style: AppTypography.body.copyWith(
                    color: context.palette.body,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!task.completed) ...[
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: FilledButton.icon(
              onPressed: onFocus,
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.gradientSkyLight,
                foregroundColor: context.palette.ink,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: const StadiumBorder(),
              ),
              icon: AppIcon(
                icon: AppIcons.play,
                size: 17,
                color: context.palette.ink,
              ),
              label: Text(
                'Focus',
                style: AppTypography.rowTitle.copyWith(
                  color: context.palette.ink,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Future<void> _showTaskEditor(
  BuildContext context,
  TaskStore store,
  FocusTask? task,
) async {
  final result = await showModalBottomSheet<TaskEditResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.canvas,
    barrierColor: context.palette.primary.withValues(alpha: 0.54),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => TaskEditorSheet(task: task),
  );
  if (result == null || !context.mounted) return;
  if (result.delete && task != null) {
    await store.delete(task);
  } else if (task == null) {
    await store.add(result.title, result.minutes);
  } else {
    await store.update(task, result.title, result.minutes);
  }
}
