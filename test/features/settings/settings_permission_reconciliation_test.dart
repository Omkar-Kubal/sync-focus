import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/settings/settings_controller.dart';
import 'package:syncfocus/features/settings/settings_platform_bridge.dart';
import 'package:syncfocus/features/settings/settings_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'revoked Android permissions disable protection but preserve app choices',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsController();
      await settings.load();
      await settings.setDndEnabled(true);
      await settings.setFocusGuard(
        enabled: true,
        blockedApps: {'com.example.reader'},
      );
      final billing = ProBillingController();
      const channel = MethodChannel('test.sync_focus/revoked_permissions');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return switch (call.method) {
              'hasDndAccess' => false,
              'getFocusGuardAccess' => {
                'usageAccess': false,
                'overlayAccess': false,
              },
              'getLaunchableApps' => const <Object?>[],
              _ => null,
            };
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        settings.dispose();
        billing.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsSheet(
              settings: settings,
              proBilling: billing,
              platformBridge: SettingsPlatformBridge(
                channel: channel,
                supportedOverride: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(settings.isDndEnabled, isFalse);
      expect(settings.isFocusGuardEnabled, isFalse);
      expect(settings.blockedApps, {'com.example.reader'});
      expect(tester.takeException(), isNull);
    },
  );
}
