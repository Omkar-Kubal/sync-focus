# Lucide Settings Icons — Design

## Intent
Apply the selected Lucide icon family to the Settings page and its nested settings sheets, matching the Lucide bottom navigation.

## Approved mapping
- Pro: `crown`; Focus Guard: `shieldBan`; Break duration: `timer`; Focus sound: `audioLines`.
- Appearance: `sun` and `moon`; What's New: `newspaper`; Help & Feedback: `messageCircleQuestion`; Privacy Policy: `shieldCheck`.
- Feature Requests: `lightbulb`; Support Email: `mail`.
- Shared settings controls: `chevronRight`, `arrowUpRight`, `x`, and `check`.

## Goals and constraints
- Render Lucide glyphs at the existing icon sizes, tints, labels, and positions.
- Keep Settings interactions, semantics, layout, colors, and branding unchanged.
- Scope icon-family changes to `settings_sheet.dart`, including its private nested sheets and shared controls.
- Leave other app screens on their current icon mapping in this pass.

## Anti-goals
- Do not add section-header icons, alter colors or spacing, or change any settings behavior.
- Do not change the global `AppIcons`/Hugeicons API, which remains in use elsewhere.

## Implementation choice
Use a private Settings icon map of `IconData` values from the existing `lucide_icons_flutter` dependency. Render them with Flutter `Icon` widgets in the Settings-only components.
