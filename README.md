# prototype_hud

El HUD de los prototipos de Betterfly: todo lo que rodea al teléfono en la página de un prototipo (header, rail, visor de código y escenario). **Es una herramienta interna de diseño para revisar, no es parte de Aura DS.** Se arma con tokens de Aura.

Mantiene: Christian Del Barco. Cómo es y por qué, en [GUIDE.md](GUIDE.md). Las reglas para trabajar con Claude Code, en [CLAUDE.md](CLAUDE.md).

## Instalar en un prototipo

El prototipo vive en `aura_ds/ds/example`, en una rama `prototype/<slug>`. En `ds/example/pubspec.yaml`:

```yaml
dependencies:
  prototype_hud:
    git:
      url: https://github.com/cdelbarco-btf/prototype-hud.git
      ref: main

dependency_overrides:
  # El HUD pide Aura desde git; dentro de aura_ds usamos el Aura de la rama.
  aura_ds:
    path: ../
```

Después:

```bash
flutter pub get
```

## Recibir actualizaciones

Cuando el HUD cambia, cada prototipo lo trae con:

```bash
flutter pub upgrade prototype_hud
```

`pubspec.lock` guarda la versión exacta: hasta que corras ese comando, tu prototipo no cambia solo. Para fijar una versión, cambia `ref: main` por un tag (`ref: v1.0.0`).

## Usarlo

```dart
import 'package:prototype_hud/prototype_hud.dart';

PrototypeShell(
  title: 'GLP-1 v2',
  author: 'Your name',
  lastUpdated: lastUpdate,          // generado, ver abajo
  content: content,                 // HudContent: el prototipo como datos
  sources: const ['lib/my_prototype.dart'], // para el visor de código
  screen: (context, p) => myScreen(p.view, p.state),
)
```

1. **Describe el prototipo como datos** con `HudContent`: la pregunta, las vistas por flujo (`HudViewGroup`, `HudView`), el recorrido (`HudJourneyStep`), los estados (`HudState`, con `group` si hay versiones) y lo no final (`HudOpenItem`). El HUD no trae contenido propio.
2. **`screen`** arma la pantalla para `p.view` y `p.state`. Para navegar desde la pantalla: `p.show('view', flow)`.
3. **Marca las piezas** de cada pantalla con `HudComponent(name:, origin:, child:)` para el inspector, y declara el archivo de la pantalla como asset en el `pubspec`, para el visor de código.
4. **Estampa la fecha antes de cada build.** Copia `tool/stamp_last_update.py` a tu `ds/example/tool/` y corre:

   ```bash
   python3 tool/stamp_last_update.py --out lib/<prototipo>/last_update.g.dart lib/<prototipo> lib/<entrada>.dart
   ```

Links: `?view=<id>&state=<id>&device=se|18-pro|18-pro-max`.

## Probar cambios al HUD

```bash
cd example
flutter run -d chrome
```

Para probarlo contra tu clon local de Aura en vez del de git, crea `example/pubspec_overrides.yaml` (no se sube):

```yaml
dependency_overrides:
  aura_ds:
    path: /ruta/a/tu/aura_ds/ds
```

Antes de pushear: `flutter analyze lib` sin errores y el ejemplo construido con `flutter build web --profile --no-tree-shake-icons`.
