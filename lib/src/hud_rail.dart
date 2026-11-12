import 'package:aura_ds/aura_ds.dart';
import 'package:aura_ds/foundation/base/typography.dart'
    show AuraBaseTextStyles;
import 'package:flutter/material.dart';

import 'hud_content.dart';
import 'hud_controls.dart';
import 'hud_inspector.dart';
import 'hud_motion.dart';
import 'hud_prototype.dart';

/// Text that wraps over several lines. Aura's label styles set lines at
/// 100%, right for a single line, cramped for a paragraph, so prose in the
/// rail takes Aura's paragraph rhythm: 140%.
final TextStyle _prose = AuraTextStyles.paragraphSmall;
final TextStyle _proseSm = AuraTextStyles.labelSm.copyWith(
  height: AuraBaseTextStyles.lineHeight140,
);

/// The HUD rail, in two levels, so it never turns into an endless scroll:
///
/// - **An icon strip** on the outer edge picks a category: Summary, the
///   Navigator (steps, states and pieces in one tree), and Layout at the
///   foot.
/// - **A panel** beside it shows only that category.
///
/// The panel is built from solid layers: the rail is layer 1, a card on it
/// layer 2, and what is chosen inside the card layer 3. Lime marks only what
/// is active: the category, the current step, the chosen state.
///
/// It draws whatever [content] the prototype describes, and reads and
/// changes what is on the phone through the [HudPrototypeScope].
///
/// **Local to the HUD, not part of Aura DS.** Built from Aura tokens only.
class HudRail extends StatefulWidget {
  /// Creates the rail.
  const HudRail({
    required this.content,
    required this.layoutControls,
    super.key,
  });

  /// What the prototype puts in the HUD.
  final HudContent content;

  /// The page-layout controls, shown under the Layout category.
  final Widget layoutControls;

  @override
  State<HudRail> createState() => _HudRailState();
}

enum _Category {
  summary('Summary'),
  journey('Navigator'),
  layout('Layout');

  const _Category(this.label);

  /// The default name. The Navigator can be renamed per prototype; read the
  /// name shown with [labelIn].
  final String label;

  /// The name shown for this category in [content]'s HUD.
  String labelIn(HudContent content) =>
      this == journey ? content.journeyLabel : label;

  IconData get icon => switch (this) {
    summary => AuraIcons.info,
    journey => AuraIcons.missions,
    layout => AuraIcons.settings,
  };
}

class _HudRailState extends State<HudRail> {
  _Category _category = _Category.summary;

  /// The entry point opened last, kept while the phone walks the shared
  /// steps after it.
  String? _entry;

  /// The flow group picked last, for when no flow is picked yet.
  String? _pickedGroup;

  /// The flow group under review: the picked flow's, else the last picked,
  /// else the first.
  String? get _group =>
      _userFlow?.group ?? _pickedGroup ?? _content.flowGroups.firstOrNull;

  HudContent get _content => widget.content;
  HudPrototype get _prototype => HudPrototypeScope.of(context);

  /// The view on the phone, shared with the stage.
  String get _view => _prototype.view;

  /// The user flow being reviewed, or null for all views.
  HudUserFlow? get _userFlow => _content.userFlow(_prototype.userFlow);

  /// The journey being walked: the user flow's, or the content's own.
  List<HudJourneyStep> get _journey => _content.journeyOf(_userFlow);

  String get _journeyTitle => _userFlow?.journeyTitle ?? _content.journeyTitle;

  bool get _journeyIsProgress =>
      _userFlow?.journeyIsProgress ?? _content.journeyIsProgress;

  /// Where the phone sits in the journey, if it is in it. A step that names
  /// a state only counts in that state.
  int get _step => _journey.indexWhere(
    (s) => s.view == _view && (s.state == null || s.state == _prototype.state),
  );

  /// Sends the phone to [view], in [state] when given. Otherwise the state
  /// stays if the new view has it, or resets to its first.
  void _show(String view, {String? state}) {
    HudInspectorScope.of(context).focus = null;
    var states = _content.statesOf(view);
    var keep = states.any((st) => st.id == _prototype.state);
    _prototype.show(
      view,
      _content.flowOf(view),
      state: state ?? (keep || states.isEmpty ? null : states.first.id),
    );
  }

  /// Reviews the user flow [id] (null for all views) and sends the phone to
  /// its first step.
  void _pickUserFlow(String? id) {
    _entry = null;
    _prototype.userFlow = id;
    var first = _content.journeyOf(_content.userFlow(id)).firstOrNull;
    if (id != null && first != null) _show(first.view, state: first.state);
  }

  /// Opens a category. Clicks on the phone pick pieces only while the
  /// Navigator is open with Inspect on, and leaving it closes the code
  /// viewer, which only makes sense beside the tree that opened it.
  void _go(_Category c) {
    var inspector = HudInspectorScope.of(context);
    var navigator = c == _Category.journey;
    inspector.picking = navigator && inspector.on;
    if (!navigator) inspector.focus = null;
    _prototype.browsingViews = false;
    setState(() => _category = c);
  }

  /// Turns the inspector's outlines and picking on the phone on or off.
  void _inspect(bool on) {
    var inspector = HudInspectorScope.of(context);
    inspector
      ..on = on
      ..picking = on;
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Strip(
        content: _content,
        selected: _category,
        badges: {
          if (_content.generalOpenItems.isNotEmpty)
            _Category.summary: _content.generalOpenItems.length,
        },
        onPick: _go,
      ),
      Expanded(
        // The old panel fades out quickly; the new one assembles itself,
        // its cards rising in one after another (see _panel).
        child: AnimatedSwitcher(
          duration: AuraMotion.durationNormal,
          switchInCurve: HudMotion.flow,
          switchOutCurve: HudMotion.flow,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(
            key: ValueKey(_category),
            child: _panel(_category),
          ),
        ),
      ),
    ],
  );

  // Spacing runs on an 8 grid: 20 around the panel, 20 under its title, 12
  // between cards. Inside a card everything starts 16 in, so card titles,
  // plain text and row labels share one left edge.
  Widget _panel(_Category c) => ListView(
    padding: const EdgeInsets.fromLTRB(
      AuraSpacing.space20,
      AuraSpacing.space20,
      AuraSpacing.space20,
      AuraSpacing.space32,
    ),
    children: [
      for (final (i, w) in [
        Padding(
          padding: const EdgeInsets.only(
            left: AuraSpacing.space16,
            bottom: AuraSpacing.space20,
          ),
          child: AuraText(
            c.labelIn(_content),
            style: AuraTextStyles.h3,
            color: AuraColors.textInverse,
          ),
        ),
        ...switch (c) {
          _Category.summary => _summary(),
          _Category.journey => _navigatorPanel(),
          _Category.layout => [_Card(child: widget.layoutControls)],
        },
      ].indexed)
        HudReveal(index: i, child: w),
    ],
  );

  /// A card that says a category has nothing to show yet, and why.
  Widget _empty(String text) => _Card(
    child: AuraText(text, style: _prose, color: AuraColors.textInverseMuted),
  );

  /// What a reviewer needs before touching anything: the question, and what
  /// is on the phone right now, each a shortcut to its category.
  List<Widget> _summary() {
    var view = _content.view(_view);
    var states = _content.statesOf(_view);
    var state = states.where((st) => st.id == _prototype.state).firstOrNull;
    return [
      _Card(
        title: 'What we’re testing',
        meta: _content.round,
        child: AuraText(
          _content.question,
          style: AuraTextStyles.labelLg.copyWith(
            height: AuraBaseTextStyles.lineHeight130,
          ),
          color: AuraColors.textInverse,
        ),
      ),
      _Card(
        title: 'On the phone now',
        flush: true,
        child: Column(
          children: [
            _JumpRow(
              label: 'Screen',
              value: view.label,
              onTap: () => _go(_Category.journey),
            ),
            if (_userFlow != null)
              _JumpRow(
                label: 'Flow',
                value: _userFlow!.label,
                onTap: () => _go(_Category.journey),
              ),
            if (_step >= 0 && _journeyIsProgress)
              _JumpRow(
                label: 'Step',
                value: '${_step + 1} of ${_journey.length}',
                onTap: () => _go(_Category.journey),
              ),
            if (state != null)
              _JumpRow(
                label: 'State',
                value: state.fullLabel,
                onTap: () => _go(_Category.journey),
              ),
            if (_content.openItemsOn(_view).isNotEmpty)
              _JumpRow(
                label: 'Not final here',
                value: '${_content.openItemsOn(_view).length}',
                onTap: () => _go(_Category.journey),
              ),
          ],
        ),
      ),
      if (view.note != null)
        _Card(
          title: view.label,
          child: AuraText(
            view.note!,
            style: _prose,
            color: AuraColors.textInverseMuted,
          ),
        ),
      if (_content.generalOpenItems.isNotEmpty)
        _Card(
          title: 'Not final',
          meta: '${_content.generalOpenItems.length}',
          child: Column(
            children: [
              for (final o in _content.generalOpenItems)
                _OpenItem(what: o.what, note: o.note),
            ],
          ),
        ),
    ];
  }

  /// The Navigator: one tree, read top to bottom. The flow, the steps in
  /// order (the current one unfolds its states and open items), the views
  /// outside the journey, and the pieces of the screen on the phone.
  List<Widget> _navigatorPanel() {
    var steps = _journey;
    var inJourney = {for (final st in steps) st.view};
    var others = [
      for (final g in _content.viewsIn(_userFlow))
        for (final v in g.views)
          if (!inJourney.contains(v.id)) v,
    ];
    // The journey's entry points, in order. Without them, one list.
    var entries = [
      ...{
        for (final st in steps)
          if (st.entry != null) st.entry!,
      },
    ];
    var here = _step >= 0 ? steps[_step].entry : null;
    if (here != null) _entry = here;
    var open = _entry != null && entries.contains(_entry)
        ? _entry!
        : entries.firstOrNull;
    return [
      if (_content.userFlows.isNotEmpty) _flowCard(),
      if (steps.isNotEmpty && entries.isEmpty)
        _Card(
          title: _journeyTitle,
          flush: true,
          meta: _journeyIsProgress && _step >= 0
              ? '${_step + 1} of ${steps.length}'
              : '${steps.length}',
          child: _stepColumn([for (final (i, st) in steps.indexed) (i, st)]),
        ),
      for (final e in entries)
        _EntryCard(
          title: e,
          lead: steps.firstWhere((st) => st.entry == e).lead,
          count: steps.where((st) => st.entry == e || st.entry == null).length,
          open: e == open,
          onTap: () {
            if (e == open) return;
            setState(() => _entry = e);
            var first = steps.firstWhere((st) => st.entry == e);
            _show(first.view, state: first.state);
          },
          // Its own steps, then the shared ones.
          child: _stepColumn([
            for (final (i, st) in steps.indexed)
              if (st.entry == e || st.entry == null) (i, st),
          ]),
        ),
      if (others.isNotEmpty)
        _Card(
          title: steps.isEmpty ? 'Views' : 'Other views',
          flush: true,
          meta: '${others.length}',
          child: HudLiquidColumn(
            gap: AuraSpacing.space2,
            radius: AuraSpacing.radiusMd,
            selected: null,
            children: [
              for (final v in others)
                _StepRow(
                  step: _Step(v.label, offApp: _content.flowOf(v.id).order > 0),
                  lead: '·',
                  current: v.id == _view && _step < 0,
                  done: false,
                  flag: _content.openItemsOn(v.id).length,
                  detail: v.id == _view && _step < 0
                      ? _detail(v.id, note: v.note, withStates: true)
                      : null,
                  onTap: () => _show(v.id),
                ),
            ],
          ),
        ),
      if (steps.isEmpty && others.isEmpty)
        _empty('This prototype has no views yet.'),
      ..._componentsCards(),
    ];
  }

  /// Steps as rows, each with its place in the journey. A step with a
  /// divider after it draws the divider. No drop on the steps: the lime
  /// number marks the current one, and the drop would make everything it
  /// unfolds look chosen too.
  Widget _stepColumn(List<(int, HudJourneyStep)> items) {
    var rows = <Widget>[];
    for (final (i, st) in items) {
      var view = _content.view(st.view);
      // A step that names a state reads as that state.
      var state = _content
          .statesOf(st.view)
          .where((x) => x.id == st.state)
          .firstOrNull;
      var current = i == _step;
      rows.add(
        _StepRow(
          step: _Step(
            state?.fullLabel ?? view.label,
            offApp: _content.flowOf(st.view).order > 0,
          ),
          lead: st.lead ?? '${i + 1}',
          current: current,
          done: _journeyIsProgress && _step >= 0 && i < _step,
          flag: _content.openItemsOn(st.view).length,
          detail: current
              ? _detail(
                  st.view,
                  note: state == null ? view.note : view.label,
                  withStates: st.state == null,
                )
              : null,
          onTap: () => _show(st.view, state: st.state),
        ),
      );
      if (st.dividerAfter != null) rows.add(_Divider(st.dividerAfter!));
    }
    return HudLiquidColumn(
      gap: AuraSpacing.space2,
      radius: AuraSpacing.radiusMd,
      selected: null,
      children: rows,
    );
  }

  /// The flow pickers, right above the steps: the group (a session) when
  /// flows have groups, then the flow inside it. Bare, not in a card,
  /// because they drive the card below them.
  Widget _flowCard() {
    var groups = _content.flowGroups;
    var group = _group;
    var flows = [
      for (final f in _content.userFlows)
        if (groups.isEmpty || f.group == group) f,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AuraSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (groups.isNotEmpty) ...[
            HudSelect<String>(
              value: group!,
              options: [for (final g in groups) (g, g)],
              onChanged: (g) {
                setState(() => _pickedGroup = g);
                _pickUserFlow(
                  _content.userFlows.where((f) => f.group == g).firstOrNull?.id,
                );
              },
            ),
            const SizedBox(height: AuraSpacing.space8),
          ],
          // Only the flows: a prototype is reviewed one flow at a time
          // (Nov 12, 2026, Christian: All views was not needed).
          HudSelect<String?>(
            value: _userFlow?.id ?? flows.firstOrNull?.id,
            options: [for (final f in flows) (f.id, f.label)],
            onChanged: _pickUserFlow,
          ),
        ],
      ),
    );
  }

  /// What the current row unfolds: its note, its states and what on it is
  /// not final.
  Widget _detail(String viewId, {String? note, bool withStates = true}) {
    var states = withStates ? _content.statesOf(viewId) : const <HudState>[];
    var open = _content.openItemsOn(viewId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: AuraSpacing.space4),
            child: AuraText(
              note,
              style: _proseSm,
              color: AuraColors.textInverseMuted,
            ),
          ),
        if (states.isNotEmpty) ...[
          const SizedBox(height: AuraSpacing.space8),
          for (final (g, inGroup) in _groups(states)) ...[
            if (g != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AuraSpacing.space8,
                  AuraSpacing.space8,
                  AuraSpacing.space8,
                  AuraSpacing.space4,
                ),
                child: AuraText(
                  g.toUpperCase(),
                  style: AuraTextStyles.labelSm,
                  color: AuraColors.textInverseSubtle,
                ),
              ),
            for (final st in inGroup)
              _StateRow(
                label: st.label,
                note: st.note,
                selected: st.id == _prototype.state,
                onTap: () {
                  HudInspectorScope.of(context).focus = null;
                  _prototype.setState(st.id);
                },
              ),
          ],
        ],
        if (open.isNotEmpty) ...[
          const SizedBox(height: AuraSpacing.space4),
          for (final o in open)
            _OpenItem(
              what: o.state == null
                  ? o.what
                  : '${o.what} · ${_content.statesOf(viewId).where((x) => x.id == o.state).firstOrNull?.label ?? o.state}',
              note: o.note,
            ),
        ],
      ],
    );
  }

  /// Inspect mode. Off, the phone behaves like the app and the card only
  /// offers the switch. On, the pieces show on the phone and in a tree, and
  /// picking one, here or on the phone, opens its code.
  List<Widget> _componentsCards() {
    var inspector = HudInspectorScope.of(context);
    var on = inspector.on;
    var tree = on ? inspector.tree : const <HudTreeEntry>[];
    var focused = tree.indexWhere((e) => e.path == inspector.focus);
    return [
      _Card(
        title: on ? 'Components · ${_content.view(_view).label}' : null,
        flush: on && tree.isNotEmpty,
        meta: on && tree.isNotEmpty ? '${tree.length}' : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: on && tree.isNotEmpty
                  ? const EdgeInsets.fromLTRB(
                      AuraSpacing.space8,
                      0,
                      AuraSpacing.space8,
                      AuraSpacing.space8,
                    )
                  : EdgeInsets.zero,
              child: HudSwitch(
                value: on,
                label: 'Inspect',
                onChanged: _inspect,
              ),
            ),
            if (!on)
              Padding(
                padding: const EdgeInsets.only(top: AuraSpacing.space8),
                child: AuraText(
                  'See how the screen is built: its pieces on the phone and '
                  'their code.',
                  style: _proseSm,
                  color: AuraColors.textInverseMuted,
                ),
              )
            else if (tree.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AuraSpacing.space8),
                child: AuraText(
                  'No pieces marked on this screen yet. Wrap them in '
                  'HudComponent to see how the screen is built.',
                  style: _proseSm,
                  color: AuraColors.textInverseMuted,
                ),
              )
            else
              HudLiquidColumn(
                gap: AuraSpacing.space2,
                radius: AuraSpacing.radiusMd,
                selected: focused < 0 ? null : focused,
                children: [
                  for (final e in tree)
                    _TreeRow(
                      entry: e,
                      selected: inspector.focus == e.path,
                      onTap: () => inspector.focus = inspector.focus == e.path
                          ? null
                          : e.path,
                    ),
                ],
              ),
          ],
        ),
      ),
      if (on && tree.isNotEmpty)
        _Card(
          title: 'By origin',
          child: Column(
            children: [
              for (final o in HudOrigin.values)
                _JumpRow(
                  label: o.label,
                  value: '${tree.where((e) => e.origin == o).length}',
                ),
            ],
          ),
        ),
    ];
  }
}

/// Where the journey changes meaning: a hairline and a short caption.
class _Divider extends StatelessWidget {
  const _Divider(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AuraSpacing.space8),
    child: Row(
      children: [
        // A short rule, the width of a step's badge, then the caption, which
        // can wrap: it never fights the rule for room.
        const SizedBox(
          width: AuraSpacing.space24,
          child: Divider(
            height: AuraSpacing.borderWidthThin,
            thickness: AuraSpacing.borderWidthThin,
            color: AuraColors.borderInverseSubtle,
          ),
        ),
        const SizedBox(width: AuraSpacing.space12),
        Flexible(
          child: AuraText(
            text,
            style: AuraTextStyles.labelSmLight.copyWith(
              height: AuraBaseTextStyles.lineHeight140,
            ),
            color: AuraColors.textInverseSubtle,
          ),
        ),
      ],
    ),
  );
}

/// A screen in the journey.
class _Step {
  const _Step(this.label, {this.offApp = false});

  final String label;

  /// Happens outside the app: a partner's page, the system browser.
  final bool offApp;
}

/// The icon strip: one button per category, Layout pinned to the foot.
class _Strip extends StatelessWidget {
  const _Strip({
    required this.content,
    required this.selected,
    required this.badges,
    required this.onPick,
  });

  final HudContent content;
  final _Category selected;
  final Map<_Category, int> badges;
  final ValueChanged<_Category> onPick;

  /// The height each button takes: the 40 button and its 4 above and below.
  static const double _slot = AuraSpacing.space48;

  @override
  Widget build(BuildContext context) => Container(
    width: AuraSpacing.space48,
    padding: const EdgeInsets.symmetric(vertical: AuraSpacing.space12),
    color: AuraColors.surfaceInverse,
    // The edge is painted over, not laid out, so it takes no width and the
    // strip's centre stays at 24: the same axis as the header's toggle.
    foregroundDecoration: const BoxDecoration(
      border: Border(right: BorderSide(color: AuraColors.borderInverseFaint)),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        var top = selected == _Category.layout
            ? box.maxHeight - _slot
            : _Category.values.indexOf(selected) * _slot;
        // Expand, so the column of buttons spans the strip and centres
        // them, instead of shrinking to one button and hugging the left.
        return Stack(
          fit: StackFit.expand,
          children: [
            // One highlight that flows between buttons like a drop of
            // liquid, instead of one that blinks on and off.
            HudLiquidDrop(
              rect: Rect.fromLTWH(
                (box.maxWidth - AuraSpacing.space40) / 2,
                top + AuraSpacing.space4,
                AuraSpacing.space40,
                AuraSpacing.space40,
              ),
              color: AuraColors.surfaceInverseL2,
              radius: AuraSpacing.radiusMd,
            ),
            Column(
              children: [
                for (final c in _Category.values)
                  if (c != _Category.layout)
                    _StripButton(
                      category: c,
                      label: c.labelIn(content),
                      selected: c == selected,
                      badge: badges[c],
                      onTap: () => onPick(c),
                    ),
                const Spacer(),
                _StripButton(
                  category: _Category.layout,
                  label: _Category.layout.label,
                  selected: selected == _Category.layout,
                  onTap: () => onPick(_Category.layout),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _StripButton extends StatefulWidget {
  const _StripButton({
    required this.category,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final _Category category;
  final String label;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  @override
  State<_StripButton> createState() => _StripButtonState();
}

class _StripButtonState extends State<_StripButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    var selected = widget.selected;
    return Tooltip(
      message: widget.label,
      waitDuration: AuraMotion.durationXSlow,
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.label,
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AuraSpacing.space4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: AuraMotion.durationSlow,
                    curve: HudMotion.flow,
                    width: AuraSpacing.space40,
                    height: AuraSpacing.space40,
                    alignment: Alignment.center,
                    // Clear at rest, so the travelling highlight shows
                    // through; a faint lift on hover.
                    decoration: BoxDecoration(
                      color: !selected && _hover
                          ? AuraColors.surfaceInverseFaint
                          : AuraColors.surfaceInverseFaint.withValues(alpha: 0),
                      borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
                    ),
                    child: AnimatedScale(
                      scale: selected ? 1.1 : 1,
                      duration: AuraMotion.durationSlow,
                      curve: HudMotion.wobble,
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(
                          end: selected
                              ? AuraColors.interactiveAccentOn
                              : _hover
                              ? AuraColors.iconInverse
                              : AuraColors.iconInverseSubtle,
                        ),
                        duration: AuraMotion.durationSlow,
                        curve: HudMotion.flow,
                        builder: (context, color, _) => Icon(
                          widget.category.icon,
                          size: AuraSpacing.space16,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  if (widget.badge != null)
                    Positioned(
                      top: AuraSpacing.space4,
                      right: AuraSpacing.space4,
                      child: Container(
                        width: AuraSpacing.space14,
                        height: AuraSpacing.space14,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuraColors.surfaceInverseL3,
                        ),
                        child: AuraText(
                          '${widget.badge}',
                          style: AuraTextStyles.labelSmLight,
                          color: AuraColors.textInverse,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A layer-2 card on the rail, with an optional title and meta.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.title, this.meta, this.flush = false});

  final String? title;
  final String? meta;
  final Widget child;

  /// For lists of rows: the rows run to 8 from the card's edge and carry
  /// their own 8 of padding, so their labels land on the same 16 as the
  /// title, and their drop sits concentric with the card's corners.
  final bool flush;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AuraSpacing.space12),
    padding: const EdgeInsets.all(AuraSpacing.space8),
    decoration: BoxDecoration(
      color: AuraColors.surfaceInverseL2,
      borderRadius: BorderRadius.circular(AuraSpacing.radiusLg),
      border: Border.all(
        color: AuraColors.borderInverseFaint,
        width: AuraSpacing.borderWidthThin,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AuraSpacing.space8,
              AuraSpacing.space8,
              AuraSpacing.space8,
              AuraSpacing.space12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AuraText(
                    title!.toUpperCase(),
                    style: AuraTextStyles.labelSm,
                    color: AuraColors.textInverseSubtle,
                  ),
                ),
                if (meta != null)
                  AuraText(
                    meta!,
                    style: AuraTextStyles.labelSmLight,
                    color: AuraColors.textInverseSubtle,
                  ),
              ],
            ),
          ),
        if (flush)
          child
        else
          Padding(
            padding: EdgeInsets.fromLTRB(
              AuraSpacing.space8,
              title == null ? AuraSpacing.space8 : 0,
              AuraSpacing.space8,
              AuraSpacing.space8,
            ),
            child: child,
          ),
      ],
    ),
  );
}

/// Summary: a label, the current value and a chevron; tapping it opens the
/// category that owns it.
class _JumpRow extends StatefulWidget {
  const _JumpRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;

  /// Null for a row that only reads: no hover, no chevron.
  final VoidCallback? onTap;

  @override
  State<_JumpRow> createState() => _JumpRowState();
}

class _JumpRowState extends State<_JumpRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hover = widget.onTap != null),
    onExit: (_) => setState(() => _hover = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AuraMotion.durationSlow,
        curve: HudMotion.flow,
        padding: const EdgeInsets.all(AuraSpacing.space8),
        decoration: BoxDecoration(
          color: _hover
              ? AuraColors.surfaceInverseL3
              : AuraColors.surfaceInverseL2,
          borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
        ),
        child: Row(
          children: [
            // The label keeps its width; a long value gives way, ending in
            // an ellipsis, instead of squeezing the label onto two lines.
            AuraText(
              widget.label,
              style: AuraTextStyles.labelMd,
              color: AuraColors.textInverseMuted,
            ),
            const SizedBox(width: AuraSpacing.space12),
            Expanded(
              child: AuraText(
                widget.value,
                style: AuraTextStyles.labelMdStrong,
                color: AuraColors.textInverse,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.onTap != null) ...[
              const SizedBox(width: AuraSpacing.space4),
              Icon(
                AuraIcons.forward,
                size: AuraSpacing.space12,
                color: AuraColors.iconInverseSubtle,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Journey: a row with a numbered badge. The current one rises to layer 3
/// with a lime badge; steps already walked show a check.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.lead,
    required this.current,
    required this.done,
    required this.onTap,
    this.flag = 0,
    this.detail,
  });

  final _Step step;

  /// How many open items sit on the step's view: a ⚠ and the count on the
  /// right.
  final int flag;

  /// What the row unfolds while it is the current one: note, states, open
  /// items.
  final Widget? detail;

  /// What the badge shows: its place, or a rung on a ladder.
  final String lead;
  final bool current;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AuraMotion.durationSlow,
        curve: HudMotion.flow,
        padding: const EdgeInsets.all(AuraSpacing.space8),
        decoration: BoxDecoration(
          color: hudRowFill(hover: false),
          borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AuraMotion.durationSlow,
              curve: HudMotion.flow,
              width: AuraSpacing.space24,
              height: AuraSpacing.space24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: current
                    ? AuraColors.interactiveAccentOn
                    : AuraColors.surfaceInverseL3,
              ),
              child: done && !current
                  ? Icon(
                      AuraIcons.check,
                      size: AuraSpacing.space12,
                      color: AuraColors.iconInverse,
                    )
                  : AuraText(
                      lead,
                      style: AuraTextStyles.labelSm,
                      color: current
                          ? AuraColors.textOnAccentBright
                          : AuraColors.textInverseSubtle,
                    ),
            ),
            const SizedBox(width: AuraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(
                    step.label,
                    style: current
                        ? AuraTextStyles.labelMdStrong
                        : AuraTextStyles.labelMd,
                    color: current
                        ? AuraColors.textInverse
                        : AuraColors.textInverseMuted,
                  ),
                  if (step.offApp) const _LeavesTheApp(),
                  AnimatedSize(
                    duration: AuraMotion.durationExpand,
                    curve: HudMotion.flow,
                    alignment: Alignment.topLeft,
                    child: detail ?? const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
            if (flag > 0) ...[
              const SizedBox(width: AuraSpacing.space8),
              const SizedBox(height: AuraSpacing.space24),
              Icon(
                AuraIcons.warning,
                size: AuraSpacing.space12,
                color: AuraColors.iconInverseSubtle,
              ),
              const SizedBox(width: AuraSpacing.space2),
              AuraText(
                '$flag',
                style: AuraTextStyles.labelSm,
                color: AuraColors.textInverseSubtle,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// States: a dense row. The chosen one rises to layer 3, with a lime bar on
/// its left edge and a lime check on its right.
class _StateRow extends StatefulWidget {
  const _StateRow({
    required this.label,
    this.note,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// One line on what it is, shown while it is the chosen one.
  final String? note;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StateRow> createState() => _StateRowState();
}

class _StateRowState extends State<_StateRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    var selected = widget.selected;
    // The chosen state is the one thing raised to layer 3 in its step.
    var fill = selected
        ? AuraColors.surfaceInverseL3
        : hudRowFill(hover: _hover);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AuraMotion.durationSlow,
          curve: HudMotion.flow,
          padding: const EdgeInsets.all(AuraSpacing.space8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuraText(
                      widget.label,
                      style: selected
                          ? AuraTextStyles.labelMdStrong
                          : AuraTextStyles.labelMd,
                      color: selected
                          ? AuraColors.textInverse
                          : AuraColors.textInverseMuted,
                    ),
                    _Note(text: widget.note, open: selected),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  AuraIcons.check,
                  size: AuraSpacing.space14,
                  color: AuraColors.interactiveAccentOn,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Components: one piece of the tree. Each level of depth draws a guide in
/// its rainbow color, like VS Code's indent guides; a dot of the piece's own
/// color leads its name, and its origin sits on the right.
class _TreeRow extends StatefulWidget {
  const _TreeRow({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final HudTreeEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_TreeRow> createState() => _TreeRowState();
}

class _TreeRowState extends State<_TreeRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    var e = widget.entry;
    var selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AuraMotion.durationSlow,
          curve: HudMotion.flow,
          padding: const EdgeInsets.symmetric(horizontal: AuraSpacing.space8),
          decoration: BoxDecoration(
            color: hudRowFill(hover: _hover && !selected),
            borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // One guide per ancestor, each in that ancestor's color.
                for (var d = 0; d < e.depth; d++)
                  Container(
                    width: AuraSpacing.space12,
                    alignment: Alignment.centerLeft,
                    // On the centre of the parent's dot above.
                    padding: const EdgeInsets.only(left: AuraSpacing.space4),
                    child: Container(
                      width: AuraSpacing.borderWidthDefault,
                      color: HudDepthColors.onDark(d),
                    ),
                  ),
                Center(
                  child: Container(
                    width: AuraSpacing.space8,
                    height: AuraSpacing.space8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: HudDepthColors.onDark(e.depth),
                    ),
                  ),
                ),
                const SizedBox(width: AuraSpacing.space8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AuraSpacing.space6,
                    ),
                    child: AuraText(
                      e.count > 1 ? '${e.name} ×${e.count}' : e.name,
                      style: selected
                          ? AuraTextStyles.labelMdStrong
                          : AuraTextStyles.labelMd,
                      color: selected
                          ? AuraColors.textInverse
                          : AuraColors.textInverseMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Center(
                  child: AuraText(
                    e.origin.label,
                    style: AuraTextStyles.labelSmLight,
                    color: AuraColors.textInverseSubtle,
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

/// A row's one-line note, unfolding under its label while the row is the
/// current one.
class _Note extends StatelessWidget {
  const _Note({required this.text, required this.open});

  final String? text;
  final bool open;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: AuraMotion.durationExpand,
    curve: HudMotion.flow,
    alignment: Alignment.topLeft,
    child: text != null && open
        ? Padding(
            padding: const EdgeInsets.only(top: AuraSpacing.space4),
            child: AuraText(
              text!,
              style: _proseSm,
              color: AuraColors.textInverseMuted,
            ),
          )
        : const SizedBox(width: double.infinity),
  );
}

/// The off-app marker under a journey step.
class _LeavesTheApp extends StatelessWidget {
  const _LeavesTheApp();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AuraSpacing.space2),
    child: Row(
      children: [
        Icon(
          AuraIcons.externalLink,
          size: AuraSpacing.space12,
          color: AuraColors.iconInverseSubtle,
        ),
        const SizedBox(width: AuraSpacing.space4),
        AuraText(
          'Leaves the app',
          style: AuraTextStyles.labelSmLight,
          color: AuraColors.textInverseSubtle,
        ),
      ],
    ),
  );
}

/// Something on screen that is mock or undecided.
class _OpenItem extends StatelessWidget {
  const _OpenItem({required this.what, required this.note});

  final String what;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AuraSpacing.space8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AuraSpacing.space2),
          child: Icon(
            AuraIcons.warning,
            size: AuraSpacing.space14,
            color: AuraColors.iconInverseSubtle,
          ),
        ),
        const SizedBox(width: AuraSpacing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraText(
                what,
                style: AuraTextStyles.labelMdStrong,
                color: AuraColors.textInverse,
              ),
              const SizedBox(height: AuraSpacing.space4),
              AuraText(
                note,
                style: _proseSm,
                color: AuraColors.textInverseMuted,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The states of the view on the phone, beside the rail while it is on
/// Views: what the view is, then each state as a card with its title and
/// what it shows, all in sight at once. Picking one puts the phone in it.
class HudStatesRail extends StatelessWidget {
  /// Creates the states rail for [content].
  const HudStatesRail({required this.content, super.key});

  /// How wide it opens.
  static const double width = 280;

  /// What the prototype puts in the HUD.
  final HudContent content;

  @override
  Widget build(BuildContext context) {
    var prototype = HudPrototypeScope.of(context);
    var view = content.view(prototype.view);
    var states = content.statesOf(prototype.view);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AuraColors.surfaceInverse,
        border: Border(
          right: BorderSide(color: AuraColors.borderInverseSubtle),
        ),
      ),
      child: ListView(
        // A new view assembles its cards again, one after another.
        key: ValueKey(prototype.view),
        padding: const EdgeInsets.fromLTRB(
          AuraSpacing.space16,
          AuraSpacing.space20,
          AuraSpacing.space16,
          AuraSpacing.space32,
        ),
        children: [
          for (final (i, w) in [
            Padding(
              padding: const EdgeInsets.only(
                left: AuraSpacing.space4,
                bottom: AuraSpacing.space4,
              ),
              child: AuraText(
                'STATES · ${states.length}',
                style: AuraTextStyles.labelSm,
                color: AuraColors.textInverseSubtle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AuraSpacing.space4,
                bottom: AuraSpacing.space8,
              ),
              child: AuraText(
                view.label,
                style: AuraTextStyles.h3,
                color: AuraColors.textInverse,
              ),
            ),
            if (view.note != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: AuraSpacing.space4,
                  bottom: AuraSpacing.space20,
                ),
                child: AuraText(
                  view.note!,
                  style: _prose,
                  color: AuraColors.textInverseMuted,
                ),
              ),
            for (final (g, inGroup) in _groups(states)) ...[
              if (g != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AuraSpacing.space4,
                    AuraSpacing.space12,
                    AuraSpacing.space4,
                    AuraSpacing.space8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AuraText(
                          g.toUpperCase(),
                          style: AuraTextStyles.labelSm,
                          color: AuraColors.textInverseSubtle,
                        ),
                      ),
                      AuraText(
                        '${inGroup.length}',
                        style: AuraTextStyles.labelSm,
                        color: AuraColors.textInverseFaint,
                      ),
                    ],
                  ),
                ),
              for (final st in inGroup)
                Padding(
                  padding: const EdgeInsets.only(bottom: AuraSpacing.space8),
                  child: _StateCard(
                    state: st,
                    selected: st.id == prototype.state,
                    onTap: () => prototype.setState(st.id),
                  ),
                ),
            ],
          ].indexed)
            HudReveal(index: i, child: w),
        ],
      ),
    );
  }
}

/// The states in their sets, in the order each set first comes. States
/// with no set make one set with no heading.
List<(String?, List<HudState>)> _groups(List<HudState> states) {
  var sets = <String?, List<HudState>>{};
  for (final st in states) {
    sets.putIfAbsent(st.group, () => []).add(st);
  }
  return [for (final e in sets.entries) (e.key, e.value)];
}

/// One state, as a card: its title, and what it shows underneath, always
/// in sight. The chosen one carries the lime edge and the check.
class _StateCard extends StatefulWidget {
  const _StateCard({
    required this.state,
    required this.selected,
    required this.onTap,
  });

  final HudState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_StateCard> createState() => _StateCardState();
}

class _StateCardState extends State<_StateCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    var selected = widget.selected;
    var st = widget.state;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AuraMotion.durationSlow,
          curve: HudMotion.flow,
          padding: const EdgeInsets.all(AuraSpacing.space16),
          decoration: BoxDecoration(
            color: selected || _hover
                ? AuraColors.surfaceInverseL3
                : AuraColors.surfaceInverseL2,
            borderRadius: BorderRadius.circular(AuraSpacing.radiusLg),
            border: Border.all(
              color: selected
                  ? AuraColors.interactiveAccentOn
                  : AuraColors.borderInverseFaint,
              width: AuraSpacing.borderWidthThin,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (st.icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: AuraSpacing.space2),
                  child: Icon(
                    st.icon,
                    size: AuraSpacing.space14,
                    color: AuraColors.iconInverseSubtle,
                  ),
                ),
                const SizedBox(width: AuraSpacing.space8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuraText(
                      st.label,
                      style: AuraTextStyles.labelMdStrong,
                      color: AuraColors.textInverse,
                    ),
                    if (st.note != null) ...[
                      const SizedBox(height: AuraSpacing.space4),
                      AuraText(
                        st.note!,
                        style: _proseSm,
                        color: AuraColors.textInverseMuted,
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: AuraMotion.durationSlow,
                curve: HudMotion.flow,
                child: Padding(
                  padding: const EdgeInsets.only(left: AuraSpacing.space8),
                  child: Icon(
                    AuraIcons.check,
                    size: AuraSpacing.space14,
                    color: AuraColors.interactiveAccentOn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One entry point of a flow: collapsed to its name, or open on its steps
/// and the shared ones after them. One is open at a time.
class _EntryCard extends StatefulWidget {
  const _EntryCard({
    required this.title,
    required this.count,
    required this.open,
    required this.onTap,
    required this.child,
    this.lead,
  });

  final String title;

  /// Its first step's badge, such as 1a.
  final String? lead;

  /// How many steps it walks, shared ones included.
  final int count;
  final bool open;
  final VoidCallback onTap;

  /// The steps, shown while open.
  final Widget child;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    var open = widget.open;
    return Container(
      margin: const EdgeInsets.only(bottom: AuraSpacing.space12),
      padding: const EdgeInsets.all(AuraSpacing.space8),
      decoration: BoxDecoration(
        color: AuraColors.surfaceInverseL2,
        borderRadius: BorderRadius.circular(AuraSpacing.radiusLg),
        border: Border.all(
          color: AuraColors.borderInverseFaint,
          width: AuraSpacing.borderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: open ? MouseCursor.defer : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: AuraMotion.durationSlow,
                curve: HudMotion.flow,
                padding: const EdgeInsets.all(AuraSpacing.space8),
                decoration: BoxDecoration(
                  color: hudRowFill(hover: _hover && !open),
                  borderRadius: BorderRadius.circular(AuraSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AuraText(
                        widget.title,
                        style: open
                            ? AuraTextStyles.labelMdStrong
                            : AuraTextStyles.labelMd,
                        color: open
                            ? AuraColors.textInverse
                            : AuraColors.textInverseMuted,
                      ),
                    ),
                    AuraText(
                      '${widget.count}',
                      style: AuraTextStyles.labelSmLight,
                      color: AuraColors.textInverseSubtle,
                    ),
                    const SizedBox(width: AuraSpacing.space8),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: AuraMotion.durationSlow,
                      curve: HudMotion.flow,
                      child: Icon(
                        AuraIcons.expandDown,
                        size: AuraSpacing.space12,
                        color: AuraColors.iconInverseSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AuraMotion.durationExpand,
            curve: HudMotion.flow,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.only(top: AuraSpacing.space4),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
