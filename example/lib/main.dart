import 'package:aura_ds/aura_ds.dart';
import 'package:flutter/material.dart';

import 'package:prototype_hud/prototype_hud.dart';
import 'last_update.g.dart';
import 'placeholder_screen.dart';

void main() => runApp(const LayoutTemplateApp());

/// Root of the HUD sandbox.
///
/// Mirrors the storybook's root shell so the framed screen inherits the same
/// theme and glass adapter it would render with inside the catalog. Without
/// [AuraTheme.light] every `Text` falls back to Flutter's debug yellow-underline
/// style, and without [AuraGlassProvider] any liquid-glass component asserts.
class LayoutTemplateApp extends StatelessWidget {
  /// Creates the app.
  const LayoutTemplateApp({super.key});

  static const String _title = 'Prototype HUD';

  @override
  Widget build(BuildContext context) => AuraGlassProvider.adaptive(
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: AuraTheme.light(),
      home: Scaffold(
        body: PrototypeShell(
          title: _title,
          author: 'Christian Del Barco',
          lastUpdated: lastUpdate,
          content: _example,
          sources: const ['lib/placeholder_screen.dart'],
          screen: (context, p) =>
              PlaceholderScreen(title: _example.view(p.view).label),
        ),
      ),
    ),
  );
}

// The sandbox's example content, to judge the HUD on its own. A real
// prototype describes its own.

const HudFlow _inApp = HudFlow('In the app', 0);
const HudFlow _partner = HudFlow('Partner site', 1);

final HudContent _example = HudContent(
  question: 'Does the member understand that this card was made for them?',
  round: 'Round 2',
  views: const [
    HudViewGroup('Screens', _inApp, [
      HudView('home', 'Home'),
      HudView('detail', 'Detail'),
      HudView('confirmation', 'Confirmation'),
    ]),
    HudViewGroup('Sheets and modals', _inApp, [
      HudView('cancel', 'Cancel sheet'),
      HudView('meaning', 'What this means'),
    ]),
    HudViewGroup('Outside the app', _partner, [
      HudView('partner', 'Partner form'),
    ]),
  ],
  journey: const [
    HudJourneyStep('home'),
    HudJourneyStep('detail'),
    HudJourneyStep('partner'),
    HudJourneyStep('confirmation'),
  ],
  states: [
    HudState('normal', 'Normal', icon: AuraIcons.check),
    HudState('loading', 'Loading', icon: AuraIcons.refresh),
    HudState('offline', 'Offline', icon: AuraIcons.wifiOff),
    HudState('error', "Couldn't load", icon: AuraIcons.cloudOff),
    HudState('empty', 'Empty', icon: AuraIcons.minus),
  ],
  notFinal: const [
    HudOpenItem('Prices', r'$199/mo is a placeholder'),
    HudOpenItem('Dates', 'Illustrative'),
    HudOpenItem('Copy', 'Draft until Content approves'),
  ],
);
