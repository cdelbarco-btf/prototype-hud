import 'package:aura_ds/aura_ds.dart';
import 'package:aura_ds/foundation/base/colors.dart' show AuraBaseColors;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'hud_controls.dart';
import 'hud_inspector.dart';
import 'hud_motion.dart';

/// The code viewer: opens beside the rail when a piece is picked in the
/// Components tree, and shows how that piece is built.
///
/// The code is read from the prototype's own source files, bundled as assets,
/// so it is always the code that is running. Brackets take the inspector's
/// rainbow by nesting depth, the way VS Code colors bracket pairs, so the
/// structure on the phone and the structure in the code read the same.
///
/// **Local to the HUD, not part of Aura DS.**
class HudCodeView extends StatefulWidget {
  /// Creates the viewer over the given source assets.
  const HudCodeView({required this.sources, super.key});

  /// Width of the open viewer. Layout data, like the rail's width.
  static const double width = 400;

  /// The least the stage keeps for the phone when the viewer opens. On a
  /// window too narrow for both, the viewer gives up width, not the phone.
  static const double minStage = 360;

  /// Below this, the viewer is too narrow to read beside the phone, and
  /// opens over it instead.
  static const double minWidth = 280;

  /// Asset paths of the source files that hold marked pieces.
  final List<String> sources;

  @override
  State<HudCodeView> createState() => _HudCodeViewState();
}

class _HudCodeViewState extends State<HudCodeView> {
  late final Future<Map<String, String>> _files = _load();

  Future<Map<String, String>> _load() async => {
    for (final path in widget.sources) path: await rootBundle.loadString(path),
  };

  @override
  Widget build(BuildContext context) {
    var inspector = HudInspectorScope.of(context);
    var path = inspector.focus;
    var name = path?.split(' / ').last;
    var entry = inspector.tree.where((e) => e.path == path).firstOrNull;

    // Neutral dark gray, an editor's surface, so the code reads as its own
    // place next to the green rail. Aura has no semantic dark neutral; these
    // are its base grays.
    return Container(
      decoration: const BoxDecoration(
        color: AuraBaseColors.neutral950,
        border: Border(right: BorderSide(color: AuraBaseColors.neutral800)),
      ),
      child: FutureBuilder(
        future: _files,
        builder: (context, files) {
          var snippet = name == null || !files.hasData
              ? null
              : _Snippet.find(files.data!, name);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: AuraMotion.durationNormal,
                switchInCurve: HudMotion.flow,
                switchOutCurve: HudMotion.flow,
                child: _Header(
                  key: ValueKey(path),
                  name: name ?? '',
                  origin: entry?.origin.label,
                  where: snippet == null
                      ? null
                      : '${snippet.file.split('/').last} · line ${snippet.line}',
                  depth: entry?.depth ?? 0,
                  onClose: () => inspector.focus = null,
                ),
              ),
              Expanded(
                child: snippet == null
                    ? Center(
                        child: AuraText(
                          files.hasData
                              ? 'No source found for this piece'
                              : 'Loading the source…',
                          style: AuraTextStyles.labelSm,
                          color: AuraColors.textInverseSubtle,
                        ),
                      )
                    // A new piece replaces the old code with a quick
                    // cross-fade; its lines then ripple in.
                    : AnimatedSwitcher(
                        duration: AuraMotion.durationNormal,
                        switchInCurve: HudMotion.flow,
                        switchOutCurve: HudMotion.flow,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topLeft,
                          children: [...previous, ?current],
                        ),
                        child: _Code(
                          key: ValueKey(path),
                          snippet: snippet,
                          baseDepth: entry?.depth ?? 0,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    super.key,
    required this.name,
    required this.origin,
    required this.where,
    required this.depth,
    required this.onClose,
  });

  final String name;
  final String? origin;
  final String? where;
  final int depth;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AuraSpacing.space16,
      AuraSpacing.space12,
      AuraSpacing.space8,
      AuraSpacing.space12,
    ),
    decoration: const BoxDecoration(
      color: AuraBaseColors.neutral900,
      border: Border(bottom: BorderSide(color: AuraBaseColors.neutral800)),
    ),
    child: Row(
      children: [
        Container(
          width: AuraSpacing.space8,
          height: AuraSpacing.space8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: HudDepthColors.onDark(depth),
          ),
        ),
        const SizedBox(width: AuraSpacing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraText(
                name,
                style: AuraTextStyles.labelLgStrong,
                color: AuraColors.textInverse,
              ),
              AuraText(
                [?origin, ?where].join(' · '),
                style: AuraTextStyles.labelSmLight,
                color: AuraColors.textInverseSubtle,
              ),
            ],
          ),
        ),
        HudIconButton(
          icon: AuraIcons.close,
          semanticLabel: 'Close the code',
          onPressed: onClose,
        ),
      ],
    ),
  );
}

/// A piece's code: what its marker wraps, cut from the source file.
class _Snippet {
  const _Snippet({required this.file, required this.line, required this.code});

  final String file;

  /// The 1-based line the code starts on.
  final int line;
  final String code;

  static const String _marker = 'HudComponent(';

  /// Finds the first piece called [name] in [files] and cuts out its child.
  static _Snippet? find(Map<String, String> files, String name) {
    for (final MapEntry(key: file, value: src) in files.entries) {
      var at = src.indexOf("name: '$name'");
      if (at < 0) continue;
      var start = src.lastIndexOf(_marker, at);
      if (start < 0) continue;
      var end = _closing(src, start + _marker.length - 1);
      if (end < 0) continue;
      var child = src.indexOf('child:', at);
      if (child < 0 || child > end) continue;
      var from = child + 'child:'.length;
      var body = src.substring(from, end).trim();
      if (body.endsWith(',')) body = body.substring(0, body.length - 1);

      // Dedent by the indent of the line the child starts on.
      var lineStart = src.lastIndexOf('\n', child) + 1;
      var indent = child - lineStart;
      var lines = body.split('\n');
      var code = [
        lines.first,
        for (final l in lines.skip(1))
          l.length >= indent && l.substring(0, indent).trim().isEmpty
              ? l.substring(indent)
              : l.trimLeft(),
      ].join('\n');

      var line = '\n'.allMatches(src.substring(0, child)).length + 1;
      return _Snippet(file: file, line: line, code: code);
    }
    return null;
  }

  /// The index of the bracket that closes the one at [open], skipping
  /// strings; -1 if it never closes.
  static int _closing(String src, int open) {
    var depth = 0;
    String? quote;
    for (var i = open; i < src.length; i++) {
      var c = src[i];
      if (quote != null) {
        if (c == r'\') {
          i++;
        } else if (c == quote) {
          quote = null;
        }
        continue;
      }
      if (c == "'" || c == '"') {
        quote = c;
      } else if ('([{'.contains(c)) {
        depth++;
      } else if (')]}'.contains(c)) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }
}

/// The code, line-numbered, with rainbow brackets. Strings, keywords and
/// Aura names each get their own tone; everything else stays muted.
class _Code extends StatelessWidget {
  const _Code({required this.snippet, required this.baseDepth, super.key});

  final _Snippet snippet;

  /// The piece's depth, so its first bracket takes its own color and the
  /// code continues the rainbow from where the tree left off.
  final int baseDepth;

  static const Set<String> _keywords = {
    'const',
    'final',
    'var',
    'for',
    'in',
    'if',
    'else',
    'true',
    'false',
    'null',
    'return',
  };

  @override
  Widget build(BuildContext context) {
    var mono = GoogleFonts.jetBrainsMono(textStyle: AuraTextStyles.labelSm);
    var lines = snippet.code.split('\n');
    var depth = baseDepth;
    var rows = <Widget>[];
    for (final (i, line) in lines.indexed) {
      var (spans, next) = _highlight(line, depth, mono, dim: _isMarker(line));
      depth = next;
      rows.add(
        // Lines ripple in, top to bottom, each a beat after the last.
        HudReveal(
          index: i,
          step: HudReveal.lineStep,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AuraSpacing.space32,
                child: Text(
                  '${snippet.line + i}',
                  textAlign: TextAlign.right,
                  style: mono.copyWith(color: AuraBaseColors.neutral700),
                ),
              ),
              const SizedBox(width: AuraSpacing.space16),
              Text.rich(TextSpan(children: spans), softWrap: false),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AuraSpacing.space12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AuraSpacing.space16),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
      ),
    );
  }

  /// Whether [line] is the inspector's own marking rather than the piece's
  /// code. Those lines stay, so line numbers match the file, but recede.
  static bool _isMarker(String line) {
    var t = line.trimLeft();
    return t.contains('HudComponent(') ||
        t.startsWith('name: ') ||
        t.startsWith('origin: HudOrigin');
  }

  (List<InlineSpan>, int) _highlight(
    String line,
    int depth,
    TextStyle mono, {
    bool dim = false,
  }) {
    var spans = <InlineSpan>[];
    var i = 0;
    void add(String text, Color color, {bool strong = false}) => spans.add(
      TextSpan(
        text: text,
        style: mono.copyWith(
          color: dim ? AuraBaseColors.neutral700 : color,
          fontWeight: strong ? AuraTextStyles.labelMdStrong.fontWeight : null,
        ),
      ),
    );

    while (i < line.length) {
      var c = line[i];
      if ('([{'.contains(c)) {
        add(c, HudDepthColors.onDark(depth), strong: true);
        depth++;
        i++;
      } else if (')]}'.contains(c)) {
        depth = depth > 0 ? depth - 1 : 0;
        add(c, HudDepthColors.onDark(depth), strong: true);
        i++;
      } else if (c == "'" || c == '"') {
        var end = line.indexOf(c, i + 1);
        end = end < 0 ? line.length : end + 1;
        add(line.substring(i, end), AuraBaseColors.peach400);
        i = end;
      } else if (RegExp('[0-9]').hasMatch(c)) {
        var m = RegExp(r'[0-9.]+').matchAsPrefix(line, i)!;
        add(m[0]!, AuraBaseColors.emerald400);
        i = m.end;
      } else if (RegExp('[A-Za-z_\$]').hasMatch(c)) {
        var m = RegExp(r'[A-Za-z_$][A-Za-z0-9_]*').matchAsPrefix(line, i)!;
        var word = m[0]!;
        var named = line.startsWith(':', m.end);
        if (word.startsWith('Aura')) {
          // What the piece is built from: the point of the viewer.
          add(word, AuraBaseColors.teal400, strong: true);
        } else if (_keywords.contains(word)) {
          add(word, AuraBaseColors.violet200);
        } else if (word[0].toUpperCase() == word[0] && word[0] != r'$') {
          add(word, AuraBaseColors.teal400);
        } else if (named) {
          add(word, AuraBaseColors.sky200);
        } else {
          add(word, AuraBaseColors.neutral300);
        }
        i = m.end;
      } else {
        add(c, AuraBaseColors.neutral500);
        i++;
      }
    }
    return (spans, depth);
  }
}
