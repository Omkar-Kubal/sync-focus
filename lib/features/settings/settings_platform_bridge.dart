import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FocusGuardAccess {
  const FocusGuardAccess({
    required this.usageAccess,
    required this.overlayAccess,
  });

  final bool usageAccess;
  final bool overlayAccess;

  bool get isGranted => usageAccess && overlayAccess;
}

class LaunchableApp {
  const LaunchableApp({
    required this.packageName,
    required this.label,
    this.iconBytes,
  });

  final String packageName;
  final String label;
  final Uint8List? iconBytes;

  factory LaunchableApp.fromMap(Map<Object?, Object?> map) => LaunchableApp(
    packageName: map['packageName'] as String? ?? '',
    label: map['label'] as String? ?? '',
    iconBytes: map['icon'] as Uint8List?,
  );
}

/// Android permission and app-list operations used by Pro settings features.
class SettingsPlatformBridge {
  SettingsPlatformBridge({MethodChannel? channel, bool? supportedOverride})
    : _channel = channel ?? const MethodChannel(_channelName),
      _isSupportedOverride = supportedOverride;

  static const _channelName = 'com.appylab.syncfocus/settings';
  final MethodChannel _channel;
  final bool? _isSupportedOverride;

  bool get isSupported =>
      _isSupportedOverride ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  Future<bool> hasDndAccess() async =>
      await _channel.invokeMethod<bool>('hasDndAccess') ?? false;

  Future<void> requestDndAccess() =>
      _channel.invokeMethod<void>('requestDndAccess');

  Future<FocusGuardAccess> getFocusGuardAccess() async {
    final result = await _channel.invokeMapMethod<String, bool>(
      'getFocusGuardAccess',
    );
    return FocusGuardAccess(
      usageAccess: result?['usageAccess'] ?? false,
      overlayAccess: result?['overlayAccess'] ?? false,
    );
  }

  Future<void> requestUsageAccess() =>
      _channel.invokeMethod<void>('requestUsageAccess');

  Future<void> requestOverlayAccess() =>
      _channel.invokeMethod<void>('requestOverlayAccess');

  Future<List<LaunchableApp>> getLaunchableApps() async {
    final result = await _channel.invokeListMethod<Object?>(
      'getLaunchableApps',
    );
    return (result ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(LaunchableApp.fromMap)
        .where((app) => app.packageName.isNotEmpty && app.label.isNotEmpty)
        .toList(growable: false);
  }
}
