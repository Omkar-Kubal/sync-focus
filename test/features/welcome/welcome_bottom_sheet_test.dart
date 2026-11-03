import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/main.dart';

void main() {
  testWidgets('new users see the welcome sheet after Home loads', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-run-welcome')), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcome-get-started')));
    await tester.pumpAndSettle();

    expect(find.text('Start focus'), findsOneWidget);
    expect(find.byKey(const Key('new-user-welcome-sheet')), findsOneWidget);
    expect(find.text('Welcome to\nSync Focus'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-user-welcome-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('new-user-welcome-sheet')), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('home_welcome_pending'), isFalse);
  });
}
