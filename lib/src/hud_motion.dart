import 'dart:math' as math;

import 'package:aura_ds/aura_ds.dart';
import 'package:flutter/widgets.dart';

/// The HUD's entrance: content rises a touch while it fades in, and siblings
/// follow one another in a short cascade, so a panel assembles instead of
/// popping in whole.
///
/// **Local to the HUD, not part of Aura DS.** Timing and curves are Aura's.
class HudReveal extends StatefulWidget {
  /// Reveals [child] as the [index]th of its siblings.
  const HudReveal({required this.child, this.index = 0, this.step, super.key});

  /// The gap between cards: half of Aura's fast duration.
  static final Duration cardStep = AuraMotion.durationFast ~/ 2;

  /// The gap between lines of code: a quick ripple, not a slow typewriter.
  static final Duration lineStep = AuraMotion.durationFast ~/ 8;

  /// Never wait longer than this, however many siblings come first.
  static const Duration maxDelay = AuraMotion.durationSlow;

  /// The content.
  final Widget child;

  /// Its place among the siblings revealed together.
  final int index;

  /// The gap between one sibling and the next; [cardStep] when null.
  final Duration? step;

  @override
  State<HudReveal> createState() => _HudRevealState();
}

class _HudRevealState extends State<HudReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AuraMotion.durationExpand,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: HudMotion.flow,
  );

  @override
  void initState() {
    super.initState();
    var delay = (widget.step ?? HudReveal.cardStep) * widget.index;
    if (delay > HudReveal.maxDelay) delay = HudReveal.maxDelay;
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, AuraSpacing.space8 * (1 - _t.value)),
        child: child,
      ),
    ),
    child: widget.child,
  );
}

/// The HUD's fluid motion: curves that move like a liquid settling, not
/// like a timer running out.
///
/// Both are a spring's step response, so motion starts with momentum, eases
/// out long and settles, and a value interrupted mid-flight carries on
/// smoothly. Aura has easings but no springs; these are local to the HUD and
/// a DS gap worth raising if they stay.
abstract final class HudMotion {
  /// Glides in and settles with no overshoot: sizes, fades, positions.
  static const Curve flow = _SpringCurve(damping: 1, stiffness: 8);

  /// Arrives, swells a touch past and settles back, the way a liquid does:
  /// things that travel, like the strip's highlight.
  static const Curve wobble = _SpringCurve(damping: 0.62, stiffness: 9);
}

/// A unit spring released from rest, as a [Curve] over its settling time.
class _SpringCurve extends Curve {
  const _SpringCurve({required this.damping, required this.stiffness});

  /// Damping ratio: 1 settles without overshoot, below 1 wobbles.
  final double damping;

  /// Natural frequency, in radians per unit of the curve's time. High enough
  /// that the spring has settled by t = 1.
  final double stiffness;

  @override
  double transformInternal(double t) {
    var w = stiffness;
    var z = damping;
    if (z >= 1) return 1 - math.exp(-w * t) * (1 + w * t);
    var wd = w * math.sqrt(1 - z * z);
    return 1 -
        math.exp(-z * w * t) *
            (math.cos(wd * t) + (z * w / wd) * math.sin(wd * t));
  }
}
