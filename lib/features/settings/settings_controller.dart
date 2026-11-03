import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/focus/ambient_sound.dart';

enum AppAppearance { light, dark, amoledBlack }

/// Single persisted source of truth for settings exposed in the Settings sheet.
class SettingsController extends ChangeNotifier {
  static const _appearanceKey = 'settings.appearance';
  static const _legacyLightModeKey = 'settings.light_mode';
  static const _breakDurationKey = 'settings.break_duration_minutes';
  static const _dndEnabledKey = 'settings.dnd_enabled';
  static const _focusGuardEnabledKey = 'settings.focus_guard_enabled';
  static const _blockedAppsKey = 'settings.focus_guard_blocked_apps';
  static const _ambientSoundKey = 'settings.ambient_sound';

  AppAppearance _appearance = AppAppearance.light;
  int _breakDurationMinutes = 5;
  bool _isDndEnabled = false;
  bool _isFocusGuardEnabled = false;
  Set<String> _blockedApps = <String>{};
  AmbientSound _ambientSound = AmbientSound.rain;

  AppAppearance get appearance => _appearance;
  bool get isLightMode => _appearance == AppAppearance.light;
  bool get isAmoledBlack => _appearance == AppAppearance.amoledBlack;
  int get breakDurationMinutes => _breakDurationMinutes;
  bool get isDndEnabled => _isDndEnabled;
  bool get isFocusGuardEnabled => _isFocusGuardEnabled;
  Set<String> get blockedApps => Set.unmodifiable(_blockedApps);
  AmbientSound get ambientSound => _ambientSound;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedAppearance = preferences.getString(_appearanceKey);
    _appearance = AppAppearance.values.firstWhere(
      (mode) => mode.name == savedAppearance,
      orElse: () => preferences.getBool(_legacyLightModeKey) == false
          ? AppAppearance.dark
          : AppAppearance.light,
    );
    _breakDurationMinutes = (preferences.getInt(_breakDurationKey) ?? 5)
        .clamp(1, 60)
        .toInt();
    _isDndEnabled = preferences.getBool(_dndEnabledKey) ?? false;
    _isFocusGuardEnabled = preferences.getBool(_focusGuardEnabledKey) ?? false;
    _blockedApps = preferences.getStringList(_blockedAppsKey)?.toSet() ?? {};
    _ambientSound = AmbientSound.fromName(
      preferences.getString(_ambientSoundKey),
    );
    notifyListeners();
  }

  Future<void> setAppearance(AppAppearance mode) async {
    if (_appearance == mode) return;
    _appearance = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appearanceKey, mode.name);
    await preferences.setBool(_legacyLightModeKey, mode == AppAppearance.light);
  }

  Future<void> setLightMode(bool enabled) =>
      setAppearance(enabled ? AppAppearance.light : AppAppearance.dark);

  Future<void> setAmoledBlack(bool enabled) =>
      setAppearance(enabled ? AppAppearance.amoledBlack : AppAppearance.dark);

  Future<void> setBreakDurationMinutes(int minutes) async {
    final next = minutes.clamp(1, 60).toInt();
    if (_breakDurationMinutes == next) return;
    _breakDurationMinutes = next;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_breakDurationKey, next);
  }

  Future<void> setDndEnabled(bool enabled) async {
    if (_isDndEnabled == enabled) return;
    _isDndEnabled = enabled;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_dndEnabledKey, enabled);
  }

  Future<void> setFocusGuard({
    required bool enabled,
    Set<String>? blockedApps,
  }) async {
    final nextBlockedApps = blockedApps ?? _blockedApps;
    if (_isFocusGuardEnabled == enabled &&
        setEquals(_blockedApps, nextBlockedApps)) {
      return;
    }
    _isFocusGuardEnabled = enabled;
    _blockedApps = Set<String>.of(nextBlockedApps);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_focusGuardEnabledKey, enabled);
    await preferences.setStringList(
      _blockedAppsKey,
      _blockedApps.toList()..sort(),
    );
  }

  Future<void> setAmbientSound(AmbientSound sound) async {
    if (_ambientSound == sound) return;
    _ambientSound = sound;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_ambientSoundKey, sound.name);
  }
}
