# Lucide Bottom Navigation Icons — Design

## Intent
Replace the Home, Tasks, and Progress bottom-navigation glyphs with Lucide icons as the first step in the app-wide icon-family change.

## Goals
- Use Lucide house, list/todo, and rising-chart glyphs for Home, Tasks, and Progress.
- Preserve the current labels, order, dimensions, selection colors, tap behavior, and selected accessibility semantics.
- Keep the change limited to the bottom bar in this pass.

## Non-goals and anti-goals
- Do not change icons elsewhere yet, including the separate Settings button, logo, or brand assets.
- Do not alter navigation behavior, spacing, typography, or color tokens.
- Avoid introducing a filled active glyph if that makes the set inconsistent; keep the current selected-color treatment.

## Approaches considered
- **Lucide**: crisp, minimal outline shapes; selected for the clean visual direction and consistent line weight.
- **Material Symbols Rounded**: familiar Android feel and easy filled active state, but more platform-standard in character.
- **Phosphor**: rounded shapes with flexible weights, but slightly more expressive than the desired minimal look.

## Implementation choice
Use Lucide glyphs in the existing `_BottomNav` for Home, Tasks, and Progress, preserving the current 22 px size and primary/muted colors. Keep the existing semantic `AppIcons`/Hugeicons renderer for the rest of the app in this first pass.

## Constraints and remaining calls
The Flutter package/API mapping for the selected Lucide glyphs must be verified during implementation. Package choice and exact glyph constants are implementation details; choose a maintained Flutter Lucide package and the closest semantic equivalents.
