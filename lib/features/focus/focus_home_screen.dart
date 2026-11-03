import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/focus/focus_sound_controller.dart';
import 'package:syncfocus/features/focus/focus_timer_controller.dart';
import 'package:syncfocus/features/focus/focus_widget_bridge.dart';
import 'package:syncfocus/features/progress/focus_session_recorder.dart';
import 'package:syncfocus/features/progress/progress_screen.dart';
import 'package:syncfocus/features/progress/session_store.dart';
import 'package:syncfocus/features/settings/settings_controller.dart';
import 'package:syncfocus/features/settings/settings_sheet.dart';
import 'package:syncfocus/features/tasks/task_store.dart';
import 'package:syncfocus/features/tasks/tasks_screen.dart';
import 'package:syncfocus/features/welcome/welcome_bottom_sheet.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_logo.dart';
import 'package:syncfocus/theme/app_typography.dart';

class FocusHomeShell extends StatefulWidget {
  const FocusHomeShell({
    super.key,
    required this.settings,
    required this.proBilling,
  });

  final SettingsController settings;
  final ProBillingController proBilling;

  @override
  State<FocusHomeShell> createState() => _FocusHomeShellState();
}

class _FocusHomeShellState extends State<FocusHomeShell>
    with WidgetsBindingObserver {
  static const _homeWelcomePendingKey = 'home_welcome_pending';

  late final FocusTimerController _timer;
  late final FocusWidgetBridge _widgetBridge;
  late final FocusSoundController _focusSound;
  late final TaskStore _tasks;
  late final SessionStore _sessions;
  late final FocusSessionRecorder _sessionRecorder;
  int _selectedTab = 0;
  bool _showHomeWelcome = false;
  FocusTimerPhase _lastHapticPhase = FocusTimerPhase.ready;

  @override
  void initState() {
    super.initState();
    _timer = FocusTimerController();
    _timer.addListener(_onTimerPhaseChanged);
    _widgetBridge = FocusWidgetBridge(
      timer: _timer,
      settings: widget.settings,
      proBilling: widget.proBilling,
      onOpenFocus: () {
        if (!mounted) return;
        setState(() => _selectedTab = 0);
      },
    );
    unawaited(_widgetBridge.initialize());
    _focusSound = FocusSoundController(
      timer: _timer,
      output: JustAudioAmbientOutput(),
      selectedSound: () => widget.settings.ambientSound,
      isPro: () => widget.proBilling.isPro,
      configuration: Listenable.merge([widget.settings, widget.proBilling]),
    );
    _tasks = TaskStore();
    _sessions = SessionStore();
    _sessionRecorder = FocusSessionRecorder(timer: _timer, store: _sessions);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showWelcomeIfPending());
    });
  }

  Future<void> _showWelcomeIfPending() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted || !(preferences.getBool(_homeWelcomePendingKey) ?? false)) {
        return;
      }
      setState(() => _showHomeWelcome = true);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Sync Focus welcome sheet',
          context: ErrorDescription('while reading the welcome sheet state'),
        ),
      );
    }
  }

  Future<void> _dismissHomeWelcome() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_homeWelcomePendingKey, false);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Sync Focus welcome sheet',
          context: ErrorDescription('while saving the welcome sheet state'),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _showHomeWelcome = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer.refresh();
      unawaited(_widgetBridge.refreshSnapshot());
      unawaited(_widgetBridge.consumePendingAction());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.removeListener(_onTimerPhaseChanged);
    _widgetBridge.dispose();
    _sessionRecorder.dispose();
    unawaited(_focusSound.dispose());
    _timer.dispose();
    _tasks.dispose();
    _sessions.dispose();
    super.dispose();
  }

  void _onTimerPhaseChanged() {
    final phase = _timer.phase;
    if (phase == _lastHapticPhase) return;
    final completed =
        phase == FocusTimerPhase.complete ||
        phase == FocusTimerPhase.breakComplete;
    _lastHapticPhase = phase;
    if (completed) unawaited(HapticFeedback.heavyImpact().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.canvas,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _HomeHeader(onSettings: _openSettings),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _FocusHomeBody(timer: _timer, settings: widget.settings),
                      TasksScreen(store: _tasks, onFocus: _focusTask),
                      ProgressScreen(
                        store: _sessions,
                        onGoToTimer: () => setState(() => _selectedTab = 0),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: _BottomNav(
                    selectedIndex: _selectedTab,
                    onSelected: (index) => setState(() => _selectedTab = index),
                  ),
                ),
              ],
            ),
          ),
          if (_showHomeWelcome)
            Positioned.fill(
              child: HomeWelcomeOverlay(onDismissed: _dismissHomeWelcome),
            ),
        ],
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: context.palette.ink.withValues(alpha: 0.28),
      builder: (_) => SettingsSheet(
        settings: widget.settings,
        proBilling: widget.proBilling,
      ),
    );
  }

  void _focusTask(FocusTask task) {
    if (!_timer.canEditDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End the current session before switching tasks.'),
        ),
      );
      return;
    }
    _timer.assignTaskDuration(task.title, task.minutes, tag: task.tag);
    setState(() => _selectedTab = 0);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettings});

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const AppLogo(size: 56, semanticLabel: 'Sync Focus logo'),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                'Sync Focus',
                style: AppTypography.pageTitle.copyWith(
                  color: context.palette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: AppIcon(
                icon: AppIcons.settings,
                color: context.palette.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusHomeBody extends StatelessWidget {
  const _FocusHomeBody({required this.timer, required this.settings});

  final FocusTimerController timer;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: timer,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 520;
          final ringSize = math.min(
            320.0,
            math.min(
              constraints.maxWidth - 64,
              math.max(
                180.0,
                constraints.maxHeight - (compact ? 120.0 : 150.0),
              ),
            ),
          );
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 28,
                vertical: compact ? 8 : 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TimerRing(
                    key: const Key('timer-ring'),
                    timer: timer,
                    size: ringSize,
                    onExactTime: () => _showExactTimeDialog(context),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  Text(
                    _hint,
                    style: AppTypography.body.copyWith(
                      color: context.palette.body,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? 24 : 42),
                  SizedBox(
                    width: math.min(320, constraints.maxWidth - 56),
                    height: 58,
                    child: FilledButton.icon(
                      onPressed: _onPrimaryAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.palette.primary,
                        foregroundColor: context.palette.onPrimary,
                        shape: const StadiumBorder(),
                      ),
                      icon: AppIcon(
                        icon: timer.phase == FocusTimerPhase.running
                            ? AppIcons.pause
                            : AppIcons.play,
                        size: 23,
                        color: context.palette.onPrimary,
                      ),
                      label: Text(
                        _buttonLabel,
                        style: AppTypography.cardTitle.copyWith(
                          color: context.palette.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (timer.phase == FocusTimerPhase.complete) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      key: const Key('start-break-action'),
                      onPressed: () => timer.startBreak(
                        breakDurationMinutes: settings.breakDurationMinutes,
                      ),
                      icon: const Icon(LucideIcons.coffee),
                      label: Text(
                        'Start break · ${settings.breakDurationMinutes} min',
                      ),
                    ),
                  ],
                  if (timer.phase == FocusTimerPhase.paused ||
                      timer.phase == FocusTimerPhase.breakPaused)
                    TextButton(
                      key: const Key('end-timer-session'),
                      onPressed: timer.reset,
                      child: const Text('End session'),
                    ),
                  if (timer.phase == FocusTimerPhase.breakRunning)
                    TextButton(
                      key: const Key('end-break-action'),
                      onPressed: timer.reset,
                      child: const Text('End break'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get _hint => switch (timer.phase) {
    FocusTimerPhase.ready => 'Drag the ring to set time',
    FocusTimerPhase.running => '${timer.displayTime} remaining',
    FocusTimerPhase.paused => 'Timer paused',
    FocusTimerPhase.complete => 'Focus session complete',
    FocusTimerPhase.breakRunning => '${timer.displayTime} left in your break',
    FocusTimerPhase.breakPaused => 'Break paused',
    FocusTimerPhase.breakComplete => 'Break complete',
  };

  String get _buttonLabel => switch (timer.phase) {
    FocusTimerPhase.ready => 'Start focus',
    FocusTimerPhase.running => 'Pause focus',
    FocusTimerPhase.paused => 'Resume focus',
    FocusTimerPhase.complete => 'Start focus',
    FocusTimerPhase.breakRunning => 'Pause break',
    FocusTimerPhase.breakPaused => 'Resume break',
    FocusTimerPhase.breakComplete => 'Start focus',
  };

  void _onPrimaryAction() {
    unawaited(HapticFeedback.lightImpact().catchError((_) {}));
    if (timer.phase == FocusTimerPhase.running ||
        timer.phase == FocusTimerPhase.breakRunning) {
      timer.pause();
    } else {
      timer.start();
    }
  }

  Future<void> _showExactTimeDialog(BuildContext context) async {
    if (!timer.canEditDuration) return;
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => _ExactTimeDialog(initialMinutes: timer.durationMinutes),
    );
    if (minutes != null) timer.setDurationMinutes(minutes);
  }
}

class _ExactTimeDialog extends StatefulWidget {
  const _ExactTimeDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_ExactTimeDialog> createState() => _ExactTimeDialogState();
}

class _ExactTimeDialogState extends State<_ExactTimeDialog> {
  late final TextEditingController _input;

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

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Set focus time'),
    content: TextField(
      controller: _input,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Minutes',
        helperText: 'Choose 5 to 240 minutes',
      ),
      onSubmitted: (_) => Navigator.pop(context, int.tryParse(_input.text)),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, int.tryParse(_input.text)),
        child: const Text('Set time'),
      ),
    ],
  );
}

class _TimerRing extends StatefulWidget {
  const _TimerRing({
    super.key,
    required this.timer,
    required this.size,
    required this.onExactTime,
  });

  final FocusTimerController timer;
  final double size;
  final VoidCallback onExactTime;

  @override
  State<_TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends State<_TimerRing> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final timer = widget.timer;
    final canEditDuration = timer.canEditDuration;
    final isConfiguringFocus = timer.phase == FocusTimerPhase.ready;
    final fraction = isConfiguringFocus
        ? _fractionForDuration(timer.durationMinutes)
        : timer.remainingFraction;

    return Semantics(
      label: 'Focus timer',
      value: isConfiguringFocus
          ? '${timer.durationMinutes} minutes'
          : '${timer.displayTime} remaining',
      slider: canEditDuration,
      enabled: canEditDuration,
      increasedValue: canEditDuration
          ? '${math.min(240, timer.durationMinutes + 5)} minutes'
          : null,
      decreasedValue: canEditDuration
          ? '${math.max(5, timer.durationMinutes - 5)} minutes'
          : null,
      onIncrease: canEditDuration
          ? () {
              unawaited(HapticFeedback.selectionClick().catchError((_) {}));
              timer.setDurationMinutes(timer.durationMinutes + 5);
            }
          : null,
      onDecrease: canEditDuration
          ? () {
              unawaited(HapticFeedback.selectionClick().catchError((_) {}));
              timer.setDurationMinutes(timer.durationMinutes - 5);
            }
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: canEditDuration ? _onPanStart : null,
        onPanUpdate: canEditDuration ? _onPanUpdate : null,
        onPanEnd: (_) => _dragging = false,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  context.palette.gradientSkyLight.withValues(alpha: 0.78),
                  context.palette.gradientSkyLight.withValues(alpha: 0.45),
                  context.palette.canvas.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.68, 1.0],
              ),
            ),
            child: CustomPaint(
              painter: _RingPainter(
                fraction: fraction,
                showHandle: canEditDuration,
                palette: context.palette,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    switch (timer.phase) {
                      FocusTimerPhase.ready =>
                        timer.taskTitle ?? 'Ready to focus',
                      FocusTimerPhase.running => 'Focusing',
                      FocusTimerPhase.paused => 'Paused',
                      FocusTimerPhase.complete => 'Complete',
                      FocusTimerPhase.breakRunning => 'Taking a break',
                      FocusTimerPhase.breakPaused => 'Break paused',
                      FocusTimerPhase.breakComplete => 'Break complete',
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyTitle.copyWith(
                      color: context.palette.body,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: canEditDuration ? widget.onExactTime : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          timer.displayTime,
                          style: AppTypography.timerReadout.copyWith(
                            color: context.palette.ink,
                            fontSize: timer.durationMinutes >= 60 ? 59 : 74,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2 - 12;
    final distance = (details.localPosition - center).distance;
    _dragging = (distance - radius).abs() < 38;
    if (_dragging) _setFromPosition(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragging) _setFromPosition(details.localPosition);
  }

  void _setFromPosition(Offset position) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final delta = position - center;
    final angle =
        (math.atan2(delta.dy, delta.dx) + math.pi / 2) % (math.pi * 2);
    final fraction = angle / (math.pi * 2);
    widget.timer.setDurationMinutes(_durationForFraction(fraction));
  }
}

// A gentle nonlinear scale keeps common 25-minute sessions easy to dial while
// still allowing the full 5–240-minute range within a single revolution.
double _fractionForDuration(int minutes) {
  if (minutes <= 25) return 0.25 * (minutes - 5) / 20;
  if (minutes <= 60) return 0.25 + 0.35 * (minutes - 25) / 35;
  return 0.60 + 0.40 * (minutes - 60) / 180;
}

int _durationForFraction(double fraction) {
  final minutes = switch (fraction) {
    < 0.25 => 5 + fraction / 0.25 * 20,
    < 0.60 => 25 + (fraction - 0.25) / 0.35 * 35,
    _ => 60 + (fraction - 0.60) / 0.40 * 180,
  };
  return ((minutes / 5).round() * 5).clamp(5, 240).toInt();
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.showHandle,
    required this.palette,
  });

  final double fraction;
  final bool showHandle;
  final AppColorPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -math.pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = palette.gradientSkyMid.withValues(alpha: 0.27)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    final activePaint = Paint()
      ..color = palette.gradientSkyMid
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);
    final sweep = math.pi * 2 * fraction.clamp(0.0, 1.0);
    canvas.drawArc(rect, startAngle, sweep, false, activePaint);
    if (showHandle) {
      final end = startAngle + sweep;
      final marker =
          center + Offset(radius * math.cos(end), radius * math.sin(end));
      canvas.drawCircle(marker, 11, Paint()..color = palette.gradientSkyMid);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.showHandle != showHandle ||
      oldDelegate.palette.isDark != palette.isDark;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (label: 'Home', icon: LucideIcons.house),
      (label: 'Tasks', icon: LucideIcons.listTodo),
      (label: 'Progress', icon: LucideIcons.chartNoAxesColumnIncreasing),
    ];
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: context.palette.canvas,
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: context.palette.hairlineStrong),
        boxShadow: [
          BoxShadow(
            color: context.palette.ink.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(i),
                borderRadius: BorderRadius.circular(40),
                child: Semantics(
                  selected: selectedIndex == i,
                  button: true,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 22,
                        color: selectedIndex == i
                            ? context.palette.primary
                            : context.palette.muted,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: AppTypography.rowTitle.copyWith(
                          color: selectedIndex == i
                              ? context.palette.primary
                              : context.palette.muted,
                          fontWeight: selectedIndex == i
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
