import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfocus/features/tasks/task_store.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_typography.dart';

class TaskEditResult {
  const TaskEditResult(this.title, this.minutes, {this.delete = false});

  final String title;
  final int minutes;
  final bool delete;
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.task});

  final FocusTask? task;

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  late final TextEditingController _title;
  late int _minutes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _minutes = widget.task?.minutes ?? 25;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _stepTime(int delta) => setState(() {
    _minutes = (_minutes + delta).clamp(5, 240);
    _error = null;
  });

  Future<void> _editExactTime() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _ExactTaskTimeDialog(initialMinutes: _minutes),
    );
    if (result != null && mounted) {
      setState(() {
        _minutes = result;
        _error = null;
      });
    }
  }

  void _save() {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Enter a task name.');
      return;
    }
    Navigator.of(context).pop(TaskEditResult(_title.text.trim(), _minutes));
  }

  Future<void> _showCustomTagInfo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Custom tags are a Pro feature'),
        content: const Text(
          'Create and manage your own tags with Sync Focus Pro. '
          'Subscriptions are not available yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = math.min(screenHeight * 0.59, 620.0);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SizedBox(
        key: const Key('task-editor-sheet'),
        height: sheetHeight,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: context.palette.mutedSoft,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.task == null ? 'Add task' : 'Edit task',
                            style: AppTypography.heroMetric.copyWith(
                              color: context.palette.ink,
                              fontSize: 28,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (widget.task != null)
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pop(const TaskEditResult('', 0, delete: true)),
                            child: const Text('Delete'),
                          ),
                        IconButton(
                          tooltip: 'Close task sheet',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: AppIcon(
                            icon: AppIcons.close,
                            size: 26,
                            color: context.palette.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Task name', style: _labelStyle(context)),
                    TextField(
                      key: const Key('task-title-input'),
                      controller: _title,
                      maxLength: 80,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTypography.bodyTitle.copyWith(
                        color: context.palette.ink,
                        fontSize: 19,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write project outline',
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: context.palette.body),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: context.palette.ink,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _error!,
                          style: AppTypography.supporting.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text('Focus time', style: _labelStyle(context)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TimeStepButton(
                          key: const Key('focus-time-decrease'),
                          icon: AppIcons.minus,
                          tooltip: 'Decrease focus time by 5 minutes',
                          onPressed: () => _stepTime(-5),
                        ),
                        const SizedBox(width: 17),
                        InkWell(
                          onTap: _editExactTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Text(
                              '$_minutes min',
                              style: AppTypography.heroMetric.copyWith(
                                color: context.palette.ink,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 17),
                        _TimeStepButton(
                          key: const Key('focus-time-increase'),
                          icon: AppIcons.add,
                          tooltip: 'Increase focus time by 5 minutes',
                          onPressed: () => _stepTime(5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Center(
                      child: Text(
                        '5–240 min',
                        style: _labelStyle(context).copyWith(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Tag', style: _labelStyle(context)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.palette.hairlineStrong,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 60,
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 19,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.palette.gradientSkyLight,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(24),
                                    ),
                                  ),
                                  child: Text(
                                    'Focus',
                                    style: AppTypography.cardTitle.copyWith(
                                      color: context.palette.ink,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                AppIcon(
                                  icon: AppIcons.confirm,
                                  size: 22,
                                  color: context.palette.ink,
                                ),
                                const SizedBox(width: 17),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Divider(
                              height: 1,
                              color: context.palette.hairlineStrong,
                            ),
                          ),
                          InkWell(
                            onTap: _showCustomTagInfo,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(14),
                            ),
                            child: SizedBox(
                              height: 60,
                              child: Row(
                                children: [
                                  const SizedBox(width: 14),
                                  AppIcon(
                                    icon: AppIcons.add,
                                    size: 22,
                                    color: context.palette.ink,
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Create a custom tag',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.body.copyWith(
                                              color: context.palette.body,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Container(
                                          key: const Key('custom-tag-crown'),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context
                                                .palette
                                                .gradientSkyLight,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(20),
                                            ),
                                          ),
                                          child: AppIcon(
                                            icon: AppIcons.crown,
                                            size: 18,
                                            color: context.palette.textLink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppIcon(
                                    icon: AppIcons.rowNext,
                                    size: 20,
                                    color: context.palette.ink,
                                  ),
                                  const SizedBox(width: 15),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.palette.primary,
                          foregroundColor: context.palette.onPrimary,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          widget.task == null ? 'Save task' : 'Save changes',
                          style: AppTypography.cardTitle.copyWith(
                            color: context.palette.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) =>
      AppTypography.body.copyWith(color: context.palette.body, fontSize: 14);
}

class _TimeStepButton extends StatelessWidget {
  const _TimeStepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: AppIcon(icon: icon, size: 22, color: context.palette.ink),
    style: IconButton.styleFrom(
      backgroundColor: context.palette.gradientSkyLight,
      shape: const CircleBorder(),
      minimumSize: const Size(44, 44),
    ),
  );
}

class _ExactTaskTimeDialog extends StatefulWidget {
  const _ExactTaskTimeDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_ExactTaskTimeDialog> createState() => _ExactTaskTimeDialogState();
}

class _ExactTaskTimeDialogState extends State<_ExactTaskTimeDialog> {
  late final TextEditingController _input;
  String? _error;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialMinutes.toString());
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _save() {
    final minutes = int.tryParse(_input.text);
    if (minutes == null || minutes < 5 || minutes > 240) {
      setState(() => _error = 'Choose 5 to 240 minutes.');
      return;
    }
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Focus minutes'),
    content: TextField(
      key: const Key('task-minutes-input'),
      controller: _input,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Minutes',
        helperText: 'Choose 5 to 240 minutes',
        errorText: _error,
      ),
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Set time')),
    ],
  );
}
