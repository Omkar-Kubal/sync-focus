import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_logo.dart';
import 'package:syncfocus/theme/app_typography.dart';

class HomeWelcomeOverlay extends StatefulWidget {
  const HomeWelcomeOverlay({super.key, required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  State<HomeWelcomeOverlay> createState() => _HomeWelcomeOverlayState();
}

class _HomeWelcomeOverlayState extends State<HomeWelcomeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onDismissed();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = disableAnimations ? 1.0 : _controller.value;
          final eased = Curves.easeOutCubic.transform(progress);

          return Stack(
            children: [
              Positioned.fill(
                child: ModalBarrier(
                  dismissible: false,
                  color: palette.ink.withValues(alpha: 0.48 * eased),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.88,
                        widthFactor: 1,
                        child: Opacity(
                          opacity: eased,
                          child: Transform.translate(
                            offset: Offset(0, 28 * (1 - eased)),
                            child: _HomeWelcomeSheet(
                              onDismissed: widget.onDismissed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeWelcomeSheet extends StatefulWidget {
  const _HomeWelcomeSheet({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  State<_HomeWelcomeSheet> createState() => _HomeWelcomeSheetState();
}

class _HomeWelcomeSheetState extends State<_HomeWelcomeSheet> {
  bool _showSummary = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final compact = MediaQuery.sizeOf(context).height < 720;

    return Container(
      key: const ValueKey('new-user-welcome-sheet'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surfaceCard,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(34),
          bottom: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 64,
            height: compact ? 200 : 240,
            child: const IgnorePointer(child: _WelcomeConfetti()),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                32,
                compact ? 80 : 96,
                32,
                compact ? 112 : 132,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: const AppLogo(
                      size: 136,
                      semanticLabel: 'Sync Focus logo',
                    ),
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: Text(
                      'Welcome to\nSync Focus',
                      textAlign: TextAlign.center,
                      style: AppTypography.pageTitle.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Thanks for giving Sync Focus a try. I’m excited to have you here.',
                    style: AppTypography.bodyTitle.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    key: const ValueKey('new-user-welcome-tldr'),
                    onPressed: () =>
                        setState(() => _showSummary = !_showSummary),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      _showSummary
                          ? 'Read the full welcome'
                          : 'Click for TL;DR',
                      style: AppTypography.action.copyWith(
                        color: palette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _showSummary
                        ? Text(
                            'Set a focus time or choose a task to begin. Review your completed sessions in Progress, and find help in Settings → Support.',
                            key: const ValueKey('welcome-summary'),
                            style: _letterStyle(context),
                          )
                        : _WelcomeLetterText(
                            key: const ValueKey('welcome-letter'),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: IconButton(
              key: const ValueKey('new-user-welcome-close'),
              onPressed: widget.onDismissed,
              tooltip: 'Close welcome',
              style: IconButton.styleFrom(
                minimumSize: const Size(52, 52),
                backgroundColor: palette.canvas.withValues(alpha: 0.72),
                foregroundColor: palette.body,
                shape: CircleBorder(
                  side: BorderSide(
                    color: palette.hairlineStrong.withValues(alpha: 0.72),
                  ),
                ),
              ),
              icon: AppIcon(icon: AppIcons.close, size: 24),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SizedBox(
              height: 58,
              child: FilledButton(
                key: const ValueKey('new-user-welcome-continue'),
                onPressed: widget.onDismissed,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: AppTypography.button.copyWith(
                    color: palette.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeLetterText extends StatelessWidget {
  const _WelcomeLetterText({super.key});

  @override
  Widget build(BuildContext context) {
    final style = _letterStyle(context);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(
            text: 'Hey, I’m Omkar, the developer behind Sync Focus.\n\n',
          ),
          const TextSpan(
            text: 'Sync Focus is designed to help you make room for the work that matters. Set a session with the timer ring or begin from a task, then use Progress to look back on your completed focus sessions.\n\n',
          ),
          const TextSpan(
            text: 'This is an early version, and there is plenty we want to improve. If you have suggestions or run into an issue, I would love to hear from you. You can reach us from ',
          ),
          TextSpan(
            text: 'Settings > Support.',
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
          const TextSpan(
            text: '\n\nThanks for being here. I hope Sync Focus helps you find a little more time for focused work.',
          ),
        ],
      ),
    );
  }
}

TextStyle _letterStyle(BuildContext context) => AppTypography.body.copyWith(
  color: context.palette.ink,
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.34,
);

class _WelcomeConfetti extends StatefulWidget {
  const _WelcomeConfetti();

  @override
  State<_WelcomeConfetti> createState() => _WelcomeConfettiState();
}

class _WelcomeConfettiState extends State<_WelcomeConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final animation = MediaQuery.disableAnimationsOf(context)
        ? const AlwaysStoppedAnimation<double>(1)
        : _controller;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _WelcomeConfettiPainter(
          progress: animation,
          colors: [
            palette.progressBlue,
            palette.gradientSkyMid,
            palette.accentPreview,
            palette.semanticSuccess,
          ],
        ),
      ),
    );
  }
}

class _WelcomeConfettiPainter extends CustomPainter {
  _WelcomeConfettiPainter({required this.progress, required this.colors})
    : super(repaint: progress);

  final Listenable progress;
  final List<Color> colors;

  static const _pieces = [
    _ConfettiPiece(0.08, 0.22, -44, 34, 0.00, 0),
    _ConfettiPiece(0.22, 0.12, -30, 48, 0.08, 1),
    _ConfettiPiece(0.38, 0.18, -16, 40, 0.14, 2),
    _ConfettiPiece(0.55, 0.10, 10, 52, 0.04, 3),
    _ConfettiPiece(0.72, 0.18, 30, 42, 0.16, 0),
    _ConfettiPiece(0.90, 0.24, 44, 38, 0.10, 1),
    _ConfettiPiece(0.17, 0.38, -35, 54, 0.20, 2),
    _ConfettiPiece(0.34, 0.32, -18, 58, 0.06, 3),
    _ConfettiPiece(0.62, 0.36, 18, 54, 0.12, 0),
    _ConfettiPiece(0.82, 0.34, 36, 52, 0.22, 1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final value = progress is Animation<double>
        ? (progress as Animation<double>).value
        : 1.0;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final piece in _pieces) {
      final local = ((value - piece.delay) / 0.78).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(local);
      final fade = local < 0.75 ? 1.0 : (1 - ((local - 0.75) / 0.25));
      if (fade <= 0) continue;

      final origin = Offset(size.width * piece.x, size.height * piece.y);
      final center =
          origin +
          Offset(
            piece.driftX * eased,
            piece.fallY * eased + 14 * math.sin(eased * math.pi),
          );
      paint.color = colors[piece.colorIndex].withValues(alpha: fade);
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(eased * math.pi * 1.8 + piece.colorIndex);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.colorIndex.isEven ? 9 : 6,
        height: piece.colorIndex.isEven ? 5 : 10,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomeConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

class _ConfettiPiece {
  const _ConfettiPiece(
    this.x,
    this.y,
    this.driftX,
    this.fallY,
    this.delay,
    this.colorIndex,
  );

  final double x;
  final double y;
  final double driftX;
  final double fallY;
  final double delay;
  final int colorIndex;
}
