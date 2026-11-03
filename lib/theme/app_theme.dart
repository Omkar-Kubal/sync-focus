import 'package:flutter/material.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';
import 'package:syncfocus/theme/app_typography.dart';

/// App-wide Material mapping for the supplied color tokens.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    dividerColor: AppColors.hairline,
    textTheme: AppTypography.materialTextTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    iconTheme: const IconThemeData(size: AppIconSizes.standard),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.surfaceStrong,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.textLink,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.gradientSkyLight,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.accentPreview,
      onTertiary: AppColors.onPrimary,
      error: AppColors.semanticError,
      onError: AppColors.ink,
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.canvas,
      surfaceContainerLow: AppColors.canvasSoft,
      surfaceContainer: AppColors.hairlineSoft,
      surfaceContainerHigh: AppColors.surfaceStrong,
      outline: AppColors.hairlineStrong,
      outlineVariant: AppColors.hairline,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.canvas,
      modalBackgroundColor: AppColors.canvas,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.canvas),
    extensions: const [AppThemeVariant(isAmoledBlack: false)],
  );

  /// Dark mapping uses the supplied dark surfaces and on-dark text tokens.
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surfaceDark,
    dividerColor: AppColors.surfaceDarkElevated,
    textTheme: AppTypography.materialTextTheme.apply(
      bodyColor: AppColors.onDark,
      displayColor: AppColors.onDark,
    ),
    iconTheme: const IconThemeData(size: AppIconSizes.standard),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.onDark,
      onPrimary: AppColors.primary,
      primaryContainer: AppColors.surfaceDarkElevated,
      onPrimaryContainer: AppColors.onDark,
      secondary: AppColors.accentLinkBright,
      onSecondary: AppColors.primary,
      secondaryContainer: Color(0xFF26384A),
      onSecondaryContainer: AppColors.onDark,
      tertiary: AppColors.gradientSkyMid,
      onTertiary: AppColors.ink,
      error: AppColors.semanticError,
      onError: AppColors.ink,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onDark,
      surfaceContainerLow: AppColors.surfaceDark,
      surfaceContainer: AppColors.surfaceDarkElevated,
      surfaceContainerHigh: AppColors.surfaceDarkElevated,
      outline: AppColors.body,
      outlineVariant: AppColors.surfaceDarkElevated,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      modalBackgroundColor: AppColors.surfaceDark,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceDarkElevated,
    ),
    extensions: const [AppThemeVariant(isAmoledBlack: false)],
  );

  static ThemeData get amoledBlack {
    final dark = AppTheme.dark;
    return dark.copyWith(
      scaffoldBackgroundColor: Colors.black,
      dividerColor: const Color(0xFF111111),
      colorScheme: dark.colorScheme.copyWith(
        surface: Colors.black,
        surfaceContainerLow: Colors.black,
        primaryContainer: Colors.black,
        surfaceContainer: Colors.black,
        surfaceContainerHigh: Colors.black,
        outlineVariant: const Color(0xFF161616),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.black,
        modalBackgroundColor: Colors.black,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: Colors.black),
      extensions: const [AppThemeVariant(isAmoledBlack: true)],
    );
  }
}
