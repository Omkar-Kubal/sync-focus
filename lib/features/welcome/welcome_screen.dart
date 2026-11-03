import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_logo.dart';
import 'package:syncfocus/theme/app_typography.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      key: const Key('first-run-welcome'),
      backgroundColor: palette.canvasSoft,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 680;
            const topInset = 24.0;
            const bottomInset = 20.0;
            final heroHeight = math.min(
              compact ? 320.0 : 400.0,
              math.max(compact ? 270.0 : 320.0, constraints.maxHeight * 0.48),
            );

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  topInset,
                  20,
                  bottomInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight - topInset - bottomInset,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: heroHeight,
                        child: AnimatedBuilder(
                          animation: _entryController,
                          builder: (context, child) => _WelcomeIllustration(
                            progress: disableAnimations
                                ? 1
                                : _entryController.value,
                            compact: compact,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Welcome to Sync Focus',
                                textAlign: TextAlign.center,
                                style: AppTypography.pageTitle.copyWith(
                                  fontSize: compact ? 28 : 30,
                                  fontWeight: FontWeight.w700,
                                  height: 1.12,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A calmer way to focus,\none session at a time.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              fontSize: 16,
                              height: 1.3,
                              color: palette.body,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: math.min(320, constraints.maxWidth - 40),
                        height: 58,
                        child: FilledButton(
                          key: const Key('welcome-get-started'),
                          onPressed: widget.onGetStarted,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.primary,
                            foregroundColor: palette.onPrimary,
                            shape: const StadiumBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: AppTypography.cardTitle.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              AppIcon(
                                icon: AppIcons.next,
                                size: AppIconSizes.small,
                                color: palette.onPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration({required this.progress, required this.compact});

  final double progress;
  final bool compact;

  static const _previews =
      <({List<List<dynamic>> icon, String title, String time})>[
        (icon: AppIcons.timer, title: 'Deep work', time: '25 min'),
        (icon: AppIcons.tasks, title: 'Read chapter', time: '40 min'),
        (icon: AppIcons.progress, title: 'Plan the day', time: '15 min'),
      ];

  @override
  Widget build(BuildContext context) {
    final cardGap = compact ? 12.0 : 16.0;
    final cardHeight = compact ? 56.0 : 64.0;
    final logoSize = compact ? 72.0 : 82.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            for (var index = 0; index < _previews.length; index++) ...[
              _WelcomePreviewCard(
                preview: _previews[index],
                index: index,
                progress: progress,
                height: cardHeight,
              ),
              if (index < _previews.length - 1) SizedBox(height: cardGap),
            ],
          ],
        ),
        SizedBox(height: compact ? 12 : 16),
        AppLogo(size: logoSize, semanticLabel: 'Sync Focus logo'),
      ],
    );
  }
}

class _WelcomePreviewCard extends StatelessWidget {
  const _WelcomePreviewCard({
    required this.preview,
    required this.index,
    required this.progress,
    required this.height,
  });

  final ({List<List<dynamic>> icon, String title, String time}) preview;
  final int index;
  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entry = ((progress - index * 0.12) / 0.64).clamp(0.0, 1.0);
    final easedEntry = Curves.easeOutCubic.transform(entry);

    return Transform.translate(
      offset: Offset(0, 28 * (1 - easedEntry)),
      child: Opacity(
        opacity: (0.3 + easedEntry * 0.7).clamp(0.0, 1.0),
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 34),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surfaceCard,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: palette.ink.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: height - 20,
                height: height - 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.progressHalo,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppIcon(
                  icon: preview.icon,
                  size: AppIconSizes.standard,
                  color: palette.progressBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  preview.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                preview.time,
                style: AppTypography.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
