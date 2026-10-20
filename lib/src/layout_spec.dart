import 'package:aura_ds/aura_ds.dart';
import 'package:flutter/widgets.dart';

/// Which side of the stage the control rail sits on.
enum RailSide {
  /// Rail first, phone to its right. What the shipped prototypes do today.
  left('Left'),

  /// Phone first, rail to its right.
  right('Right');

  const RailSide(this.label);

  /// Human-readable label for the layout controls.
  final String label;
}

/// How the phone is sized inside the stage.
enum StageFit {
  /// Grows into a tall window and shrinks into a short one. Today's behaviour.
  contain('Contain, fills the height'),

  /// Shrinks to fit, but never scales past 1:1. Keeps text at true phone size.
  scaleDown('Scale down, never past 1:1'),

  /// No scaling at all. Overflows a short window; the truest pixel reading.
  none('None, always 1:1');

  const StageFit(this.label);

  /// Human-readable label for the layout controls.
  final String label;
}

/// Background token the stage paints behind the phone.
enum StageBackground {
  /// The recessed canvas. What the prototypes use today.
  sunken('surfaceSunken', AuraColors.surfaceSunken),

  /// The plain app canvas.
  standard('surfaceDefault', AuraColors.surfaceDefault),

  /// Dark, so a light phone reads as an object on a table.
  inverse('surfaceInverse', AuraColors.surfaceInverse),

  /// Warm secondary.
  secondary('surfaceSecondary', AuraColors.surfaceSecondary);

  const StageBackground(this.label, this.color);

  /// Token name, shown in the layout controls.
  final String label;

  /// The resolved colour.
  final Color color;
}

/// Every dimension of the prototype page's chrome, in one object.
///
/// The point of this file: the layout is data, not structure spread across
/// widgets. To try a different page, change these values, or drive them live
/// from the Layout controls in the running app and read the chosen numbers off
/// the screen when you are happy.
///
/// Nothing here describes the *screen inside* the phone. That is the feature's
/// job, and this sandbox deliberately shows a placeholder instead so the chrome
/// can be judged on its own.
@immutable
class LayoutSpec {
  /// Creates a layout spec. The defaults are what the shipped prototypes render
  /// today, so an unmodified run is the current baseline to compare against.
  const LayoutSpec({
    this.showHeader = true,
    this.headerPadH = AuraSpacing.space24,
    this.headerPadV = AuraSpacing.space16,
    this.showRail = true,
    this.railSide = RailSide.left,
    this.railWidth = 320,
    this.railPad = AuraSpacing.space24,
    this.stagePadH = AuraSpacing.space24,
    this.stagePadV = AuraSpacing.space20,
    this.stageFit = StageFit.contain,
    this.background = StageBackground.sunken,
  });

  /// Whether the branded header band is drawn.
  final bool showHeader;

  /// Header horizontal padding.
  final double headerPadH;

  /// Header vertical padding. With the wordmark's height, this sets the band.
  final double headerPadV;

  /// Whether the control rail is drawn.
  final bool showRail;

  /// Which side the rail sits on.
  final RailSide railSide;

  /// Rail width, icon strip included: 48 of strip, 272 of panel.
  final double railWidth;

  /// Padding inside the rail.
  final double railPad;

  /// Stage horizontal padding, i.e. the gutter around the phone.
  final double stagePadH;

  /// Stage vertical padding.
  final double stagePadV;

  /// How the phone scales to the space it is given.
  final StageFit stageFit;

  /// Background token behind the phone.
  final StageBackground background;

  /// Returns a copy with the given fields replaced.
  LayoutSpec copyWith({
    bool? showHeader,
    double? headerPadH,
    double? headerPadV,
    bool? showRail,
    RailSide? railSide,
    double? railWidth,
    double? railPad,
    double? stagePadH,
    double? stagePadV,
    StageFit? stageFit,
    StageBackground? background,
  }) => LayoutSpec(
    showHeader: showHeader ?? this.showHeader,
    headerPadH: headerPadH ?? this.headerPadH,
    headerPadV: headerPadV ?? this.headerPadV,
    showRail: showRail ?? this.showRail,
    railSide: railSide ?? this.railSide,
    railWidth: railWidth ?? this.railWidth,
    railPad: railPad ?? this.railPad,
    stagePadH: stagePadH ?? this.stagePadH,
    stagePadV: stagePadV ?? this.stagePadV,
    stageFit: stageFit ?? this.stageFit,
    background: background ?? this.background,
  );

  /// The spec as Dart source, ready to paste back into the defaults above or
  /// into a real `prototype_page.dart`.
  ///
  /// This is how a live experiment becomes a committed decision without anyone
  /// transcribing numbers off a screenshot by eye.
  String toDartSource() =>
      'const LayoutSpec(\n'
      '  showHeader: $showHeader,\n'
      '  headerPadH: ${_n(headerPadH)},\n'
      '  headerPadV: ${_n(headerPadV)},\n'
      '  showRail: $showRail,\n'
      '  railSide: $railSide,\n'
      '  railWidth: ${_n(railWidth)},\n'
      '  railPad: ${_n(railPad)},\n'
      '  stagePadH: ${_n(stagePadH)},\n'
      '  stagePadV: ${_n(stagePadV)},\n'
      '  stageFit: $stageFit,\n'
      '  background: $background,\n'
      ')';

  /// Drops a trailing `.0` so pasted source reads as the tokens it came from.
  static String _n(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}
