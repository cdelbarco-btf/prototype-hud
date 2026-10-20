# Prototype HUD · guide

## In short
The HUD is everything around the phone on a prototype page: the header, the rail, the code viewer and the stage. **Every prototype uses the same one**, with the same categories in the same order, so whoever reviews always knows where to look. The code is this package; how to install and update it is in the README.

**The HUD is an internal design tool for reviews, not part of Aura DS** (Christian, Oct 8, 2026). It is built with Aura tokens, but its pieces are local and are not promoted to the DS.

## Anatomy

```
┌───────────────────────────────────────────────────────────────────────────┐
│ ✕ │ Betterfly │ Project    iPhone [SE|18 Pro|…] [Last update Oct 2026] Chris │
│▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔ accent line (brand gradient) ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔│
├────┬──────────────┬──────────────────┬────────────────────────────────────┤
│ ⓘ  │ PANEL        │ CODE VIEWER      │                                    │
│ 🏃 │ (one         │ (only with a     │              STAGE                 │
│ 📂 │  category    │  piece picked    │         (the phone, 1:1)           │
│ ⏚  │  at a time)  │  in Components)  │                                    │
│ 📕 │              │                  │                                    │
│ ⚠3 │              │                  │                                    │
│    │              │                  │                                    │
│ ⚙  │              │                  │                                    │
└────┴──────────────┴──────────────────┴────────────────────────────────────┘
 48      272              400
```

### Text
Single-line text uses Aura's *label* styles (100% line height). **Any text that can wrap** (the question, view and state notes, *Not final*, empty states) uses Aura's paragraph rhythm: `paragraphSmall`, or the *label* with `lineHeight140`. At 100% line height a paragraph looks cramped (Oct 13, 2026).

### Header
A low band in `surfaceInverse`:
- **Left:** the ☰ / ✕ button that folds the rail, in a 48 column, the same width as the icon bar, so they share one vertical axis. Then the Betterfly logo (tinted with `textInverse`), a separator and the project name (`labelLgStrong`).
- **Right:**
  - **The device picker:** a button with the current device (*iPhone 18 Pro Max ⌄*) that opens a tiered dropdown with the HUD's liquid motion. **Platform** as a section (today *iPhone*; Android comes in as another section), **model** as a row, and **variant** unfolded in place when a model has more than one screen (the level exists even though no model uses it today). Everything by click; a click outside closes it. Opens on the **18 Pro**; the phone changes with a fade and a slight shrink, on the `flow` curve. In a narrow window the header hides the author first and then the date, and the device name truncates with an ellipsis. Added Oct 13, 2026.
  - `Last update <Month Year>` as a compact on-dark `AuraTag`.
  - The designer's name (`labelMdStrong`).
- **Bottom edge:** a 2 px line in `AuraGradients.special`.
- No avatar.

### Rail: two levels, 320 wide
The rail is not one long scrolling list. It has **an icon bar (48)** that picks the category and **a panel (272)** that shows only that category.

| Icon | Category | What it shows |
|---|---|---|
| `info` | **Summary** | The round's question (*What we're testing*) and an *On the phone now* card with screen, step, state and open items. Each row is a shortcut to its category |
| `missions` | **Journey** | The screens in the order the person lives them. The current step with its number in lime, the ones walked with ✓, and *Leaves the app* under the ones that leave the app. Tapping a step takes the phone there |
| `files` | **Views** | Every screen the prototype can show, whether or not it is in the flow, in one card per kind: *Screens*, *Sheets and modals*, *Outside the app*. One line per view, with its number of states on the right. Its states open in the *States rail*. Views and Journey stay in sync |
| `learning` | **Components** | How the screen is built. See *Inspector and code viewer* |
| `warning` | **Not final** | What is simulated or undecided (prices, dates, unapproved copy). The icon carries a badge with the count |
| `settings`, at the bottom | **Layout** | The page's measurement controls, to tune the HUD itself. At the end, *Current spec* with the code to copy |

The Journey, Views and Components icons are approximate: Aura has no route, screens or layers icons.

**Solid layers, not transparency:**
- The rail in `surfaceInverseL1`.
- Cards in `surfaceInverseL2`.
- What is selected inside a card in `surfaceInverseL3`.
- The icon bar in `surfaceInverse`.

**Cards** carry an uppercase `labelSm` title with their data on the right: a count, "1 of 4" or "Round 2".

**Spacing, on an 8 grid:**
- **Panel:** 20 around and 20 below its title.
- **Cards:** 12 between them, with 8 of inner margin.
- **Inside a card,** everything starts 16 from the edge: the title, the text and the row labels share the same left edge. In row cards, rows reach 8 from the edge and carry their own 8.
- **Rows:** 2 between them, so the drop never touches its neighbor.
- **Concentric radii:** card `radiusLg` (20) minus 8 of margin gives rows and drop `radiusMd` (12).

### States rail
Since Oct 19, 2026, **States is no longer a category** (Christian): picking the screen and its state is one decision, and jumping between two categories split it in two. A first attempt nested the states under their view inside Views, and the notes made everything warp.

Now, while the rail is on **Views** and the phone's view has states, **a secondary 280 rail opens next to the rail**, between the rail and the stage:
- At the top: `STATES · N`, the view's name (`h3`) and its note.
- Below: **each state is a card** with its title (`labelMdStrong`) and its note, always visible. The selected one has the `interactiveAccentOn` border and the ✓; on hover it lightens to `surfaceInverseL3`.
- Background `surfaceInverse`, one step darker than the rail, with a border on the right.
- It opens and folds like the code viewer (width on `flow`, content comes in when there is room) and the cards come in as a cascade. Leaving Views, or on a view without states, it closes and the stage gets its width back.
- In Summary, the *State* row goes to Views.
- **Groups (Oct 19, 2026):** a `HudState` can carry a `group` (for example *Today* and *Proposal*). The rail shows each group under its `labelSm` header with its count, in the order each group first appears, so what exists today and what is proposed never mix. With a group, the state's name does not repeat the prefix; where it appears alone, as in Summary, `fullLabel` is used (*Today · As it is*). A view without groups reads as a plain list.

In the code: `HudStatesRail` in `lib/src/hud_rail.dart`, the `browsingViews` flag in `HudPrototype` and the slot in `prototype_shell.dart`. First tried in the AI Health Coach prototype.

### Inspector and code viewer
**Inspector**, in Components:
- A *Show on the phone* switch draws the outline of each marked piece over the phone, in its depth's color, like VS Code's bracket rainbow. Each name is labeled once.
- **Structure** is the screen's real tree:
  - It builds itself by reading what is on the phone.
  - Each piece sits under its parent, with indent guides in the same color and its origin on the right.
  - Repeated pieces are grouped (*List item ×12*).
- **By origin** counts the pieces of each origin, with the four categories of the *Design Handoff Guide*: *Aura*, *Aura, modified*, *New, goes to Aura*, *Local*.

**Picking a piece:**
- Pick it by tapping its row in the tree or, **only with Components open**, by clicking it on the phone.
- Hovering the phone highlights the piece underneath before the click.
- A click always picks the innermost piece.
- While picking, the screen's buttons don't react, but scrolling still works.

**Code viewer.** Picking a piece opens a 400 dark gray panel to the right of the rail:
- **Header:** the piece's name, its origin, the file and the line.
- **Code:** the real one, read from the prototype's file. With line numbers, JetBrains Mono, and selectable.
- **Colors:**
  - Brackets in the same rainbow by level.
  - Aura components and tokens in bold teal.
  - Parameters in light blue.
  - Strings in peach.
  - Inspector marks, dimmed.
- **It closes** with its ✕, by tapping the piece again or by changing category.

**Marking pieces.** For the inspector to see them, each piece of the screen is wrapped by hand in `HudComponent(name:, origin:, child:)`. The screen's file is declared as an asset in `pubspec.yaml` so the viewer can read it. It is extra work when building the prototype, but it leaves the handoff's *Components* inventory ready.

**The rainbow** cycles gold, orchid, blue, green and teal, in a dark tone over the phone and a light one over the rail.

## Motion: liquid

**Everything that is HUD moves like a liquid. The only thing that does not is what goes inside the phone**, which keeps Aura's motion because it has to look like the real app (Christian, Oct 9, 2026).

**The curves** are two springs, `HudMotion` in `hud_motion.dart`:

| Curve | How it moves | Where |
|---|---|---|
| `flow` | Starts with momentum, brakes long and settles without bounce | Sizes, fades, colors, folding the rail and the viewer, entrances |
| `wobble` | Arrives, overshoots a little and comes back, like a liquid settling | What travels or appears: the drop, labels, an option's dot, a button's bounce |

Durations are always `AuraMotion` tokens.

**The drop** (`HudLiquidDrop`) marks the selection across the HUD:
- In the icon bar, Journey, Views, the Components tree, the Layout options and the switches' knob.
- When it moves, the leading edge goes first and stretches, and the trailing edge follows.
- While long it thins, and on arrival it gathers with a slight sway.
- If interrupted, it continues from the shape it has.
- In lists it carries the lime bar along.
- If the selection moves to another card, it fades out in one and appears in the other.

**Entrances** (`HudReveal`):
- When the category changes, cards rise a little as they appear, in a cascade.
- In the viewer, code lines come in as a quick cascade.

**Folding:** the rail and the viewer shrink, and their content fades and slides a little toward the edge.

**Changing flow: a new phone** (`HudPhoneSwap`, in `hud_prototype.dart`):
- **Each view belongs to a flow.** In the example: *In the app* (screens, sheets and modals) and *Partner site* (outside the app). Flows go in the order the person lives them.
- **Within the same flow,** the screen changes inside the phone, with the app's navigation.
- **When moving to another flow** from Views or Journey, the phone is swapped with the same physics as the drop:
  - **Chained timing:** the old phone starts first and leaves on `flow`, in `durationXSlow` (500). The new one starts a moment later (22% of the way), overshoots the center a little and comes back on `wobble`, in `durationXxSlow` (800).
  - **Stretch with speed:** while traveling, each phone stretches in the direction of motion and thins in the other, keeping its area. At rest it returns to its shape.
  - **Motion blur** proportional to speed, mostly horizontal.
  - It fades with its distance from the center.
- **Direction:** moving forward in the journey enters from the right; going back, from the left.

## Local components
No HUD piece is an Aura component with its own animation. All are local, with Aura tokens and the liquid curves.

| Piece | File | Replaces |
|---|---|---|
| `HudIconButton`: a circle that sinks and bounces when pressed | `hud_controls.dart` | `AuraIconButton` |
| `HudSwitch`: the knob travels as a drop and the track turns lime | `hud_controls.dart` | `AuraToggle` |
| `HudChoice`: every option visible, with the drop on the selected one and a lime dot. Two options sit side by side | `hud_controls.dart` | `AuraSelect` |
| `HudSlider`: the knob follows the mouse with liquid drag and grows while held | `hud_controls.dart` | Material `Slider` |
| `HudLiquidDrop` and `HudLiquidColumn`: the drop and the list that uses it | `hud_controls.dart` | — |
| `HudReveal`, `HudMotion` | `hud_motion.dart` | — |
| `HudInspector`, `HudComponent` | `hud_inspector.dart` | — |
| `HudCodeView` | `hud_code_view.dart` | — |

`AuraTag` and `AuraDivider`, which have no animation, are still Aura's.

## Rules

- **The HUD is in US English**, because engineering and product read it.
- **Aura tokens always:** color, typography, spacing, radii and durations.
- **Deep links are mandatory:** every view and every state has its URL, for example `?view=page&state=offline&entry=semaglutide`. They are for:
  - review links;
  - the handoff;
  - automated captures (headless Chrome can't click).
- **The URL without a hash opens the prototype.** With a story hash, it opens the storybook.
- **The rail drives the feature, not the layout.** Measurements come from `LayoutSpec`, and their controls live in the Layout category.
- **The header date computes itself**, as month and year (*Oct 2026*), from when the prototype's code changed. **It is never today's date:** a prototype nobody touched in three months has to look three months old.
  - `tool/stamp_last_update.py` writes it to `lib/last_update.g.dart`.
  - In a git repo it uses the last commit that touched the prototype's folder, or the files' dates if there are uncommitted changes. Outside git, the newest file.
  - The dev watcher runs it on every change. **Run it before every build:** `python3 tool/stamp_last_update.py`.
  - Until Oct 9, 2026 it was a hand-written constant, and it was stuck in August without anyone noticing.
- **Lime (`interactiveAccentOn`) is only for what is active:**
  - the open category's icon;
  - the current step;
  - the selected row's bar;
  - the selected option's dot;
  - the switch when on;
  - the header line.

  That is exactly why strings in the code viewer are peach.
- **What is not in this guide is not added to a project's HUD** without updating the guide first. That way the copies don't drift apart again.

## DS gaps the HUD uses
Values that are not Aura semantic tokens because Aura doesn't have them. Noted here for reference; they are not requested from the DS.

| What | What is used today |
|---|---|
| Categorical palette (the rainbow) | Base colors: `amber`, `indigo`/`orchid`, `sky`, `emerald`, `teal` |
| Dark gray surface (the viewer) | `neutral950`, `neutral900`, `neutral800` |
| Monospace style | JetBrains Mono via `google_fonts`, at `labelSm`'s size |
| Spring curves | `HudMotion.flow` and `wobble` |
| Motion proportions | The drop thins 12% of what it stretches; the button sinks to 88%; the slider knob grows to 130%; the active icon, to 110%; content slides 4% when folding; when changing flow, the phone travels 110% of its width, stretches 5% per unit of speed (up to 22%) and blurs up to 12 px |

## Files

| File | What it is |
|---|---|
| `lib/src/prototype_shell.dart` | The assembly: header, rail, viewer and stage, and the Layout controls |
| `lib/src/hud_rail.dart` | The rail: the icon bar, each category's panel and the states rail |
| `lib/src/hud_controls.dart` | The local controls and the drop |
| `lib/src/hud_motion.dart` | The liquid curves and the cascading entrances |
| `lib/src/hud_inspector.dart` | The inspector: marks, tree, outlines and picking on the phone |
| `lib/src/hud_code_view.dart` | The code viewer |
| `lib/src/hud_content.dart` | The prototype as data: views, journey, states, Not final |
| `lib/src/hud_prototype.dart` | What the phone shows (view, flow, state) and the phone swap between flows |
| `lib/src/layout_spec.dart` | The layout as data: every measurement in one object |
| `lib/src/device_stage.dart` | The phone and the 1:1 scale |
| `lib/src/hud_devices.dart` | The devices and the header's picker. SE 375 × 667, 18 Pro 402 × 874, 18 Pro Max 440 × 956. Android comes in with `platform: 'Android'`. `HudDeviceScope.of(context)` tells the screen which device is on the stage |
| `tool/stamp_last_update.py` | Computes the header's date from the code |
| `example/` | The HUD with a generic screen, to try changes to the HUD itself |

**Links:** `?view=<id>&state=<id>` opens the phone on that view and state, and `?device=se|18-pro|18-pro-max` on that device.

**The code viewer** opens beside the rail if it fits while leaving 360 for the phone; in a narrower window, it opens over the phone.
