# Lucide Bottom Navigation Icons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Replace the Home, Tasks, and Progress bottom-navigation glyphs with Lucide icons while preserving current navigation behavior and styling.

**Architecture:** Add the maintained `lucide_icons_flutter` package and render `LucideIcons.house`, `LucideIcons.listTodo`, and `LucideIcons.chartNoAxesColumnIncreasing` directly in `_BottomNav`. Keep the existing `AppIcons`/Hugeicons system for other screens during this first pass.

**Tech Stack:** Flutter, Dart, `lucide_icons_flutter` 4.0.1.

**Spec:** `docs/superpowers/specs/2026-11-02-lucide-bottom-navigation-design.md`

## Global Constraints

- Change only the Home, Tasks, and Progress bottom-navigation glyphs in this pass.
- Preserve the existing labels, item order, 22 px icon size, selected/unselected colors, tap behavior, and selected/button semantics.
- Keep the Settings icon, all other Hugeicons, and brand assets unchanged.

## Review Focus

- Home, Tasks, and Progress remain paired with icon indices 0, 1, and 2 respectively.
- Selected icons use `context.palette.primary`; unselected icons use `context.palette.muted`.
- Labels, selected semantics, tap callbacks, size, and spacing remain unchanged.
- Lucide regular-weight glyphs render at the existing size with the bundled Lucide font.
- No other screen icon changes as a side effect.

No automated tests will be added or run for this change; this follows the current instruction to avoid testing unless requested.

---

### Task 1: Replace the bottom-navigation glyphs

**Files:**
- Modify: `sync-focus/pubspec.yaml` — add `lucide_icons_flutter: ^4.0.1`.
- Update: `sync-focus/pubspec.lock` — resolve the new dependency with `flutter pub get`.
- Modify: `sync-focus/lib/features/focus/focus_home_screen.dart` — import Lucide and use it in `_BottomNav`.

**Interfaces:**
- Consumes: Existing `_BottomNav(selectedIndex: int, onSelected: ValueChanged<int>)` and `context.palette` colors.
- Produces: Home uses `LucideIcons.house`, Tasks uses `LucideIcons.listTodo`, Progress uses `LucideIcons.chartNoAxesColumnIncreasing`; each renders at 22 px in the existing selected/unselected color.

- [x] Add the Lucide dependency and resolve `pubspec.lock`.
- [x] Import `package:lucide_icons_flutter/lucide_icons.dart` in `focus_home_screen.dart`.
- [x] Replace the three `AppIcons` entries in `_BottomNav` with the Lucide constants and replace only the bottom bar's `AppIcon` widget with Flutter `Icon`; retain the current semantics wrapper, labels, layout, and colors.
- [x] Review the diff to confirm the change is limited to the dependency files and `_BottomNav`.

