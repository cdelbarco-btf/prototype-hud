# prototype_hud: reglas

Este paquete es el HUD de los prototipos de diseño de Betterfly. Lo usan varios diseñadores en sus prototipos, así que **un cambio acá le llega a todos** con el próximo `flutter pub upgrade prototype_hud`. La guía completa está en `GUIDE.md`: léela antes de cambiar algo.

## Reglas que no se rompen

- **El HUD no es Aura DS.** Es una herramienta interna de revisión. Sus piezas son locales y no se promueven al DS ni se le piden a Aura.
- **Tokens de Aura siempre**, también en el HUD: color, tipografía, espaciado, radios y duraciones. Antes de dar algo por terminado, busca valores crudos (`Color(0x`, números sueltos de padding o radio, `Duration(milliseconds:`) en lo que tocaste. Los únicos valores fuera de tokens son los de la tabla *Huecos del DS que el HUD usa* de la guía.
- **Movimiento:** todo lo del HUD se mueve con `HudMotion` (`flow` y `wobble`). **Lo que va dentro del teléfono no**: usa el movimiento de Aura (`AuraMotion`), porque tiene que verse como la app real.
- **El lime (`interactiveAccentOn`) es sólo para lo activo**: categoría abierta, paso actual, fila elegida, opción elegida, switch encendido, línea del header.
- **El HUD va en inglés de EE.UU.** (`color`, `behavior`, sentence case). Las conversaciones y esta documentación pueden ir en español.
- **Texto de varias líneas** usa ritmo de párrafo (`paragraphSmall` o el label con `lineHeight140`); los labels de interlineado 100% son sólo para una línea.
- **Espaciado y radios:** revisa a 2x antes de mostrar cualquier cambio de UI. Retícula de 8; radios concéntricos (tarjeta 20, menos 8 de margen, filas 12).
- **Lo que no está en la guía no se agrega al HUD** sin actualizar primero `GUIDE.md`. Así las copias no divergen.

## En un prototipo

- El prototipo vive en `aura_ds/ds/example/lib/<prototipo>/`, en una rama `prototype/<slug>`. **Nunca se toca `ds/lib`.**
- El contenido es siempre datos (`HudContent`); el HUD no trae pantallas ni copy propios.
- Cada vista y cada estado tiene deep link (`?view=&state=`): sirve para revisión, handoff y capturas headless.
- La fecha del header la calcula `tool/stamp_last_update.py`; nunca se escribe a mano ni es la fecha de hoy.

## Cambiar el HUD

- Se cambia acá, no en la copia de un prototipo. Prueba en `example/` con `flutter run -d chrome`.
- `flutter analyze lib` sin errores, y `flutter build web --profile --no-tree-shake-icons` en `example/` antes de pushear.
- Un cambio que rompe la API (`PrototypeShell`, `HudContent` y sus clases) se avisa y se versiona con un tag nuevo.
