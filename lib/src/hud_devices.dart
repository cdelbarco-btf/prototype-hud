import 'package:aura_ds/aura_ds.dart';
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';

import 'hud_motion.dart';

/// A device the prototype can be seen on, to judge it at different sizes.
///
/// Grouped in levels, so the header's menu stays ordered as devices are
/// added: the [platform] (iPhone today, Android later), the [model], and,
/// when a model has more than one screen, the [variant].
///
/// Sizes are Apple's, in points. `device_frame` stops at the iPhone 16, so
/// the 18 Pro and 18 Pro Max borrow the 16 Pro and 16 Pro Max frames, which
/// have the same screens (402 × 874 and 440 × 956).
///
/// **Local to the HUD, not part of Aura DS.**
enum HudDevice {
  /// The smallest iPhone still sold: 375 × 667, home button, no island.
  se('se', 'iPhone', 'SE'),

  /// The default: 402 × 874.
  pro('18-pro', 'iPhone', '18 Pro'),

  /// 440 × 956.
  proMax('18-pro-max', 'iPhone', '18 Pro Max');

  // No device has variants today; the level stays for one that does, like
  // a foldable's two screens.
  // ignore: unused_element_parameter
  const HudDevice(this.id, this.platform, this.model, [this.variant]);

  /// Used in links: `?device=18-pro-max`.
  final String id;

  /// The menu's first level.
  final String platform;

  /// The second.
  final String model;

  /// The third, only when the model has more than one screen.
  final String? variant;

  /// How the header names it: "iPhone 18 Pro".
  String get label => ['$platform $model', ?variant].join(' · ');

  /// Whether it has a Dynamic Island. The SE does not: Live Activity
  /// updates show there as a banner instead.
  bool get hasIsland => this != se;

  /// The frame and screen.
  DeviceInfo get info => switch (this) {
    se => Devices.ios.iPhoneSE,
    pro => Devices.ios.iPhone16Pro.copyWith(name: 'iPhone 18 Pro'),
    proMax => Devices.ios.iPhone16ProMax.copyWith(name: 'iPhone 18 Pro Max'),
  };

  /// The device the link names, or [fallback].
  static HudDevice fromLink(HudDevice fallback) {
    var id = Uri.base.queryParameters['device'];
    return values.firstWhere((d) => d.id == id, orElse: () => fallback);
  }
}

/// The device on the stage, for screens that draw the phone's own chrome
/// and need to know it: whether there is a Dynamic Island, for instance.
///
/// **Local to the HUD, not part of Aura DS.**
class HudDeviceScope extends InheritedWidget {
  /// Shares [device] with the screen.
  const HudDeviceScope({required this.device, required super.child, super.key});

  /// The device on the stage.
  final HudDevice device;

  /// The device on the stage, or the default when there is no scope.
  static HudDevice of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HudDeviceScope>()?.device ??
      HudDevice.pro;

  @override
  bool updateShouldNotify(HudDeviceScope old) => old.device != device;
}

/// Picks the device, in the header: a button naming the one on the stage,
/// opening a panel in levels. Platforms are sections (iPhone today, Android
/// later), their models are rows, and a model with more than one screen
/// unfolds its variants in place. All by click, all on the HUD's liquid
/// motion.
///
/// **Local to the HUD, not part of Aura DS.**
class HudDevicePicker extends StatefulWidget {
  /// Creates the picker.
  const HudDevicePicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The device on the stage.
  final HudDevice value;

  /// Called with the device picked.
  final ValueChanged<HudDevice> onChanged;

  @override
  State<HudDevicePicker> createState() => _HudDevicePickerState();
}

class _HudDevicePickerState extends State<HudDevicePicker>
    with SingleTickerProviderStateMixin {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  late final _motion = AnimationController(
    vsync: this,
    duration: AuraMotion.durationSlow,
  );

  /// The model whose variants are unfolded: the one on the stage, until
  /// another is opened.
  String? _unfolded;

  static const double _panelWidth = 220;
  static const double _row = AuraSpacing.space32;

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  bool get _open => _portal.isShowing;

  void _toggle() => _open ? _close() : _show();

  void _show() {
    _unfolded = widget.value.variant == null ? null : widget.value.model;
    _portal.show();
    _motion.forward(from: 0);
    setState(() {});
  }

  Future<void> _close() async {
    await _motion.reverse();
    if (mounted) setState(_portal.hide);
  }

  void _pick(HudDevice d) {
    widget.onChanged(d);
    _close();
  }

  /// Levels: platform, then model, then variant.
  Map<String, Map<String, List<HudDevice>>> get _levels {
    var levels = <String, Map<String, List<HudDevice>>>{};
    for (final d in HudDevice.values) {
      levels
          .putIfAbsent(d.platform, () => {})
          .putIfAbsent(d.model, () => [])
          .add(d);
    }
    return levels;
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (context) => Stack(
      children: [
        // A clear layer under the panel: a click anywhere else closes it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, AuraSpacing.space8),
          child: _panel(),
        ),
      ],
    ),
    child: CompositedTransformTarget(link: _link, child: _button()),
  );

  Widget _button() => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        height: AuraSpacing.space28,
        padding: const EdgeInsets.only(
          left: AuraSpacing.space12,
          right: AuraSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: AuraColors.surfaceInverseL1,
          borderRadius: BorderRadius.circular(AuraSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: AuraText(
                widget.value.label,
                style: AuraTextStyles.labelSm,
                color: AuraColors.textInverse,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AuraSpacing.space4),
            // The chevron turns as the panel opens, on the HUD's flow.
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: AuraMotion.durationNormal,
              curve: HudMotion.flow,
              child: Icon(
                AuraIcons.expandDown,
                size: AuraSpacing.space12,
                color: AuraColors.textInverseMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// The panel drops from the button: it fades in, slides down a touch and
  /// settles, on the flow curve.
  Widget _panel() {
    var t = CurvedAnimation(parent: _motion, curve: HudMotion.flow);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.04),
          end: Offset.zero,
        ).animate(t),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(t),
          alignment: Alignment.topRight,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: _panelWidth,
              padding: const EdgeInsets.all(AuraSpacing.space8),
              decoration: BoxDecoration(
                color: AuraColors.surfaceInverseL1,
                borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
                border: Border.all(color: AuraColors.borderInverseSubtle),
                boxShadow: AuraShadows.large,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final MapEntry(key: platform, value: models)
                      in _levels.entries) ...[
                    // Level one: the platform, as a section label.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AuraSpacing.space8,
                        AuraSpacing.space4,
                        AuraSpacing.space8,
                        AuraSpacing.space4,
                      ),
                      child: AuraText(
                        platform.toUpperCase(),
                        style: AuraTextStyles.labelSm,
                        color: AuraColors.textInverseMuted,
                      ),
                    ),
                    for (final MapEntry(key: model, value: devices)
                        in models.entries)
                      if (devices.length == 1)
                        _rowFor(
                          model,
                          devices.single.id,
                          () {
                            _pick(devices.single);
                          },
                          picked: devices.single == widget.value,
                        )
                      else
                        ..._withVariants(model, devices),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Level two with a level three: the model, and under it its variants,
  /// unfolding in place.
  List<Widget> _withVariants(String model, List<HudDevice> devices) {
    var unfolded = _unfolded == model;
    return [
      _rowFor(
        model,
        model,
        () => setState(() => _unfolded = unfolded ? null : model),
        picked: devices.contains(widget.value) && !unfolded,
        trailing: AnimatedRotation(
          turns: unfolded ? 0.25 : 0,
          duration: AuraMotion.durationNormal,
          curve: HudMotion.flow,
          child: Icon(
            AuraIcons.forward,
            size: AuraSpacing.space12,
            color: AuraColors.textInverseMuted,
          ),
        ),
      ),
      AnimatedSize(
        duration: AuraMotion.durationNormal,
        curve: HudMotion.flow,
        alignment: Alignment.topCenter,
        child: unfolded
            ? Padding(
                padding: const EdgeInsets.only(left: AuraSpacing.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final d in devices)
                      _rowFor(
                        d.variant!,
                        d.id,
                        () => _pick(d),
                        picked: d == widget.value,
                      ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    ];
  }

  Widget _rowFor(
    String text,
    String key,
    VoidCallback onTap, {
    required bool picked,
    Widget? trailing,
  }) => _PickerRow(
    key: ValueKey(key),
    text: text,
    picked: picked,
    onTap: onTap,
    trailing:
        trailing ??
        (picked
            ? Icon(
                AuraIcons.check,
                size: AuraSpacing.space16,
                color: AuraColors.textInverse,
              )
            : null),
    height: _row,
  );
}

/// One row of the picker: a hover fill, its label, and a check or chevron.
class _PickerRow extends StatefulWidget {
  const _PickerRow({
    required this.text,
    required this.picked,
    required this.onTap,
    required this.height,
    this.trailing,
    super.key,
  });

  final String text;
  final bool picked;
  final VoidCallback onTap;
  final double height;
  final Widget? trailing;

  @override
  State<_PickerRow> createState() => _PickerRowState();
}

class _PickerRowState extends State<_PickerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AuraMotion.durationFast,
        curve: HudMotion.flow,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.space8),
        decoration: BoxDecoration(
          color: _hover || widget.picked
              ? AuraColors.surfaceInverseL3
              : AuraColors.surfaceInverseL1,
          borderRadius: BorderRadius.circular(AuraSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(
              child: AuraText(
                widget.text,
                style: widget.picked
                    ? AuraTextStyles.labelMdStrong
                    : AuraTextStyles.labelMd,
                color: AuraColors.textInverse,
              ),
            ),
            ?widget.trailing,
          ],
        ),
      ),
    ),
  );
}
