# Sync Focus Widgets Implementation Plan

## Files and responsibilities

- `design/widgets/*.png`: retained user references for the square and wide widget designs.
- `android/app/src/main/AndroidManifest.xml`: registers the two widget providers.
- `android/app/src/main/kotlin/com/appylab/syncfocus/MainActivity.kt`: owns the widget/timer platform channel and routes widget launch actions.
- `android/app/src/main/kotlin/com/appylab/syncfocus/widget/FocusWidgetProviders.kt`: renders both RemoteViews layouts, ring bitmap, and action intents from the shared snapshot.
- `android/app/src/main/res/layout/widget_focus_square.xml` and `widget_focus_wide.xml`: the two widget surfaces.
- `android/app/src/main/res/xml/widget_focus_square_info.xml` and `widget_focus_wide_info.xml`: launcher sizing and resize metadata.
- `android/app/src/main/res/drawable/` and `drawable-nodpi/`: widget card/background and app logo assets.
- `lib/features/focus/focus_timer_controller.dart`: expose a restorable timer snapshot and restore the persisted phase/deadline.
- `lib/features/focus/focus_widget_bridge.dart`: synchronize timer state with Android and deliver widget toggle actions to Flutter.
- `lib/features/focus/focus_home_screen.dart`: initialize/dispose the bridge alongside its timer and handle widget actions.

## Tasks

1. Preserve the two selected screenshots under `design/widgets/` and add this design and implementation plan.
2. Add timer snapshot/restore support to `FocusTimerController`, including running-deadline reconciliation.
3. Add the Dart Android widget bridge; restore state on startup, send state changes only at meaningful UI update points, and process widget toggle actions.
4. Add Android widget providers, RemoteViews layouts, launcher metadata, shared timer snapshot storage, and `MainActivity` channel/intent routing.
5. Register providers in the manifest and review the final diff for scope and consistent channel/state keys.

## Verification constraints

No tests, builds, or emulator checks are included in this pass because the current task did not ask for test or verification work. Report this limitation plainly at handoff.
