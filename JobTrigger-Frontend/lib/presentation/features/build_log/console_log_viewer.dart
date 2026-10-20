import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../../core/theme/app_typography.dart';
import '../../../domain/jenkins/console_decoder.dart';
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
  });

  final List<ConsoleLine> lines;
  final ConsolePrefs prefs;

  /// Absolute number of `lines[0]`, for timestamp lookup when earlier
  /// lines were dropped.
  final int firstLineNumber;
  final ConsoleTimestamps timestamps;
  final String query;
  final int? currentMatchLine;

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

  static const _padding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  TextStyle get _baseStyle => AppTypography.buildLog.copyWith(
    color: Colors.white,
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
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 24;
    if (atBottom != _autoScroll) setState(() => _autoScroll = atBottom);
  }

  @override
  void didUpdateWidget(covariant ConsoleLogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length != oldWidget.lines.length && _autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  /// Scrolls so [line] (an index into `lines`) is on screen.
  void jumpToLine(int line) {
    if (!_scrollController.hasClients) return;
    setState(() {
      _autoScroll = false;
      _jumpTarget = line;
    });
    final estimate = (line * _lineHeight - 120).clamp(
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

  @override
  void dispose() {
    _scrollController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    final showTimestamps = widget.prefs.timestamps;
    final list = ListView.builder(
      controller: _scrollController,
      padding: _padding,
      itemExtent: widget.prefs.wrap ? null : _lineHeight,
      // Rows are cheap; a generous cache means a wrapped jump's estimate
      // still builds the target row, so `ensureVisible` can correct it.
      scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final row = _LineRow(
          line: lines[index],
          baseStyle: _baseStyle,
          wrap: widget.prefs.wrap,
          timestamp: showTimestamps
              ? _timestampFor(lines[index], widget.firstLineNumber + index)
              : null,
          showTimestampGutter: showTimestamps,
          query: widget.query,
          isCurrentMatch: index == widget.currentMatchLine,
        );
        return index == _jumpTarget
            ? KeyedSubtree(key: _jumpKey, child: row)
            : row;
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
                  width: _contentWidth(constraints.maxWidth, showTimestamps),
                  child: list,
                ),
              ),
            ),
          ),
        if (!_autoScroll)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              tooltip: 'Jump to latest output',
              onPressed: () {
                setState(() {
                  _autoScroll = true;
                  _jumpTarget = null;
                });
                _scrollToEnd();
              },
              child: const Icon(Icons.arrow_downward),
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
  double _contentWidth(double viewport, bool showTimestamps) {
    final painter = TextPainter(
      text: TextSpan(text: 'M', style: _baseStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    var longest = 0;
    for (final line in widget.lines) {
      if (line.text.length > longest) longest = line.text.length;
    }
    final gutter = showTimestamps ? 9 * painter.width + 8 : 0;
    final width = longest * painter.width + gutter + _padding.horizontal;
    return width > viewport ? width : viewport;
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.baseStyle,
    required this.wrap,
    required this.timestamp,
    required this.showTimestampGutter,
    required this.query,
    required this.isCurrentMatch,
  });

  final ConsoleLine line;
  final TextStyle baseStyle;
  final bool wrap;
  final String? timestamp;
  final bool showTimestampGutter;
  final String query;
  final bool isCurrentMatch;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[
      if (showTimestampGutter)
        TextSpan(
          text: '${(timestamp ?? '').padRight(8)}  ',
          style: baseStyle.copyWith(color: Colors.white38),
        ),
      ...highlightConsoleSpans(
        line.spans,
        baseStyle,
        query,
        isCurrentMatch: isCurrentMatch,
      ),
    ];
    return Text.rich(
      TextSpan(children: spans),
      softWrap: wrap,
      maxLines: wrap ? null : 1,
      overflow: wrap ? TextOverflow.clip : TextOverflow.visible,
    );
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
      ? const Color(0xFFFFB300)
      : const Color(0x66FFB300);
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

/// The 16 standard colors, tuned for legibility on black.
const _standardColors = [
  Color(0xFF000000),
  Color(0xFFEF5350),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
  Color(0xFF42A5F5),
  Color(0xFFAB47BC),
  Color(0xFF26C6DA),
  Color(0xFFE0E0E0),
  Color(0xFF757575),
  Color(0xFFFF8A80),
  Color(0xFFB9F6CA),
  Color(0xFFFFFF8D),
  Color(0xFF82B1FF),
  Color(0xFFEA80FC),
  Color(0xFF84FFFF),
  Color(0xFFFFFFFF),
];

/// xterm-256 and truecolor to [Color].
Color consoleColor(ConsoleColor color) {
  final rgb = color.rgb;
  if (rgb != null) return Color(0xFF000000 | rgb);
  final index = color.index!;
  if (index < 16) return _standardColors[index];
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
