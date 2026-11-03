import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfocus/features/settings/settings_platform_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads Android permission state and launchable app choices', () async {
    const channel = MethodChannel('test.sync_focus/settings');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'hasDndAccess' => true,
            'getFocusGuardAccess' => {
              'usageAccess': true,
              'overlayAccess': false,
            },
            'getLaunchableApps' => [
              {'packageName': 'com.example.reader', 'label': 'Reader'},
            ],
            _ => null,
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final bridge = SettingsPlatformBridge(channel: channel);

    expect(await bridge.hasDndAccess(), isTrue);
    final access = await bridge.getFocusGuardAccess();
    expect(access.usageAccess, isTrue);
    expect(access.overlayAccess, isFalse);
    expect(access.isGranted, isFalse);
    final apps = await bridge.getLaunchableApps();
    expect(apps, hasLength(1));
    expect(apps.single.packageName, 'com.example.reader');
    expect(apps.single.label, 'Reader');
    expect(calls, ['hasDndAccess', 'getFocusGuardAccess', 'getLaunchableApps']);
  });

  test(
    'launches Android settings pages for each required permission',
    () async {
      const channel = MethodChannel('test.sync_focus/settings_permissions');
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final bridge = SettingsPlatformBridge(channel: channel);

      await bridge.requestDndAccess();
      await bridge.requestUsageAccess();
      await bridge.requestOverlayAccess();

      expect(calls, [
        'requestDndAccess',
        'requestUsageAccess',
        'requestOverlayAccess',
      ]);
    },
  );
}
