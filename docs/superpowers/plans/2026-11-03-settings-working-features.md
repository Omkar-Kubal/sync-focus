# Sync Focus Settings Working Features Implementation Plan

> **For agentic workers:** Execute this plan task by task with test-first changes. Keep the current Android widget and foreground-service bridge compatible with old snapshots.

**Goal:** Make all Settings features accurately described, persisted, gated, and connected to their runtime behavior.

**Architecture:** Flutter owns user-visible settings state and Pro gating. A dedicated Android MethodChannel exposes DND/Focus Guard permissions and launchable apps; the existing foreground timer service applies protections while a focus phase is running. Flutter and Android continue to share the timer snapshot, extended with optional settings fields.

**Tech Stack:** Flutter/Dart, SharedPreferences, `in_app_purchase`, Android Kotlin, MethodChannel, Android foreground service.

**Spec:** `docs/superpowers/specs/2026-11-03-settings-working-features.md`

## Global constraints

- Focus Guard and DND operate only on Android.
- Focus Guard is Pro-only and requires Usage Access plus overlay access.
- DND is Pro-only, disabled by default, and restores the previous Android interruption filter.
- Rain is the default ambient sound; system media volume controls playback.
- Focus completion offers a **Start break** action; break time is excluded from focus history.
- Free users retain light/dark appearance and the full core timer.

## Review focus

- Existing snapshots do not contain settings fields: restore must default all protections off and preserve legacy timer state.
- Pro can expire while enabled: native protection must stop when current entitlement is false.
- Android permissions can be revoked while the app is backgrounded: the service must check before applying them.
- User-manual DND changes during a timer must not be overwritten when Sync Focus restores its prior filter.
- A break can outlive the Flutter process: the Android foreground service and widget must recognize its phase without recording a second focus session.

### Task 1: Settings state, theme modes, copy, and tests

**Files:** `lib/features/settings/settings_controller.dart`, `lib/theme/app_theme.dart`, `lib/theme/app_colors.dart`, `lib/features/settings/settings_sheet.dart`, `lib/features/pro/pro_paywall_sheet.dart`, settings tests.

- [ ] Add persistence and tests for break duration, DND preference, blocked packages, selected sound, and light/dark/AMOLED appearance.
- [ ] Add an AMOLED-aware theme extension and assert pure-black surfaces while preserving dark/light behavior.
- [ ] Make Pro rows route to the paywall for Free users and to their working configuration flow for Pro users.
- [ ] Align Pro banner/paywall copy with shipped timer, DND, Focus Guard, sounds, and appearance behavior.
- [ ] Keep Support and About rows actionable and test their presence in the settings sheet.

### Task 2: Focus and break state machine

**Files:** `lib/features/focus/focus_timer_controller.dart`, `lib/features/focus/focus_home_screen.dart`, `lib/features/focus/focus_widget_bridge.dart`, `lib/features/progress/focus_session_recorder.dart`, `android/app/src/main/kotlin/com/appylab/syncfocus/service/FocusTimerForegroundService.kt`, widget snapshot storage, timer tests.

- [ ] Add failing tests for completed-focus → explicit Start break → selected break countdown → break completion.
- [ ] Extend snapshots and Android notifications/widgets to resume the break countdown after backgrounding or process recreation.
- [ ] Keep progress recording limited to focus completion and add haptics at timer transitions.

### Task 3: Ambient sound selection

**Files:** sound assets under `assets/sounds/`, `pubspec.yaml`, `lib/features/focus/focus_sound_controller.dart`, `lib/features/focus/focus_home_screen.dart`, `lib/features/settings/settings_sheet.dart`, sound tests.

- [ ] Test Rain as the persisted default, Pro-only selection for premium sounds, no in-app volume control, and playback synchronization with focus/pause/break.
- [ ] Bundle the existing Kotlin ambient tracks and allow active sessions to switch tracks without changing Android media volume.

### Task 4: Android DND and Focus Guard

**Files:** `lib/features/settings/settings_platform_bridge.dart`, `lib/features/settings/settings_sheet.dart`, `android/app/src/main/kotlin/com/appylab/syncfocus/MainActivity.kt`, `android/app/src/main/kotlin/com/appylab/syncfocus/service/FocusTimerForegroundService.kt`, new Android DND/overlay helpers, `AndroidManifest.xml`.

- [ ] Add platform-channel tests for permission state, permission settings intents, and launchable-app selection data.
- [ ] Add the DND status/request flow and automatic timer-bound filter apply/restore logic.
- [ ] Add the Focus Guard app picker and permission status sheet; persist blocked packages and enabled state.
- [ ] Apply app blocking from the existing foreground timer service while focus runs; remove overlays on pause/end/complete and exclude the app/launcher/system settings.

### Task 5: Emulator verification and state restoration

**Files:** targeted tests and `docs/qa/` evidence.

- [ ] Run `flutter test` and `flutter analyze`.
- [ ] Build and install on `emulator-5554`.
- [ ] Verify settings scrolling, Free/Pro routing, theme persistence, DND permission handoff, Focus Guard selection/permission handoffs, focus-to-break behavior, notification countdown, and cleanup.
- [ ] Restore emulator settings to 5-minute breaks, Light mode on, and timer Ready.
