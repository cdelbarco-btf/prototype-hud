# Prototype HUD · guía

## En corto
El HUD es todo lo que rodea al teléfono en la página de un prototipo: el header, el rail, el visor de código y el escenario. **Todos los prototipos usan el mismo**, con las mismas categorías en el mismo orden, para que quien revisa sepa siempre dónde mirar. El código es este paquete; cómo instalarlo y actualizarlo está en el README.

**El HUD es una herramienta interna de diseño para revisar, no es parte de Aura DS** (Christian, 8 oct 2026). Se arma con tokens de Aura, pero sus piezas son locales y no se promueven al DS.

## Anatomía

```
┌───────────────────────────────────────────────────────────────────────────┐
│ ✕ │ Betterfly │ Proyecto   iPhone [SE|18 Pro|…] [Last update Oct 2026] Chris │
│▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔ línea de acento (gradiente de marca) ▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔│
├────┬──────────────┬──────────────────┬────────────────────────────────────┤
│ ⓘ  │ PANEL        │ VISOR DE CÓDIGO  │                                    │
│ 🏃 │ (una         │ (sólo con una    │            ESCENARIO               │
│ 📂 │  categoría   │  pieza elegida   │        (el teléfono, 1:1)          │
│ ⏚  │  a la vez)   │  en Components)  │                                    │
│ 📕 │              │                  │                                    │
│ ⚠3 │              │                  │                                    │
│    │              │                  │                                    │
│ ⚙  │              │                  │                                    │
└────┴──────────────┴──────────────────┴────────────────────────────────────┘
 48      272              400
```

### Texto
Los textos de una línea usan los estilos *label* de Aura (interlineado 100%). **Todo texto que pueda ocupar varias líneas** (la pregunta, las notas de vista y de estado, *Not final*, los estados vacíos) usa el ritmo de párrafo de Aura: `paragraphSmall`, o el *label* con `lineHeight140`. Con interlineado de 100%, un párrafo queda apretado (13 oct 2026).

### Header
Una franja baja en `surfaceInverse`:
- **Izquierda:** el botón ☰ / ✕ que pliega el rail, en una columna de 48, el mismo ancho que la barra de íconos, para que quede en el mismo eje vertical. Después, el logo de Betterfly (teñido con `textInverse`), un separador y el nombre del proyecto (`labelLgStrong`).
- **Derecha:**
  - **El selector de dispositivo:** un botón con el dispositivo actual (*iPhone 18 Pro Max ⌄*) que abre un dropdown por niveles, con el movimiento líquido del HUD. **Plataforma** como sección (hoy *iPhone*; Android entra como otra sección), **modelo** como fila, y **variante** desplegada en el lugar cuando un modelo tiene más de una pantalla (el nivel existe aunque hoy ningún modelo lo usa). Todo con clic; un clic afuera lo cierra. Abre en el **18 Pro**; el teléfono cambia con un fundido y un leve achique, con la curva `flow`. Si la ventana es angosta, el header oculta primero el autor y después la fecha, y el nombre del dispositivo se corta con puntos suspensivos. Agregado el 13 oct 2026.
  - `Last update <Mes Año>` como `AuraTag` compacto on-dark.
  - El nombre del diseñador (`labelMdStrong`).
- **Borde inferior:** una línea de 2 px con `AuraGradients.special`.
- Sin avatar.

### Rail: dos niveles, 320 de ancho
El rail no es una lista larga con scroll. Tiene **una barra de íconos (48)** que elige la categoría y **un panel (272)** que muestra sólo esa categoría.

| Ícono | Categoría | Qué muestra |
|---|---|---|
| `info` | **Summary** | La pregunta de la ronda (*What we're testing*) y una tarjeta *On the phone now* con pantalla, paso, estado e ítems sin cerrar. Cada fila es un atajo a su categoría |
| `missions` | **Journey** | Las pantallas en el orden en que la persona las vive. El paso actual con el número en lime, los recorridos con ✓ y *Leaves the app* bajo los que salen de la app. Tocar un paso lleva el teléfono ahí |
| `files` | **Views** | Todas las pantallas que el prototipo puede mostrar, estén o no en el flujo, en una tarjeta por tipo: *Screens*, *Sheets and modals*, *Outside the app*. Una línea por vista, con su cantidad de estados a la derecha. Sus estados se abren en el *Rail de estados*. Views y Journey van sincronizados |
| `learning` | **Components** | Cómo está construida la pantalla. Ver *Inspector y visor de código* |
| `warning` | **Not final** | Lo simulado o no decidido (precios, fechas, copy sin aprobar). El ícono lleva un globo con la cantidad |
| `settings`, abajo | **Layout** | Los controles de medidas de la página, para afinar el propio HUD. Al final, *Current spec* con el código para copiar |

Los íconos de Journey, Views y Components son aproximados: Aura no tiene íconos de ruta, pantallas ni capas.

**Capas sólidas, no transparencias:**
- El rail en `surfaceInverseL1`.
- Las tarjetas en `surfaceInverseL2`.
- Lo elegido dentro de una tarjeta en `surfaceInverseL3`.
- La barra de íconos en `surfaceInverse`.

**Las tarjetas** llevan un título en mayúsculas `labelSm` y su dato a la derecha: una cantidad, "1 of 4" o "Round 2".

**Espaciado, sobre una retícula de 8:**
- **Panel:** 20 alrededor y 20 bajo su título.
- **Tarjetas:** 12 entre una y otra, con 8 de margen interno.
- **Dentro de una tarjeta,** todo arranca a 16 del borde: el título, el texto y las etiquetas de las filas comparten el mismo borde izquierdo. En las tarjetas de filas, las filas llegan a 8 del borde y llevan sus propios 8.
- **Filas:** 2 entre una y otra, para que la gota no toque a la vecina.
- **Radios concéntricos:** tarjeta `radiusLg` (20) menos 8 de margen da filas y gota en `radiusMd` (12).

### Rail de estados
Desde el 19 oct 2026, **States ya no es una categoría** (Christian): elegir la pantalla y su estado es una sola decisión, y saltar entre dos categorías la partía en dos. Un primer intento anidó los estados bajo su vista dentro de Views, y con las notas se deformaba todo.

Ahora, mientras el rail está en **Views** y la vista del teléfono tiene estados, se abre **un rail secundario de 280 al lado del rail**, entre el rail y el escenario:
- Arriba: `STATES · N`, el nombre de la vista (`h3`) y su nota.
- Debajo: **cada estado es una tarjeta** con su título (`labelMdStrong`) y su nota, siempre a la vista. La elegida lleva el borde `interactiveAccentOn` y el ✓; con hover se aclara a `surfaceInverseL3`.
- Fondo `surfaceInverse`, un escalón más oscuro que el rail, con un borde a la derecha.
- Se abre y se pliega como el visor de código (ancho con `flow`, el contenido entra cuando hay lugar) y las tarjetas entran en cascada. Al salir de Views, o con una vista sin estados, se cierra y el escenario recupera el ancho.
- En Summary, la fila *State* lleva a Views.
- **Grupos (19 oct 2026):** un `HudState` puede llevar `group` (por ejemplo *Today* y *Proposal*). El rail muestra cada grupo bajo su encabezado en `labelSm` con su cantidad, en el orden en que aparece cada grupo, así lo de hoy y lo propuesto no se mezclan. Con grupo, el nombre del estado no repite el prefijo; donde aparece solo, como en Summary, se usa `fullLabel` (*Today · As it is*). Una vista sin grupos se ve como una lista simple.

En el código: `HudStatesRail` en `lib/src/hud_rail.dart`, el flag `browsingViews` en `HudPrototype` y el hueco en `prototype_shell.dart`. Probado primero en el prototipo de AI Health Coach.

### Inspector y visor de código
**Inspector**, en Components:
- Un switch *Show on the phone* dibuja sobre el teléfono el contorno de cada pieza marcada, con el color de su profundidad, como el arcoíris de llaves de VS Code. Cada nombre se etiqueta una vez.
- **Structure** es el árbol real de la pantalla:
  - Se arma solo, leyendo lo que hay en el teléfono.
  - Cada pieza va bajo su padre, con guías de indentación del mismo color y su origen a la derecha.
  - Las piezas repetidas se agrupan (*List item ×12*).
- **By origin** cuenta las piezas de cada origen, con las cuatro categorías de la *Design Handoff Guide*: *Aura*, *Aura, modified*, *New, goes to Aura*, *Local*.

**Elegir una pieza:**
- Se elige tocando su fila en el árbol o, **sólo con Components abierto**, haciendo clic sobre ella en el teléfono.
- Al pasar el mouse por el teléfono, la pieza de abajo se ilumina antes del clic.
- El clic elige siempre la pieza más interna.
- Mientras se elige, los botones de la pantalla no reaccionan, pero el scroll sí funciona.

**Visor de código.** Al elegir una pieza, se abre a la derecha del rail un panel de 400 en gris oscuro:
- **Encabezado:** el nombre de la pieza, su origen, el archivo y la línea.
- **Código:** el de verdad, leído del archivo del prototipo. Lleva números de línea, JetBrains Mono, y se puede seleccionar.
- **Colores:**
  - Llaves con el mismo arcoíris por nivel.
  - Componentes y tokens de Aura en teal y negrita.
  - Parámetros en celeste.
  - Textos en durazno.
  - Las marcas del inspector, atenuadas.
- **Se cierra** con su ✕, tocando de nuevo la pieza o cambiando de categoría.

**Marcar las piezas.** Para que el inspector las vea, cada pieza de la pantalla se envuelve a mano con `HudComponent(name:, origin:, child:)`. El archivo de la pantalla se declara como asset en el `pubspec` para que el visor pueda leerlo. Es trabajo extra al armar el prototipo, pero deja listo el inventario de *Components* del handoff.

**El arcoíris** cicla dorado, orquídea, azul, verde y teal, en tono oscuro sobre el teléfono y claro sobre el rail.

## Movimiento: líquido

**Todo lo que es HUD se mueve como un líquido. Lo único que no es lo que va dentro del teléfono**, que mantiene el movimiento de Aura porque tiene que verse como la app real (Christian, 9 oct 2026).

**Las curvas** son dos resortes, `HudMotion` en `hud_motion.dart`:

| Curva | Cómo se mueve | Dónde |
|---|---|---|
| `flow` | Arranca con impulso, frena largo y se asienta sin rebote | Tamaños, fundidos, colores, plegar el rail y el visor, entradas |
| `wobble` | Llega, se pasa un poco y vuelve, como un líquido que se acomoda | Lo que viaja o aparece: la gota, las etiquetas, el punto de una opción, el rebote de un botón |

Las duraciones son siempre tokens de `AuraMotion`.

**La gota** (`HudLiquidDrop`) marca la selección en todo el HUD:
- En la barra de íconos, Journey, Views, el árbol de Components, las opciones de Layout y la perilla de los switches.
- Al moverse, el borde que va adelante sale primero y se estira, y el de atrás lo sigue.
- Mientras está larga se afina, y al llegar se recoge con un leve vaivén.
- Si se interrumpe, sigue desde la forma que tiene.
- En las listas lleva consigo la barra lime.
- Si la selección pasa a otra tarjeta, en una se desvanece y en la otra aparece.

**Las entradas** (`HudReveal`):
- Al cambiar de categoría, las tarjetas suben un poco mientras aparecen, en cascada.
- En el visor, las líneas de código entran en cascada rápida.

**Plegar:** el rail y el visor se achican, y su contenido se desvanece y se desliza un poco hacia el borde.

**Cambio de flujo: un teléfono nuevo** (`HudPhoneSwap`, en `hud_prototype.dart`):
- **Cada vista pertenece a un flujo.** En el ejemplo: *In the app* (pantallas, hojas y modales) y *Partner site* (fuera de la app). Los flujos van en el orden en que la persona los vive.
- **Dentro del mismo flujo,** la pantalla cambia dentro del teléfono, con la navegación de la app.
- **Al pasar a otro flujo** desde Views o Journey, el teléfono se cambia con la misma física de la gota:
  - **Tiempos encadenados:** el teléfono viejo arranca primero y se va con `flow`, en `durationXSlow` (500). El nuevo sale un instante después (22% del recorrido), se pasa un poco del centro y vuelve con `wobble`, en `durationXxSlow` (800).
  - **Estirar según la velocidad:** mientras viaja, cada teléfono se estira en la dirección del movimiento y se afina en la otra, conservando su área. En reposo vuelve a su forma.
  - **Desenfoque de movimiento** proporcional a la velocidad, sobre todo horizontal.
  - Se desvanece según qué tan lejos está del centro.
- **Sentido:** avanzar en el recorrido entra desde la derecha; volver, desde la izquierda.

## Componentes locales
Ninguna pieza del HUD es un componente de Aura con animación propia. Todas son locales, con tokens de Aura y las curvas líquidas.

| Pieza | Archivo | Reemplaza a |
|---|---|---|
| `HudIconButton`: círculo que se hunde y rebota al presionarlo | `hud_controls.dart` | `AuraIconButton` |
| `HudSwitch`: la perilla viaja como gota y el fondo pasa a lime | `hud_controls.dart` | `AuraToggle` |
| `HudChoice`: todas las opciones a la vista, con la gota en la elegida y un punto lime. Dos opciones van lado a lado | `hud_controls.dart` | `AuraSelect` |
| `HudSlider`: la perilla sigue al mouse con arrastre líquido y crece al sostenerla | `hud_controls.dart` | `Slider` de Material |
| `HudLiquidDrop` y `HudLiquidColumn`: la gota y la lista que la usa | `hud_controls.dart` | — |
| `HudReveal`, `HudMotion` | `hud_motion.dart` | — |
| `HudInspector`, `HudComponent` | `hud_inspector.dart` | — |
| `HudCodeView` | `hud_code_view.dart` | — |

Siguen siendo de Aura `AuraTag` y `AuraDivider`, que no tienen animación.

## Reglas

- **El HUD va en inglés de EE.UU.**, porque lo leen ingeniería y producto.
- **Tokens de Aura siempre:** color, tipografía, espaciado, radios y duraciones.
- **Deep links obligatorios:** cada vista y cada estado tiene su URL, por ejemplo `?view=page&state=offline&entry=semaglutide`. Sirven para:
  - los links de revisión;
  - el handoff;
  - las capturas automáticas (Chrome headless no puede hacer clic).
- **La URL sin hash abre el prototipo.** Con un hash de story, abre el storybook.
- **El rail maneja el feature, no el layout.** Las medidas salen de `LayoutSpec`, y sus controles viven en la categoría Layout.
- **La fecha del header se calcula sola**, en mes y año (*Oct 2026*), a partir de cuándo cambió el código del prototipo. **Nunca es la fecha de hoy:** un prototipo que nadie tocó en tres meses tiene que verse de hace tres meses.
  - La escribe `tool/stamp_last_update.py` en `lib/last_update.g.dart`.
  - En un repo de git usa el último commit que tocó la carpeta del prototipo, o la fecha de los archivos si hay cambios sin commitear. Fuera de git, el archivo más reciente.
  - El watcher de desarrollo la corre en cada cambio. **Hay que correrla antes de cada build:** `python3 tool/stamp_last_update.py`.
  - Hasta el 9 de octubre de 2026 era una constante a mano, y quedó en agosto sin que nadie lo notara.
- **El lime (`interactiveAccentOn`) se usa sólo para lo activo:**
  - el ícono de la categoría abierta;
  - el paso actual;
  - la barra de la fila elegida;
  - el punto de la opción elegida;
  - el switch encendido;
  - la línea del header.
  
  Los textos del visor de código van en durazno justamente por esto.
- **Lo que no está en esta spec, no se agrega al HUD de un proyecto** sin actualizar primero la spec. Así no vuelven a divergir.

## Huecos del DS que el HUD usa
Valores que no son tokens semánticos de Aura porque Aura no los tiene. Quedan anotados como referencia; no se le piden al DS.

| Qué | Qué se usa hoy |
|---|---|
| Paleta categórica (el arcoíris) | Colores base: `amber`, `indigo`/`orchid`, `sky`, `emerald`, `teal` |
| Superficie gris oscura (el visor) | `neutral950`, `neutral900`, `neutral800` |
| Estilo monoespaciado | JetBrains Mono vía `google_fonts`, sobre el tamaño de `labelSm` |
| Curvas de resorte | `HudMotion.flow` y `wobble` |
| Proporciones de movimiento | La gota se afina 12% de lo que se estira; el botón se hunde a 88%; la perilla del slider crece a 130%; el ícono activo, a 110%; el contenido se desliza 4% al plegar; al cambiar de flujo, el teléfono viaja 110% de su ancho, se estira 5% por unidad de velocidad (hasta 22%) y se desenfoca hasta 12 px |

## Archivos

| Archivo | Qué es |
|---|---|
| `lib/src/prototype_shell.dart` | El armado: header, rail, visor y escenario, y los controles de Layout |
| `lib/src/hud_rail.dart` | El rail: la barra de íconos, los paneles de cada categoría y el rail de estados |
| `lib/src/hud_controls.dart` | Los controles locales y la gota |
| `lib/src/hud_motion.dart` | Las curvas líquidas y las entradas en cascada |
| `lib/src/hud_inspector.dart` | El inspector: marcas, árbol, contornos y selección en el teléfono |
| `lib/src/hud_code_view.dart` | El visor de código |
| `lib/src/hud_content.dart` | El prototipo como datos: vistas, recorrido, estados, Not final |
| `lib/src/hud_prototype.dart` | Qué muestra el teléfono (vista, flujo, estado) y el cambio de teléfono entre flujos |
| `lib/src/layout_spec.dart` | El layout como dato: todas las medidas en un objeto |
| `lib/src/device_stage.dart` | El teléfono y la escala 1:1 |
| `lib/src/hud_devices.dart` | Los dispositivos y el selector del header. SE 375 × 667, 18 Pro 402 × 874, 18 Pro Max 440 × 956. Android entra con `platform: 'Android'`. `HudDeviceScope.of(context)` le dice a la pantalla qué dispositivo está en el escenario |
| `tool/stamp_last_update.py` | Calcula la fecha del header desde el código |
| `example/` | El HUD con una pantalla genérica, para probar cambios al HUD mismo |

**Links:** `?view=<id>&state=<id>` abre el teléfono en esa vista y estado, y `?device=se|18-pro|18-pro-max` en ese dispositivo.

**El visor de código** se abre al costado del rail si cabe dejando 360 al teléfono; en una ventana más angosta, se abre encima del teléfono.
