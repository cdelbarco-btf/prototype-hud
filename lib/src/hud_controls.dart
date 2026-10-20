import 'package:aura_ds/aura_ds.dart';
import 'package:flutter/material.dart';

import 'hud_motion.dart';

/// The HUD's own controls, so every part of the chrome moves with the same
/// fluid motion. Aura's equivalents carry Aura's motion, which belongs to the
/// product inside the phone, not to the review tool around it.
///
/// **Local to the HUD, not part of Aura DS.** Built from Aura tokens only.

/// A highlight that moves like a drop of liquid between resting places: the
/// edge facing where it goes leaves first and stretches, the other follows,
/// the drop thins while long and gathers back as it lands, with a small
/// settle. Interrupted mid-flow, it carries on from the shape it has.
///
/// Lives in a [Stack]; [rect] is where it rests, in the stack's coordinates.
class HudLiquidDrop extends StatefulWidget {
  /// Creates a drop resting at [rect].
  const HudLiquidDrop({
    required this.rect,
    required this.color,
    required this.radius,
    this.axis = Axis.vertical,
    this.accent,
    this.visible = true,
    super.key,
  });

  /// A thin edge on the drop's leading side, which travels with it: the
  /// lime bar that marks a chosen row.
  final Color? accent;

  /// Where the drop rests.
  final Rect rect;

  /// Which way it travels.
  final Axis axis;

  /// Its fill.
  final Color color;

  /// Its corner radius at rest; it rounds further as it stretches.
  final double radius;

  /// Whether the drop shows. It fades and gathers in or out, for a choice
  /// that moves to or from another list.
  final bool visible;

  @override
  State<HudLiquidDrop> createState() => _HudLiquidDropState();
}

class _HudLiquidDropState extends State<HudLiquidDrop>
    with SingleTickerProviderStateMixin {
  // The leading edge sets off at once and arrives with a wobble; the
  // trailing edge waits a beat, then flows after it.
  static const Curve _lead = Interval(0, 0.7, curve: HudMotion.wobble);
  static const Curve _trail = Interval(0.18, 1, curve: HudMotion.flow);

  /// How much thinner the drop gets for each unit it stretches.
  static const double _thinning = 0.12;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AuraMotion.durationXSlow,
    value: 1,
  );

  late double _fromStart = _start(widget.rect);
  late double _fromEnd = _end(widget.rect);
  late double _toStart = _fromStart;
  late double _toEnd = _fromEnd;

  double _start(Rect r) => widget.axis == Axis.vertical ? r.top : r.left;
  double _end(Rect r) => widget.axis == Axis.vertical ? r.bottom : r.right;

  (double, double) _edgesAt(double t) {
    var forward = _toStart >= _fromStart;
    double lerp(double a, double b, Curve c) => a + (b - a) * c.transform(t);
    return (
      lerp(_fromStart, _toStart, forward ? _trail : _lead),
      lerp(_fromEnd, _toEnd, forward ? _lead : _trail),
    );
  }

  @override
  void didUpdateWidget(HudLiquidDrop old) {
    super.didUpdateWidget(old);
    var start = _start(widget.rect);
    var end = _end(widget.rect);
    if (start == _toStart && end == _toEnd) return;
    // Flow on from the shape on screen right now, not the old resting place.
    var (s, e) = _edgesAt(_c.value);
    _fromStart = s;
    _fromEnd = e;
    _toStart = start;
    _toEnd = end;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      var (s, e) = _edgesAt(_c.value);
      var lo = s < e ? s : e;
      var length = (e - s).abs();
      var rest = _toEnd - _toStart;
      var stretch = (length - rest).clamp(0.0, rest * 2);
      var vertical = widget.axis == Axis.vertical;
      var r = widget.rect;
      var cross = (vertical ? r.width : r.height) - stretch * _thinning;
      var crossCentre = vertical ? r.center.dx : r.center.dy;
      var radius = BorderRadius.circular(widget.radius + stretch * _thinning);
      Widget box = DecoratedBox(
        decoration: BoxDecoration(color: widget.color, borderRadius: radius),
        child: widget.accent == null
            ? null
            : ClipRRect(
                borderRadius: radius,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: AuraSpacing.space2,
                    color: widget.accent,
                  ),
                ),
              ),
      );
      box = AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: AuraMotion.durationSlow,
        curve: HudMotion.flow,
        child: AnimatedScale(
          scale: widget.visible ? 1 : 0.92,
          duration: AuraMotion.durationXSlow,
          curve: HudMotion.wobble,
          child: box,
        ),
      );
      return vertical
          ? Positioned(
              top: lo,
              height: length,
              left: crossCentre - cross / 2,
              width: cross,
              child: box,
            )
          : Positioned(
              left: lo,
              width: length,
              top: crossCentre - cross / 2,
              height: cross,
              child: box,
            );
    },
  );
}

/// A column of rows where the chosen one sits on a liquid drop that flows
/// from row to row, whatever their heights. Rows paint no background of
/// their own when chosen; the drop is the selection.
class HudLiquidColumn extends StatefulWidget {
  /// Creates the column.
  const HudLiquidColumn({
    required this.children,
    required this.selected,
    this.gap = 0,
    this.radius = AuraSpacing.radiusSm,
    this.accent,
    super.key,
  });

  /// The rows.
  final List<Widget> children;

  /// The chosen row, or null when the choice lives in another list.
  final int? selected;

  /// Space between rows.
  final double gap;

  /// The drop's corner radius.
  final double radius;

  /// An edge that travels with the drop, like the lime bar of a chosen row.
  final Color? accent;

  @override
  State<HudLiquidColumn> createState() => _HudLiquidColumnState();
}

class _HudLiquidColumnState extends State<HudLiquidColumn> {
  final List<GlobalKey> _keys = [];
  Rect? _rect;

  // Rows are measured after they lay out, so the drop fits rows of any
  // height; it only rebuilds when the chosen row's place really changes.
  void _measure(Duration _) {
    if (!mounted) return;
    var i = widget.selected;
    if (i == null || i >= _keys.length) return;
    var row = _keys[i].currentContext?.findRenderObject();
    var stack = context.findRenderObject();
    if (row is! RenderBox || stack is! RenderBox || !row.hasSize) return;
    var rect = row.localToGlobal(Offset.zero, ancestor: stack) & row.size;
    if (rect != _rect) setState(() => _rect = rect);
  }

  @override
  Widget build(BuildContext context) {
    while (_keys.length < widget.children.length) {
      _keys.add(GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    return Stack(
      children: [
        if (_rect != null)
          HudLiquidDrop(
            rect: _rect!,
            color: AuraColors.surfaceInverseL3,
            radius: widget.radius,
            accent: widget.accent,
            visible: widget.selected != null,
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in widget.children.indexed) ...[
              if (i > 0 && widget.gap > 0) SizedBox(height: widget.gap),
              KeyedSubtree(key: _keys[i], child: child),
            ],
          ],
        ),
      ],
    );
  }
}

/// A row's own fill: clear, or a faint lift on hover. Chosen rows rely on
/// the drop beneath them.
Color hudRowFill({required bool hover}) => hover
    ? AuraColors.stateHoverDark
    : AuraColors.stateHoverDark.withValues(alpha: 0);

/// A round icon button for the chrome. Lifts on hover; on press it sinks and
/// springs back.
class HudIconButton extends StatefulWidget {
  /// Creates the button.
  const HudIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  /// The glyph.
  final IconData icon;

  /// What it does, for screen readers.
  final String semanticLabel;

  /// What happens on press.
  final VoidCallback onPressed;

  @override
  State<HudIconButton> createState() => _HudIconButtonState();
}

class _HudIconButtonState extends State<HudIconButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.semanticLabel,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.88 : 1,
          duration: AuraMotion.durationSlow,
          curve: HudMotion.wobble,
          child: AnimatedContainer(
            duration: AuraMotion.durationSlow,
            curve: HudMotion.flow,
            width: AuraSpacing.space32,
            height: AuraSpacing.space32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hover
                  ? AuraColors.surfaceInverseRaised
                  : AuraColors.surfaceInverseFaint,
            ),
            child: Icon(
              widget.icon,
              size: AuraSpacing.space16,
              color: AuraColors.iconInverse,
            ),
          ),
        ),
      ),
    ),
  );
}

/// An on/off switch with its label. The thumb travels as a liquid drop,
/// stretching toward the other side and gathering as it lands; the track
/// fills lime when on, the HUD's colour for "active".
class HudSwitch extends StatelessWidget {
  /// Creates the switch.
  const HudSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// What it turns on.
  final String label;

  /// Whether it is on.
  final bool value;

  /// Called with the new value.
  final ValueChanged<bool> onChanged;

  static const double _w = AuraSpacing.space44;
  static const double _h = AuraSpacing.space24;
  static const double _inset = AuraSpacing.space2;
  static const double _thumb = _h - _inset * 2;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: AuraText(
                label,
                style: AuraTextStyles.labelMd,
                color: AuraColors.textInverse,
              ),
            ),
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                end: value
                    ? AuraColors.interactiveAccentOn
                    : AuraColors.surfaceInverseRaised,
              ),
              duration: AuraMotion.durationXSlow,
              curve: HudMotion.flow,
              builder: (context, track, _) => Container(
                width: _w,
                height: _h,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(AuraSpacing.radiusFull),
                ),
                child: Stack(
                  children: [
                    HudLiquidDrop(
                      axis: Axis.horizontal,
                      rect: Rect.fromLTWH(
                        value ? _w - _inset - _thumb : _inset,
                        _inset,
                        _thumb,
                        _thumb,
                      ),
                      color: value
                          ? AuraColors.surfaceInverse
                          : AuraColors.textInverse,
                      radius: AuraSpacing.radiusFull,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A choice among a few options, all in view: no menu to open. The chosen
/// one sits on a drop that flows between options. Two options sit side by
/// side; more stack.
class HudChoice<T> extends StatelessWidget {
  /// Creates the choice.
  const HudChoice({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  /// What is being chosen.
  final String label;

  /// The current option.
  final T value;

  /// Each option and how it reads.
  final List<(T, String)> options;

  /// Called with the picked option.
  final ValueChanged<T> onChanged;

  static const double _row = AuraSpacing.space32;
  static const double _pad = AuraSpacing.space4;

  @override
  Widget build(BuildContext context) {
    var across = options.length <= 2;
    var index = options.indexWhere((o) => o.$1 == value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuraText(
          label,
          style: AuraTextStyles.labelSm,
          color: AuraColors.textInverseMuted,
        ),
        const SizedBox(height: AuraSpacing.space8),
        Container(
          padding: const EdgeInsets.all(_pad),
          decoration: BoxDecoration(
            color: AuraColors.surfaceInverseL1,
            borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              var w = across ? box.maxWidth / options.length : box.maxWidth;
              var rect = across
                  ? Rect.fromLTWH(w * index, 0, w, _row)
                  : Rect.fromLTWH(0, _row * index, w, _row);
              return SizedBox(
                height: across ? _row : _row * options.length,
                child: Stack(
                  children: [
                    HudLiquidDrop(
                      axis: across ? Axis.horizontal : Axis.vertical,
                      rect: rect,
                      color: AuraColors.surfaceInverseL3,
                      radius: AuraSpacing.radiusSm,
                    ),
                    Flex(
                      direction: across ? Axis.horizontal : Axis.vertical,
                      children: [
                        for (final (i, (v, text)) in options.indexed)
                          SizedBox(
                            width: w,
                            height: _row,
                            child: _ChoiceOption(
                              text: text,
                              selected: i == index,
                              centred: across,
                              onTap: () => onChanged(v),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  const _ChoiceOption({
    required this.text,
    required this.selected,
    required this.centred,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool centred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: text,
    excludeSemantics: true,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.space8),
          child: Row(
            mainAxisAlignment: centred
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              // A lime dot marks the chosen one; it swells in with a settle.
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: AuraMotion.durationSlow,
                curve: HudMotion.wobble,
                child: Container(
                  width: AuraSpacing.space6,
                  height: AuraSpacing.space6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.interactiveAccentOn,
                  ),
                ),
              ),
              const SizedBox(width: AuraSpacing.space8),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: AuraMotion.durationSlow,
                  curve: HudMotion.flow,
                  style:
                      (selected
                              ? AuraTextStyles.labelMdStrong
                              : AuraTextStyles.labelMd)
                          .copyWith(
                            color: selected
                                ? AuraColors.textInverse
                                : AuraColors.textInverseMuted,
                          ),
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A slider for whole numbers, its value in the label. The thumb follows the
/// pointer with a slight liquid lag and swells while held.
class HudSlider extends StatefulWidget {
  /// Creates the slider.
  const HudSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  /// What it sets.
  final String label;

  /// The current value.
  final double value;

  /// The lowest value.
  final double min;

  /// The highest value.
  final double max;

  /// Called with a new whole value.
  final ValueChanged<double> onChanged;

  @override
  State<HudSlider> createState() => _HudSliderState();
}

class _HudSliderState extends State<HudSlider> {
  bool _held = false;

  static const double _thumb = AuraSpacing.space16;
  static const double _track = AuraSpacing.space4;

  void _set(double dx, double width) {
    var t = (dx / width).clamp(0.0, 1.0);
    var v = (widget.min + t * (widget.max - widget.min)).roundToDouble();
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    var span = widget.max - widget.min;
    var t = span == 0
        ? 0.0
        : ((widget.value - widget.min) / span).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuraText(
          '${widget.label} · ${widget.value.round()}',
          style: AuraTextStyles.labelSm,
          color: AuraColors.textInverseMuted,
        ),
        LayoutBuilder(
          builder: (context, box) {
            var width = box.maxWidth - _thumb;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _set(d.localPosition.dx - _thumb / 2, width),
                onHorizontalDragStart: (d) {
                  setState(() => _held = true);
                  _set(d.localPosition.dx - _thumb / 2, width);
                },
                onHorizontalDragUpdate: (d) =>
                    _set(d.localPosition.dx - _thumb / 2, width),
                onHorizontalDragEnd: (_) => setState(() => _held = false),
                onHorizontalDragCancel: () => setState(() => _held = false),
                child: SizedBox(
                  height: AuraSpacing.space32,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: t),
                    duration: AuraMotion.durationNormal,
                    curve: HudMotion.flow,
                    builder: (context, p, _) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          left: _thumb / 2,
                          right: _thumb / 2,
                          child: Container(
                            height: _track,
                            decoration: BoxDecoration(
                              color: AuraColors.surfaceInverseRaised,
                              borderRadius: BorderRadius.circular(
                                AuraSpacing.radiusFull,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _thumb / 2,
                          width: width * p,
                          child: Container(
                            height: _track,
                            decoration: BoxDecoration(
                              color: AuraColors.textInverseMuted,
                              borderRadius: BorderRadius.circular(
                                AuraSpacing.radiusFull,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: width * p,
                          child: AnimatedScale(
                            scale: _held ? 1.3 : 1,
                            duration: AuraMotion.durationSlow,
                            curve: HudMotion.wobble,
                            child: Container(
                              width: _thumb,
                              height: _thumb,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AuraColors.textInverse,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
