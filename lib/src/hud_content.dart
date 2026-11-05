import 'package:flutter/widgets.dart';

import 'hud_prototype.dart';

/// What a prototype puts in the HUD: the question, its views, the order the
/// member meets them, the states each view can be put in, and what is not
/// final. The HUD draws it; the prototype only describes it.
///
/// Product text, so English (en-US).
///
/// **Local to the HUD, not part of Aura DS.**
@immutable
class HudContent {
  /// Describes a prototype for the HUD.
  const HudContent({
    required this.question,
    required this.views,
    this.round,
    this.journey = const [],
    this.journeyTitle = 'Screens in order',
    this.journeyIsProgress = true,
    this.states = const [],
    this.notFinal = const [],
    this.userFlows = const [],
  });

  /// What this round is testing.
  final String question;

  /// Which round, shown beside the question: "Round 2".
  final String? round;

  /// Every view the phone can show, in a group per kind.
  final List<HudViewGroup> views;

  /// The views in the order the member meets them. Empty hides nothing:
  /// the Journey category then says there is no order to walk.
  final List<HudJourneyStep> journey;

  /// The Journey card's title.
  final String journeyTitle;

  /// Whether the journey is a progression, so steps before the current one
  /// show as walked. A ladder or a set of alternatives is not.
  final bool journeyIsProgress;

  /// The states a view can be put in, unless the view lists its own.
  final List<HudState> states;

  /// What is mock or undecided.
  final List<HudOpenItem> notFinal;

  /// The tasks the prototype holds, such as Create a goal and Change a goal,
  /// to review one at a time. Empty shows every view and [journey], as
  /// before. See [HudUserFlow].
  final List<HudUserFlow> userFlows;

  /// The user flow with [id], or null for all views.
  HudUserFlow? userFlow(String? id) =>
      userFlows.where((f) => f.id == id).firstOrNull;

  /// The view groups [flow] uses, each with only its views; groups left
  /// empty are dropped. Null gives every group.
  List<HudViewGroup> viewsIn(HudUserFlow? flow) => flow == null
      ? views
      : [
          for (final g in views)
            if (g.views.any((v) => flow.views.contains(v.id)))
              HudViewGroup(g.title, g.flow, [
                for (final v in g.views)
                  if (flow.views.contains(v.id)) v,
              ]),
        ];

  /// The journey for [flow], or the content's own for all views.
  List<HudJourneyStep> journeyOf(HudUserFlow? flow) =>
      flow?.journey ?? journey;

  /// Every view, flat.
  List<HudView> get allViews => [for (final g in views) ...g.views];

  /// The view with [id].
  HudView view(String id) => allViews.firstWhere((v) => v.id == id);

  /// The flow [view] lives in.
  HudFlow flowOf(String view) =>
      views.firstWhere((g) => g.views.any((v) => v.id == view)).flow;

  /// The states [view] can be put in.
  List<HudState> statesOf(String view) => this.view(view).states ?? states;
}

/// A kind of view, all living in one flow: "Screens", "Sheets and modals",
/// "Outside the app".
@immutable
class HudViewGroup {
  /// Creates the group.
  const HudViewGroup(this.title, this.flow, this.views);

  /// The card's title.
  final String title;

  /// Where these views live. Moving to another flow swaps the phone.
  final HudFlow flow;

  /// The views.
  final List<HudView> views;
}

/// A view the phone can show.
@immutable
class HudView {
  /// Creates the view.
  const HudView(this.id, this.label, {this.note, this.states});

  /// Stable id, used in links and by the prototype's screen builder.
  final String id;

  /// How the HUD names it.
  final String label;

  /// One line on what it is, shown when it is the one on the phone.
  final String? note;

  /// The states this view can be put in, when they differ from the
  /// prototype's default set.
  final List<HudState>? states;
}

/// A task the member does, such as Create a goal: the views it uses and
/// the order they come in. Not a [HudFlow], which is where a view lives
/// (the app, a partner site): a user flow can cross several of those.
///
/// When a prototype has user flows, Views opens with a dropdown to pick
/// one, its cards list only that flow's views, and Journey walks its
/// journey. `?flow=<id>` opens on it.
@immutable
class HudUserFlow {
  /// Creates the user flow.
  const HudUserFlow(
    this.id,
    this.label, {
    required this.views,
    required this.journey,
    this.note,
    this.journeyTitle = 'Screens in order',
    this.journeyIsProgress = true,
  });

  /// Stable id, used in links.
  final String id;

  /// How the dropdown names it.
  final String label;

  /// One line on what it covers, under the dropdown.
  final String? note;

  /// The ids of the views it uses.
  final List<String> views;

  /// Its steps, in order.
  final List<HudJourneyStep> journey;

  /// The Journey card's title while it is picked.
  final String journeyTitle;

  /// Whether its journey is a progression (see [HudContent]).
  final bool journeyIsProgress;
}

/// A step of the journey, pointing at a view and, optionally, a state of
/// it, so one view can be several steps.
@immutable
class HudJourneyStep {
  /// Creates the step.
  const HudJourneyStep(this.view, {this.state, this.lead, this.dividerAfter});

  /// The view it opens.
  final String view;

  /// The state it puts the view in. A step with a state is current only
  /// while the phone shows that state.
  final String? state;

  /// What its badge shows. Defaults to its place in the journey.
  final String? lead;

  /// A line drawn after this step, where the journey changes meaning.
  final String? dividerAfter;
}

/// A state a view can be put in.
@immutable
class HudState {
  /// Creates the state.
  const HudState(this.id, this.label, {this.icon, this.note, this.group});

  /// Stable id, used in links and by the screen builder.
  final String id;

  /// How the HUD names it.
  final String label;

  /// Its icon in the list, if any.
  final IconData? icon;

  /// One line on what it is.
  final String? note;

  /// The set it belongs to, such as Today or Proposal. The states rail
  /// shows each set under its own heading, in the order they first come;
  /// a view with none shows one plain list.
  final String? group;

  /// The label with its set in front, for where it stands alone.
  String get fullLabel => group == null ? label : '$group · $label';
}

/// Something on screen that is mock or undecided.
@immutable
class HudOpenItem {
  /// Creates the item.
  const HudOpenItem(this.what, this.note);

  /// What it is.
  final String what;

  /// Why it is not final, and whose call it is.
  final String note;
}
