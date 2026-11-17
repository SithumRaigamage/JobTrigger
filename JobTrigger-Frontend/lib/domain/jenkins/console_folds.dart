/// Folding of noisy console sections (NR-01, `docs/implemented/improvement-plan.md`
/// "Next release"). Jenkins logs repeat the same line with a different
/// number for hundreds of rows — download progress, retry loops, "test n
/// passed", "Waiting for next available executor". Those runs cost a lot of
/// scrolling and carry almost no information, so the console shows them as
/// one summary row that the user can open.
///
/// Plain Dart with no Flutter imports: the grouping rule is testable on its
/// own, and the viewer only renders the sections it returns.
library;

import 'console_decoder.dart';

/// How many near-identical lines in a row make a fold. Three repeated lines
/// are usually meaningful (a retry with context); four or more are noise.
const defaultFoldMinRun = 4;

/// One renderable piece of the console, in order: either a single line or a
/// run of lines that can collapse into one summary row.
///
/// Indices point into the same `List<ConsoleLine>` the viewer renders, so a
/// fold never changes line numbers, search indices or the error marker.
class ConsoleSection {
  const ConsoleSection.line(int index) : firstLine = index, lastLine = index;

  const ConsoleSection.fold(this.firstLine, this.lastLine);

  /// First line index, inclusive.
  final int firstLine;

  /// Last line index, inclusive. Equal to [firstLine] for a single line.
  final int lastLine;

  bool get isFold => lastLine > firstLine;

  int get lineCount => lastLine - firstLine + 1;
}

/// A line's shape, for deciding whether two lines are "the same" noise:
/// lower-cased, hex ids and every number replaced by `#`, whitespace
/// collapsed. `Downloading 3/50` and `Downloading 4/50` share one
/// signature; `Downloading 3/50` and `Build failed` do not.
String consoleLineSignature(String text) {
  var signature = text.toLowerCase();
  signature = signature.replaceAll(RegExp(r'0x[0-9a-f]+'), '#');
  signature = signature.replaceAll(RegExp(r'\b[0-9a-f]{7,}\b'), '#');
  // Decimals first, so `1.4s` and `12s` both become `#s`.
  signature = signature.replaceAll(RegExp(r'\d+(?:[.,]\d+)+'), '#');
  signature = signature.replaceAll(RegExp(r'\d+'), '#');
  signature = signature.replaceAll(RegExp(r'\s+'), ' ');
  return signature.trim();
}

/// Groups [lines] into sections, folding runs of [minRun] or more lines
/// that share a signature.
///
/// A line that looks like a failure ([isErrorLine]) is never folded and
/// always breaks a run: "jump to first error" must land on real output, and
/// a repeated stack trace is exactly what someone needs to read.
List<ConsoleSection> foldConsole(
  List<ConsoleLine> lines, {
  int minRun = defaultFoldMinRun,
}) {
  final sections = <ConsoleSection>[];
  var start = 0;
  String? signature;

  void flush(int end) {
    if (end <= start) return;
    final count = end - start;
    if (signature != null && count >= minRun) {
      sections.add(ConsoleSection.fold(start, end - 1));
    } else {
      for (var i = start; i < end; i++) {
        sections.add(ConsoleSection.line(i));
      }
    }
    start = end;
    signature = null;
  }

  for (var i = 0; i < lines.length; i++) {
    if (isErrorLine(lines[i].text)) {
      flush(i);
      sections.add(ConsoleSection.line(i));
      start = i + 1;
      signature = null;
      continue;
    }
    final next = consoleLineSignature(lines[i].text);
    if (signature == null) {
      signature = next;
      start = i;
    } else if (next != signature) {
      flush(i);
      signature = next;
      start = i;
    }
  }
  flush(lines.length);
  return sections;
}

/// The index of the section holding [line], or null if there is none.
int? sectionIndexForLine(List<ConsoleSection> sections, int line) {
  for (var i = 0; i < sections.length; i++) {
    final section = sections[i];
    if (line >= section.firstLine && line <= section.lastLine) return i;
  }
  return null;
}
