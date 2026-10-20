import 'dart:math' as math;

import 'package:device_frame/device_frame.dart';
import 'package:flutter/widgets.dart';

import 'layout_spec.dart';

/// A phone frame that renders its [child] at true phone scale, then lets the
/// stage scale the whole frame to the space available.
///
/// Self-contained on purpose. The storybook's `PlaygroundDeviceFrame` does the
/// same arithmetic but drags in `storybook_flutter` and `provider`; this sandbox
/// only needs the maths, which is the part worth carrying:
///
/// [DeviceFrame] nests two `FittedBox` layers: an inner one scaling
/// `screenSize` to the screen path's bounds, and an outer one scaling
/// `frameSize` to whatever the parent gives it. Net scale on the screen content
/// is the product of the two. For 1:1 the outer must be `1 / innerScale`, which
/// means handing the frame a parent of exactly `frameSize / innerScale`.
///
/// [_oneToOneSize] computes that. Feeding it to a [SizedBox] inside a
/// [FittedBox] is what makes the result scalable: without the bounded
/// constraints the sized box provides, `DeviceFrame`'s own `LayoutBuilder`
/// resolves against the infinite width a [FittedBox] hands its child.
class DeviceStage extends StatelessWidget {
  /// Creates a stage showing [child] inside [device].
  const DeviceStage({
    required this.device,
    required this.spec,
    required this.child,
    super.key,
  });

  /// The phone to frame.
  final DeviceInfo device;

  /// Padding and fit come from here.
  final LayoutSpec spec;

  /// The screen rendered inside the phone.
  final Widget child;

  /// The parent size at which [DeviceFrame] renders its screen 1:1.
  static Size _oneToOneSize(DeviceInfo device) {
    var bounds = device.screenPath.getBounds();
    var innerScale = math.min(
      bounds.width / device.screenSize.width,
      bounds.height / device.screenSize.height,
    );
    return Size(
      device.frameSize.width / innerScale,
      device.frameSize.height / innerScale,
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = _oneToOneSize(device);
    var phone = SizedBox(
      width: size.width,
      height: size.height,
      child: DeviceFrame(device: device, screen: child),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spec.stagePadH,
        vertical: spec.stagePadV,
      ),
      child: switch (spec.stageFit) {
        // Flutter applies the scale while painting, so text and borders stay
        // crisp whether the phone grew or shrank.
        StageFit.contain => FittedBox(child: phone),
        StageFit.scaleDown => FittedBox(fit: BoxFit.scaleDown, child: phone),
        // No FittedBox at all: the phone keeps its true size and a short window
        // simply clips it. Useful for judging real pixel sizes, useless for
        // seeing the whole screen at once.
        StageFit.none => Center(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: phone,
            ),
          ),
        ),
      },
    );
  }
}
