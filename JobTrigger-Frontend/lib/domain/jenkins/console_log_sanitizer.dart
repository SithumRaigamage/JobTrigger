/// Jenkins' raw console output — via `progressiveText`/`consoleText`,
/// what `LogChunk`/`BuildLogNotifier` stream in — isn't plain text. It
/// carries two kinds of terminal escape sequences a plain-text log viewer
/// must never render verbatim:
///
/// - **Console notes**: Jenkins encodes metadata for its own web UI (e.g.
///   the "started by user" link, replay/pipeline-step annotations) as
///   `ESC[8m<base64 payload>ESC[0m` — SGR code 8 ("conceal"), used here as
///   a carrier for a hidden payload only Jenkins' own JS decodes into a
///   clickable element. A plain terminal renders concealed text as
///   nothing; naively stripping only the escape *codes* and leaving the
///   payload text behind (as a generic ANSI-strip regex would) leaves
///   exactly the giant base64 blobs this was written to fix.
/// - **Standard ANSI SGR codes** (e.g. from the AnsiColor plugin) — not
///   currently rendered as color (`ConsoleLogViewer` is monochrome), so
///   these are stripped to their plain text rather than left as literal
///   escape bytes in the output.
///
/// Kept as a pure function (not inline in `ConsoleLogViewer`) so it's
/// unit-testable against real captured Jenkins output rather than only
/// exercised via a widget test.
String sanitizeConsoleLog(String raw) {
  return raw
      // Concealed console notes: drop the escape codes *and* the hidden
      // payload between them, non-greedy so back-to-back notes on the
      // same line don't swallow the text separating them.
      .replaceAll(RegExp('\x1B\\[8m.*?\x1B\\[0m'), '')
      // Any remaining OSC sequences (e.g. hyperlinks), terminated by BEL
      // or ST.
      .replaceAll(RegExp('\x1B\\][^\x07\x1B]*(\x07|\x1B\\\\)'), '')
      // Any remaining plain ANSI CSI sequences (color/formatting codes).
      .replaceAll(RegExp('\x1B\\[[0-9;]*[a-zA-Z]'), '');
}
