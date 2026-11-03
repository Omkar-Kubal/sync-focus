import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/progress/session_store.dart';
import 'package:syncfocus/features/settings/settings_sheet.dart';
import 'package:syncfocus/main.dart';
import 'package:syncfocus/theme/app_colors.dart';

void main() {
  const proFlagEnabled = bool.fromEnvironment(
    'SYNC_FOCUS_PRO',
    defaultValue: false,
  );
  final hasProTestAccess = kDebugMode && proFlagEnabled;

  setUp(
    () => SharedPreferences.setMockInitialValues({
      'welcome_screen.seen': true,
      'home_welcome_pending': false,
    }),
  );

  testWidgets('adding a task and focusing it sets the home timer', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(
      find.text('Choose what gets your next focus session'),
      findsOneWidget,
    );
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-input')),
      'Finish proposal draft',
    );
    await tester.tap(find.text('25 min'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task-minutes-input')), '45');
    await tester.tap(find.text('Set time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(find.text('Finish proposal draft'), findsOneWidget);
    expect(find.text('45 min'), findsOneWidget);
    await tester.tap(find.text('Focus').first);
    await tester.pumpAndSettle();
    expect(find.text('45:00'), findsOneWidget);
    expect(find.text('Finish proposal draft'), findsOneWidget);
  });

  testWidgets('Add task sheet offers time steps and a custom tag crown', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('task-editor-sheet')), findsOneWidget);
    expect(find.text('Task name'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.text('5–240 min'), findsOneWidget);
    expect(find.text('Create a custom tag'), findsOneWidget);
    expect(find.byKey(const Key('custom-tag-crown')), findsOneWidget);

    await tester.tap(find.byKey(const Key('focus-time-increase')));
    await tester.pump();
    expect(find.text('30 min'), findsOneWidget);

    await tester.tap(find.text('Create a custom tag'));
    await tester.pumpAndSettle();
    expect(find.text('Custom tags are a Pro feature'), findsOneWidget);
  });

  testWidgets('Progress starts empty without invented sessions', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('See the time you gave to what matters'), findsOneWidget);
    expect(
      find.byKey(const Key('progress-empty-illustration')),
      findsOneWidget,
    );
    expect(find.text('This week'), findsNothing);
    expect(find.byKey(const Key('progress-week-chart')), findsNothing);
    expect(find.text('No focus sessions yet'), findsOneWidget);
    expect(find.byKey(const Key('progress-pro-trend-preview')), findsNothing);
    await tester.tap(find.text('Go to timer'));
    await tester.pumpAndSettle();
    expect(find.text('Start focus'), findsOneWidget);
  });

  testWidgets('Progress shows saved weekly total and recent focus', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final now = DateTime.now();
    final store = SessionStore();
    await store.ready;
    await store.addCompleted(
      'Review notes',
      25,
      DateTime(now.year, now.month, now.day, 9),
    );
    await store.addCompleted(
      'Write outline',
      45,
      DateTime(now.year, now.month, now.day, 10),
    );
    store.dispose();

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('1h 10m'), findsWidgets);
    expect(find.byKey(const Key('progress-empty-illustration')), findsNothing);
    expect(find.byKey(const Key('progress-week-chart')), findsOneWidget);
    expect(find.text('Write outline'), findsOneWidget);
    expect(find.text('Review notes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('progress-pro-insights')),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('progress-populated')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Focus over time'), findsOneWidget);
    expect(find.text('Focus by tag'), findsOneWidget);
    await tester.tap(find.byKey(const Key('progress-pro-days-90')));
    await tester.pumpAndSettle();
    expect(
      find.text('See how your focus time has changed over the last 90 days.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('1-day streak'),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey<String>('progress-populated')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('1-day streak'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings uses roomier rows and scrolls through About', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('BREAK'), findsOneWidget);
    expect(find.text('FOCUS GUARD'), findsOneWidget);
    expect(find.text('DO NOT DISTURB'), findsOneWidget);
    expect(find.text('SOUND'), findsOneWidget);
    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('SUPPORT'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('Do Not Disturb'), findsOneWidget);
    expect(
      find.text(
        hasProTestAccess
            ? 'Grant Android access to enable during focus'
            : 'Allow priority interruptions during focus',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        hasProTestAccess
            ? 'Choose apps to block during focus sessions'
            : 'Android only · Pro feature',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        hasProTestAccess
            ? 'Rain · device media volume'
            : 'Rain by default · device media volume',
      ),
      findsOneWidget,
    );
    expect(find.text('Haptic feedback'), findsNothing);

    final breakRow = find
        .ancestor(
          of: find.text('Break duration'),
          matching: find.byType(InkWell),
        )
        .first;
    expect(tester.getSize(breakRow).height, greaterThanOrEqualTo(88));

    final settingsScroll = find.byType(Scrollable).last;
    final scrollState = tester.state<ScrollableState>(settingsScroll);
    expect(scrollState.position.maxScrollExtent, greaterThan(0));
    await tester.scrollUntilVisible(
      find.text('Privacy Policy'),
      180,
      scrollable: settingsScroll,
    );
    expect(find.text('ABOUT'), findsOneWidget);
    expect(
      tester.getRect(find.text('Privacy Policy')).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved AMOLED preference follows the active Pro access state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'welcome_screen.seen': true,
      'home_welcome_pending': false,
      'settings.appearance': 'amoledBlack',
      'sync_focus_pro_subscription_active': false,
    });
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    expect(app.themeMode, ThemeMode.dark);
    expect(
      app.darkTheme?.scaffoldBackgroundColor,
      hasProTestAccess ? Colors.black : AppColors.surfaceDark,
    );
  });

  test('Focus Guard app count copy uses singular and plural correctly', () {
    expect(FocusGuardFeatureCopy.selectedAppCount(1),
        'Blocks 1 app during focus sessions');
    expect(FocusGuardFeatureCopy.selectedAppCount(2),
        'Blocks 2 apps during focus sessions');
  });

  testWidgets('DND setting follows the current Pro access state', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    if (hasProTestAccess) {
      expect(
        find.text('Grant Android access to enable during focus'),
        findsOneWidget,
      );
      expect(find.text('Restore purchase'), findsNothing);
    } else {
      await tester.tap(find.text('Do Not Disturb'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Unlock Sync Focus Pro'), findsOneWidget);
      expect(find.text('Restore purchase'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('centered logo splash opens Home after three seconds', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(find.text('Start focus'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2999));
    expect(find.byKey(const Key('splash-logo')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Start focus'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
  });

  testWidgets('the same ring starts a focus countdown', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('Start focus'));
    await tester.pump();

    expect(find.text('Focusing'), findsOneWidget);
    expect(find.text('Pause focus'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('exact-duration dialog closes without disposing live widgets', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));

    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '35');
    await tester.tap(find.text('Set time'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('35:00'), findsOneWidget);
  });
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
