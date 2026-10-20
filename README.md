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

Links: `?view=<id>&state=<id>&device=se|18-pro|18-pro-max`.

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

Before pushing: `flutter analyze lib` with no errors, and the example built with `flutter build web --profile --no-tree-shake-icons`.
