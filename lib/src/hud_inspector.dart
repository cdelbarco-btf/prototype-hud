import 'package:aura_ds/aura_ds.dart';
import 'package:aura_ds/foundation/base/colors.dart' show AuraBaseColors;
import 'package:flutter/widgets.dart';

import 'hud_motion.dart';

/// The component inspector: shows on the phone how a screen is built.
///
/// A prototype marks its pieces with [HudComponent]. With the inspector on,
/// each piece is outlined in the color of its nesting depth, the way VS Code
/// colors bracket pairs, and named once. The rail's Components panel lists the
/// same pieces as a tree, and picking one there spotlights it on the phone.
///
/// **Local to the HUD, not part of Aura DS.**
class HudInspector extends ChangeNotifier {
  bool _on = false;
  bool _picking = false;
  String? _focus;
  String? _hover;
  final List<_HudComponentState> _nodes = [];
  bool _pending = false;

  /// Whether outlines show on the phone.
  bool get on => _on;
  set on(bool value) {
    if (value == _on) return;
    _on = value;
    if (!value) _focus = null;
    notifyListeners();
  }

  /// Whether a click on the phone picks a piece instead of using the app.
  /// The rail turns it on only while Components is open.
  bool get picking => _picking;
  set picking(bool value) {
    if (value == _picking) return;
    _picking = value;
    if (!value) _hover = null;
    notifyListeners();
  }

  /// The path of the piece under the pointer while picking, if any.
  String? get hover => _hover;
  set hover(String? path) {
    if (path == _hover) return;
    _hover = path;
    notifyListeners();
  }

  /// The innermost piece at [global], the one a click there means.
  String? pathAt(Offset global) {
    _HudComponentState? best;
    for (final n in _nodes) {
      if (!n.mounted || !n.active) continue;
      var box = n.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      var local = box.globalToLocal(global);
      if (!(Offset.zero & box.size).contains(local)) continue;
      if (best == null || n.depth > best.depth) best = n;
    }
    return best?.path;
  }

  /// The path of the piece spotlit from the rail, if any.
  String? get focus => _focus;
  set focus(String? path) {
    if (path == _focus) return;
    _focus = path;
    notifyListeners();
  }

  /// The tree, parents before children and siblings top to bottom. Repeated
  /// pieces (twelve list rows) collapse into one entry with a count.
  List<HudTreeEntry> get tree {
    // One entry per path, counting its instances and keeping the highest
    // point any of them reaches, to order siblings.
    var entries = <String, HudTreeEntry>{};
    var tops = <String, double>{};
    for (final n in _nodes) {
      if (!n.mounted || !n.active) continue;
      var e = entries[n.path];
      entries[n.path] = e == null
          ? HudTreeEntry(
              path: n.path,
              name: n.widget.name,
              origin: n.widget.origin,
              depth: n.depth,
              count: 1,
            )
          : e.copyWith(count: e.count + 1);
      var top = n.top;
      if (top < (tops[n.path] ?? double.infinity)) tops[n.path] = top;
    }

    // Walk it as a tree: every piece right under its parent, siblings in
    // the order they sit on screen. Position alone would let rows scrolled
    // out of view above jump ahead of the screen that holds them.
    var children = <String?, List<String>>{};
    for (final path in entries.keys) {
      var cut = path.lastIndexOf(' / ');
      var parent = cut < 0 ? null : path.substring(0, cut);
      if (parent != null && !entries.containsKey(parent)) parent = null;
      (children[parent] ??= []).add(path);
    }
    var ordered = <HudTreeEntry>[];
    void walk(String? parent) {
      var kids = children[parent] ?? [];
      kids.sort((a, b) => tops[a]!.compareTo(tops[b]!));
      for (final k in kids) {
        ordered.add(entries[k]!);
        walk(k);
      }
    }

    walk(null);
    return ordered;
  }

  /// Whether [path]'s first piece on screen is [node], so a name is labeled
  /// once rather than on every row.
  bool _isFirst(_HudComponentState node) {
    for (final n in _nodes) {
      if (n.path == node.path) return identical(n, node);
    }
    return false;
  }

  // Pieces come and go while the tree builds; tell listeners once, after the
  // frame, so no one is rebuilt mid-build.
  void _changed() {
    if (_pending) return;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      notifyListeners();
    });
  }

  void _add(_HudComponentState n) {
    _nodes.add(n);
    _changed();
  }

  void _remove(_HudComponentState n) {
    _nodes.remove(n);
    _changed();
  }
}

/// Where a piece comes from, in the handoff's terms.
enum HudOrigin {
  aura('Aura'),
  auraModified('Aura, modified'),
  newToAura('New, goes to Aura'),
  local('Local');

  const HudOrigin(this.label);

  /// How the rail names it.
  final String label;
}

/// One line of the rail's component tree.
@immutable
class HudTreeEntry {
  /// Creates an entry.
  const HudTreeEntry({
    required this.path,
    required this.name,
    required this.origin,
    required this.depth,
    required this.count,
  });

  /// The piece's names from the root down, which identifies it.
  final String path;

  /// The piece's name.
  final String name;

  /// Where it comes from.
  final HudOrigin origin;

  /// How deep it nests: 0 is the screen itself.
  final int depth;

  /// How many times it appears on screen.
  final int count;

  /// A copy with another count.
  HudTreeEntry copyWith({int? count}) => HudTreeEntry(
    path: path,
    name: name,
    origin: origin,
    depth: depth,
    count: count ?? this.count,
  );
}

/// The depth palette, the inspector's rainbow. Each depth has a deep tone for
/// outlines on the light phone screen and a light one for the dark rail.
///
/// Aura has no categorical palette, so these are its base colors, chosen with
/// no reds so nothing reads as an error. A DS gap worth raising if the
/// inspector stays.
abstract final class HudDepthColors {
  // VS Code's bracket-pair order: gold, orchid, blue, then on into green
  // and teal for deeper trees.
  static const List<(Color, Color)> _ramp = [
    (AuraBaseColors.amber600, AuraBaseColors.amber400),
    (AuraBaseColors.indigo500, AuraBaseColors.orchid300),
    (AuraBaseColors.sky500, AuraBaseColors.sky250),
    (AuraBaseColors.emerald600, AuraBaseColors.emerald400),
    (AuraBaseColors.teal600, AuraBaseColors.teal400),
  ];

  /// The outline color for [depth], on the light screen.
  static Color onLight(int depth) => _ramp[depth % _ramp.length].$1;

  /// The guide color for [depth], on the dark rail.
  static Color onDark(int depth) => _ramp[depth % _ramp.length].$2;
}

/// Puts an inspector above the rail and the phone, so both reach it.
class HudInspectorScope extends InheritedNotifier<HudInspector> {
  /// Creates the scope.
  const HudInspectorScope({
    required HudInspector inspector,
    required super.child,
    super.key,
  }) : super(notifier: inspector);

  /// The nearest inspector.
  static HudInspector of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<HudInspectorScope>()!
      .notifier!;

  static HudInspector? _maybe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HudInspectorScope>()?.notifier;
}

/// Marks a piece of a prototype screen for the inspector.
class HudComponent extends StatefulWidget {
  /// Marks [child] as the piece called [name].
  const HudComponent({
    required this.name,
    required this.origin,
    required this.child,
    super.key,
  });

  /// What the piece is called, as the handoff names it.
  final String name;

  /// Where it comes from.
  final HudOrigin origin;

  /// The piece itself.
  final Widget child;

  @override
  State<HudComponent> createState() => _HudComponentState();
}

class _HudComponentState extends State<HudComponent> {
  HudInspector? _inspector;
  late int depth;
  late String path;

  /// False while the piece is leaving the tree, for instance with the old
  /// phone when another device is picked: still mounted, but it can no
  /// longer be measured, so the tree skips it.
  bool active = true;

  @override
  void deactivate() {
    active = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    active = true;
  }

  /// Where the piece sits on screen, to order the tree.
  double get top {
    var box = context.findRenderObject();
    return box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero).dy
        : double.infinity;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var parent = context.dependOnInheritedWidgetOfExactType<_HudParent>();
    depth = parent == null ? 0 : parent.depth + 1;
    path = parent == null ? widget.name : '${parent.path} / ${widget.name}';
    var inspector = HudInspectorScope._maybe(context);
    if (!identical(inspector, _inspector)) {
      _inspector?._remove(this);
      _inspector = inspector?.._add(this);
    }
  }

  @override
  void dispose() {
    _inspector?._remove(this);
    super.dispose();
  }

  // Always the same tree, on or off, so turning the inspector on never
  // remounts the screen (scroll positions survive) and outlines can fade.
  @override
  Widget build(BuildContext context) {
    var child = _HudParent(depth: depth, path: path, child: widget.child);
    var inspector = _inspector;
    if (inspector == null) return child;

    var focus = inspector.focus;
    var spotlit = focus == path;
    var hovered = inspector.hover == path;
    var shown = (inspector.on && (focus == null || spotlit)) || hovered;
    var strong = spotlit || hovered;
    var color = HudDepthColors.onLight(depth);
    var labeled =
        strong || (inspector.on && focus == null && inspector._isFirst(this));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: shown ? 1 : 0,
              duration: AuraMotion.durationSlow,
              curve: HudMotion.flow,
              child: AnimatedContainer(
                duration: AuraMotion.durationSlow,
                curve: HudMotion.flow,
                decoration: BoxDecoration(
                  color: hovered
                      ? AuraColors.stateHoverLight
                      : AuraColors.stateHoverLight.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(AuraSpacing.radiusXs),
                  border: Border.all(
                    color: color,
                    width: strong
                        ? AuraSpacing.space2
                        : AuraSpacing.borderWidthDefault,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: labeled ? 1 : 0,
              duration: AuraMotion.durationNormal,
              curve: HudMotion.flow,
              child: AnimatedScale(
                scale: labeled ? 1 : 0.9,
                alignment: Alignment.topLeft,
                duration: AuraMotion.durationSlow,
                curve: HudMotion.wobble,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AuraSpacing.space4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(AuraSpacing.radiusXs),
                    ),
                  ),
                  child: AuraText(
                    widget.name,
                    style: AuraTextStyles.labelSmLight,
                    color: AuraColors.textInverse,
                  ),
                ),
              ),
            ),
          ),
        ),
        // The screen's root listens for clicks while picking: it asks the
        // inspector which piece is innermost under the pointer, so nested
        // pieces never fight over the click. It is translucent, so drags and
        // the wheel still reach the screen and it scrolls; its tap joins the
        // gesture arena first, so a click picks instead of pressing a button.
        if (depth == 0 && inspector.picking)
          Positioned.fill(
            child: MouseRegion(
              opaque: false,
              hitTestBehavior: HitTestBehavior.translucent,
              cursor: SystemMouseCursors.click,
              onHover: (e) => inspector.hover = inspector.pathAt(e.position),
              onExit: (_) => inspector.hover = null,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (e) {
                  var picked = inspector.pathAt(e.globalPosition);
                  if (picked == null) return;
                  inspector
                    ..on = true
                    ..focus = picked == inspector.focus ? null : picked;
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Tells nested pieces how deep they sit and under what.
class _HudParent extends InheritedWidget {
  const _HudParent({
    required this.depth,
    required this.path,
    required super.child,
  });

  final int depth;
  final String path;

  @override
  bool updateShouldNotify(_HudParent old) =>
      depth != old.depth || path != old.path;
}
