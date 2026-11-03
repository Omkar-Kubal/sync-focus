import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_typography.dart';

class ProTrendPreview extends StatefulWidget {
  const ProTrendPreview({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  State<ProTrendPreview> createState() => _ProTrendPreviewState();
}

class _ProTrendPreviewState extends State<ProTrendPreview> {
  var _selectedDays = 30;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('progress-pro-trend-preview'),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    decoration: BoxDecoration(
      color: context.palette.progressHalo,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: AppIcon(
                icon: AppIcons.crown,
                size: 24,
                color: context.palette.textLink,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'See the bigger picture',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyTitle.copyWith(
                            color: context.palette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RangeSelector(
                        selectedDays: _selectedDays,
                        onSelected: (days) =>
                            setState(() => _selectedDays = days),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock longer trends to spot patterns and stay consistent.',
                    style: AppTypography.body.copyWith(
                      color: context.palette.body,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          key: const Key('progress-pro-preview-chart'),
          label: 'Illustrative $_selectedDays-day trend preview',
          image: true,
          child: ExcludeSemantics(
            child: SizedBox(
              height: 58,
              width: double.infinity,
              child: CustomPaint(
                painter: _TrendPreviewPainter(
                  pointCount: _selectedDays == 30 ? 8 : 10,
                  palette: context.palette,
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 31, top: 3),
          child: Text('Illustrative preview', style: AppTypography.supporting),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: FilledButton(
            key: const Key('progress-explore-pro'),
            onPressed: widget.onExplore,
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.textLink,
              foregroundColor: context.palette.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore Pro',
                  style: AppTypography.button.copyWith(
                    color: context.palette.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                AppIcon(
                  icon: AppIcons.next,
                  size: 18,
                  color: context.palette.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selectedDays, required this.onSelected});

  final int selectedDays;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _RangeChip(
        days: 30,
        selected: selectedDays == 30,
        onTap: () => onSelected(30),
      ),
      const SizedBox(width: 4),
      _RangeChip(
        days: 90,
        selected: selectedDays == 90,
        onTap: () => onSelected(90),
      ),
    ],
  );
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
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
    label: '$days days trend preview',
    child: Material(
      color: selected ? context.palette.gradientSkyLight : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? context.palette.gradientSkyLight
              : context.palette.hairlineStrong,
        ),
      ),
      child: InkWell(
        key: Key('progress-pro-range-$days'),
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            '$days days',
            style: AppTypography.supporting.copyWith(
              fontSize: 10,
              color: selected ? context.palette.textLink : context.palette.body,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TrendPreviewPainter extends CustomPainter {
  const _TrendPreviewPainter({required this.pointCount, required this.palette});

  final int pointCount;
  final AppColorPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const values = <double>[
      0.58,
      0.43,
      0.62,
      0.51,
      0.60,
      0.38,
      0.52,
      0.28,
      0.12,
      0.05,
    ];
    final points = List<Offset>.generate(pointCount, (index) {
      final x = 3 + index * (size.width - 6) / (pointCount - 1);
      final y = 7 + values[index] * (size.height - 19);
      return Offset(x, y);
    });

    final guidePaint = Paint()
      ..color = palette.hairlineStrong
      ..strokeWidth = 1;
    const guideY = 50.0;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, guideY),
        Offset(math.min(x + 3, size.width), guideY),
        guidePaint,
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final middleX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        middleX,
        previous.dy,
        middleX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.textLinkSecondary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(points.last, 8, Paint()..color = palette.progressHalo);
    canvas.drawCircle(
      points.last,
      3.5,
      Paint()..color = palette.textLinkSecondary,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPreviewPainter oldDelegate) =>
      oldDelegate.pointCount != pointCount ||
      oldDelegate.palette.isDark != palette.isDark;
}
