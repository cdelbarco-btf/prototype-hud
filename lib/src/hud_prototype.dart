import 'dart:math' as math;

import 'package:aura_ds/aura_ds.dart';
import 'package:flutter/widgets.dart';

import 'hud_motion.dart';

/// What the phone is showing: a view, the flow it belongs to, and the state
/// it is in. The rail changes it; the stage reads it.
///
/// A flow is a run of screens that live in one place: the app itself, or a
/// partner's site the member is sent to. Moving within a flow is the app's
/// own navigation, inside the phone. Moving to another flow swaps the phone.
///
/// **Local to the HUD, not part of Aura DS.**
class HudPrototype extends ChangeNotifier {
  /// Starts on [view], in [flow], in [state].
  HudPrototype({required String view, required HudFlow flow, String state = ''})
    : _view = view,
      _flow = flow,
      _state = state;

  String _view;
  HudFlow _flow;
  String _state;
  int _direction = 1;
  int _run = 0;

  /// The view on the phone.
  String get view => _view;

  /// The flow it belongs to.
  HudFlow get flow => _flow;

  /// The state the view is in.
  String get state => _state;

  /// Which way the last change of flow went: 1 onward, -1 back.
  int get direction => _direction;

  /// Goes up every time something is picked, even the same view again, so a
  /// screen keyed on it starts over: picking an animated view replays it.
  int get run => _run;

  /// Shows [view], from [flow], in [state] when given. Picking the view on
  /// the phone again replays it.
  void show(String view, HudFlow flow, {String? state}) {
    if (flow != _flow) _direction = flow.order >= _flow.order ? 1 : -1;
    _view = view;
    _flow = flow;
    if (state != null) _state = state;
    _run++;
    notifyListeners();
  }

  bool _browsingViews = false;

  /// Whether the rail is on Views, which opens the states beside it.
  bool get browsingViews => _browsingViews;

  set browsingViews(bool value) {
    if (value == _browsingViews) {
      return;
    }
    _browsingViews = value;
    notifyListeners();
  }

  /// Puts the current view in [state].
  void setState(String state) {
    _state = state;
    _run++;
    notifyListeners();
  }
}

/// A flow, in the order the member meets it.
@immutable
class HudFlow {
  /// Creates a flow.
  const HudFlow(this.name, this.order);

  /// How the HUD names it.
  final String name;

  /// Its place in the journey, to know which way a swap goes.
  final int order;

  @override
  bool operator ==(Object other) => other is HudFlow && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Shares the [HudPrototype] with the rail and the stage.
class HudPrototypeScope extends InheritedNotifier<HudPrototype> {
  /// Creates the scope.
  const HudPrototypeScope({
    required HudPrototype prototype,
    required super.child,
    super.key,
  }) : super(notifier: prototype);

  /// The nearest prototype state.
  static HudPrototype of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<HudPrototypeScope>()!
      .notifier!;
}

/// Swaps the whole phone when the flow changes, with the same physics as
/// the HUD's liquid drop.
///
/// Calm, not dramatic: the old phone drifts a little toward where the
/// journey came from, gathers in and fades; the new one glides in from the
/// other side a beat later, overlapping it, and settles with a small swell. Both stretch slightly along
/// their path in proportion to their speed, keeping their area like a
/// liquid. Nothing leaves the stage, so nothing is ever cut, and it is all
/// transforms, so it stays smooth. Within a flow nothing moves here; the
/// screen changes inside the phone.
class HudPhoneSwap extends StatelessWidget {
  /// Shows [child] as the phone for [flow].
  const HudPhoneSwap({
    required this.flow,
    required this.direction,
    required this.child,
    super.key,
  });

  /// The flow on the phone; a new one swaps it.
  final HudFlow flow;

  /// 1 if the new flow comes later in the journey, -1 if earlier.
  final int direction;

  /// The phone.
  final Widget child;

  /// How far a phone drifts, as a share of the stage's width.
  static const double _drift = 0.08;

  /// How much smaller a phone is at the far end of its drift.
  static const double _gather = 0.04;

  /// How much a phone stretches per unit of speed, and its limit.
  static const double _stretchPerSpeed = 0.06;
  static const double _maxStretch = 0.03;

  /// The new phone waits for the old one to get going, like a drop's
  /// trailing edge.
  static const Interval _inWindow = Interval(0.08, 1);

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AuraMotion.durationXxSlow,
    reverseDuration: AuraMotion.durationXSlow,
    layoutBuilder: (current, previous) =>
        Stack(alignment: Alignment.center, children: [...previous, ?current]),
    transitionBuilder: (child, animation) {
      var incoming = child.key == ValueKey(flow);
      return AnimatedBuilder(
        animation: animation,
        builder: (context, phone) => incoming
            ? _frame(
                phone!,
                progress: _inWindow.transform(animation.value),
                curve: HudMotion.flow,
                from: direction * _drift,
                to: 0,
                fadeIn: true,
              )
            // The outgoing animation runs 1 → 0; turn it into progress.
            : _frame(
                phone!,
                progress: 1 - animation.value,
                curve: HudMotion.flow,
                from: 0,
                to: -direction * _drift,
                fadeIn: false,
              ),
        child: child,
      );
    },
    child: KeyedSubtree(key: ValueKey(flow), child: child),
  );

  /// One phone at [progress] along its drift from [from] to [to], shaped by
  /// its speed there.
  static Widget _frame(
    Widget phone, {
    required double progress,
    required Curve curve,
    required double from,
    required double to,
    required bool fadeIn,
  }) {
    double at(double t) => from + (to - from) * curve.transform(t.clamp(0, 1));
    var x = at(progress);
    // Speed is the slope of the path, in stage widths per unit of time.
    const dt = 0.01;
    var speed = ((at(progress + dt) - at(progress - dt)) / (2 * dt)).abs();
    var stretch = 1 + (speed * _stretchPerSpeed).clamp(0.0, _maxStretch);

    // How far along the gather is: none at the centre, full at the edge.
    // The incoming phone's wobble carries it a hair past the centre, which
    // reads as a swell.
    var away = (x / _drift).abs().clamp(0.0, 1.0);
    // The incoming phone's size settles with the HUD's wobble, so it lands
    // with the drop's small swell while its position glides in calmly.
    var gathered = fadeIn
        ? 1 - HudMotion.wobble.transform(progress.clamp(0, 1))
        : away;
    var scale = 1 - _gather * gathered;
    var opacity = fadeIn
        ? HudMotion.flow.transform(const Interval(0, 0.6).transform(progress))
        : 1 - HudMotion.flow.transform(progress);

    return Opacity(
      opacity: opacity,
      child: FractionalTranslation(
        translation: Offset(x, 0),
        child: Transform(
          alignment: Alignment.center,
          // Longer along the path, thinner across it: the same area.
          transform: Matrix4.diagonal3Values(
            scale * stretch,
            scale / math.sqrt(stretch),
            1,
          ),
          child: phone,
        ),
      ),
    );
  }
}
