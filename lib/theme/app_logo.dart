import 'package:flutter/material.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_icons.dart';

/// Presents the selected pixel-cat mark inside the app's circular logo frame.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required this.size,
    required this.semanticLabel,
    this.asset = AppBrandAssets.catMark,
    this.backgroundColor = AppColors.progressHalo,
  });

  final double size;
  final String asset;
  final String semanticLabel;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final inset = size * 0.08;
    final markSize = size - inset * 2;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(inset),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          asset,
          width: markSize,
          height: markSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
