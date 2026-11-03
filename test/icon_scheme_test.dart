import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:syncfocus/main.dart';
import 'package:syncfocus/theme/app_icons.dart';

void main() {
  testWidgets('semantic icon role renders as Hugeicon with inherited size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IconTheme(
            data: IconThemeData(size: 21),
            child: AppIcon(icon: AppIcons.home, semanticLabel: 'Home'),
          ),
        ),
      ),
    );

    expect(find.byType(HugeIcon), findsOneWidget);
    expect(tester.getSize(find.byType(AppIcon)), const Size(21, 21));
    expect(find.bySemanticsLabel('Home'), findsOneWidget);
  });

  testWidgets('app theme provides the shared icon size', (tester) async {
    await tester.pumpWidget(const MyApp());

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.iconTheme.size, AppIconSizes.standard);
    expect(theme.iconTheme.size, 24);
  });

  test('selected pixel cat and light-mode logo are bundled', () async {
    final source = await rootBundle.load(AppBrandAssets.catSource);
    final light = await rootBundle.load(AppBrandAssets.catLight);
    expect(source.lengthInBytes, greaterThan(0));
    expect(light.lengthInBytes, greaterThan(0));
  });
}
