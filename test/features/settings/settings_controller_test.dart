import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/features/focus/ambient_sound.dart';
import 'package:syncfocus/features/settings/settings_controller.dart';
import 'package:syncfocus/theme/app_colors.dart';
import 'package:syncfocus/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('settings defaults match the free focus experience', () async {
    final settings = SettingsController();
    await settings.load();
    addTearDown(settings.dispose);

    expect(settings.breakDurationMinutes, 5);
    expect(settings.isLightMode, isTrue);
    expect(settings.isAmoledBlack, isFalse);
    expect(settings.isDndEnabled, isFalse);
    expect(settings.isFocusGuardEnabled, isFalse);
    expect(settings.blockedApps, isEmpty);
    expect(settings.ambientSound, AmbientSound.rain);
  });

  test('settings values persist and can be reloaded', () async {
    final settings = SettingsController();
    await settings.load();
    await settings.setBreakDurationMinutes(12);
    await settings.setAppearance(AppAppearance.amoledBlack);
    await settings.setDndEnabled(true);
    await settings.setFocusGuard(
      enabled: true,
      blockedApps: {'com.example.app'},
    );
    await settings.setAmbientSound(AmbientSound.ocean);
    settings.dispose();

    final restored = SettingsController();
    await restored.load();
    addTearDown(restored.dispose);

    expect(restored.breakDurationMinutes, 12);
    expect(restored.appearance, AppAppearance.amoledBlack);
    expect(restored.isLightMode, isFalse);
    expect(restored.isAmoledBlack, isTrue);
    expect(restored.isDndEnabled, isTrue);
    expect(restored.isFocusGuardEnabled, isTrue);
    expect(restored.blockedApps, {'com.example.app'});
    expect(restored.ambientSound, AmbientSound.ocean);
  });

  test('AMOLED theme uses pure black app surfaces', () {
    final theme = AppTheme.amoledBlack;

    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.colorScheme.surface, Colors.black);
    expect(theme.bottomSheetTheme.backgroundColor, Colors.black);
    expect(theme.extension<AppThemeVariant>()?.isAmoledBlack, isTrue);
  });

  testWidgets('AMOLED palette keeps app cards on true black surfaces', (
    tester,
  ) async {
    late AppColorPalette palette;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.amoledBlack,
        home: Builder(
          builder: (context) {
            palette = context.palette;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(palette.canvas, Colors.black);
    expect(palette.canvasSoft, Colors.black);
    expect(palette.surfaceCard, Colors.black);
    expect(palette.surfaceStrong, Colors.black);
    expect(palette.surfaceDarkElevated, Colors.black);
    expect(palette.progressSurface, Colors.black);
  });
}
