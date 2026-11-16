import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/console_decoder.dart';
import '../../../domain/jenkins/console_folds.dart';
import 'console_notifiers.dart';

/// Renders decoded console lines (US-JX-07): ANSI colors, optional
/// timestamps, search highlighting, and wrap / no-wrap. `ListView.builder`,
/// so only visible lines are ever built.
///
/// Auto-scrolls to the bottom on new output unless the user has scrolled
/// up (P5-11). [ConsoleLogViewerState.jumpToLine] scrolls to a line for
/// search and "jump to error". Without wrap every row is exactly one line
/// high, so the jump is exact. With wrap it jumps to an estimate, then
/// corrects once the row is built.
class ConsoleLogViewer extends StatefulWidget {
  const ConsoleLogViewer({
    super.key,
    required this.lines,
    required this.prefs,
    this.firstLineNumber = 0,
    this.timestamps = ConsoleTimestamps.none,
    this.query = '',
    this.currentMatchLine,
    this.onFollowChanged,
  });

  final List<ConsoleLine> lines;
  final ConsolePrefs prefs;

  /// Absolute number of `lines[0]`, for timestamp lookup when earlier
  /// lines were dropped.
  final int firstLineNumber;
  final ConsoleTimestamps timestamps;
  final String query;
  final int? currentMatchLine;

  /// Called when following the latest output turns on or off — off as
  /// soon as the user scrolls up or jumps to a line (P14-16: the screen's
  /// Follow toggle shows it).
  final ValueChanged<bool>? onFollowChanged;

  @override
  State<ConsoleLogViewer> createState() => ConsoleLogViewerState();
}

class ConsoleLogViewerState extends State<ConsoleLogViewer> {
  final _scrollController = ScrollController();
  final _horizontalController = ScrollController();
  bool _autoScroll = true;

  /// The row a jump is aiming for, keyed so a wrapped jump can be corrected
  /// once it's built.
  int? _jumpTarget;
  final _jumpKey = GlobalKey();

  /// Folds the user has opened, by their first line. A fold that isn't in
  /// here is collapsed, so a long noisy run starts out as one summary row.
  final _expandedFolds = <int>{};

  /// The rows as built last — lines, or a fold's summary row, in display
  /// order. Jumps and search go through this, because a line's row and its
  /// line index differ once anything is folded.
  List<_Row> _rows = const [];

  static const _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// Console text, and the dimmer gutters (line numbers, timestamps) —
  /// 5.6:1 on the console background, where `white38` was about 3:1.
  static const _text = AppColors.consoleText;
  static const _gutter = AppColors.consoleGutter;

  /// Whether new output scrolls into view.
  bool get following => _autoScroll;

  void _setFollowing(bool value) {
    if (value == _autoScroll) return;
    setState(() => _autoScroll = value);
    widget.onFollowChanged?.call(value);
  }

  /// Turns following back on and scrolls to the latest output.
  void follow() {
    setState(() => _jumpTarget = null);
    _setFollowing(true);
    _scrollToEnd();
  }

  TextStyle get _baseStyle => AppTypography.buildLog.copyWith(
    color: _text,
    fontSize: widget.prefs.fontSize,
    height: 1.35,
  );

  /// The real height of one rendered line in [_baseStyle], measured
  /// rather than derived from the font size (an estimate overshot a
  /// 2,000-line jump by 17 lines).
  double get _lineHeight => (TextPainter(
    text: TextSpan(text: 'M', style: _baseStyle),
    textDirection: TextDirection.ltr,
  )..layout()).height;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Opening straight onto a match (search restored from a previous visit)
    // still has to show the line rather than the fold that hides it.
    if (widget.currentMatchLine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealMatch(widget.currentMatchLine);
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 24;
    _setFollowing(atBottom);
  }

  @override
  void didUpdateWidget(covariant ConsoleLogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMatchLine != oldWidget.currentMatchLine) {
      _revealMatch(widget.currentMatchLine);
    }
    if (widget.lines.length != oldWidget.lines.length && _autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  /// Scrolls so [line] (an index into `lines`) is on screen. A line inside
  /// a collapsed fold opens that fold first, so search and "jump to first
  /// error" always land on real output.
  void jumpToLine(int line) {
    if (!_scrollController.hasClients) return;
    final index = _rowIndexForLine(line);
    if (index == null) return;
    final row = _rows[index];
    if (row.kind == _RowKind.foldHeader && !row.expanded) {
      // Opening puts the line `offset` rows below the fold's summary.
      final target = index + 1 + (line - row.line);
      setState(() {
        _expandedFolds.add(row.line);
        _jumpTarget = target;
      });
      _setFollowing(false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) _scrollToRow(target);
      });
      return;
    }
    _scrollToRow(index);
  }

  /// Scrolls row [index] of [_rows] into view.
  void _scrollToRow(int index) {
    if (!_scrollController.hasClients) return;
    setState(() => _jumpTarget = index);
    _setFollowing(false);
    final estimate = (index * _lineHeight - 120).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(estimate);
    if (widget.prefs.wrap) {
      // Wrapped rows vary in height: correct once the target row exists.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _jumpKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(context, alignment: 0.3);
        }
      });
    }
  }

  /// The row showing [line], or null if this log doesn't have that line.
  int? _rowIndexForLine(int line) {
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      if (row.kind == _RowKind.line) {
        if (row.line == line) return i;
      } else if (line >= row.line && line <= row.foldEnd!) {
        return i;
      }
    }
    return null;
  }

  /// Opens a fold that holds the current search match, so its highlight is
  /// on screen rather than hidden inside the summary.
  void _revealMatch(int? line) {
    if (line == null) return;
    final index = _rowIndexForLine(line);
    if (index == null) return;
    final row = _rows[index];
    if (row.kind != _RowKind.foldHeader || row.expanded) return;
    setState(() => _expandedFolds.add(row.line));
  }

  void _toggleFold(int firstLine) {
    setState(() {
      if (!_expandedFolds.remove(firstLine)) _expandedFolds.add(firstLine);
    });
  }

  /// Lines → rows: single lines as they are, a fold as one summary row, plus
  /// its lines underneath once the user opens it.
  List<_Row> _buildRows(List<ConsoleLine> lines) {
    final rows = <_Row>[];
    if (!widget.prefs.foldSections) {
      for (var i = 0; i < lines.length; i++) {
        rows.add(_Row.line(i));
      }
      return rows;
    }
    for (final section in foldConsole(lines)) {
      if (!section.isFold) {
        rows.add(_Row.line(section.firstLine));
        continue;
      }
      final expanded = _expandedFolds.contains(section.firstLine);
      rows.add(_Row.fold(section.firstLine, section.lastLine, expanded));
      if (expanded) {
        for (var i = section.firstLine; i <= section.lastLine; i++) {
          rows.add(_Row.line(i));
        }
      }
    }
    return rows;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    final rows = _rows = _buildRows(lines);
    final showTimestamps = widget.prefs.timestamps;
    final gutterChars = '${widget.firstLineNumber + lines.length}'.length;
    // Measured once per build, not per row: the face is monospaced.
    final gutterWidth = (TextPainter(
      text: TextSpan(text: '0' * (gutterChars + 1), style: _baseStyle),
      textDirection: TextDirection.ltr,
    )..layout()).width;
    final list = ListView.builder(
      controller: _scrollController,
      padding: _padding,
      itemExtent: widget.prefs.wrap ? null : _lineHeight,
      // Rows are cheap; a generous cache means a wrapped jump's estimate
      // still builds the target row, so `ensureVisible` can correct it.
      scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final child = row.kind == _RowKind.line
            ? _LineRow(
                line: lines[row.line],
                lineNumber: widget.firstLineNumber + row.line + 1,
                gutterChars: gutterChars,
                gutterWidth: gutterWidth,
                baseStyle: _baseStyle,
                wrap: widget.prefs.wrap,
                timestamp: showTimestamps
                    ? _timestampFor(
                        lines[row.line],
                        widget.firstLineNumber + row.line,
                      )
                    : null,
                showTimestampGutter: showTimestamps,
                query: widget.query,
                isCurrentMatch: row.line == widget.currentMatchLine,
              )
            : _FoldRow(
                firstLineNumber: widget.firstLineNumber + row.line + 1,
                count: row.lineCount,
                expanded: row.expanded,
                gutterChars: gutterChars,
                gutterWidth: gutterWidth,
                baseStyle: _baseStyle,
                onTap: () => _toggleFold(row.line),
              );
        return index == _jumpTarget
            ? KeyedSubtree(key: _jumpKey, child: child)
            : child;
      },
    );

    return Stack(
      children: [
        if (widget.prefs.wrap)
          list
        else
          LayoutBuilder(
            builder: (context, constraints) => Scrollbar(
              controller: _horizontalController,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _contentWidth(
                    constraints.maxWidth,
                    showTimestamps,
                    gutterChars,
                  ),
                  child: list,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The line's embedded Timestamper time (pipelines), in local time, else
  /// the one fetched from the Timestamper API (freestyle jobs).
  String? _timestampFor(ConsoleLine line, int absoluteLine) {
    final embedded = line.timestamp?.toLocal();
    if (embedded == null) return widget.timestamps.at(absoluteLine);
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(embedded.hour)}:${two(embedded.minute)}:${two(embedded.second)}';
  }

  /// Wide enough for the longest line in monospace, at least the viewport.
  double _contentWidth(double viewport, bool showTimestamps, int gutterChars) {
    final painter = TextPainter(
      text: TextSpan(text: 'M', style: _baseStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    var longest = 0;
    for (final line in widget.lines) {
      if (line.text.length > longest) longest = line.text.length;
    }
    final gutter =
        (showTimestamps ? 9 * painter.width + 8 : 0) +
        (gutterChars + 1) * painter.width;
    final width = longest * painter.width + gutter + _padding.horizontal;
    return width > viewport ? width : viewport;
  }
}

enum _RowKind { line, foldHeader }

/// One rendered row: a console line, or a fold's summary row (NR-01).
class _Row {
  const _Row.line(this.line)
    : kind = _RowKind.line,
      foldEnd = null,
      expanded = false;

  const _Row.fold(this.line, this.foldEnd, this.expanded)
    : kind = _RowKind.foldHeader;

  final _RowKind kind;

  /// The line index, or a fold's first line.
  final int line;

  /// A fold's last line, inclusive; null for a single line.
  final int? foldEnd;
  final bool expanded;

  int get lineCount => foldEnd == null ? 1 : foldEnd! - line + 1;
}

/// A collapsed run of similar lines, as one tappable row that opens it.
/// Exactly one line tall in no-wrap mode, so row heights stay uniform and
/// a jump's estimate stays exact.
class _FoldRow extends StatelessWidget {
  const _FoldRow({
    required this.firstLineNumber,
    required this.count,
    required this.expanded,
    required this.gutterChars,
    required this.gutterWidth,
    required this.baseStyle,
    required this.onTap,
  });

  final int firstLineNumber;
  final int count;
  final bool expanded;
  final int gutterChars;
  final double gutterWidth;
  final TextStyle baseStyle;
  final VoidCallback onTap;

  static const _gutter = ConsoleLogViewerState._gutter;

  @override
  Widget build(BuildContext context) {
    final style = baseStyle.copyWith(color: _gutter);
    final number = '$firstLineNumber'.padLeft(gutterChars);
    return Semantics(
      button: true,
      label: expanded
          ? 'Hide $count similar lines'
          : 'Show $count folded lines',
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ColoredBox(
          color: AppColors.consoleBar,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: gutterWidth),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      // Never taller than the line, so the row keeps the
                      // one-line height the jump estimate relies on.
                      size: baseStyle.fontSize ?? 12,
                      color: _gutter,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        expanded
                            ? 'Hide $count similar lines'
                            : '$count similar lines',
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: ExcludeSemantics(child: Text(number, style: style)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.lineNumber,
    required this.gutterChars,
    required this.gutterWidth,
    required this.baseStyle,
    required this.wrap,
    required this.timestamp,
    required this.showTimestampGutter,
    required this.query,
    required this.isCurrentMatch,
  });

  final ConsoleLine line;

  /// 1-based number of this line in the whole log.
  final int lineNumber;

  /// How many digits the widest line number has, so numbers right-align.
  final int gutterChars;

  /// The gutter's width, measured once by the viewer.
  final double gutterWidth;
  final TextStyle baseStyle;
  final bool wrap;
  final String? timestamp;
  final bool showTimestampGutter;
  final String query;
  final bool isCurrentMatch;

  /// A failing line's tint (`UI-UX/screens/15-build-log`).
  static const _errorTint = AppColors.consoleErrorLine;

  @override
  Widget build(BuildContext context) {
    final gutterStyle = baseStyle.copyWith(
      color: ConsoleLogViewerState._gutter,
    );
    final spans = <InlineSpan>[
      if (showTimestampGutter)
        TextSpan(
          text: '${(timestamp ?? '').padRight(8)}  ',
          style: gutterStyle,
        ),
      ...highlightConsoleSpans(
        line.spans,
        baseStyle,
        query,
        isCurrentMatch: isCurrentMatch,
      ),
      // An empty paragraph lays out taller than a line of text; a
      // zero-width space keeps a blank line the height of the others.
      // Copy, share and search read `line.text`, not these spans.
      if (line.text.isEmpty) const TextSpan(text: '\u200B'),
    ];
    final number = '$lineNumber'.padLeft(gutterChars);
    final row = Stack(
      children: [
        // The line comes first in the tree; the number is painted beside
        // it, decoration a screen reader skips.
        Padding(
          padding: EdgeInsets.only(left: gutterWidth),
          child: Text.rich(
            TextSpan(style: baseStyle, children: spans),
            softWrap: wrap,
            maxLines: wrap ? null : 1,
            overflow: wrap ? TextOverflow.clip : TextOverflow.visible,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: ExcludeSemantics(child: Text(number, style: gutterStyle)),
        ),
      ],
    );
    if (!isErrorLine(line.text)) return row;
    return ColoredBox(color: _errorTint, child: row);
  }
}

/// Converts console spans to Flutter spans, splitting out case-insensitive
/// matches of [query] with a highlight (the current match stands out).
List<TextSpan> highlightConsoleSpans(
  List<ConsoleSpan> spans,
  TextStyle base,
  String query, {
  bool isCurrentMatch = false,
}) {
  final needle = query.toLowerCase();
  final highlight = isCurrentMatch
      ? AppColors.consoleMatch
      : AppColors.consoleOtherMatch;
  final result = <TextSpan>[];
  for (final span in spans) {
    final style = consoleTextStyle(span.style, base);
    if (needle.isEmpty) {
      result.add(TextSpan(text: span.text, style: style));
      continue;
    }
    final lower = span.text.toLowerCase();
    var from = 0;
    while (true) {
      final hit = lower.indexOf(needle, from);
      if (hit == -1) break;
      if (hit > from) {
        result.add(
          TextSpan(text: span.text.substring(from, hit), style: style),
        );
      }
      result.add(
        TextSpan(
          text: span.text.substring(hit, hit + needle.length),
          style: style.copyWith(
            backgroundColor: highlight,
            color: isCurrentMatch ? Colors.black : style.color,
          ),
        ),
      );
      from = hit + needle.length;
    }
    if (from < span.text.length) {
      result.add(TextSpan(text: span.text.substring(from), style: style));
    }
  }
  return result;
}

/// ANSI style → Flutter text style on the always-dark console.
TextStyle consoleTextStyle(ConsoleStyle style, TextStyle base) {
  var foreground = style.foreground == null
      ? base.color
      : consoleColor(style.foreground!);
  if (style.dim && foreground != null) {
    foreground = foreground.withValues(alpha: 0.6);
  }
  return base.copyWith(
    color: foreground,
    backgroundColor: style.background == null
        ? null
        : consoleColor(style.background!),
    fontWeight: style.bold ? FontWeight.w700 : null,
    fontStyle: style.italic ? FontStyle.italic : null,
    decoration: style.underline ? TextDecoration.underline : null,
  );
}

/// xterm-256 and truecolor to [Color].
Color consoleColor(ConsoleColor color) {
  final rgb = color.rgb;
  if (rgb != null) return Color(0xFF000000 | rgb);
  final index = color.index!;
  if (index < 16) return AppColors.consoleAnsi[index];
  if (index < 232) {
    const levels = [0, 95, 135, 175, 215, 255];
    final cube = index - 16;
    return Color.fromARGB(
      255,
      levels[cube ~/ 36],
      levels[(cube ~/ 6) % 6],
      levels[cube % 6],
    );
  }
  final grey = 8 + (index - 232) * 10;
  return Color.fromARGB(255, grey, grey, grey);
}
