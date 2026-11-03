# Sync Focus Android Widgets

## Intent

Implement the two supplied Sync Focus home-screen widget designs in the Flutter app: a compact square timer with a circular progress ring and a wide timer card with a horizontal progress bar. The widgets should display the same timer that users control in the app and let them start, pause, or resume a focus session from the widget.

## Goals

- Provide separate 3×2 square and 4×1 wide Android home-screen widgets using the supplied visual references.
- Match the app's monochrome surfaces, pale blue progress treatment, circular cat logo, and clear timer typography.
- Keep the displayed countdown accurate while the Flutter UI is not visible.
- Restore timer state after Android recreates the app process.
- Route widget actions into the existing Flutter `FocusTimerController`.

## Non-goals

- iOS widgets, a new timer service, task editing from the widget, or editable duration controls on the widget.
- Replacing the app's existing timer controller or changing session, notification, or sound behavior.
- Running build, test, or emulator verification as part of this implementation pass.

## Approaches

1. **Native Android `AppWidgetProvider` layouts plus a Flutter `MethodChannel` (chosen).** Use RemoteViews layouts and providers for predictable Android launcher rendering, with an Android-owned timer snapshot and a channel for Flutter state updates/actions. A native `Chronometer` keeps the visible countdown moving while Flutter is backgrounded; a generated ring bitmap and standard progress bar match the two references. This avoids another plugin and can reuse the existing Android host.
2. **Jetpack Glance widgets copied from the legacy Kotlin app.** This reuses old Kotlin widget code, but would pull Compose/Glance dependencies into the Flutter Android host and the legacy widget currently provides only one layout and a different visual design.
3. **A Flutter widget plugin.** This would add a dependency and still require native Android code for launcher rendering and process-safe timer state, so it adds another integration layer without removing the platform work.

## Design and behavior

- The 3×2 square widget places the circular logo, Sync Focus title, and phase at the top; its compact ring and timer sit beside the start/pause/resume action.
- The 4×1 wide widget uses one horizontal row: logo/title/phase at the left, timer and blue progress bar in the center, and a compact action button at the right.
- Both widgets use the app's black, white, and soft-blue palette. They show `FOCUS READY` with `25:00` by default; while active they show the remaining countdown and `PAUSE`, while paused they show `RESUME`.
- The widget surface opens the app on the focus tab. Its action button opens the app and toggles the existing timer controller. App timer duration and phase changes are sent to Android; Android returns its saved snapshot at app startup so running timers can be restored.
- Android renders an active countdown with `Chronometer`. The ring/progress fill is refreshed when Flutter reports a phase change or the displayed minute changes, avoiding per-second RemoteViews broadcasts. A one-shot inexact idle-allowed alarm refreshes the widget near the deadline so its phase/action label can change after the app is closed.
- The square ring reflects the selected duration while ready, then the remaining-time fraction while running or paused, following the home timer's existing behavior.

## Constraints and implementation calls

- Android widgets are implemented with `RemoteViews`; no widget plugin or new Gradle dependency is needed.
- Square widget launcher metadata uses a 128dp minimum height for a 3×2 placement; wide widget metadata uses a 52dp minimum height for a 4×1 placement, allowing for Android's added widget-host padding.
- Timer state is stored in a dedicated Android `SharedPreferences` file through the method channel, rather than depending on the private storage format of `shared_preferences`.
- The launcher-hosted `Chronometer` continues updating its digits independently. The progress ring/bar refreshes on Flutter state updates and completion; its fill can remain at the last rendered minute while the Flutter process is stopped.
- The references are copied into `design/widgets/` so they remain available in the project.
- This work is scoped to Android and the current Flutter app. No code or files outside `sync-focus/` are modified.
