# Splash and Home emulator QA

Final result: passed for the requested Flutter splash and Home screen on Android emulator.

## Visual targets

- User-supplied splash reference: `C:/WINDOWS/TEMP/codex-clipboard-7d875f71-9685-435f-b13d-4aede9d9e382.png`
- User-supplied Home reference: `C:/WINDOWS/TEMP/codex-clipboard-196a7c7c-ed63-4b2c-a022-d0f7bf33b03e.png`
- Existing selected pixel-cat brand asset: `assets/brand/sync_focus_cat_source.png`

## Device and checks

- Medium Phone Android emulator, API 36, 1080 × 2400. Installed the debug APK and drove the app with `adb` UI-tree-derived input.
- [Cold-start screenshot at one second](docs/qa/flutter-splash-emulator.png) shows the selected pixel-cat logo centered on white. The native launch image now uses the same cat mark, removing the default Flutter logo seen in the first emulator pass. Home appeared after the app's three-second splash timer.
- [Home screenshot](docs/qa/flutter-home-emulator.png) shows the logo header, large pale-blue ring, one primary focus action, open white space, and floating three-tab navigation with no visible clipping or overlap.
- Ring drag changed the duration from 25 to 50 minutes. Tapping the time and entering 35 minutes returned to Home displaying 35 minutes. An initial emulator pass exposed a controller-disposal assertion on submission; the dialog now owns and disposes its text controller, and the reproduced widget test passes.
- Starting 35 minutes showed a decrementing countdown in the same ring and a Pause action. Pause held 34:37 while switching to Tasks and back. Resume continued from 34:37 to 34:33.
- The emulator crash buffer contained no `com.appylab.syncfocus` or `FATAL EXCEPTION` entries in the final pass. Progress and Settings are currently minimal navigation shells because those screens are outside this build step.

## Remaining scope

- The countdown is Flutter UI state for this screen. Android foreground service, boot recovery, notification actions, widget, and session persistence are later conversion steps and are not covered by this visual pass.

## Tasks screen emulator QA — 2026-11-01

Final result: passed for the selected Tasks screen on Android emulator.

- [Selected reference](docs/qa/tasks-selected-reference.png), [final emulator capture](docs/qa/flutter-tasks-final-emulator.png), and [side by side comparison](docs/qa/tasks-side-by-side-final.png). The reference is 853 × 1844 pixels; the emulator capture is 1080 × 2400 pixels, shown at equal display height in the comparison. The emulator's status and gesture bars are platform chrome absent from the mockup.
- The final pass corrected an approximately 36-pixel downward offset in the title and first row by reducing top padding from 44 to 26 logical pixels and the intro-to-list gap from 27 to 20. The final capture places the title, rows, Add task button, and bottom nav in the same visual rhythm as the reference.
- Typography uses Google Sans Flex, with matching large black title, compact bold row names, and gray secondary text. White canvas, black primary button, light blue Focus pills, gray rules, and outlined completion circles follow the supplied scheme. The pixel-cat logo is the existing brand asset; all visible controls use the Hugeicons set.
- The mockup's three task names were entered manually on the emulator for comparison. A fresh install presents a purposeful empty state rather than hardcoded sample tasks. The manually entered tasks display in newest-first order, so their order differs from the static reference. The Focus pills use a solid pale-blue token where the reference has a very subtle blue variation; this is a P3 polish difference.
- Emulator UI-tree checks confirmed Add task entry, 45-minute Focus assignment to the Home ring, and task survival after app force-stop and relaunch. The widget and store tests cover the same focus path, the 10-active-task Free cap, completion releasing a slot, and persistence.
- No P0, P1, or P2 visual issues remain. Progress and Settings remain separate conversion steps.

## Add task bottom sheet emulator QA — 2026-11-01

Final result: passed for the selected Add task bottom sheet on Android emulator.

- [Selected reference](docs/qa/add-task-sheet-selected-reference.png), [final emulator capture](docs/qa/flutter-add-task-sheet-final-emulator.png), and [equal-height comparison](docs/qa/add-task-sheet-side-by-side.png). Source: 853 × 1844; emulator: 1080 × 2400. The emulator's system status and gesture bars are platform chrome.
- The first emulator pass showed the custom-tag label truncated beside the crown. The label now renders in full, with the crown adjacent and the chevron aligned to the row edge. A second pass reduced the sheet height and upper spacing; the sheet top, title, time controls, tag panel, and Save button now closely follow the reference.
- Typography uses the existing Google Sans Flex tokens. White surface, near-black title and primary button, muted labels, pale-blue controls, thin dividers, and the selected cat logo follow the shared scheme. The crown, stepper, checkmark, close, and row arrow use Hugeicons. The active text field has a darker underline than the static mockup; this is a P3 focus-state difference. The example tasks behind the sheet appear newest first, so their order differs from the mockup.
- Emulator UI-tree checks confirmed adding a 45-minute task through the stepper, opening the custom-tag Pro explanation, returning to the still-filled sheet, and saving a task. Flutter widget and store tests cover the sheet controls, timer assignment, active-task limit, and local persistence. `flutter analyze` reports no issues.
- Custom-tag creation and subscription purchase remain future features. The crown action explains availability without claiming that a purchase flow exists.

## Progress screen emulator QA — 2026-11-01

Final result: passed for the selected Progress screen on Android emulator.

- [Selected reference](design/progress-selected-reference.png) is 853 × 1844; [populated emulator capture](docs/qa/flutter-progress-populated-emulator.png) is 1080 × 2400. The capture uses three QA-only completed sessions (1h 50m and a 3-day streak), so its values differ from the reference examples. [Clean final emulator capture](docs/qa/flutter-progress-clean-final-emulator.png) shows the real zero-session state. Android status and gesture bars are platform chrome.
- Typography and copy: Google Sans Flex retains the reference's strong title hierarchy, quieter dates and durations, and short explanatory subtitle. The exact session text varies with real history.
- Spacing and layout: the header, title, weekly summary, line chart, recent-session timeline, streak, and floating navigation follow the reference order and open white spacing. On the populated capture the streak is closer to the floating nav than in the static reference; it remains readable and is a P3 spacing difference.
- Colors and assets: white canvas, black headings, muted gray supporting text, blue chart and timeline marks, hairline rules, the selected pixel-cat logo, and Hugeicons match the shared scheme. The chart is Flutter-rendered UI data, with a Sunday highlight. No reference image assets were replaced.
- Behavior: a fresh install shows no invented sessions. A completed timer is stored locally once; pause and reset do not add history. Weekly totals, seven local calendar days, recent sessions, and streaks are derived from saved completions. The complete Flutter suite passed 21 tests, `flutter analyze` found no issues, and the normal x86_64 release APK installed on both emulators. The final clean emulator launch produced no app crash-buffer entries.
- QA data was cleared from the capture emulator. The original Medium Phone emulator's preferences were restored from its pre-QA backup with a matching SHA-256 checksum, then the normal release APK was installed while preserving that data.

No P0, P1, or P2 visual or functional findings remain. Android foreground service, boot recovery, notification actions, and widget integration are separate conversion steps; this Progress history records completions from the current Flutter timer process.

## Progress empty state illustration — 2026-11-01

Final result: passed on Android emulator.

- [Emulator capture](docs/qa/flutter-progress-empty-illustration-emulator.png) shows the empty Progress page after installing the normal x86_64 release APK. The weekly zero chart, zero total, recent-session placeholder, and empty streak are replaced by one centered illustration and concise guidance. The illustration reuses the selected pixel-cat asset inside the app's pale-blue focus ring, so its imagery and colors stay consistent with Home.
- The page title, subtitle, typography, white canvas, black action button, cat header, and floating navigation follow the existing design system. The message and button fit above navigation without clipping at 1080 × 2400. The empty view scrolls on shorter screens.
- “Go to timer” returned to Home on the emulator, where “Start focus” was visible. The populated Progress state still renders the real weekly chart and saved sessions. All 21 Flutter tests passed and `flutter analyze` found no issues.

## Pro trend preview implementation — 2026-11-02

Final result: blocked for emulator visual comparison; implementation checks passed.

- Implemented the selected [Pro trend mockup](design/progress-pro-selected-reference.png) in the populated Progress view, after recent focus. The empty-state illustration stays free of the Pro promotion.
- The card has interactive 30/90-day selectors and an explicitly illustrative chart. “Explore Pro” opens a notice that expanded trends are planned, without offering a purchase for unavailable features.
- All 21 Flutter tests passed and `flutter analyze` found no issues. The x86_64 release APK (version code 4007) built and installed on the Medium Phone AVD.
- Emulator visual capture was blocked by Android System UI becoming unresponsive during boot. Temporary QA sessions were removed and the original preferences were restored from the saved copy; its SHA-256 matched before the final APK install. No emulator visual match is claimed for this section.

## Progress Pro analytics panel implementation — 2026-11-02

Final result: passed

- Source visual truth: [selected Pro panel reference](design/pro-progress-panel-selected-reference.png), 1047 × 1503 px. The card region is 973 × 1382 px. The final Android capture is [the populated Progress screen](docs/qa/pro-progress-panel-final-emulator.png), 1080 × 2400 px at 420 dpi (411 × 914 logical dp); the panel bounds from the emulator UI tree are `[42,585][1038,1987]` (996 × 1402 px). The source and implementation panel crops are shown together in [the final side-by-side comparison](docs/qa/pro-progress-panel-side-by-side-final.png), normalized to a 1000 px width.
- State: the screenshot uses 46 temporary QA sessions (18h 40m total) and the default 30-day range. The focused card capture is [available separately](docs/qa/pro-progress-panel-only-emulator.png). A second capture and UI tree confirm the [90-day range](docs/qa/pro-progress-panel-90day-final-emulator.png) updates the heading and x-axis to Aug 4–Nov 2. The final app was returned to the clean zero-session Progress state; [its emulator capture](docs/qa/pro-progress-clean-final-emulator.png) shows the empty-state message. The temporary sessions were removed from the emulator and the local fixture XML was deleted.
- Full-view evidence: the selected reference is only the Pro panel, while the app screen includes the existing Progress header, recent-session list, and navigation. The comparison therefore crops the complete Pro card from both images and compares the same populated 30-day state. No device chrome or surrounding Progress sections are included in the focused comparison.
- Typography and copy: the panel uses the existing Google Sans Flex typography tokens, with the reference's title hierarchy and constrained explanatory text blocks. The title, descriptions, metric labels, chart axes, tag names, and durations are legible and follow the selected copy.
- Spacing and layout: the Progress screen horizontal inset is 16 dp; the card uses 16 dp internal horizontal padding, 18 dp corner radius, a wider trend chart, and tag summaries in the reference order. The normalized panel height differs by under 1% from the selected card crop. The full panel and bottom navigation fit in the emulator viewport when scrolled to the section.
- Colors and visual assets: the pale-blue panel surface and border, blue trend line, muted labels, and white canvas use the existing global tokens. The tag glyphs use the app's Hugeicons set; the source contains illustrative line glyphs, so a few icon shapes differ slightly. The reference has no separate raster illustration or logo to reproduce.
- Behavior: on the installed x86_64 debug build (version code 8016), tapping 90 days changed the period description and chart labels to the 90-day window; tapping 30 days returned them to Oct 3–Nov 2. The summary totals and tag breakdown derive from completed local sessions. After clearing the synthetic fixture, the emulator remained on the Progress tab and its SharedPreferences directory contained no session data. The crash buffer had no app crash entries. `flutter analyze` reported no issues.

**Findings**

- No actionable P0, P1, or P2 differences remain in the selected panel.
- [P3] The mockup labels Writing as 34%; the displayed 6h 15m out of 18h 40m computes to 33% with standard rounding. The implementation keeps the value mathematically consistent with the live totals.
- [P3] The Hugeicons glyphs are close in meaning but not identical to the generated mockup's illustrative line icons.

**Implementation Checklist**

- [x] Match the panel width, text wrapping, chart height, tag order, and blue-white color scheme.
- [x] Verify 30-day and 90-day range selection on the Android emulator.
- [x] Clear the synthetic session data and leave the emulator on the clean Progress state.

**Follow-up Polish**

- Subscription entitlement gating, custom-tag creation, and searchable session history are not connected yet. The panel currently reads locally saved session data for any user.

## Pro Progress empty state — 2026-11-02

Final result: passed on Android emulator.

- The clean Progress state now shows a Pro-focused empty card in place of analytics values and the generic cat-in-a-ring illustration. The card has a Hugeicons trend glyph with a crown badge, “No focus sessions yet” guidance, and a working “Go to timer” action. The 30/90-day selector and metrics stay hidden when there is no session history.
- The empty card remains in the same pale-blue surface and 16 dp page inset as the populated Pro panel. It fits above the floating navigation at 1080 × 2400 px / 420 dpi. [Final emulator capture](docs/qa/pro-progress-empty-state-emulator.png) and [UI tree](docs/qa/pro-progress-empty-state-final-ui.xml) show the empty state and selected Progress tab.
- Emulator interaction: tapping “Go to timer” returned to Home; tapping Progress returned to the empty Pro state. The installed x86_64 debug APK is version code 8020. `flutter analyze` reported no issues. The emulator has no saved synthetic session data and the temporary QA fixture was removed.
- When saved sessions exist outside the selected date range, the empty Pro state retains its 30/90-day selector and suggests widening the range, so older sessions remain reachable. Entitlement gating and subscription purchase are still not connected.

## Settings spacing and scroll emulator QA — 2026-11-02

Final result: passed on Android emulator.

- The Settings sheet keeps its full-height layout and now scrolls through the full page. Sections have more separation; setting rows use larger icon tiles, text, and vertical touch space; the Pro and brand cards have more internal padding.
- [Top-of-sheet emulator capture](docs/qa/settings-roomier-top-emulator.png) shows the larger Break, Focus Guard, Sound, and Appearance sections. [Scrolled capture](docs/qa/settings-roomier-about-emulator.png) shows Support, the logo card, and the full Privacy Policy row. Device: `syncfocus_qa_20261031`, Android API 36, 1080 × 2400 px at 420 dpi.
- The x86_64 debug APK built and installed. An emulator swipe moved from the first sections down to About; UI-tree captures confirm the Privacy Policy row is fully visible after scrolling. The app process remained active and the crash buffer was empty.
- A widget test verifies the enlarged Break row, nonzero scroll extent, and access to About. All 24 Flutter tests passed; `flutter analyze --no-pub` reported no issues.
