import 'package:flutter/material.dart';

/// Primitive sizes retained from the Android type scale.
abstract final class AppTypeScale {
  static const double xSmall = 12;
  static const double small = 14;
  static const double medium = 16;
  static const double large = 22;
  static const double xLarge = 28;
  static const double xxLarge = 32;
}

/// Semantic styles for Sync Focus screens and their Material counterparts.
/// Colors belong to the active color scheme and are deliberately omitted here.
abstract final class AppTypography {
  static const String fontFamily = 'GoogleSansFlex';

  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.large,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: 0,
  );
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.medium,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    letterSpacing: 0,
  );
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.xSmall,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
  );
  static const TextStyle bodyTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.medium,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
    letterSpacing: 0,
  );
  static const TextStyle rowTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.small,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
  );
  static const TextStyle supporting = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.xSmall,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
  );
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.small,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0,
  );
  static const TextStyle action = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.small,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
  );
  static const TextStyle heroMetric = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.xxLarge,
    fontWeight: FontWeight.w600,
    height: 38 / 32,
    letterSpacing: 0,
  );
  static const TextStyle amountInput = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.xLarge,
    fontWeight: FontWeight.w600,
    height: 34 / 28,
    letterSpacing: 0,
  );
  static const TextStyle inlineAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.small,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0,
  );
  static const TextStyle chartLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.xSmall,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.small,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
  );
  static const TextStyle timerReadout = TextStyle(
    fontFamily: fontFamily,
    fontSize: 74,
    fontWeight: FontWeight.w700,
    height: 78 / 74,
    letterSpacing: 0,
  );
  static const TextStyle timerReadoutCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 58,
    fontWeight: FontWeight.w700,
    height: 64 / 58,
    letterSpacing: 0,
  );
  static const TextStyle timerEyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.small,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 1.8,
  );
  static const TextStyle timerPhaseLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: AppTypeScale.xSmall,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 2,
  );

  static const TextTheme materialTextTheme = TextTheme(
    displayLarge: heroMetric,
    displayMedium: amountInput,
    displaySmall: pageTitle,
    headlineLarge: heroMetric,
    headlineMedium: amountInput,
    headlineSmall: pageTitle,
    titleLarge: pageTitle,
    titleMedium: cardTitle,
    titleSmall: rowTitle,
    bodyLarge: bodyTitle,
    bodyMedium: body,
    bodySmall: supporting,
    labelLarge: button,
    labelMedium: action,
    labelSmall: sectionLabel,
  );
}
