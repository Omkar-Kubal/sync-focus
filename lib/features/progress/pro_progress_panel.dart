import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfocus/features/progress/session_store.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_typography.dart';

class ProProgressPanel extends StatefulWidget {
  const ProProgressPanel({
    super.key,
    required this.sessions,
    required this.now,
    this.onGoToTimer,
  });

  final List<FocusSession> sessions;
  final DateTime now;
  final VoidCallback? onGoToTimer;

  @override
  State<ProProgressPanel> createState() => _ProProgressPanelState();
}

class _ProProgressPanelState extends State<ProProgressPanel> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final summary = ProProgressSummary.fromSessions(
      widget.sessions,
      widget.now,
      days: _selectedDays,
    );
    if (summary.totalMinutes == 0) {
      return _ProProgressEmptyState(
        selectedDays: _selectedDays,
        showRangeSelector: widget.sessions.isNotEmpty,
        onSelectedDays: (days) => setState(() => _selectedDays = days),
        onGoToTimer: widget.onGoToTimer,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeader = constraints.maxWidth < 318;
        final heading = Text(
          'Focus over time',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.pageTitle.copyWith(
            color: context.palette.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        );
        final range = _RangeSelector(
          selectedDays: _selectedDays,
          onSelected: (days) => setState(() => _selectedDays = days),
        );

        return Container(
          key: const Key('progress-pro-insights'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          decoration: BoxDecoration(
            color: context.palette.progressSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.gradientSkyLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compactHeader) ...[
                heading,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: range),
              ] else
                Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 7),
                    range,
                  ],
                ),
              const SizedBox(height: 3),
              SizedBox(
                width: constraints.maxWidth * 0.48,
                child: Text(
                  'See how your focus time has changed over the last '
                  '$_selectedDays days.',
                  style: AppTypography.body.copyWith(
                    color: context.palette.body,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SummaryMetrics(summary: summary),
              const SizedBox(height: 12),
              _ProTrendChart(summary: summary),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: context.palette.hairlineStrong,
                ),
              ),
              Text(
                'Focus by tag',
                style: AppTypography.pageTitle.copyWith(
                  color: context.palette.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: constraints.maxWidth * 0.52,
                child: Text(
                  'How your focus time is distributed across different types '
                  'of work.',
                  style: AppTypography.body.copyWith(
                    color: context.palette.body,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              if (summary.tags.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Complete a focus session to see your tag breakdown.',
                    style: AppTypography.body.copyWith(
                      color: context.palette.body,
                    ),
                  ),
                )
              else
                for (
                  var index = 0;
                  index < math.min(3, summary.tags.length);
                  index++
                ) ...[
                  _TagBreakdownRow(
                    item: summary.tags[index],
                    totalMinutes: summary.totalMinutes,
                  ),
                  if (index < math.min(3, summary.tags.length) - 1)
                    const SizedBox(height: 8),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _ProProgressEmptyState extends StatelessWidget {
  const _ProProgressEmptyState({
    required this.selectedDays,
    required this.showRangeSelector,
    required this.onSelectedDays,
    required this.onGoToTimer,
  });

  final int selectedDays;
  final bool showRangeSelector;
  final ValueChanged<int> onSelectedDays;
  final VoidCallback? onGoToTimer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = Text(
        'Focus over time',
        style: AppTypography.pageTitle.copyWith(
          color: context.palette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      );
      final range = _RangeSelector(
        selectedDays: selectedDays,
        onSelected: onSelectedDays,
      );
      final compactHeader = constraints.maxWidth < 318;

      return Container(
        key: const Key('progress-pro-empty-state'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        decoration: BoxDecoration(
          color: context.palette.progressSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.palette.gradientSkyLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showRangeSelector && compactHeader) ...[
              Align(alignment: Alignment.centerLeft, child: heading),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: range),
            ] else
              Row(
                children: [
                  Expanded(child: heading),
                  if (showRangeSelector) ...[const SizedBox(width: 7), range],
                ],
              ),
            const SizedBox(height: 18),
            const _ProProgressEmptyIllustration(),
            const SizedBox(height: 14),
            Text(
              showRangeSelector
                  ? 'No focus in the last $selectedDays days'
                  : 'No focus sessions yet',
              textAlign: TextAlign.center,
              style: AppTypography.pageTitle.copyWith(
                color: context.palette.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              showRangeSelector
                  ? 'Try a wider range to include earlier focus sessions.'
                  : 'Complete your first focus session to see your focus trends '
                        'and tag breakdown.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: context.palette.body),
            ),
            if (!showRangeSelector && onGoToTimer != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: 184,
                height: 52,
                child: FilledButton(
                  onPressed: onGoToTimer,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    foregroundColor: context.palette.onPrimary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Go to timer',
                    style: AppTypography.button.copyWith(
                      color: context.palette.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _ProProgressEmptyIllustration extends StatelessWidget {
  const _ProProgressEmptyIllustration();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Focus insights illustration with a trend chart and Pro crown',
    image: true,
    child: SizedBox(
      key: const Key('progress-empty-illustration'),
      width: 144,
      height: 144,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.palette.progressHalo,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: context.palette.canvas,
              shape: BoxShape.circle,
              border: Border.all(color: context.palette.gradientSkyLight),
            ),
            child: Center(
              child: AppIcon(
                icon: AppIcons.progress,
                size: 42,
                color: context.palette.progressBlue,
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.palette.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: context.palette.gradientSkyLight),
              ),
              child: Center(
                child: AppIcon(
                  icon: AppIcons.crown,
                  size: 22,
                  color: context.palette.textLink,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

@immutable
class ProTagSummary {
  const ProTagSummary({required this.tag, required this.minutes});

  final String tag;
  final int minutes;
}

@immutable
class ProProgressSummary {
  const ProProgressSummary({
    required this.days,
    required this.startDay,
    required this.dailyMinutes,
    required this.totalMinutes,
    required this.sessionCount,
    required this.tags,
  });

  final int days;
  final DateTime startDay;
  final List<int> dailyMinutes;
  final int totalMinutes;
  final int sessionCount;
  final List<ProTagSummary> tags;

  factory ProProgressSummary.fromSessions(
    Iterable<FocusSession> sessions,
    DateTime now, {
    required int days,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(today.year, today.month, today.day - days);
    final startUtc = DateTime.utc(startDay.year, startDay.month, startDay.day);
    final todayUtc = DateTime.utc(today.year, today.month, today.day);
    final dailyMinutes = List<int>.filled(days + 1, 0);
    final tagMinutes = <String, int>{};
    var totalMinutes = 0;
    var sessionCount = 0;

    for (final session in sessions) {
      if (session.durationMinutes <= 0) continue;
      final day = DateTime(
        session.completedAt.year,
        session.completedAt.month,
        session.completedAt.day,
      );
      final dayUtc = DateTime.utc(day.year, day.month, day.day);
      if (dayUtc.isBefore(startUtc) || dayUtc.isAfter(todayUtc)) continue;

      final dayIndex = dayUtc.difference(startUtc).inDays;
      dailyMinutes[dayIndex] += session.durationMinutes;
      totalMinutes += session.durationMinutes;
      sessionCount++;
      final tag = session.tag.trim().isEmpty ? 'Focus' : session.tag.trim();
      tagMinutes[tag] = (tagMinutes[tag] ?? 0) + session.durationMinutes;
    }

    final tags =
        tagMinutes.entries
            .map((entry) => ProTagSummary(tag: entry.key, minutes: entry.value))
            .toList()
          ..sort((a, b) => b.minutes.compareTo(a.minutes));

    return ProProgressSummary(
      days: days,
      startDay: startDay,
      dailyMinutes: List.unmodifiable(dailyMinutes),
      totalMinutes: totalMinutes,
      sessionCount: sessionCount,
      tags: List.unmodifiable(tags),
    );
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({required this.summary});

  final ProProgressSummary summary;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: _SummaryMetric(
          value: _formatDuration(summary.totalMinutes),
          label: 'focused',
        ),
      ),
      Container(width: 1, height: 43, color: context.palette.hairlineStrong),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: _SummaryMetric(
            value: '${summary.sessionCount}',
            label: 'sessions',
          ),
        ),
      ),
    ],
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          style: AppTypography.heroMetric.copyWith(
            color: context.palette.ink,
            fontSize: 31,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: AppTypography.body.copyWith(
          color: context.palette.body,
          fontSize: 14,
        ),
      ),
    ],
  );
}

class _ProTrendChart extends StatelessWidget {
  const _ProTrendChart({required this.summary});

  final ProProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final highestDay = summary.dailyMinutes.isEmpty
        ? 0
        : summary.dailyMinutes.reduce(math.max);
    final scaleMinutes = math.max(120, ((highestDay + 59) ~/ 60) * 60);
    final midpoint = scaleMinutes ~/ 2;
    final ticks = _chartSampleIndices(summary.days);
    final chartMinutes = [
      for (final index in ticks) summary.dailyMinutes[index],
    ];

    return Semantics(
      label: 'Focus time trend for the last ${summary.days} days',
      image: true,
      child: SizedBox(
        height: 130,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: _AxisLabel(_formatAxis(scaleMinutes)),
            ),
            Positioned(
              left: 0,
              top: 56,
              child: _AxisLabel(_formatAxis(midpoint)),
            ),
            const Positioned(left: 0, bottom: 23, child: _AxisLabel('0h')),
            Positioned(
              left: 28,
              right: 0,
              top: 2,
              bottom: 25,
              child: CustomPaint(
                painter: _ProTrendPainter(
                  minutes: chartMinutes,
                  scaleMinutes: scaleMinutes,
                  tickIndices: List.generate(chartMinutes.length, (i) => i),
                  palette: context.palette,
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 0,
              bottom: 0,
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final index in ticks)
                    Flexible(
                      child: Text(
                        _formatAxisDate(
                          DateTime(
                            summary.startDay.year,
                            summary.startDay.month,
                            summary.startDay.day + index,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: AppTypography.chartLabel.copyWith(
                          color: context.palette.body,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTypography.chartLabel.copyWith(color: context.palette.body),
  );
}

class _ProTrendPainter extends CustomPainter {
  const _ProTrendPainter({
    required this.minutes,
    required this.scaleMinutes,
    required this.tickIndices,
    required this.palette,
  });

  final List<int> minutes;
  final int scaleMinutes;
  final List<int> tickIndices;
  final AppColorPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || minutes.isEmpty) return;
    const inset = 7.0;
    final baseline = size.height - 7;
    final plotHeight = baseline - inset;
    final points = List<Offset>.generate(minutes.length, (index) {
      final x = minutes.length == 1
          ? size.width / 2
          : index * size.width / (minutes.length - 1);
      final y =
          baseline -
          (minutes[index].clamp(0, scaleMinutes) / scaleMinutes) * plotHeight;
      return Offset(x, y);
    });

    final guidePaint = Paint()
      ..color = palette.hairlineStrong
      ..strokeWidth = 1;
    for (final index in tickIndices) {
      final x = points[index].dx;
      for (var y = inset; y < baseline; y += 7) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 2.5, baseline)),
          guidePaint,
        );
      }
    }
    canvas.drawLine(
      Offset(0, baseline),
      Offset(size.width, baseline),
      Paint()
        ..color = palette.hairlineStrong
        ..strokeWidth = 1,
    );

    if (minutes.any((value) => value > 0)) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index++) {
        final previous = points[index - 1];
        final current = points[index];
        final middleX = (previous.dx + current.dx) / 2;
        linePath.cubicTo(
          middleX,
          previous.dy,
          middleX,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, baseline)
        ..lineTo(points.first.dx, baseline)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()..color = palette.progressBlue.withValues(alpha: 0.1),
      );
      canvas.drawPath(
        linePath,
        Paint()
          ..color = palette.progressBlue
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      for (final index in tickIndices) {
        canvas.drawCircle(points[index], 5.5, Paint()..color = palette.canvas);
        canvas.drawCircle(
          points[index],
          4,
          Paint()..color = palette.progressBlue,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProTrendPainter oldDelegate) =>
      oldDelegate.scaleMinutes != scaleMinutes ||
      oldDelegate.palette.isDark != palette.isDark ||
      !_sameValues(oldDelegate.minutes, minutes) ||
      !_sameValues(oldDelegate.tickIndices, tickIndices);

  bool _sameValues(List<int> first, List<int> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selectedDays, required this.onSelected});

  final int selectedDays;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.hairlineStrong),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RangeOption(
          days: 30,
          selected: selectedDays == 30,
          onTap: () => onSelected(30),
        ),
        _RangeOption(
          days: 90,
          selected: selectedDays == 90,
          onTap: () => onSelected(90),
        ),
      ],
    ),
  );
}

class _RangeOption extends StatelessWidget {
  const _RangeOption({
    required this.days,
    required this.selected,
    required this.onTap,
  });

  final int days;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$days days',
    child: Material(
      color: selected ? context.palette.gradientSkyLight : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: Key('progress-pro-days-$days'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 62,
          height: 30,
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                '$days days',
                style: AppTypography.body.copyWith(
                  color: selected
                      ? context.palette.textLink
                      : context.palette.body,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TagBreakdownRow extends StatelessWidget {
  const _TagBreakdownRow({required this.item, required this.totalMinutes});

  final ProTagSummary item;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final fraction = totalMinutes == 0
        ? 0.0
        : (item.minutes / totalMinutes).clamp(0.0, 1.0).toDouble();
    final percentage = (fraction * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.palette.progressHalo,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppIcon(
              icon: _iconForTag(item.tag),
              size: 20,
              color: context.palette.textLink,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyTitle.copyWith(
                        color: context.palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDuration(item.minutes),
                    style: AppTypography.body.copyWith(
                      color: context.palette.ink,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 33,
                    child: Text(
                      '$percentage%',
                      textAlign: TextAlign.right,
                      style: AppTypography.body.copyWith(
                        color: context.palette.body,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: context.palette.progressTrack),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.palette.progressBlue,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
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
      ],
    );
  }
}

List<List<dynamic>> _iconForTag(String tag) {
  final normalized = tag.toLowerCase();
  if (normalized.contains('meeting')) return AppIcons.meetingSession;
  if (normalized.contains('writ') || normalized.contains('read')) {
    return AppIcons.writingSession;
  }
  if (normalized.contains('deep') || normalized.contains('work')) {
    return AppIcons.projectSession;
  }
  return AppIcons.tag;
}

List<int> _chartSampleIndices(int days) =>
    days == 30 ? const [0, 7, 14, 21, 28, 30] : const [0, 18, 36, 54, 72, 90];

String _formatAxis(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  return remaining == 0 ? '${hours}h' : '${hours}h ${remaining}m';
}

String _formatAxisDate(DateTime value) =>
    '${_monthNames[value.month - 1]} ${value.day}';

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '${remaining}m';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
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
