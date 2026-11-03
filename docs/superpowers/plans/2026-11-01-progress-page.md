# Progress Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Progress placeholder with the selected weekly chart and recent-session layout backed by actual completed focus sessions.

**Architecture:** Persist completed sessions locally in a small store. The existing timer emits one completion event per finished session; the shell records that event. The Progress screen derives its weekly chart, total, recent list, and streak from stored sessions and device-local dates.

**Tech Stack:** Flutter, Dart, `shared_preferences`, Hugeicons, existing app tokens.

**Spec:** `design/progress-selected-reference.png`; Free/Pro boundary in `docs/free-pro-feature-plan.md`.

## Global Constraints

- Reuse the existing cat header, floating bottom nav, Google Sans Flex, Hugeicons, and color tokens.
- Show no sample sessions to real users; use an honest empty state until a session completes.
- Weekly chart and five recent sessions are Free. Do not expose unbuilt Pro history or purchase controls.
- Verify on Android emulator, not web.

## Review Focus

- A timer that completes should create exactly one local session, even if the timer notifies again.
- A reset or pause should not create a completed session.
- Week calculations should cross month and year boundaries correctly.
- The current streak should include yesterday when today has no session yet.
- An empty store should render without invented activity.

---

### Task 1: Completed session storage and summaries

**Files:** Create `lib/features/progress/session_store.dart`; test in `test/session_store_test.dart`.

**Interfaces:** `FocusSession`, `SessionStore.addCompleted`, `ProgressSummary.fromSessions`.

- [x] Write tests for persistence, weekly totals, recent ordering, and streak edge cases.
- [x] Run the tests and confirm the missing behavior fails.
- [x] Implement the store and summary using local calendar days.
- [x] Run the tests and confirm they pass.

### Task 2: Record timer completion once

**Files:** Modify `lib/features/focus/focus_timer_controller.dart` and `lib/features/focus/focus_home_screen.dart`; test in `test/focus_timer_controller_test.dart`.

**Interfaces:** Timer completion revision and timestamp consumed by the shell's session recorder.

- [x] Write a test for one completion event and no event on pause/reset.
- [x] Confirm failure, implement event metadata and shell recording, then rerun tests.

### Task 3: Progress screen and emulator QA

**Files:** Create `lib/features/progress/progress_screen.dart`; modify `lib/features/focus/focus_home_screen.dart` and `lib/theme/app_icons.dart`; test in `test/widget_test.dart`.

- [x] Write a widget test for an empty Progress page and a populated seven-day summary.
- [x] Confirm failure, implement the responsive chart, recent timeline, and streak row.
- [x] Run `flutter test` and `flutter analyze`.
- [x] Build, install, and inspect on the Medium Phone Android emulator; compare with the selected reference and record evidence in `design-qa.md`.
