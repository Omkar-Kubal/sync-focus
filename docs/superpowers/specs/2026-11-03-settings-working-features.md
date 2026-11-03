# Sync Focus Settings: Working Features

## Goal

Make every control shown in Sync Focus Settings accurately describe a feature, persist its state, and connect to the runtime behavior it promises.

## Product behavior

- Break duration is saved in Settings. When a focus session completes, the Home screen offers **Start break**. The break timer starts only after the user taps it and uses the selected duration. Break time is not recorded as focus time.
- Focus Guard is an Android-only Pro feature. Free users see the crown gate. Pro users can choose launchable apps and enable blocking for focus sessions. Usage Access and display-over-other-apps access must be granted before blocking starts.
- Do Not Disturb is a Pro setting. It is off by default, requires Android notification-policy access, applies only while a focus timer is running, and restores the interruption filter that was active beforehand when focus pauses or ends.
- Rain remains the default ambient sound and uses the device media volume. Pro users can choose the other bundled ambient sounds. No in-app volume slider is shown.
- Light and dark appearance are free. AMOLED black is Pro-only and changes the app's surfaces to pure black. Losing Pro disables Pro-only behavior without deleting saved choices.
- The Pro banner and paywall describe only the features available in the app. What's New, Help & Feedback, and Privacy Policy remain actionable.
- Haptics stay built into timer interactions; there is no haptics setting.
- The timer foreground notification and widget remain synchronized through focus and break countdowns.

## Constraints

- DND and Focus Guard are Android-only. Other platforms show a clear unavailable state.
- Pro features require an active `ProBillingController` entitlement; cached screen state must not unlock them.
- Focus Guard must never block Sync Focus itself, the launcher, or a system permission screen.
- If permission is revoked while the timer runs, protection stops safely and the timer continues.

## Acceptance checks

- Settings values survive app restart and immediately affect the visible app or the next focus/break session.
- Permission denial or unsupported platform never crashes or falsely shows an enabled state.
- Pausing, ending, completing, or restoring a timer does not leave DND or the Focus Guard overlay active.
- Unit/widget tests cover persistence, Pro gating, timer phase transitions, and truthful settings copy; Android emulator QA covers permission handoffs and runtime cleanup.
