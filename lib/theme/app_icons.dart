import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Icon sizes used by screens. Keep tap-target dimensions in the component.
abstract final class AppIconSizes {
  static const double badge = 13;
  static const double small = 17;
  static const double supporting = 18;
  static const double settingsRow = 21;
  static const double standard = 24;
}

/// Pixel-cat mark used inside the circular Sync Focus logo.
abstract final class AppBrandAssets {
  static const String catMark = 'assets/brand/sync_focus_cat_mark.png';
  static const String catSource = 'assets/brand/sync_focus_cat_source.png';
  static const String catLight = 'assets/brand/sync_focus_cat_light.png';
}

/// Semantic icon roles shared by screens. Every glyph uses Hugeicons' free
/// stroke-rounded set; screens should use [AppIcon] to render them.
abstract final class AppIcons {
  // Primary navigation.
  static const home = HugeIcons.strokeRoundedHome01;
  static const tasks = HugeIcons.strokeRoundedTask01;
  static const progress = HugeIcons.strokeRoundedBarChart;
  static const settings = HugeIcons.strokeRoundedSettings01;

  // Navigation and common actions.
  static const back = HugeIcons.strokeRoundedArrowLeft01;
  static const next = HugeIcons.strokeRoundedArrowRight01;
  static const rowNext = HugeIcons.strokeRoundedArrowRight02;
  static const add = HugeIcons.strokeRoundedAdd01;
  static const minus = HugeIcons.strokeRoundedMinusSign;
  static const crown = HugeIcons.strokeRoundedCrown;
  static const moreActions = HugeIcons.strokeRoundedMore01;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const confirm = HugeIcons.strokeRoundedTick01;
  static const completed = HugeIcons.strokeRoundedCheckmarkCircle01;
  static const calendar = HugeIcons.strokeRoundedCalendar03;
  static const tag = HugeIcons.strokeRoundedTag01;

  // Timer and task controls.
  static const play = HugeIcons.strokeRoundedPlay;
  static const pause = HugeIcons.strokeRoundedPause;
  static const stop = HugeIcons.strokeRoundedStop;
  static const timer = HugeIcons.strokeRoundedTimer01;
  static const schedule = HugeIcons.strokeRoundedClock01;

  // Settings and feature status.
  static const music = HugeIcons.strokeRoundedMusicNote01;
  static const sound = HugeIcons.strokeRoundedAudioWave01;
  static const vibration = HugeIcons.strokeRoundedVibrate;
  static const export = HugeIcons.strokeRoundedDownload01;
  static const locked = HugeIcons.strokeRoundedLock;
  static const doNotDisturb = HugeIcons.strokeRoundedNotificationOff01;
  static const cloudSync = HugeIcons.strokeRoundedCloudSync;
  static const focusGuard = HugeIcons.strokeRoundedSecurity;
  static const installedApp = HugeIcons.strokeRoundedAndroid;
  static const warning = HugeIcons.strokeRoundedAlert01;
  static const breakDuration = HugeIcons.strokeRoundedCoffee01;
  static const lightMode = HugeIcons.strokeRoundedSun03;
  static const darkMode = HugeIcons.strokeRoundedMoon01;
  static const whatsNew = HugeIcons.strokeRoundedNews01;
  static const helpFeedback = HugeIcons.strokeRoundedMessageQuestion;
  static const featureRequest = HugeIcons.strokeRoundedBulb;
  static const supportEmail = HugeIcons.strokeRoundedMail01;
  static const privacy = HugeIcons.strokeRoundedShield01;
  static const externalLink = HugeIcons.strokeRoundedArrowUpRight01;

  // Progress history.
  static const projectSession = HugeIcons.strokeRoundedLaptop;
  static const generalSession = HugeIcons.strokeRoundedFile01;
  static const writingSession = HugeIcons.strokeRoundedNoteEdit;
  static const meetingSession = HugeIcons.strokeRoundedUserGroup;
  static const streak = HugeIcons.strokeRoundedFire;
}

/// Renders a semantic Hugeicon using the surrounding [IconTheme] for color and
/// size. Supply a label for standalone meaning; leave it null beside text.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.icon,
    this.semanticLabel,
    this.size,
    this.color,
    this.strokeWidth,
  });

  final List<List<dynamic>> icon;
  final String? semanticLabel;
  final double? size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final glyph = HugeIcon(
      icon: icon,
      size: size,
      color: color,
      strokeWidth: strokeWidth,
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: glyph)
        : Semantics(label: semanticLabel, image: true, child: glyph);
  }
}
