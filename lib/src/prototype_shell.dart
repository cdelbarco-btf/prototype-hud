import 'package:aura_ds/aura_ds.dart';
import 'package:aura_ds/foundation/base/colors.dart' show AuraBaseColors;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'device_stage.dart';
import 'hud_devices.dart';
import 'hud_code_view.dart';
import 'hud_content.dart';
import 'hud_controls.dart';
import 'hud_inspector.dart';
import 'hud_motion.dart';
import 'hud_prototype.dart';
import 'hud_rail.dart' show HudRail, HudStatesRail;
import 'layout_spec.dart';

/// The prototype page's chrome: a header band across the top, the HUD rail
/// down one side, and the phone on the stage that is left.
///
/// A prototype gives it its name, what goes in the HUD ([content]) and how
/// to build the screen for each view and state ([screen]). Everything else,
/// the rail, the inspector, the code viewer and the phone swap, is the HUD's.
/// Every measure comes from a [LayoutSpec], which can be changed while the
/// app runs.
///
/// Deep links: `?view=<id>&state=<id>` opens the phone on that view and
/// state, and `?device=<id>` on that phone (see [HudDevice]).
class PrototypeShell extends StatefulWidget {
  /// Creates the shell.
  const PrototypeShell({
    required this.title,
    required this.author,
    required this.lastUpdated,
    required this.content,
    required this.screen,
    this.device = HudDevice.pro,
    this.sources = const [],
    this.spec = const LayoutSpec(),
    this.initialView,
    this.initialState,
    super.key,
  });

  /// The feature's name, beside the wordmark.
  final String title;

  /// Who designed the prototype, at the right of the header.
  final String author;

  /// When the prototype last changed, in the header: month and year.
  ///
  /// Stamped by `tool/stamp_last_update.py` from when the prototype's code
  /// last changed, never from today's date: a build nobody touched in three
  /// months must still look three months old.
  final String lastUpdated;

  /// What goes in the HUD.
  final HudContent content;

  /// The screen on the phone for what the prototype state says: its view,
  /// its state. Rebuilt from scratch on every pick, so animated screens
  /// replay.
  final Widget Function(BuildContext context, HudPrototype prototype) screen;

  /// The phone it opens on, unless the link names one. The header's picker
  /// changes it.
  final HudDevice device;

  /// Source files bundled as assets, for the code viewer.
  final List<String> sources;

  /// The page's starting layout.
  final LayoutSpec spec;

  /// Where the phone opens when the link names no view: for prototypes
  /// with links of their own from before the HUD. Defaults to the first.
  final String? initialView;

  /// The state it opens in when the link names none.
  final String? initialState;

  @override
  State<PrototypeShell> createState() => _PrototypeShellState();
}

class _PrototypeShellState extends State<PrototypeShell> {
  late LayoutSpec _spec = widget.spec;

  /// The phone on the stage, picked in the header.
  late HudDevice _device = HudDevice.fromLink(widget.device);

  void _pickDevice(HudDevice next) => setState(() => _device = next);

  /// Whether the rail is showing. The header's menu button folds it away so
  /// the phone can be reviewed on its own.
  bool _railOpen = true;

  /// Shared by the rail and the phone: the rail turns it on and picks a
  /// piece, the phone draws the outlines.
  final HudInspector _inspector = HudInspector();

  /// What the phone shows, shared by the rail (which changes it) and the
  /// stage (which swaps the phone when the flow changes). Opens on the view
  /// and state the link names, or on the first of each.
  late final HudPrototype _prototype = _opening();

  HudPrototype _opening() {
    var content = widget.content;
    var q = Uri.base.queryParameters;
    var ids = content.allViews.map((v) => v.id);
    var view = ids.contains(q['view'])
        ? q['view']!
        : ids.contains(widget.initialView)
        ? widget.initialView!
        : ids.first;
    var states = content.statesOf(view).map((st) => st.id);
    var state = states.contains(q['state'])
        ? q['state']!
        : states.contains(widget.initialState)
        ? widget.initialState!
        : (states.isEmpty ? '' : states.first);
    return HudPrototype(view: view, flow: content.flowOf(view), state: state);
  }

  @override
  void dispose() {
    _inspector.dispose();
    _prototype.dispose();
    super.dispose();
  }

  void _update(LayoutSpec next) => setState(() => _spec = next);

  void _toggleRail() => setState(() => _railOpen = !_railOpen);

  @override
  Widget build(BuildContext context) {
    var stageBody = ListenableBuilder(
      listenable: _prototype,
      builder: (context, _) => HudPhoneSwap(
        flow: _prototype.flow,
        direction: _prototype.direction,
        // Another phone picked in the header: the old one fades and
        // shrinks a touch as the new one settles in, on the HUD's flow.
        child: AnimatedSwitcher(
          duration: AuraMotion.durationSlow,
          switchInCurve: HudMotion.flow,
          switchOutCurve: HudMotion.flow,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: DeviceStage(
            key: ValueKey(_device),
            device: _device.info,
            spec: _spec,
            child: HudDeviceScope(
              device: _device,
              child: KeyedSubtree(
                key: ValueKey(_prototype.run),
                child: widget.screen(context, _prototype),
              ),
            ),
          ),
        ),
      ),
    );

    // The rail folds by its width, with the accordion's own duration and a
    // curve that starts quick and settles slowly. Its content fades out ahead
    // of the width, so nothing is seen being cut by the closing edge, and
    // fades back in once there is room for it.
    var rail = AnimatedContainer(
      duration: AuraMotion.durationExpand,
      curve: HudMotion.flow,
      width: _railOpen ? _spec.railWidth : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: AuraColors.surfaceInverseL1),
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: _spec.railWidth,
        maxWidth: _spec.railWidth,
        child: AnimatedOpacity(
          opacity: _railOpen ? 1 : 0,
          duration: _railOpen
              ? AuraMotion.durationXSlow
              : AuraMotion.durationNormal,
          // Opening, the content waits for the width to make room, then
          // flows in; closing, it flows out at once, ahead of the edge.
          curve: _railOpen
              ? const Interval(0.35, 1, curve: HudMotion.flow)
              : HudMotion.flow,
          // Slides a touch toward its edge as it fades, so it reads as
          // tucking away rather than vanishing.
          child: AnimatedSlide(
            offset: _railOpen ? Offset.zero : const Offset(-0.04, 0),
            duration: AuraMotion.durationExpand,
            curve: HudMotion.flow,
            child: _LayoutRail(
              spec: _spec,
              content: widget.content,
              onChanged: _update,
            ),
          ),
        ),
      ),
    );

    // The code viewer opens beside the rail when a piece is picked in the
    // Components tree, and folds the same way the rail does.
    // The viewer takes what room is left after the rail and a phone-wide
    // stage: its full width on a wide window, less on a narrow one.
    Widget code(double room) => ListenableBuilder(
      listenable: _inspector,
      builder: (context, _) {
        var open = _railOpen && _inspector.on && _inspector.focus != null;
        return AnimatedContainer(
          duration: AuraMotion.durationExpand,
          curve: HudMotion.flow,
          width: open ? room.clamp(0, HudCodeView.width).toDouble() : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: AuraBaseColors.neutral950),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: HudCodeView.width,
            maxWidth: HudCodeView.width,
            child: AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: open
                  ? AuraMotion.durationXSlow
                  : AuraMotion.durationNormal,
              // Opening, the content waits for the width to make room, then
              // flows in; closing, it flows out at once, ahead of the edge.
              curve: open
                  ? const Interval(0.35, 1, curve: HudMotion.flow)
                  : HudMotion.flow,
              child: AnimatedSlide(
                offset: open ? Offset.zero : const Offset(-0.04, 0),
                duration: AuraMotion.durationExpand,
                curve: HudMotion.flow,
                child: HudCodeView(sources: widget.sources),
              ),
            ),
          ),
        );
      },
    );

    // The states of the view on the phone open beside the rail while it is
    // on Views, and fold the same way the rail and the code viewer do.
    var states = ListenableBuilder(
      listenable: _prototype,
      builder: (context, _) {
        var open =
            _railOpen &&
            _prototype.browsingViews &&
            widget.content.statesOf(_prototype.view).isNotEmpty;
        return AnimatedContainer(
          duration: AuraMotion.durationExpand,
          curve: HudMotion.flow,
          width: open ? HudStatesRail.width : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: AuraColors.surfaceInverse),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: HudStatesRail.width,
            maxWidth: HudStatesRail.width,
            child: AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: open
                  ? AuraMotion.durationXSlow
                  : AuraMotion.durationNormal,
              curve: open
                  ? const Interval(0.35, 1, curve: HudMotion.flow)
                  : HudMotion.flow,
              child: AnimatedSlide(
                offset: open ? Offset.zero : const Offset(-0.04, 0),
                duration: AuraMotion.durationExpand,
                curve: HudMotion.flow,
                child: HudStatesRail(content: widget.content),
              ),
            ),
          ),
        );
      },
    );

    return HudPrototypeScope(
      prototype: _prototype,
      child: HudInspectorScope(
        inspector: _inspector,
        child: ColoredBox(
          color: _spec.background.color,
          child: SafeArea(
            child: Column(
              children: [
                if (_spec.showHeader)
                  _ShellHeader(
                    spec: _spec,
                    title: widget.title,
                    author: widget.author,
                    lastUpdated: widget.lastUpdated,
                    railOpen: _railOpen,
                    onToggleRail: _toggleRail,
                    device: _device,
                    onDevice: _pickDevice,
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      var room =
                          box.maxWidth -
                          (_spec.showRail && _railOpen ? _spec.railWidth : 0) -
                          HudCodeView.minStage;
                      // Too narrow to set the viewer beside the phone: it
                      // opens over the phone instead of not opening at all.
                      var narrow = room < HudCodeView.minWidth;
                      var stage = Expanded(
                        child: narrow
                            ? Stack(
                                children: [
                                  Positioned.fill(child: stageBody),
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: code(HudCodeView.width),
                                  ),
                                ],
                              )
                            : stageBody,
                      );
                      return Row(
                        // stretch, not the default centre: the rail is full-height, and
                        // centring leaves its background floating mid-page.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: switch (_spec.railSide) {
                          RailSide.left => [
                            if (_spec.showRail) ...[
                              rail,
                              states,
                              if (!narrow) code(room),
                            ],
                            stage,
                          ],
                          RailSide.right => [
                            stage,
                            if (_spec.showRail) ...[
                              if (!narrow) code(room),
                              states,
                              rail,
                            ],
                          ],
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded header, one compact row on the rail's dark green. Left: the
/// wordmark, a divider and the project's name. Right: the phone picker, when
/// it last changed, as a tag, and who designed it. The brand gradient runs along the bottom edge.
class _ShellHeader extends StatelessWidget {
  const _ShellHeader({
    required this.spec,
    required this.title,
    required this.author,
    required this.lastUpdated,
    required this.railOpen,
    required this.onToggleRail,
    required this.device,
    required this.onDevice,
  });

  final LayoutSpec spec;
  final String title;
  final String author;
  final String lastUpdated;
  final bool railOpen;
  final VoidCallback onToggleRail;
  final HudDevice device;
  final ValueChanged<HudDevice> onDevice;

  /// Window widths from which the date and the author fit.
  static const double _tagFrom = 900;
  static const double _authorFrom = 1060;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColoredBox(
          color: AuraColors.surfaceInverse,
          child: Padding(
            padding: EdgeInsets.only(
              right: spec.headerPadH,
              top: AuraSpacing.space12,
              bottom: AuraSpacing.space12,
            ),
            child: Row(
              children: [
                // The toggle sits in a column as wide as the rail's icon strip,
                // so it centres on the same vertical axis as the icons below.
                SizedBox(
                  width: AuraSpacing.space48,
                  child: Center(
                    // Menu and close swap with a quarter turn and a cross-fade.
                    child: AnimatedSwitcher(
                      duration: AuraMotion.durationSlow,
                      switchInCurve: HudMotion.flow,
                      switchOutCurve: HudMotion.flow,
                      transitionBuilder: (child, animation) =>
                          RotationTransition(
                            turns: Tween<double>(
                              begin: 0.75,
                              end: 1,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child: HudIconButton(
                        key: ValueKey(railOpen),
                        icon: railOpen ? AuraIcons.close : AuraIcons.menu,
                        semanticLabel: railOpen
                            ? 'Hide the rail'
                            : 'Show the rail',
                        onPressed: onToggleRail,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AuraSpacing.space8),
                // The wordmark is one flat colour, so it is tinted to the
                // inverse token rather than shipping a second, light asset.
                Image.asset(
                  'assets/bf-logo-main.png',
                  package: 'prototype_hud',
                  height: AuraSpacing.space20,
                  color: AuraColors.textInverse,
                  colorBlendMode: BlendMode.srcIn,
                  semanticLabel: 'Betterfly',
                ),
                const SizedBox(width: AuraSpacing.space16),
                Container(
                  width: AuraSpacing.borderWidthThin,
                  height: AuraSpacing.space24,
                  color: AuraColors.borderInverseSubtle,
                ),
                const SizedBox(width: AuraSpacing.space16),
                Expanded(
                  child: AuraText(
                    title,
                    style: AuraTextStyles.labelLgStrong,
                    color: AuraColors.textInverse,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Which phone the prototype is seen on, to judge it at
                // different sizes.
                // Its natural width, capped, so the title keeps the rest of the row
                // and is the one to give way on a narrow window.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: HudDevicePicker(value: device, onChanged: onDevice),
                ),
                // On a narrow window the header gives up the least needed
                // first: the author, then the date.
                if (width >= _tagFrom) ...[
                  const SizedBox(width: AuraSpacing.space16),
                  AuraTag(
                    label: 'Last update $lastUpdated',
                    size: AuraTagSize.compact,
                    onDark: true,
                  ),
                ],
                if (width >= _authorFrom) ...[
                  const SizedBox(width: AuraSpacing.space16),
                  AuraText(
                    author,
                    style: AuraTextStyles.labelMdStrong,
                    color: AuraColors.textInverse,
                  ),
                ],
              ],
            ),
          ),
        ),
        // The accent line: the brand gradient instead of a hairline.
        Container(
          height: AuraSpacing.space2,
          decoration: const BoxDecoration(gradient: AuraGradients.special),
        ),
      ],
    );
  }
}

/// The rail. In a real prototype this drives the feature's scenario; here it
/// drives the layout itself, so the page can be reshaped without a rebuild.
class _LayoutRail extends StatelessWidget {
  const _LayoutRail({
    required this.spec,
    required this.content,
    required this.onChanged,
  });

  final LayoutSpec spec;
  final HudContent content;
  final ValueChanged<LayoutSpec> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: spec.railWidth,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AuraColors.surfaceInverseL1,
        border: switch (spec.railSide) {
          RailSide.left => const Border(
            right: BorderSide(color: AuraColors.borderInverseSubtle),
          ),
          RailSide.right => const Border(
            left: BorderSide(color: AuraColors.borderInverseSubtle),
          ),
        },
      ),
      // The HUD's five sections, with the layout controls folded at the end.
      child: HudRail(content: content, layoutControls: _controls(context)),
    ),
  );

  Widget _controls(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Structure ──
        HudChoice<RailSide>(
          label: 'Rail side',
          value: spec.railSide,
          options: [for (final s in RailSide.values) (s, s.label)],
          onChanged: (s) => onChanged(spec.copyWith(railSide: s)),
        ),
        const SizedBox(height: AuraSpacing.space16),
        HudChoice<StageFit>(
          label: 'Phone fit',
          value: spec.stageFit,
          options: [for (final f in StageFit.values) (f, f.label)],
          onChanged: (f) => onChanged(spec.copyWith(stageFit: f)),
        ),
        const SizedBox(height: AuraSpacing.space16),
        HudChoice<StageBackground>(
          label: 'Stage background',
          value: spec.background,
          options: [for (final b in StageBackground.values) (b, b.label)],
          onChanged: (b) => onChanged(spec.copyWith(background: b)),
        ),

        const SizedBox(height: AuraSpacing.space20),
        const AuraDivider(color: AuraColors.borderInverseSubtle),

        // ── Dimensions ──
        _SpecSlider(
          label: 'Rail width',
          value: spec.railWidth,
          min: 220,
          max: 460,
          onChanged: (v) => onChanged(spec.copyWith(railWidth: v)),
        ),
        _SpecSlider(
          label: 'Rail padding',
          value: spec.railPad,
          min: 8,
          max: 48,
          onChanged: (v) => onChanged(spec.copyWith(railPad: v)),
        ),
        _SpecSlider(
          label: 'Stage padding · horizontal',
          value: spec.stagePadH,
          min: 0,
          max: 96,
          onChanged: (v) => onChanged(spec.copyWith(stagePadH: v)),
        ),
        _SpecSlider(
          label: 'Stage padding · vertical',
          value: spec.stagePadV,
          min: 0,
          max: 96,
          onChanged: (v) => onChanged(spec.copyWith(stagePadV: v)),
        ),

        const SizedBox(height: AuraSpacing.space8),
        const AuraDivider(color: AuraColors.borderInverseSubtle),
        const SizedBox(height: AuraSpacing.space8),

        // ── Header ──
        _SpecToggle(
          label: 'Header',
          value: spec.showHeader,
          onChanged: (v) => onChanged(spec.copyWith(showHeader: v)),
        ),
        if (spec.showHeader) ...[
          _SpecSlider(
            label: 'Header padding · horizontal',
            value: spec.headerPadH,
            min: 0,
            max: 64,
            onChanged: (v) => onChanged(spec.copyWith(headerPadH: v)),
          ),
          _SpecSlider(
            label: 'Header padding · vertical',
            value: spec.headerPadV,
            min: 0,
            max: 48,
            onChanged: (v) => onChanged(spec.copyWith(headerPadV: v)),
          ),
        ],

        const SizedBox(height: AuraSpacing.space20),
        const AuraDivider(color: AuraColors.borderInverseSubtle),
        const SizedBox(height: AuraSpacing.space16),

        // The whole point of a sandbox: leaving with the numbers, not with
        // a screenshot someone has to measure.
        AuraText(
          'Current spec',
          style: AuraTextStyles.labelSm,
          color: AuraColors.textInverse,
        ),
        const SizedBox(height: AuraSpacing.space8),
        SelectableText(
          spec.toDartSource(),
          // The same mono face as the code viewer.
          style: GoogleFonts.jetBrainsMono(
            textStyle: AuraTextStyles.labelSmLight,
            color: AuraColors.textInverseSubtle,
          ),
        ),
      ],
    ),
  );
}

/// A labelled slider that reports whole pixels, with the value in the label so
/// a chosen number can be read off without opening dev tools.
class _SpecSlider extends StatelessWidget {
  const _SpecSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AuraSpacing.space12),
    child: HudSlider(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
    ),
  );
}

/// A labelled on-dark switch.
class _SpecToggle extends StatelessWidget {
  const _SpecToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AuraSpacing.space8),
    child: HudSwitch(label: label, value: value, onChanged: onChanged),
  );
}
