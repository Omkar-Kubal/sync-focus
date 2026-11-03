# Lucide Settings Icons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task.

**Goal:** Replace all Hugeicons in the Settings sheet and nested Settings sheets with the approved Lucide glyphs.

**Architecture:** Add a private `_SettingsIcons` mapping in `settings_sheet.dart`, using the existing `lucide_icons_flutter` dependency. Update Settings-only icon components to accept and render `IconData`, preserving current component APIs where practical.

**Tech Stack:** Flutter, Dart, `lucide_icons_flutter` 4.0.1.

**Spec:** `docs/superpowers/specs/2026-11-02-lucide-settings-icons-design.md`

## Global Constraints

- Scope icon changes to `sync-focus/lib/features/settings/settings_sheet.dart`.
- Preserve current icon sizes, tints, labels, layout, semantics, and tap behavior.
- Keep global `AppIcons`/Hugeicons unchanged for non-settings screens.

## Review Focus

- Every settings-page and nested-sheet icon uses the approved Lucide mapping.
- Row icons and trailing controls retain their current dimensions and colors.
- Settings navigation, button labels, selected appearance controls, and sheet close actions remain intact.
- No logo, brand, or non-settings screen changes occur.

No tests will be added or run unless requested.

---

### Task 1: Convert Settings sheet icon rendering to Lucide

**Files:**
- Modify: `sync-focus/lib/features/settings/settings_sheet.dart`.

**Interfaces:**
- Add private `_SettingsIcons` constants typed as `IconData` for every approved mapping.
- Change `_SettingsRow.icon` and `_IconTile.icon` to `IconData`; render with `Icon` while preserving the existing `size` and `color`.

- [x] Add the Lucide import and private Settings icon mapping.
- [x] Replace every Settings `AppIcons`/`AppIcon` use with its approved Lucide role.
- [x] Update Settings-only icon component types and renderers.
- [x] Review the file to confirm the scope and preserved behavior.

