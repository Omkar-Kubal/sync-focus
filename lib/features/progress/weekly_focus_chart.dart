import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_typography.dart';

class WeeklyFocusChart extends StatelessWidget {
  const WeeklyFocusChart({
    super.key,
    required this.dailyMinutes,
    required this.weekStart,
    required this.today,
  });

  final List<int> dailyMinutes;
  final DateTime weekStart;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    assert(dailyMinutes.length == 7);
    final todayIndex = today.weekday - 1;
    final hasActivity = dailyMinutes.any((value) => value > 0);
    final maxMinutes = math.max(90, dailyMinutes.reduce(math.max));
    return Semantics(
      label: 'Focus minutes this week',
      child: SizedBox(
        height: 174,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double x(int index) => 10 + index * (width - 20) / 6;
            double y(int index) =>
                32 + (1 - dailyMinutes[index] / maxMinutes) * 80;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _WeeklyLinePainter(
                      dailyMinutes: dailyMinutes,
                      todayIndex: todayIndex,
                      maxMinutes: maxMinutes,
                      hasActivity: hasActivity,
                      palette: context.palette,
                    ),
                  ),
                ),
                for (var i = 0; i < 7; i++) ...[
                  if (hasActivity && i <= todayIndex)
                    Positioned(
                      left: x(i) - 21,
                      top: math.max(0, y(i) - 25),
                      width: 42,
                      child: Text(
                        '${dailyMinutes[i]}m',
                        textAlign: TextAlign.center,
                        style: AppTypography.supporting.copyWith(
                          color: context.palette.body,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Positioned(
                    left: x(i) - 20,
                    top: 133,
                    width: 40,
                    child: Column(
                      children: [
                        Text(
                          _weekdays[i],
                          style: AppTypography.supporting.copyWith(
                            color: context.palette.body,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_months[_dayAt(i).month - 1]} ${_dayAt(i).day}',
                          maxLines: 1,
                          style: AppTypography.supporting.copyWith(
                            color: context.palette.body,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  DateTime _dayAt(int index) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + index);
}

class _WeeklyLinePainter extends CustomPainter {
  const _WeeklyLinePainter({
    required this.dailyMinutes,
    required this.todayIndex,
    required this.maxMinutes,
    required this.hasActivity,
    required this.palette,
  });

  final List<int> dailyMinutes;
  final int todayIndex;
  final int maxMinutes;
  final bool hasActivity;
  final AppColorPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    double x(int index) => 10 + index * (size.width - 20) / 6;
    double y(int index) => 32 + (1 - dailyMinutes[index] / maxMinutes) * 80;
    const baseline = 118.0;

    if (!hasActivity) {
      canvas.drawLine(
        const Offset(10, baseline),
        Offset(size.width - 10, baseline),
        Paint()
          ..color = palette.hairlineStrong
          ..strokeWidth = 1.5,
      );
      return;
    }

    final guidePaint = Paint()
      ..color = palette.hairlineStrong
      ..strokeWidth = 1;
    final path = Path()..moveTo(x(0), y(0));
    for (var i = 1; i <= todayIndex; i++) {
      final middle = (x(i - 1) + x(i)) / 2;
      path.cubicTo(middle, y(i - 1), middle, y(i), x(i), y(i));
    }
    for (var i = 0; i <= todayIndex; i++) {
      for (var guideY = y(i) + 9; guideY < baseline; guideY += 5) {
        canvas.drawLine(
          Offset(x(i), guideY),
          Offset(x(i), math.min(guideY + 2, baseline)),
          guidePaint,
        );
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.progressBlue
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i <= todayIndex; i++) {
      final point = Offset(x(i), y(i));
      if (i == todayIndex) {
        canvas.drawCircle(point, 12, Paint()..color = palette.progressHalo);
      }
      canvas.drawCircle(
        point,
        i == todayIndex ? 5.5 : 4.5,
        Paint()..color = palette.progressBlue,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyLinePainter oldDelegate) =>
      oldDelegate.todayIndex != todayIndex ||
      oldDelegate.maxMinutes != maxMinutes ||
      oldDelegate.hasActivity != hasActivity ||
      oldDelegate.palette.isDark != palette.isDark ||
      !_sameMinutes(oldDelegate.dailyMinutes, dailyMinutes);

  bool _sameMinutes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
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
