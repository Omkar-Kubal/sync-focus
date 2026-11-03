import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfocus/main.dart';
import 'package:syncfocus/theme/app_typography.dart';

void main() {
  testWidgets('app exposes the shared type scheme to screens', (tester) async {
    await tester.pumpWidget(const MyApp());

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.textTheme.titleLarge?.fontFamily, 'GoogleSansFlex');
    expect(theme.textTheme.titleLarge?.fontSize, 22);
    expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
    expect(theme.textTheme.bodyLarge?.fontSize, 16);
    expect(theme.textTheme.labelLarge?.fontSize, 14);
  });

  test('timer readout has regular and compact semantic styles', () {
    expect(AppTypography.timerReadout.fontSize, 74);
    expect(AppTypography.timerReadout.height, 78 / 74);
    expect(AppTypography.timerReadoutCompact.fontSize, 58);
    expect(AppTypography.timerReadoutCompact.height, 64 / 58);
  });

  test('bundled font is available without a network request', () async {
    final font = await rootBundle.load(
      'assets/fonts/google_sans_flex_regular.ttf',
    );
    expect(font.lengthInBytes, greaterThan(0));
  });
}
