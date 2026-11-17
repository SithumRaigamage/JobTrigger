/// Incremental decoding of Jenkins console output into styled lines
/// (US-JX-07). Replaces re-sanitizing and re-splitting the *whole* log on
/// every poll and rebuild, which was O(n²) (AUD-12).
///
/// Each progressive-text chunk is decoded exactly once, and state carries
/// across chunk boundaries (AUD-34):
/// - the unfinished last line,
/// - an escape sequence cut off mid-way,
/// - the active SGR style, which terminals keep across lines,
/// - an open Jenkins console note (`ESC[8m…ESC[0m`), whose hidden base64
///   payload is dropped rather than shown.
///
/// `\r\n` is a normal line end. A bare `\r` (progress bars) returns to the
/// start of the line, so only what follows it is kept.
library;

/// One of the 256 xterm palette colors, or a 24-bit RGB color.
class ConsoleColor {
  const ConsoleColor.indexed(this.index) : rgb = null;
  const ConsoleColor.rgb(int value) : rgb = value, index = null;

  /// 0–15 are the standard and bright colors; 16–255 the xterm cube and
  /// greys. Rendering maps these to the console palette.
  final int? index;

  /// `0xRRGGBB`.
  final int? rgb;

  @override
  bool operator ==(Object other) =>
      other is ConsoleColor && other.index == index && other.rgb == rgb;

  @override
  int get hashCode => Object.hash(index, rgb);
}

/// SGR attributes for a run of text.
class ConsoleStyle {
  const ConsoleStyle({
    this.foreground,
    this.background,
    this.bold = false,
    this.dim = false,
    this.italic = false,
    this.underline = false,
  });

  static const plain = ConsoleStyle();

  final ConsoleColor? foreground;
  final ConsoleColor? background;
  final bool bold;
  final bool dim;
  final bool italic;
  final bool underline;

  ConsoleStyle copyWith({
    ConsoleColor? foreground,
    ConsoleColor? background,
    bool clearForeground = false,
    bool clearBackground = false,
    bool? bold,
    bool? dim,
    bool? italic,
    bool? underline,
  }) => ConsoleStyle(
    foreground: clearForeground ? null : (foreground ?? this.foreground),
    background: clearBackground ? null : (background ?? this.background),
    bold: bold ?? this.bold,
    dim: dim ?? this.dim,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
  );

  @override
  bool operator ==(Object other) =>
      other is ConsoleStyle &&
      other.foreground == foreground &&
      other.background == background &&
      other.bold == bold &&
      other.dim == dim &&
      other.italic == italic &&
      other.underline == underline;

  @override
  int get hashCode =>
      Object.hash(foreground, background, bold, dim, italic, underline);
}

/// A run of text in one style.
class ConsoleSpan {
  const ConsoleSpan(this.text, [this.style = ConsoleStyle.plain]);

  final String text;
  final ConsoleStyle style;
}

/// One decoded line: styled spans plus its plain text, used for search,
/// copy, and error detection.
class ConsoleLine {
  ConsoleLine(this.spans, {this.timestamp})
    : text = spans.map((span) => span.text).join();

  /// Builds a line, lifting a leading Timestamper prefix into [timestamp].
  ///
  /// Current Timestamper writes `[2026-09-30T05:33:00.175Z] ` at the start
  /// of every pipeline log line, in the raw log itself, and Jenkins' web UI
  /// reformats it in JavaScript (verified on the fixture). Left in, every
  /// line would start with 26 characters of ISO noise. It's stripped here
  /// and shown only when the user turns timestamps on.
  factory ConsoleLine.fromSpans(List<ConsoleSpan> spans) {
    final first = spans.isEmpty ? null : spans.first;
    final match = first == null
        ? null
        : _timestampPrefix.matchAsPrefix(first.text);
    if (first == null || match == null) return ConsoleLine(spans);
    final rest = first.text.substring(match.end);
    return ConsoleLine([
      if (rest.isNotEmpty) ConsoleSpan(rest, first.style),
      ...spans.skip(1),
    ], timestamp: DateTime.tryParse(match.group(1)!));
  }

  static final _timestampPrefix = RegExp(
    r'\[(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z)\] ',
  );

  final List<ConsoleSpan> spans;
  final String text;

  /// When the line was written, if Timestamper embedded it (UTC).
  final DateTime? timestamp;
}

class ConsoleDecoder {
  static const _esc = '\x1B';

  ConsoleStyle _style = ConsoleStyle.plain;

  /// Undecoded input held back because it ends mid escape sequence.
  String _pendingEscape = '';

  /// Spans of the current, not-yet-terminated line.
  final List<ConsoleSpan> _lineSpans = [];
  final StringBuffer _text = StringBuffer();
  ConsoleStyle _textStyle = ConsoleStyle.plain;

  /// Inside a Jenkins console note (`ESC[8m` … `ESC[0m`): text is hidden.
  bool _inNote = false;

  /// Decodes [chunk] and returns the lines it completed. The unfinished
  /// last line stays pending; see [pendingLine].
  List<ConsoleLine> addChunk(String chunk) {
    final input = _pendingEscape + chunk;
    _pendingEscape = '';
    final completed = <ConsoleLine>[];
    var i = 0;
    while (i < input.length) {
      final char = input[i];
      if (char == _esc) {
        final consumed = _consumeEscape(input, i);
        if (consumed == null) {
          // Cut off mid-sequence: finish it with the next chunk.
          _pendingEscape = input.substring(i);
          break;
        }
        i = consumed;
        continue;
      }
      if (char == '\n') {
        completed.add(_endLine());
        i++;
        continue;
      }
      if (char == '\r') {
        final next = i + 1 < input.length ? input[i + 1] : null;
        if (next == '\n') {
          i++; // `\r\n`: let the `\n` end the line.
          continue;
        }
        if (next == null) {
          // Could be the first half of a `\r\n` split across chunks.
          _pendingEscape = '\r';
          break;
        }
        // Bare carriage return: overwrite from the line start.
        _flushText();
        _lineSpans.clear();
        i++;
        continue;
      }
      if (!_inNote) _appendChar(char);
      i++;
    }
    return completed;
  }

  /// The current unfinished line, or null if there is none — shown as the
  /// live last line while a build is still writing it.
  ConsoleLine? get pendingLine {
    if (_lineSpans.isEmpty && _text.isEmpty) return null;
    return ConsoleLine.fromSpans([
      ..._lineSpans,
      if (_text.isNotEmpty) ConsoleSpan(_text.toString(), _textStyle),
    ]);
  }

  void _appendChar(String char) {
    if (_text.isNotEmpty && _textStyle != _style) _flushText();
    if (_text.isEmpty) _textStyle = _style;
    _text.write(char);
  }

  void _flushText() {
    if (_text.isEmpty) return;
    _lineSpans.add(ConsoleSpan(_text.toString(), _textStyle));
    _text.clear();
  }

  ConsoleLine _endLine() {
    _flushText();
    final line = ConsoleLine.fromSpans(List.of(_lineSpans));
    _lineSpans.clear();
    return line;
  }

  /// Parses the escape sequence at [start]. Returns the index just past it,
  /// or null if [input] ends before the sequence does.
  int? _consumeEscape(String input, int start) {
    if (start + 1 >= input.length) return null;
    final kind = input[start + 1];
    if (kind == '[') {
      // CSI: parameters, then one final byte in @–~.
      var end = start + 2;
      while (end < input.length) {
        final code = input.codeUnitAt(end);
        if (code >= 0x40 && code <= 0x7E) break;
        end++;
      }
      if (end >= input.length) return null;
      if (input[end] == 'm') _applySgr(input.substring(start + 2, end));
      return end + 1;
    }
    if (kind == ']') {
      // OSC (e.g. hyperlinks): ends at BEL or ST (ESC \). Dropped.
      var end = start + 2;
      while (end < input.length) {
        if (input[end] == '\x07') return end + 1;
        if (input[end] == _esc) {
          if (end + 1 >= input.length) return null;
          if (input[end + 1] == r'\') return end + 2;
        }
        end++;
      }
      return null;
    }
    // Any other two-character escape: drop it.
    return start + 2;
  }

  void _applySgr(String params) {
    final codes = params.isEmpty
        ? const [0]
        : params.split(';').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < codes.length; i++) {
      final code = codes[i];
      switch (code) {
        case 0:
          // Also closes a console note: its payload ends at ESC[0m.
          _inNote = false;
          _style = ConsoleStyle.plain;
        case 1:
          _style = _style.copyWith(bold: true);
        case 2:
          _style = _style.copyWith(dim: true);
        case 3:
          _style = _style.copyWith(italic: true);
        case 4:
          _style = _style.copyWith(underline: true);
        case 8:
          // "Conceal": Jenkins wraps console-note payloads in it.
          _inNote = true;
        case 22:
          _style = _style.copyWith(bold: false, dim: false);
        case 23:
          _style = _style.copyWith(italic: false);
        case 24:
          _style = _style.copyWith(underline: false);
        case 28:
          _inNote = false;
        case >= 30 && <= 37:
          _style = _style.copyWith(foreground: ConsoleColor.indexed(code - 30));
        case 39:
          _style = _style.copyWith(clearForeground: true);
        case >= 40 && <= 47:
          _style = _style.copyWith(background: ConsoleColor.indexed(code - 40));
        case 49:
          _style = _style.copyWith(clearBackground: true);
        case >= 90 && <= 97:
          _style = _style.copyWith(
            foreground: ConsoleColor.indexed(code - 90 + 8),
          );
        case >= 100 && <= 107:
          _style = _style.copyWith(
            background: ConsoleColor.indexed(code - 100 + 8),
          );
        case 38 || 48:
          final (color, used) = _extendedColor(codes, i + 1);
          if (color != null) {
            _style = code == 38
                ? _style.copyWith(foreground: color)
                : _style.copyWith(background: color);
          }
          i += used;
      }
    }
  }

  /// `5;n` (256-color) or `2;r;g;b` (truecolor) after a 38/48.
  (ConsoleColor?, int) _extendedColor(List<int> codes, int at) {
    if (at >= codes.length) return (null, 0);
    if (codes[at] == 5 && at + 1 < codes.length) {
      return (ConsoleColor.indexed(codes[at + 1].clamp(0, 255)), 2);
    }
    if (codes[at] == 2 && at + 3 < codes.length) {
      final r = codes[at + 1].clamp(0, 255);
      final g = codes[at + 2].clamp(0, 255);
      final b = codes[at + 3].clamp(0, 255);
      return (ConsoleColor.rgb((r << 16) | (g << 8) | b), 4);
    }
    return (null, 1);
  }
}

/// A line that marks where a build went wrong, for "jump to first error"
/// (US-JX-07).
final _errorPattern = RegExp(
  r'\b(ERROR|FATAL|FAILURE|BUILD FAILED|Exception)\b',
);

bool isErrorLine(String text) => _errorPattern.hasMatch(text);

/// Indices of [lines] whose plain text contains [query], case-insensitive.
List<int> searchLines(List<ConsoleLine> lines, String query) {
  if (query.isEmpty) return const [];
  final needle = query.toLowerCase();
  return [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].text.toLowerCase().contains(needle)) i,
  ];
}
