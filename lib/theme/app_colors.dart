import 'package:flutter/material.dart';

/// Global palette from the supplied Expo design analysis.
/// Use the active ColorScheme for common roles and these tokens for accents.
abstract final class AppColors {
  static const Color primary = Color(0xFF000000);
  static const Color primaryActive = Color(0xFF1A1A1A);
  static const Color textLink = Color(0xFF0D74CE);
  static const Color textLinkSecondary = Color(0xFF476CFF);

  static const Color ink = Color(0xFF171717);
  static const Color body = Color(0xFF60646C);
  static const Color bodyStrong = Color(0xFF171717);
  static const Color muted = Color(0xFF999999);
  static const Color mutedSoft = Color(0xFFCCCCCC);

  static const Color hairline = Color(0xFFF0F0F3);
  static const Color hairlineSoft = Color(0xFFF5F5F7);
  static const Color hairlineStrong = Color(0xFFDCDEE0);

  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFFAFAFA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceStrong = Color(0xFFF0F0F3);
  static const Color surfaceDark = Color(0xFF171717);
  static const Color surfaceDarkElevated = Color(0xFF1A1A1A);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkSoft = Color(0xFFB0B4BA);

  static const Color gradientSkyLight = Color(0xFFCFE7FF);
  static const Color gradientSkyMid = Color(0xFFA8C8E8);
  static const Color progressBlue = Color(0xFF70A9F7);
  static const Color progressHalo = Color(0xFFE8F3FF);
  static const Color progressSurface = Color(0xFFF7FBFF);
  static const Color progressTrack = Color(0xFFE3E9F0);

  static const Color accentWarning = Color(0xFFAB6400);
  static const Color accentPreview = Color(0xFF8145B5);
  static const Color accentLinkBright = Color(0xFF47C2FF);
  static const Color semanticError = Color(0xFFEB8E90);
  static const Color semanticSuccess = Color(0xFF16A34A);
}

/// Brightness-aware versions of the global tokens used by app surfaces.
/// Accent colors remain recognizable while text, surfaces, and outlines adapt.
@immutable
class AppColorPalette {
  const AppColorPalette._(this.isDark, this.isAmoledBlack);

  factory AppColorPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    return AppColorPalette._(
      theme.brightness == Brightness.dark,
      theme.extension<AppThemeVariant>()?.isAmoledBlack ?? false,
    );
  }

  final bool isDark;
  final bool isAmoledBlack;

  Color get primary => isDark ? AppColors.onDark : AppColors.primary;
  Color get primaryActive =>
      isDark ? const Color(0xFFE6E6E6) : AppColors.primaryActive;
  Color get onPrimary => isDark ? surfaceDark : AppColors.onPrimary;
  Color get textLink =>
      isDark ? AppColors.accentLinkBright : AppColors.textLink;
  Color get textLinkSecondary =>
      isDark ? const Color(0xFF9BB4FF) : AppColors.textLinkSecondary;

  Color get ink => isDark ? AppColors.onDark : AppColors.ink;
  Color get body => isDark ? AppColors.onDarkSoft : AppColors.body;
  Color get bodyStrong => isDark ? AppColors.onDark : AppColors.bodyStrong;
  Color get muted => isDark ? const Color(0xFF858B91) : AppColors.muted;
  Color get mutedSoft => isDark ? const Color(0xFF464B50) : AppColors.mutedSoft;

  Color get hairline => isDark ? const Color(0xFF292D32) : AppColors.hairline;
  Color get hairlineSoft =>
      isDark ? const Color(0xFF22262B) : AppColors.hairlineSoft;
  Color get hairlineStrong =>
      isDark ? const Color(0xFF3B4147) : AppColors.hairlineStrong;

  Color get canvas => isDark
      ? (isAmoledBlack ? Colors.black : AppColors.surfaceDark)
      : AppColors.canvas;
  Color get canvasSoft => isDark
      ? (isAmoledBlack
            ? Colors.black
            : AppColors.surfaceDarkElevated)
      : AppColors.canvasSoft;
  Color get surfaceCard => isDark
      ? (isAmoledBlack ? Colors.black : const Color(0xFF202020))
      : AppColors.surfaceCard;
  Color get surfaceStrong => isDark
      ? (isAmoledBlack ? Colors.black : const Color(0xFF292929))
      : AppColors.surfaceStrong;
  Color get surfaceDark => isAmoledBlack ? Colors.black : AppColors.surfaceDark;
  Color get surfaceDarkElevated =>
      isAmoledBlack ? Colors.black : AppColors.surfaceDarkElevated;
  Color get onDark => AppColors.onDark;
  Color get onDarkSoft => AppColors.onDarkSoft;

  Color get gradientSkyLight =>
      isAmoledBlack
      ? const Color(0xFF0B0B0B)
      : isDark
      ? const Color(0xFF26384A)
      : AppColors.gradientSkyLight;
  Color get gradientSkyMid =>
      isDark ? const Color(0xFF7CAEE5) : AppColors.gradientSkyMid;
  Color get progressBlue =>
      isDark ? const Color(0xFF8AB9FF) : AppColors.progressBlue;
  Color get progressHalo =>
      isAmoledBlack
      ? Colors.black
      : isDark
      ? const Color(0xFF1D2A38)
      : AppColors.progressHalo;
  Color get progressSurface =>
      isAmoledBlack
      ? Colors.black
      : isDark
      ? const Color(0xFF202830)
      : AppColors.progressSurface;
  Color get progressTrack =>
      isAmoledBlack
      ? const Color(0xFF1A1A1A)
      : isDark
      ? const Color(0xFF3B4651)
      : AppColors.progressTrack;

  Color get accentWarning =>
      isDark ? const Color(0xFFFFC76A) : AppColors.accentWarning;
  Color get accentPreview =>
      isDark ? const Color(0xFFC29BED) : AppColors.accentPreview;
  Color get accentLinkBright => AppColors.accentLinkBright;
  Color get semanticError => AppColors.semanticError;
  Color get semanticSuccess =>
      isDark ? const Color(0xFF4ADE80) : AppColors.semanticSuccess;
}

@immutable
class AppThemeVariant extends ThemeExtension<AppThemeVariant> {
  const AppThemeVariant({required this.isAmoledBlack});

  final bool isAmoledBlack;

  @override
  AppThemeVariant copyWith({bool? isAmoledBlack}) =>
      AppThemeVariant(isAmoledBlack: isAmoledBlack ?? this.isAmoledBlack);

  @override
  AppThemeVariant lerp(ThemeExtension<AppThemeVariant>? other, double t) {
    if (other is! AppThemeVariant) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppColorPaletteContext on BuildContext {
  AppColorPalette get palette => AppColorPalette.of(this);
}
