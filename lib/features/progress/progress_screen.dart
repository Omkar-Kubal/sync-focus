import 'package:flutter/material.dart';
import 'package:syncfocus/features/progress/pro_progress_panel.dart';
import 'package:syncfocus/features/progress/session_store.dart';
import 'package:syncfocus/features/progress/weekly_focus_chart.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_typography.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({
    super.key,
    required this.store,
    required this.onGoToTimer,
  });

  final SessionStore store;
  final VoidCallback onGoToTimer;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      if (store.sessions.isEmpty) {
        return _EmptyProgressScreen(onGoToTimer: onGoToTimer);
      }
      final now = DateTime.now();
      final summary = ProgressSummary.fromSessions(store.sessions, now);
      final weekEnd = DateTime(
        summary.weekStart.year,
        summary.weekStart.month,
        summary.weekStart.day + 6,
      );
      return ListView(
        key: const PageStorageKey<String>('progress-populated'),
        padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
        children: [
          Text(
            'Progress',
            style: AppTypography.heroMetric.copyWith(
              color: context.palette.ink,
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'See the time you gave to what matters',
            style: AppTypography.body.copyWith(
              color: context.palette.body,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 34),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This week',
                      style: AppTypography.pageTitle.copyWith(
                        color: context.palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatWeekRange(summary.weekStart, weekEnd),
                      style: AppTypography.body.copyWith(
                        color: context.palette.body,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(summary.weeklyTotalMinutes),
                style: AppTypography.heroMetric.copyWith(
                  color: context.palette.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          WeeklyFocusChart(
            key: const Key('progress-week-chart'),
            dailyMinutes: summary.dailyMinutes,
            weekStart: summary.weekStart,
            today: now,
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: context.palette.hairlineStrong),
          const SizedBox(height: 26),
          Text(
            'Recent focus',
            style: AppTypography.pageTitle.copyWith(
              color: context.palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < summary.recent.length; i++)
            _RecentSessionRow(
              session: summary.recent[i],
              isLast: i == summary.recent.length - 1,
            ),
          const SizedBox(height: 4),
          Divider(height: 1, color: context.palette.hairlineStrong),
          const SizedBox(height: 18),
          ProProgressPanel(
            sessions: store.sessions,
            now: now,
            onGoToTimer: onGoToTimer,
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: context.palette.hairlineStrong),
          const SizedBox(height: 18),
          Row(
            children: [
              AppIcon(
                icon: AppIcons.streak,
                size: 27,
                color: context.palette.body,
              ),
              const SizedBox(width: 13),
              Text(
                summary.currentStreakDays == 0
                    ? 'No streak yet'
                    : '${summary.currentStreakDays}-day streak',
                style: AppTypography.bodyTitle.copyWith(
                  color: context.palette.body,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _EmptyProgressScreen extends StatelessWidget {
  const _EmptyProgressScreen({required this.onGoToTimer});

  final VoidCallback onGoToTimer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      key: const PageStorageKey<String>('progress-empty'),
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
      children: [
        Text(
          'Progress',
          style: AppTypography.heroMetric.copyWith(
            color: context.palette.ink,
            fontSize: 40,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'See the time you gave to what matters',
          style: AppTypography.body.copyWith(
            color: context.palette.body,
            fontSize: 15,
          ),
        ),
        SizedBox(height: constraints.maxHeight > 590 ? 40 : 24),
        ProProgressPanel(
          sessions: const [],
          now: DateTime.now(),
          onGoToTimer: onGoToTimer,
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({required this.session, required this.isLast});

  final FocusSession session;
  final bool isLast;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 69,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          height: 69,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (!isLast)
                Positioned(
                  top: 22,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: context.palette.hairlineStrong,
                  ),
                ),
              Positioned(
                top: 7,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: context.palette.canvas,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.palette.progressBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 205),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.rowTitle.copyWith(
                      color: context.palette.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatSessionDate(session.completedAt),
                    style: AppTypography.body.copyWith(
                      color: context.palette.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 54,
          child: Text(
            '${session.durationMinutes} min',
            textAlign: TextAlign.right,
            style: AppTypography.body.copyWith(color: context.palette.body),
          ),
        ),
      ],
    ),
  );
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _formatWeekRange(DateTime start, DateTime end) =>
    '${_monthNames[start.month - 1]} ${start.day} – '
    '${_monthNames[end.month - 1]} ${end.day}, ${end.year}';

String _formatSessionDate(DateTime value) =>
    '${_weekdayNames[value.weekday - 1]}, '
    '${_monthNames[value.month - 1]} ${value.day}, ${value.year}';

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '${remaining}m';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}
