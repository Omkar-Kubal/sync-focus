import 'package:flutter/material.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/pro/pro_billing_service.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_logo.dart';
import 'package:syncfocus/theme/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

class ProPaywallSheet extends StatelessWidget {
  const ProPaywallSheet({super.key, required this.billing});

  final ProBillingController billing;

  static final _privacyUri = Uri.parse(
    'https://sites.google.com/view/syncfocusprivacypolicy',
  );
  static final _termsUri = Uri.parse(
    'https://sites.google.com/view/sync-focus-legal/terms',
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: billing,
    builder: (context, _) {
      final palette = context.palette;
      final isDark = palette.isDark;
      return SafeArea(
        top: true,
        bottom: false,
        child: FractionallySizedBox(
          heightFactor: 0.9,
          alignment: Alignment.bottomCenter,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: Material(
              color: palette.canvas,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.mutedSoft
                                : AppColors.hairlineStrong,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: const Key('pro-paywall-scroll'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _PaywallHero(),
                              const SizedBox(height: 8),
                              const _ProBenefits(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      _PaywallCheckout(
                        billing: billing,
                        onPrivacy: () => _openLink(context, _privacyUri),
                        onTerms: () => _openLink(context, _termsUri),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 18,
                    right: 20,
                    child: _CloseButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !context.mounted) return;
      _showLinkError(context);
    } on Exception {
      if (context.mounted) _showLinkError(context);
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open this page.')));
  }
}

class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.progressSurface, palette.progressHalo],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
        child: Column(
          children: [
            Container(
              width: 112,
              height: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.progressSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: palette.progressBlue, width: 2),
              ),
              child: AppLogo(
                size: 76,
                backgroundColor: palette.progressHalo,
                semanticLabel: 'Sync Focus circular logo',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unlock Sync Focus Pro',
              textAlign: TextAlign.center,
              style: AppTypography.pageTitle.copyWith(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Focus with fewer distractions and understand your progress over time.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                height: 1.3,
                color: palette.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProBenefits extends StatelessWidget {
  const _ProBenefits();

  static const _features =
      <({List<List<dynamic>> icon, String title, String body})>[
        (
          icon: AppIcons.focusGuard,
          title: 'Focus Guard & Do Not Disturb',
          body: 'Block selected apps and allow only priority interruptions during focus.',
        ),
        (
          icon: AppIcons.tag,
          title: 'Custom task tags',
          body: 'Organize your focus sessions by the work that matters.',
        ),
        (
          icon: AppIcons.progress,
          title: 'Long range insights',
          body: 'See 30 and 90 day trends and focus patterns.',
        ),
        (
          icon: AppIcons.sound,
          title: 'Focus sound controls',
          body: 'Choose ambient sound options for your focus sessions.',
        ),
        (
          icon: AppIcons.darkMode,
          title: 'AMOLED black appearance',
          body: 'Use a deep black surface for a quieter focus screen.',
        ),
      ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Column(
      children: [
        for (var index = 0; index < _features.length; index++) ...[
          _ProBenefitRow(
            icon: _features[index].icon,
            title: _features[index].title,
            body: _features[index].body,
          ),
          if (index < _features.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 64, top: 14, bottom: 14),
              child: Divider(height: 1, color: context.palette.hairline),
            ),
        ],
      ],
    ),
  );
}

class _ProBenefitRow extends StatelessWidget {
  const _ProBenefitRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.progressHalo,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AppIcon(
            icon: icon,
            color: palette.progressBlue,
            size: AppIconSizes.settingsRow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.rowTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppTypography.supporting.copyWith(
                  height: 1.25,
                  color: palette.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaywallCheckout extends StatelessWidget {
  const _PaywallCheckout({
    required this.billing,
    required this.onPrivacy,
    required this.onTerms,
  });

  final ProBillingController billing;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isPro = billing.isPro;
    return DecoratedBox(
      key: const Key('pro-checkout-footer'),
      decoration: BoxDecoration(
        color: palette.canvas,
        border: Border(top: BorderSide(color: palette.hairline)),
        boxShadow: [
          BoxShadow(
            color: palette.ink.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPro)
              _ActiveProSummary(
                palette: palette,
                isTestOverride: billing.isTestOverrideActive,
              )
            else ...[
              _ProPlanChoices(billing: billing, palette: palette),
              const SizedBox(height: 12),
              Text(
                billing.pricingDisclosure,
                textAlign: TextAlign.center,
                style: AppTypography.supporting.copyWith(
                  height: 1.22,
                  color: palette.body,
                ),
              ),
              if (billing.message != null) ...[
                const SizedBox(height: 8),
                Text(
                  billing.message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.supporting.copyWith(
                    color: billing.status == ProBillingStatus.error
                        ? palette.semanticError
                        : palette.body,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: isPro
                    ? () => Navigator.of(context).maybePop()
                    : billing.canPurchase && !billing.isBusy
                    ? billing.buy
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  disabledBackgroundColor: palette.surfaceStrong,
                  disabledForegroundColor: palette.muted,
                  shape: const StadiumBorder(),
                ),
                child: billing.isBusy && !isPro
                    ? SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: palette.muted,
                        ),
                      )
                    : Text(
                        isPro ? 'Start focusing' : _purchaseLabel(billing),
                        style: AppTypography.button.copyWith(
                          color: isPro || billing.canPurchase
                              ? palette.onPrimary
                              : palette.muted,
                        ),
                      ),
              ),
            ),
            if (!isPro) ...[
              TextButton(
                onPressed: billing.status == ProBillingStatus.restoring
                    ? null
                    : billing.restore,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textLink,
                  minimumSize: const Size(48, 44),
                ),
                child: billing.status == ProBillingStatus.restoring
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Restore purchase'),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    icon: AppIcons.privacy,
                    size: AppIconSizes.small,
                    color: palette.body,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Price and payment handled by Google Play',
                      textAlign: TextAlign.center,
                      style: AppTypography.supporting.copyWith(
                        color: palette.body,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: onPrivacy,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textLink,
                      minimumSize: const Size(48, 40),
                    ),
                    child: const Text('Privacy Policy'),
                  ),
                  TextButton(
                    onPressed: onTerms,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textLink,
                      minimumSize: const Size(48, 40),
                    ),
                    child: const Text('Terms'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _purchaseLabel(ProBillingController billing) {
    if (billing.canPurchase && billing.priceLabel.isNotEmpty) {
      return switch (billing.selectedPlan) {
        ProPurchasePlan.yearly => 'Start Pro · ${billing.priceLabel} / year',
        ProPurchasePlan.lifetime => 'Buy Lifetime · ${billing.priceLabel}',
        null => 'Purchase unavailable',
      };
    }
    return billing.status == ProBillingStatus.loading
        ? 'Loading price...'
        : 'Purchase unavailable';
  }
}

class _ProPlanChoices extends StatelessWidget {
  const _ProPlanChoices({required this.billing, required this.palette});

  final ProBillingController billing;
  final AppColorPalette palette;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ProPlanCard(
        plan: ProPurchasePlan.yearly,
        option: _optionFor(ProPurchasePlan.yearly),
        selected: billing.selectedPlan == ProPurchasePlan.yearly,
        palette: palette,
        onSelect: () => billing.selectPlan(ProPurchasePlan.yearly),
      ),
      const SizedBox(height: 10),
      _ProPlanCard(
        plan: ProPurchasePlan.lifetime,
        option: _optionFor(ProPurchasePlan.lifetime),
        selected: billing.selectedPlan == ProPurchasePlan.lifetime,
        palette: palette,
        onSelect: () => billing.selectPlan(ProPurchasePlan.lifetime),
      ),
    ],
  );

  ProPurchaseOption? _optionFor(ProPurchasePlan plan) {
    for (final option in billing.options) {
      if (option.plan == plan) return option;
    }
    return null;
  }
}

class _ProPlanCard extends StatelessWidget {
  const _ProPlanCard({
    required this.plan,
    required this.option,
    required this.selected,
    required this.palette,
    required this.onSelect,
  });

  final ProPurchasePlan plan;
  final ProPurchaseOption? option;
  final bool selected;
  final AppColorPalette palette;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final available = option != null;
    final title = switch (plan) {
      ProPurchasePlan.yearly => 'Yearly',
      ProPurchasePlan.lifetime => 'Lifetime',
    };
    final detail = switch ((plan, available)) {
      (ProPurchasePlan.yearly, true) =>
        'Renews annually · Cancel anytime in Google Play',
      (ProPurchasePlan.yearly, false) => 'Unavailable in Google Play',
      (ProPurchasePlan.lifetime, true) => 'One-time purchase · No renewal',
      (ProPurchasePlan.lifetime, false) => 'Unavailable in Google Play',
    };
    final edge = selected ? palette.progressBlue : palette.hairlineStrong;
    final mainTextColor = available ? palette.ink : palette.muted;
    final detailTextColor = available ? palette.body : palette.muted;

    return Semantics(
      key: Key('pro-plan-${plan.name}-semantics'),
      label: '$title, ${option?.localizedPrice ?? 'Unavailable'}. $detail',
      button: true,
      enabled: available,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      onTap: available ? onSelect : null,
      child: InkWell(
        key: Key('pro-plan-${plan.name}'),
        onTap: available ? onSelect : null,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? palette.progressHalo : palette.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: edge, width: selected ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? palette.progressBlue
                      : palette.surfaceStrong,
                  shape: BoxShape.circle,
                  border: selected
                      ? null
                      : Border.all(color: palette.hairlineStrong),
                ),
                child: selected
                    ? AppIcon(
                        icon: AppIcons.confirm,
                        size: AppIconSizes.small,
                        color: palette.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.rowTitle.copyWith(
                        color: mainTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: AppTypography.supporting.copyWith(
                        color: detailTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                option?.localizedPrice ?? 'Unavailable',
                textAlign: TextAlign.end,
                style: AppTypography.rowTitle.copyWith(
                  color: available ? palette.ink : palette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveProSummary extends StatelessWidget {
  const _ActiveProSummary({
    required this.palette,
    required this.isTestOverride,
  });

  final AppColorPalette palette;
  final bool isTestOverride;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 2),
    child: Column(
      children: [
        AppIcon(
          icon: AppIcons.completed,
          size: 54,
          color: palette.semanticSuccess,
        ),
        const SizedBox(height: 10),
        Text(
          'You’re Pro!',
          style: AppTypography.pageTitle.copyWith(color: palette.ink),
        ),
        const SizedBox(height: 4),
        Text(
          isTestOverride
              ? 'Pro testing access is enabled for this debug build.'
              : 'Your Sync Focus Pro access is active.',
          textAlign: TextAlign.center,
          style: AppTypography.supporting.copyWith(color: palette.body),
        ),
      ],
    ),
  );
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox.square(
      dimension: 46,
      child: IconButton(
        tooltip: 'Close Pro paywall',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: palette.canvas.withValues(alpha: 0.92),
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.hairlineStrong),
          shape: const CircleBorder(),
        ),
        icon: AppIcon(
          icon: AppIcons.close,
          size: AppIconSizes.standard,
          color: palette.ink,
        ),
      ),
    );
  }
}
