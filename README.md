# prototype_hud

The HUD for Betterfly's design prototypes: everything around the phone on a prototype page (header, rail, code viewer and stage). **It is an internal design review tool, not part of Aura DS.** It is built with Aura tokens.

Maintained by Christian Del Barco. What it is and why, in [GUIDE.md](GUIDE.md). The rules for working on it with Claude Code, in [CLAUDE.md](CLAUDE.md).

## Install it in a prototype

Prototypes live in `aura_ds/ds/example`, on a `prototype/<slug>` branch. In `ds/example/pubspec.yaml`:

```yaml
dependencies:
  prototype_hud:
    git:
      url: https://github.com/cdelbarco-btf/prototype-hud.git
      ref: main

dependency_overrides:
  # The HUD asks for Aura from git; inside aura_ds, use the branch's own Aura.
  aura_ds:
    path: ../
```

Then:

```bash
flutter pub get
```

## Get updates

When the HUD changes, each prototype picks it up with:

```bash
flutter pub upgrade prototype_hud
```

`pubspec.lock` pins the exact version: your prototype does not change until you run that command. To stay on a version, replace `ref: main` with a tag (`ref: v1.0.0`).

## Use it

```dart
import 'package:prototype_hud/prototype_hud.dart';

PrototypeShell(
  title: 'GLP-1 v2',
  author: 'Your name',
  lastUpdated: lastUpdate,          // generated, see below
  content: content,                 // HudContent: the prototype as data
  sources: const ['lib/my_prototype.dart'], // for the code viewer
  screen: (context, p) => myScreen(p.view, p.state),
)
```

1. **Describe the prototype as data** with `HudContent`: the question, the views by flow (`HudViewGroup`, `HudView`), the journey (`HudJourneyStep`), the states (`HudState`, with `group` when there are versions) and what is not final (`HudOpenItem`). The HUD ships no content of its own.
2. **`screen`** builds the screen for `p.view` and `p.state`. To navigate from the screen: `p.show('view', flow)`.
3. **Mark the pieces** of each screen with `HudComponent(name:, origin:, child:)` for the inspector, and declare the screen's file as an asset in `pubspec.yaml` for the code viewer.
4. **Stamp the date before every build.** Copy `tool/stamp_last_update.py` to your `ds/example/tool/` and run:

   ```bash
   python3 tool/stamp_last_update.py --out lib/<prototype>/last_update.g.dart lib/<prototype> lib/<entry>.dart
   ```

Links: `?flow=<id>&view=<id>&state=<id>&device=se|18-pro|18-pro-max`.

## The rail: Summary, Navigator, Layout

Since Nov 12, 2026 the rail has three categories instead of six. Journey, Views and Components became one, the **Navigator**, and Not final moved into Summary and onto the screens it belongs to. The details are in [GUIDE.md](GUIDE.md).

| Category | What it shows |
|---|---|
| **Summary** | The round's question, what is on the phone now (screen, flow, step, state), the view's note, and the open items that belong to no screen. |
| **Navigator** | Everything to move around and inspect, top to bottom: the flow pickers, the steps (with each step's states and open items), the views outside the journey, and Inspect mode. |
| **Layout** | The page's measurements. |

### Name the Navigator

Call it what your steps are, for example *Sessions*:

```dart
HudContent(
  journeyLabel: 'Sessions',          // default 'Navigator'
  journeyTitle: 'Steps in order',
  ...
)
```

### Flows, in groups

A prototype with several tasks lists them as user flows. A dropdown above the steps picks one. Give flows a `group` (a session, a module) and a second dropdown appears: first the group, then the flow inside it.

```dart
userFlows: [
  HudUserFlow('create', 'Create an item', group: 'Module 1',
      views: [...], journey: [...]),
  HudUserFlow('delete', 'Delete an item', group: 'Module 1',
      views: [...], journey: [...]),
],
```

`flow.inGroup('Module 1')` returns a copy of a flow in that group, and `content.copyWith(...)` builds new content from another prototype's, to reuse its flows as one group:

```dart
final content = otherContent.copyWith(
  journeyLabel: 'Modules',
  userFlows: [for (final f in otherContent.userFlows) f.inGroup('Module 1')],
);
```

### Entry points

When a flow can start in several places (a push, the home, a chat), tag its first steps with `entry`. Steps without `entry` are shared: they follow every entry point.

```dart
journey: [
  HudJourneyStep('home', state: 'invite', lead: '1a', entry: 'Home banner'),
  HudJourneyStep('push', state: 'arrives', lead: '1d', entry: 'Push'),
  HudJourneyStep('chat', state: 'want', lead: '2'),   // shared
  HudJourneyStep('chat', state: 'signed', lead: '6'), // shared
],
```

The Navigator then shows one collapsible card per entry point. Opening one shows its steps and then the shared ones, sends the phone to its first step and closes the previous card.

### Not final, where it belongs

```dart
notFinal: [
  HudOpenItem('Prices', 'Placeholder until Fran confirms'),           // Summary
  HudOpenItem('Home layout', 'Placeholder screen', view: 'home'),     // on that screen
  HudOpenItem('Copy', 'Draft', view: 'chat', state: 'signed'),        // on that state
],
```

Items with a `view` show on that step in the Navigator, with a ⚠ and their count. The others go to Summary, and the Summary icon shows how many there are.

### Inspect mode

The pieces and their code stay hidden until **Inspect** is turned on, at the end of the Navigator. While it is off, the phone behaves like the app. With it on, the pieces are outlined on the phone, the tree and *By origin* appear, and clicking a piece (in the tree or on the phone) opens its code. Changing step or state, or turning Inspect off, closes the code viewer.

## Hot reload while you work

`tool/dev.sh` runs the prototype on a web server and reloads it every time you save a `.dart` file. It also stamps the header's date. Copy it next to `stamp_last_update.py` in your `ds/example/tool/` and run it from `ds/example`:

```bash
zsh tool/dev.sh lib/<entry>.dart lib/<prototype>/last_update.g.dart lib/<prototype>
```

Open `http://localhost:8095` and reload the tab once after the first build. `PORT=8096` changes the port. `HUD=/path/to/prototype-hud` also watches a local clone of the HUD, for when you try HUD changes from a prototype (with a `pubspec_overrides.yaml` pointing at it).

## What changed on Nov 12, 2026

None of these break the API: prototypes keep compiling, and the new fields are optional.

- **The rail is now Summary, Navigator and Layout.** Journey, Views and Components merged into the Navigator. Not final went into Summary, and onto screens with `HudOpenItem(view:, state:)`. The side states rail is gone; states unfold inside the current step.
- **Only the chosen state is highlighted.** The current step is marked by its lime number alone, so what it unfolds no longer looks selected.
- **Flow pickers** sit right above the steps, without a card or a note under them, and without the *All views* option. Groups (`HudUserFlow.group`) add a second picker.
- **Entry points** (`HudJourneyStep.entry`) turn the steps into one collapsible card per entry point.
- **Inspect mode:** the component tree and code only show with Inspect on.
- **New in the API:** `HudContent.journeyLabel`, `HudContent.copyWith`, `HudContent.generalOpenItems` and `openItemsOn`, `HudContent.flowGroups`, `HudUserFlow.group` and `inGroup`, `HudJourneyStep.entry`, `HudOpenItem.view` and `state`.
- **Fixes:** the component tree no longer breaks the rail when the phone changes state (a piece not laid out yet sorted with a null). On a narrow window the header hides the wordmark below 600 px and the device picker shrinks, and the rail is never wider than the window, so nothing overflows.
- **`tool/dev.sh`** for hot reload on save.

## Try changes to the HUD

```bash
cd example
flutter run -d chrome
```

To try it against your local Aura clone instead of the one from git, create `example/pubspec_overrides.yaml` (not committed):

```yaml
dependency_overrides:
  aura_ds:
    path: /path/to/your/aura_ds/ds
```

Before pushing: `flutter analyze lib` with no errors, and the example built with `flutter build web --profile --no-tree-shake-icons`. Build it against the Aura from git (without your `pubspec_overrides.yaml`), since that is what prototypes use: a newer local clone may have renamed members the HUD still uses for older prototypes (`AuraTagSize.compact`).
