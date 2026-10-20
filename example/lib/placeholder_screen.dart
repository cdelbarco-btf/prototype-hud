import 'package:aura_ds/aura_ds.dart';
import 'package:flutter/widgets.dart';

import 'package:prototype_hud/prototype_hud.dart';

/// Stand-in for whatever screen a real prototype puts in the phone.
///
/// Deliberately generic. The chrome around the phone is what this sandbox is
/// for, and a recognisable feature screen in here would pull the eye to the
/// content instead. What it does have is the three things that stress the
/// frame: something under the status bar, a list long enough to scroll, and
/// something that must stay clear of the home indicator.
///
/// Uses only components that exist on `main-design`, so the template keeps
/// building whichever branch the shared clone happens to be on.
class PlaceholderScreen extends StatelessWidget {
  /// Creates the placeholder screen.
  const PlaceholderScreen({this.title = 'Screen title', super.key});

  /// The screen's heading; the HUD passes the view's name, so a change of
  /// view or flow can be seen on the phone.
  final String title;

  @override
  // Each piece is marked for the inspector, as a real prototype's would be.
  Widget build(BuildContext context) =>
      HudComponent(name: 'Screen', origin: HudOrigin.local, child: _screen());

  Widget _screen() => ColoredBox(
    color: AuraColors.surfaceDefault,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AuraSpacing.space16),
            HudComponent(
              name: 'Header',
              origin: HudOrigin.local,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HudComponent(
                    name: 'Title',
                    origin: HudOrigin.aura,
                    child: AuraText(
                      title,
                      style: AuraTextStyles.h1,
                      color: AuraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AuraSpacing.space4),
                  HudComponent(
                    name: 'Subtitle',
                    origin: HudOrigin.aura,
                    child: AuraText(
                      'The feature screen goes here',
                      style: AuraTextStyles.paragraphSmall,
                      color: AuraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AuraSpacing.space20),
            Expanded(
              child: HudComponent(
                name: 'List',
                origin: HudOrigin.local,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 1; i <= 12; i++)
                      HudComponent(
                        name: 'List item',
                        origin: HudOrigin.aura,
                        child: AuraListItem(
                          title: 'Row $i',
                          subtitle: 'Secondary line',
                          trailing: HudComponent(
                            name: 'Points',
                            origin: HudOrigin.auraModified,
                            child: AuraText(
                              '+$i',
                              style: AuraTextStyles.labelMd,
                              color: AuraColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AuraSpacing.space16),
            HudComponent(
              name: 'Button',
              origin: HudOrigin.aura,
              child: AuraButton(
                label: 'Primary action',
                fullWidth: true,
                onPressed: _noop,
              ),
            ),
            const SizedBox(height: AuraSpacing.space16),
          ],
        ),
      ),
    ),
  );

  /// The button exists to occupy the bottom of the screen, not to do anything.
  static void _noop() {}
}
