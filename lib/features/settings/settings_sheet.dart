import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/pro/pro_paywall_sheet.dart';
import 'package:syncfocus/features/focus/ambient_sound.dart';
import 'package:syncfocus/features/settings/settings_controller.dart';
import 'package:syncfocus/features/settings/settings_platform_bridge.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_logo.dart';
import 'package:syncfocus/theme/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class _SettingsIcons {
  static const breakDuration = LucideIcons.timer;
  static const close = LucideIcons.x;
  static const confirm = LucideIcons.check;
  static const crown = LucideIcons.crown;
  static const darkMode = LucideIcons.moon;
  static const dnd = LucideIcons.bellOff;
  static const externalLink = LucideIcons.arrowUpRight;
  static const featureRequest = LucideIcons.lightbulb;
  static const focusGuard = LucideIcons.shieldBan;
  static const helpFeedback = LucideIcons.messageCircleQuestion;
  static const lightMode = LucideIcons.sun;
  static const privacy = LucideIcons.shieldCheck;
  static const rowNext = LucideIcons.chevronRight;
  static const sound = LucideIcons.audioLines;
  static const supportEmail = LucideIcons.mail;
  static const whatsNew = LucideIcons.newspaper;
}

abstract final class FocusGuardFeatureCopy {
  static String selectedAppCount(int count) =>
      'Blocks $count ${count == 1 ? 'app' : 'apps'} during focus sessions';
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.settings,
    required this.proBilling,
    this.platformBridge,
  });

  final SettingsController settings;
  final ProBillingController proBilling;
  final SettingsPlatformBridge? platformBridge;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet>
    with WidgetsBindingObserver {
  static final _privacyUri = Uri.parse(
    'https://sites.google.com/view/syncfocusprivacypolicy',
  );
  static final _featureRequestUri = Uri(
    scheme: 'mailto',
    path: 'omkarkubal@protonmail.com',
    queryParameters: {'subject': 'Sync Focus Feature Request'},
  );
  static final _supportEmailUri = Uri(
    scheme: 'mailto',
    path: 'omkarkubal@protonmail.com',
    queryParameters: {'subject': 'Sync Focus Support'},
  );
  late final SettingsPlatformBridge _platform;
  bool _dndAccessGranted = false;
  FocusGuardAccess _focusGuardAccess = const FocusGuardAccess(
    usageAccess: false,
    overlayAccess: false,
  );
  List<LaunchableApp> _launchableApps = const [];

  @override
  void initState() {
    super.initState();
    _platform = widget.platformBridge ?? SettingsPlatformBridge();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshAndroidSettings());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAndroidSettings());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshAndroidSettings() async {
    if (!_platform.isSupported) return;
    try {
      final results = await Future.wait<Object>([
        _platform.hasDndAccess(),
        _platform.getFocusGuardAccess(),
        _platform.getLaunchableApps(),
      ]);
      if (!mounted) return;
      final dndAccess = results[0] as bool;
      final focusGuardAccess = results[1] as FocusGuardAccess;
      if (!dndAccess && widget.settings.isDndEnabled) {
        await widget.settings.setDndEnabled(false);
      }
      if (!focusGuardAccess.isGranted &&
          widget.settings.isFocusGuardEnabled) {
        await widget.settings.setFocusGuard(enabled: false);
      }
      if (!mounted) return;
      setState(() {
        _dndAccessGranted = dndAccess;
        _focusGuardAccess = focusGuardAccess;
        _launchableApps = results[2] as List<LaunchableApp>;
      });
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      debugPrint('Settings permissions could not be checked: ${error.message}');
    }
  }

  Future<void> _toggleDnd(bool enabled) async {
    if (!widget.proBilling.isPro) {
      _showProDetails();
      return;
    }
    if (!_platform.isSupported) {
      _showMessage('Do Not Disturb automation is available on Android.');
      return;
    }
    if (!enabled) {
      await widget.settings.setDndEnabled(false);
      return;
    }
    try {
      _dndAccessGranted = await _platform.hasDndAccess();
      if (!mounted) return;
      if (_dndAccessGranted) {
        await widget.settings.setDndEnabled(true);
        return;
      }
      final granted = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _DndPermissionSheet(platform: _platform),
      );
      if (granted == true && mounted) {
        _dndAccessGranted = true;
        await widget.settings.setDndEnabled(true);
        setState(() {});
      }
    } on MissingPluginException {
      _showMessage('Android settings are unavailable on this device.');
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Could not open Do Not Disturb access.');
    }
  }

  void _openFocusGuard() {
    if (!widget.proBilling.isPro) {
      _showProDetails();
      return;
    }
    if (!_platform.isSupported) {
      _showMessage('Focus Guard is available on Android.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FocusGuardSetupSheet(
        settings: widget.settings,
        platform: _platform,
        apps: _launchableApps,
        access: _focusGuardAccess,
      ),
    ).whenComplete(_refreshAndroidSettings);
  }

  void _openSoundPicker() {
    if (!widget.proBilling.isPro) {
      _showProDetails();
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AmbientSoundSheet(
        selected: widget.settings.ambientSound,
        onSelected: widget.settings.setAmbientSound,
      ),
    );
  }

  Future<void> _showBreakPicker() async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BreakDurationSheet(
        selectedMinutes: widget.settings.breakDurationMinutes,
      ),
    );
    if (minutes != null) {
      await widget.settings.setBreakDurationMinutes(minutes);
    }
  }

  void _showProDetails() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProPaywallSheet(billing: widget.proBilling),
    );
  }

  void _showWhatsNew() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WhatsNewSheet(),
    );
  }

  void _showHelpFeedback() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HelpFeedbackSheet(
        onFeatureRequest: () =>
            _openExternal(_featureRequestUri, 'Could not open your email app.'),
        onSupportEmail: () =>
            _openExternal(_supportEmailUri, 'Could not open your email app.'),
      ),
    );
  }

  Future<void> _openExternal(Uri uri, String unavailableMessage) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
      _showMessage(unavailableMessage);
    } on Exception {
      if (mounted) _showMessage(unavailableMessage);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.settings, widget.proBilling]),
    builder: (context, _) {
      final isDark = !widget.settings.isLightMode;
      final sheetColor = isDark
          ? context.palette.surfaceDark
          : context.palette.canvas;

      return FractionallySizedBox(
        heightFactor: 0.95,
        alignment: Alignment.bottomCenter,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: sheetColor,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: Material(
            color: sheetColor,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 104,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.palette.body
                          : context.palette.mutedSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 20, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Settings',
                            style: AppTypography.pageTitle.copyWith(
                              color: isDark
                                  ? context.palette.onDark
                                  : context.palette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close settings',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            _SettingsIcons.close,
                            size: 24,
                            color: isDark
                                ? context.palette.onDarkSoft
                                : context.palette.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 2, 22, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProBanner(
                            onExplore: _showProDetails,
                            isPro: widget.proBilling.isPro,
                          ),
                          const SizedBox(height: 18),
                          _SectionLabel(label: 'BREAK'),
                          _SettingsCard(
                            child: _SettingsRow(
                              icon: _SettingsIcons.breakDuration,
                              title: 'Break duration',
                              subtitle: 'Length of a break',
                              onTap: _showBreakPicker,
                              trailing: _ValueAndChevron(
                                value:
                                    '${widget.settings.breakDurationMinutes} min',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(label: 'FOCUS GUARD'),
                          _FocusGuardCard(
                            onTap: _openFocusGuard,
                            isPro: widget.proBilling.isPro,
                            isAndroid: _platform.isSupported,
                            isEnabled: widget.settings.isFocusGuardEnabled,
                            blockedAppCount: widget.settings.blockedApps.length,
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(label: 'DO NOT DISTURB'),
                          _SettingsCard(
                            child: _SettingsRow(
                              icon: _SettingsIcons.dnd,
                              title: 'Do Not Disturb',
                              subtitle: !widget.proBilling.isPro
                                  ? 'Allow priority interruptions during focus'
                                  : !_platform.isSupported
                                  ? 'Available on Android'
                                  : _dndAccessGranted
                                  ? 'Use Priority mode while focus is running'
                                  : 'Grant Android access to enable during focus',
                              onTap: () =>
                                  _toggleDnd(!widget.settings.isDndEnabled),
                              trailing: !widget.proBilling.isPro
                                  ? const _ProAndChevron()
                                  : !_platform.isSupported
                                  ? const _AndroidOnlyLabel()
                                  : Switch(
                                      value: widget.settings.isDndEnabled,
                                      onChanged: (value) =>
                                          unawaited(_toggleDnd(value)),
                                      activeTrackColor:
                                          context.palette.textLink,
                                      activeThumbColor:
                                          context.palette.onPrimary,
                                      inactiveThumbColor:
                                          context.palette.onPrimary,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(label: 'SOUND'),
                          _SettingsCard(
                            child: _SettingsRow(
                              icon: _SettingsIcons.sound,
                              title: 'Focus sound',
                              subtitle: widget.proBilling.isPro
                                  ? '${widget.settings.ambientSound.label} · device media volume'
                                  : 'Rain by default · device media volume',
                              onTap: _openSoundPicker,
                              trailing: widget.proBilling.isPro
                                  ? const _Chevron()
                                  : const _ProAndChevron(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(label: 'APPEARANCE'),
                          _SettingsCard(
                            child: Column(
                              children: [
                                _SettingsRow(
                                  icon: _SettingsIcons.lightMode,
                                  title: 'Light mode',
                                  subtitle: 'Use the light color palette',
                                  trailing: Switch(
                                    value: widget.settings.isLightMode,
                                    onChanged: (value) => unawaited(
                                      widget.settings.setLightMode(value),
                                    ),
                                    activeTrackColor: context.palette.textLink,
                                    activeThumbColor: context.palette.onPrimary,
                                    inactiveTrackColor: isDark
                                        ? context.palette.body
                                        : context.palette.surfaceStrong,
                                    inactiveThumbColor:
                                        context.palette.onPrimary,
                                    trackOutlineColor:
                                        WidgetStateProperty.resolveWith(
                                          (states) =>
                                              states.contains(
                                                WidgetState.selected,
                                              )
                                              ? context.palette.textLink
                                              : context.palette.hairlineStrong,
                                        ),
                                  ),
                                ),
                                const _SettingsDivider(),
                                _SettingsRow(
                                  icon: _SettingsIcons.darkMode,
                                  title: 'AMOLED black',
                                  subtitle: widget.proBilling.isPro
                                      ? 'Use pure black surfaces'
                                      : 'Pro feature',
                                  onTap: widget.proBilling.isPro
                                      ? () => unawaited(
                                          widget.settings.setAmoledBlack(
                                            !widget.settings.isAmoledBlack,
                                          ),
                                        )
                                      : _showProDetails,
                                  trailing: widget.proBilling.isPro
                                      ? Switch(
                                          value: widget.settings.isAmoledBlack,
                                          onChanged: (value) => unawaited(
                                            widget.settings.setAmoledBlack(
                                              value,
                                            ),
                                          ),
                                          activeTrackColor:
                                              context.palette.textLink,
                                          activeThumbColor:
                                              context.palette.onPrimary,
                                          inactiveThumbColor:
                                              context.palette.onPrimary,
                                        )
                                      : const _ProAndChevron(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionLabel(label: 'SUPPORT'),
                          _SettingsCard(
                            child: Column(
                              children: [
                                _SettingsRow(
                                  icon: _SettingsIcons.whatsNew,
                                  title: "What's New",
                                  subtitle: 'Latest: Set focus time manually or from a task on the same ring.',
                                  onTap: _showWhatsNew,
                                  trailing: const _Chevron(),
                                ),
                                const _SettingsDivider(),
                                _SettingsRow(
                                  icon: _SettingsIcons.helpFeedback,
                                  title: 'Help & Feedback',
                                  subtitle: '',
                                  onTap: _showHelpFeedback,
                                  trailing: const _Chevron(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _BrandCard(),
                          const SizedBox(height: 16),
                          _SectionLabel(label: 'ABOUT'),
                          _SettingsCard(
                            child: _SettingsRow(
                              icon: _SettingsIcons.privacy,
                              title: 'Privacy Policy',
                              subtitle: 'How Sync Focus handles your data',
                              onTap: () => _openExternal(
                                _privacyUri,
                                'Could not open the privacy policy.',
                              ),
                              trailing: Icon(
                                _SettingsIcons.externalLink,
                                size: AppIconSizes.standard,
                                color: isDark
                                    ? context.palette.onDarkSoft
                                    : context.palette.body,
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
          ),
        ),
      );
    },
  );
}

class _ProBanner extends StatelessWidget {
  const _ProBanner({required this.onExplore, required this.isPro});

  final VoidCallback onExplore;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? context.palette.surfaceDarkElevated
            : context.palette.progressSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _IconTile(
            icon: _SettingsIcons.crown,
            size: 48,
            iconSize: 25,
            tint: context.palette.textLink,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNC FOCUS PRO',
                  style: AppTypography.button.copyWith(
                    color: context.palette.textLink,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPro
                      ? 'Your focus tools are unlocked.'
                      : 'More tools to stay focused.',
                  style: AppTypography.bodyTitle.copyWith(
                    color: isDark
                        ? context.palette.onDark
                        : context.palette.ink,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Focus Guard, Do Not Disturb, extra sounds, and AMOLED black.',
                  style: AppTypography.supporting.copyWith(
                    color: isDark
                        ? context.palette.onDarkSoft
                        : context.palette.body,
                    fontSize: 12,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            height: 42,
            child: FilledButton(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: const StadiumBorder(),
              ),
              child: Text(
                isPro ? 'Manage Pro' : 'Explore Pro',
                style: AppTypography.button.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusGuardCard extends StatelessWidget {
  const _FocusGuardCard({
    required this.onTap,
    required this.isPro,
    required this.isAndroid,
    required this.isEnabled,
    required this.blockedAppCount,
  });

  final VoidCallback onTap;
  final bool isPro;
  final bool isAndroid;
  final bool isEnabled;
  final int blockedAppCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? context.palette.surfaceDarkElevated
          : context.palette.progressSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? context.palette.surfaceDarkElevated
                  : context.palette.hairline,
            ),
          ),
          child: Row(
            children: [
              _IconTile(
                icon: _SettingsIcons.focusGuard,
                size: 48,
                iconSize: AppIconSizes.standard,
                tint: context.palette.textLink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Block distracting apps',
                      style: AppTypography.bodyTitle.copyWith(
                        color: isDark
                            ? context.palette.onDark
                            : context.palette.ink,
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      !isAndroid
                          ? 'Android only'
                          : isPro && isEnabled
                          ? FocusGuardFeatureCopy.selectedAppCount(
                              blockedAppCount,
                            )
                          : isPro
                          ? 'Choose apps to block during focus sessions'
                          : 'Android only · Pro feature',
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? context.palette.onDarkSoft
                            : context.palette.body,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isPro) const _ProPill(),
              const SizedBox(width: 6),
              _Chevron(
                color: isDark
                    ? context.palette.onDarkSoft
                    : context.palette.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProPill extends StatelessWidget {
  const _ProPill();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? context.palette.surfaceDark
            : context.palette.progressHalo,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _SettingsIcons.crown,
            size: AppIconSizes.badge,
            color: context.palette.textLink,
          ),
          const SizedBox(width: 4),
          Text(
            'Pro',
            style: AppTypography.button.copyWith(
              fontSize: 12,
              height: 1,
              color: context.palette.textLink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProAndChevron extends StatelessWidget {
  const _ProAndChevron();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ProPill(),
        const SizedBox(width: 6),
        _Chevron(
          color: isDark ? context.palette.onDarkSoft : context.palette.body,
        ),
      ],
    );
  }
}

class _AndroidOnlyLabel extends StatelessWidget {
  const _AndroidOnlyLabel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: context.palette.surfaceStrong,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      'Android',
      style: AppTypography.button.copyWith(
        fontSize: 11,
        color: context.palette.body,
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(
        label,
        style: AppTypography.sectionLabel.copyWith(
          color: isDark ? context.palette.onDarkSoft : context.palette.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? context.palette.surfaceDark
            : context.palette.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? context.palette.surfaceDarkElevated
              : context.palette.hairlineStrong,
        ),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(17), child: child),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? context.palette.onDark : context.palette.ink;
    final bodyColor = isDark
        ? context.palette.onDarkSoft
        : context.palette.body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _IconTile(
                icon: icon,
                size: 48,
                iconSize: AppIconSizes.standard,
                tint: context.palette.textLink,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyTitle.copyWith(
                        color: titleColor,
                        fontSize: 16,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: bodyColor,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.tint,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? context.palette.surfaceDarkElevated
            : context.palette.progressHalo,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: tint),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 14,
      color: isDark
          ? context.palette.surfaceDarkElevated
          : context.palette.hairline,
    );
  }
}

class _ValueAndChevron extends StatelessWidget {
  const _ValueAndChevron({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.bodyTitle.copyWith(
            color: isDark ? context.palette.onDarkSoft : context.palette.body,
          ),
        ),
        const SizedBox(width: 8),
        _Chevron(
          color: isDark ? context.palette.onDarkSoft : context.palette.body,
        ),
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => Icon(
    _SettingsIcons.rowNext,
    size: AppIconSizes.standard,
    color: color ?? context.palette.body,
  );
}

class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? context.palette.surfaceDark
            : context.palette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? context.palette.surfaceDarkElevated
              : context.palette.hairlineStrong,
        ),
      ),
      child: Row(
        children: [
          const AppLogo(
            size: 68,
            asset: AppBrandAssets.catMark,
            semanticLabel: 'Sync Focus logo',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Focus',
                  style: AppTypography.cardTitle.copyWith(
                    color: isDark
                        ? context.palette.onDark
                        : context.palette.ink,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A calmer place to focus',
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? context.palette.onDarkSoft
                        : context.palette.body,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0+1',
                  style: AppTypography.supporting.copyWith(
                    color: isDark
                        ? context.palette.body
                        : context.palette.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakDurationSheet extends StatelessWidget {
  const _BreakDurationSheet({required this.selectedMinutes});

  final int selectedMinutes;
  static const _choices = [5, 10, 15, 20, 25];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SmallSettingsSheet(
      title: 'Break duration',
      subtitle: null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final minutes in _choices)
            ListTile(
              title: Text('$minutes minutes'),
              trailing: minutes == selectedMinutes
                  ? Icon(
                      _SettingsIcons.confirm,
                      color: context.palette.textLink,
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(minutes),
              textColor: isDark ? context.palette.onDark : context.palette.ink,
            ),
        ],
      ),
    );
  }
}

class _AmbientSoundSheet extends StatelessWidget {
  const _AmbientSoundSheet({required this.selected, required this.onSelected});

  final AmbientSound selected;
  final ValueChanged<AmbientSound> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SmallSettingsSheet(
      title: 'Focus sound',
      subtitle: 'Sound follows your focus timer. Adjust volume on your device.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final sound in AmbientSound.values)
            ListTile(
              key: Key('ambient-sound-${sound.name}'),
              leading: Icon(
                sound == selected
                    ? _SettingsIcons.confirm
                    : _SettingsIcons.sound,
                color: context.palette.textLink,
              ),
              title: Text(sound.label),
              subtitle: sound.requiresPro ? const Text('Pro') : null,
              trailing: sound == selected
                  ? Icon(
                      _SettingsIcons.confirm,
                      color: context.palette.textLink,
                    )
                  : null,
              onTap: () {
                onSelected(sound);
                Navigator.of(context).pop();
              },
              textColor: isDark ? context.palette.onDark : context.palette.ink,
            ),
        ],
      ),
    );
  }
}

class _DndPermissionSheet extends StatefulWidget {
  const _DndPermissionSheet({required this.platform});

  final SettingsPlatformBridge platform;

  @override
  State<_DndPermissionSheet> createState() => _DndPermissionSheetState();
}

class _DndPermissionSheetState extends State<_DndPermissionSheet>
    with WidgetsBindingObserver {
  bool _hasAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final hasAccess = await widget.platform.hasDndAccess();
      if (!mounted) return;
      setState(() {
        _hasAccess = hasAccess;
        _isLoading = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not check DND access.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _SupportSheetFrame(
    title: 'Do Not Disturb',
    heightFactor: 0.47,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sync Focus uses Android Priority mode while a focus session is running. Your previous interruption filter is restored when you pause or finish.',
          style: AppTypography.body.copyWith(color: context.palette.body),
        ),
        const SizedBox(height: 18),
        _PermissionStatusRow(
          title: 'Notification policy access',
          isGranted: _hasAccess,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 18),
        if (_hasAccess)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable during focus'),
          )
        else
          OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await widget.platform.requestDndAccess();
                    } on PlatformException catch (error) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            error.message ?? 'Could not open Android settings.',
                          ),
                        ),
                      );
                    }
                  },
            icon: const Icon(_SettingsIcons.externalLink),
            label: const Text('Open notification access settings'),
          ),
      ],
    ),
  );
}

class _FocusGuardSetupSheet extends StatefulWidget {
  const _FocusGuardSetupSheet({
    required this.settings,
    required this.platform,
    required this.apps,
    required this.access,
  });

  final SettingsController settings;
  final SettingsPlatformBridge platform;
  final List<LaunchableApp> apps;
  final FocusGuardAccess access;

  @override
  State<_FocusGuardSetupSheet> createState() => _FocusGuardSetupSheetState();
}

class _FocusGuardSetupSheetState extends State<_FocusGuardSetupSheet>
    with WidgetsBindingObserver {
  late Set<String> _selectedPackages;
  late FocusGuardAccess _access;
  List<LaunchableApp> _apps = const [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPackages = Set.of(widget.settings.blockedApps);
    _access = widget.access;
    _apps = widget.apps;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final values = await Future.wait<Object>([
        widget.platform.getFocusGuardAccess(),
        widget.platform.getLaunchableApps(),
      ]);
      if (!mounted) return;
      setState(() {
        _access = values[0] as FocusGuardAccess;
        _apps = values[1] as List<LaunchableApp>;
        _isLoading = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not load apps.')),
      );
    }
  }

  Future<void> _requestPermission(Future<void> Function() request) async {
    try {
      await request();
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not open Android settings.'),
        ),
      );
    }
  }

  Future<void> _saveSelection() async {
    setState(() => _isSaving = true);
    final enabled = _access.isGranted && _selectedPackages.isNotEmpty;
    await widget.settings.setFocusGuard(
      enabled: enabled,
      blockedApps: _selectedPackages,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FractionallySizedBox(
      heightFactor: 0.9,
      alignment: Alignment.bottomCenter,
      child: Material(
        key: const Key('focus-guard-setup-sheet'),
        color: context.palette.canvas,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 72,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? context.palette.body
                      : context.palette.mutedSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Focus Guard',
                        style: AppTypography.pageTitle.copyWith(
                          color: context.palette.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close Focus Guard',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(_SettingsIcons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose apps to block only while your focus timer is running.',
                      style: AppTypography.body.copyWith(
                        color: context.palette.body,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PermissionStatusRow(
                      title: 'Usage Access',
                      isGranted: _access.usageAccess,
                      isLoading: _isLoading,
                      onTap: () => _requestPermission(
                        widget.platform.requestUsageAccess,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PermissionStatusRow(
                      title: 'Display over other apps',
                      isGranted: _access.overlayAccess,
                      isLoading: _isLoading,
                      onTap: () => _requestPermission(
                        widget.platform.requestOverlayAccess,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Apps to block',
                            style: AppTypography.bodyTitle.copyWith(
                              color: context.palette.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${_selectedPackages.length} selected',
                          style: AppTypography.supporting.copyWith(
                            color: context.palette.body,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _apps.isEmpty
                    ? Center(
                        child: Text(
                          _isLoading
                              ? 'Loading installed apps…'
                              : 'No launchable apps found.',
                          style: AppTypography.body.copyWith(
                            color: context.palette.body,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _apps.length,
                        itemBuilder: (context, index) {
                          final app = _apps[index];
                          final selected = _selectedPackages.contains(
                            app.packageName,
                          );
                          return CheckboxListTile(
                            key: Key('focus-guard-app-${app.packageName}'),
                            value: selected,
                            onChanged: (value) => setState(() {
                              if (value == true) {
                                _selectedPackages.add(app.packageName);
                              } else {
                                _selectedPackages.remove(app.packageName);
                              }
                            }),
                            secondary: app.iconBytes == null
                                ? const CircleAvatar(
                                    child: Icon(Icons.apps_outlined),
                                  )
                                : CircleAvatar(
                                    backgroundImage: MemoryImage(
                                      app.iconBytes!,
                                    ),
                                  ),
                            title: Text(app.label),
                            subtitle: Text(
                              app.packageName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                            activeColor: context.palette.textLink,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: FilledButton(
                  key: const Key('focus-guard-save'),
                  onPressed: _isSaving ? null : _saveSelection,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(
                    _access.isGranted && _selectedPackages.isNotEmpty
                        ? 'Save and enable Focus Guard'
                        : 'Save app selection',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionStatusRow extends StatelessWidget {
  const _PermissionStatusRow({
    required this.title,
    required this.isGranted,
    required this.isLoading,
    this.onTap,
  });

  final String title;
  final bool isGranted;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: context.palette.surfaceStrong,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isGranted || isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isGranted ? _SettingsIcons.confirm : _SettingsIcons.privacy,
                size: 20,
                color: isGranted
                    ? context.palette.semanticSuccess
                    : context.palette.textLink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? context.palette.onDark
                        : context.palette.ink,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  isGranted ? 'Allowed' : 'Grant',
                  style: AppTypography.button.copyWith(
                    color: isGranted
                        ? context.palette.semanticSuccess
                        : context.palette.textLink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsNewSheet extends StatelessWidget {
  const _WhatsNewSheet();

  static const _release = _SyncFocusRelease(
    version: 'v1.0.0',
    label: 'Initial release',
    features: [
      _SyncFocusReleaseFeature(
        title: 'One focus ring',
        description: 'Set time manually or from a task, then follow the countdown in the same ring.',
      ),
      _SyncFocusReleaseFeature(
        title: 'Tasks that start focus',
        description: 'Plan a task with its own focus duration and send it straight to the timer.',
      ),
      _SyncFocusReleaseFeature(
        title: 'Progress from real sessions',
        description:
            'Review completed focus time, weekly totals, and recent sessions.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => const _SupportSheetFrame(
    title: "What's New",
    heightFactor: 0.54,
    child: _WhatsNewReleaseCard(release: _release),
  );
}

class _SyncFocusRelease {
  const _SyncFocusRelease({
    required this.version,
    required this.label,
    required this.features,
  });

  final String version;
  final String label;
  final List<_SyncFocusReleaseFeature> features;
}

class _SyncFocusReleaseFeature {
  const _SyncFocusReleaseFeature({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class _WhatsNewReleaseCard extends StatelessWidget {
  const _WhatsNewReleaseCard({required this.release});

  final _SyncFocusRelease release;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? context.palette.surfaceDarkElevated
            : context.palette.progressSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                release.version,
                style: AppTypography.cardTitle.copyWith(
                  color: isDark ? context.palette.onDark : context.palette.ink,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? context.palette.onDarkSoft
                      : context.palette.body,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  release.label,
                  style: AppTypography.supporting.copyWith(
                    color: isDark
                        ? context.palette.onDarkSoft
                        : context.palette.body,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < release.features.length; index++) ...[
            _WhatsNewFeatureRow(feature: release.features[index]),
            if (index < release.features.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _WhatsNewFeatureRow extends StatelessWidget {
  const _WhatsNewFeatureRow({required this.feature});

  final _SyncFocusReleaseFeature feature;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? context.palette.onDarkSoft : context.palette.body,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: AppTypography.bodyTitle.copyWith(
                  color: isDark ? context.palette.onDark : context.palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature.description,
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? context.palette.onDarkSoft
                      : context.palette.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HelpFeedbackSheet extends StatelessWidget {
  const _HelpFeedbackSheet({
    required this.onFeatureRequest,
    required this.onSupportEmail,
  });

  final VoidCallback onFeatureRequest;
  final VoidCallback onSupportEmail;

  @override
  Widget build(BuildContext context) => _SupportSheetFrame(
    title: 'Help & Feedback',
    heightFactor: 0.4,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel(label: 'SUPPORT'),
        _SettingsCard(
          child: Column(
            children: [
              _SettingsRow(
                icon: _SettingsIcons.featureRequest,
                title: 'Feature Requests',
                subtitle: '',
                onTap: onFeatureRequest,
                trailing: Icon(
                  _SettingsIcons.externalLink,
                  size: AppIconSizes.standard,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.palette.onDarkSoft
                      : context.palette.body,
                ),
              ),
              const _SettingsDivider(),
              _SettingsRow(
                icon: _SettingsIcons.supportEmail,
                title: 'Support Email',
                subtitle: '',
                onTap: onSupportEmail,
                trailing: Icon(
                  _SettingsIcons.externalLink,
                  size: AppIconSizes.standard,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? context.palette.onDarkSoft
                      : context.palette.body,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SupportSheetFrame extends StatelessWidget {
  const _SupportSheetFrame({
    required this.title,
    required this.heightFactor,
    required this.child,
  });

  final String title;
  final double heightFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FractionallySizedBox(
      heightFactor: heightFactor,
      alignment: Alignment.bottomCenter,
      child: Material(
        color: isDark ? context.palette.surfaceDark : context.palette.canvas,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.palette.body
                          : context.palette.mutedSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.pageTitle.copyWith(
                          color: isDark
                              ? context.palette.onDark
                              : context.palette.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close $title',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        _SettingsIcons.close,
                        color: isDark
                            ? context.palette.onDarkSoft
                            : context.palette.body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallSettingsSheet extends StatelessWidget {
  const _SmallSettingsSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FractionallySizedBox(
      heightFactor: 0.54,
      alignment: Alignment.bottomCenter,
      child: Material(
        color: isDark ? context.palette.surfaceDark : context.palette.canvas,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.palette.body
                          : context.palette.mutedSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTypography.pageTitle.copyWith(
                    color: isDark
                        ? context.palette.onDark
                        : context.palette.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: AppTypography.body.copyWith(
                      color: isDark
                          ? context.palette.onDarkSoft
                          : context.palette.body,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                child,
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? context.palette.onDark
                        : context.palette.ink,
                    side: BorderSide(
                      color: isDark
                          ? context.palette.body
                          : context.palette.hairlineStrong,
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
