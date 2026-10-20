# prototype_hud: rules

This package is the HUD for Betterfly's design prototypes. Several designers use it in their prototypes, so **a change here reaches everyone** with their next `flutter pub upgrade prototype_hud`. The full guide is in `GUIDE.md`: read it before changing anything.

## Rules that never break

- **The HUD is not Aura DS.** It is an internal review tool. Its pieces are local; they are not promoted to the DS or requested from Aura.
- **Aura tokens always**, in the HUD too: color, typography, spacing, radii and durations. Before calling something done, look for raw values (`Color(0x`, loose padding or radius numbers, `Duration(milliseconds:`) in what you touched. The only values outside tokens are the ones in the guide's *DS gaps the HUD uses* table.
- **Motion:** everything in the HUD moves with `HudMotion` (`flow` and `wobble`). **What goes inside the phone does not**: it uses Aura's motion (`AuraMotion`), because it has to look like the real app.
- **Lime (`interactiveAccentOn`) is only for what is active**: open category, current step, selected row, selected option, switch on, header line.
- **The HUD is in US English** (`color`, `behavior`, sentence case). This documentation is in English too.
- **Multi-line text** uses paragraph rhythm (`paragraphSmall`, or the label with `lineHeight140`); 100% line-height labels are for a single line only.
- **Spacing and radii:** check at 2x before showing any UI change. 8 grid; concentric radii (card 20, minus 8 of margin, rows 12).
- **What is not in the guide is not added to the HUD** without updating `GUIDE.md` first. That way the copies don't drift.

## In a prototype

- The prototype lives in `aura_ds/ds/example/lib/<prototype>/`, on a `prototype/<slug>` branch. **`ds/lib` is never touched.**
- Content is always data (`HudContent`); the HUD ships no screens or copy of its own.
- Every view and every state has a deep link (`?view=&state=`): for review, handoff and headless captures.
- The header's date is computed by `tool/stamp_last_update.py`; it is never written by hand and is never today's date.

## Changing the HUD

- Change it here, not in a prototype's copy. Try it in `example/` with `flutter run -d chrome`.
- `flutter analyze lib` with no errors, and `flutter build web --profile --no-tree-shake-icons` in `example/`, before pushing.
- A change that breaks the API (`PrototypeShell`, `HudContent` and its classes) is announced and released under a new tag.
