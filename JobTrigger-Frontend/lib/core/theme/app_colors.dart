import 'package:flutter/material.dart';

/// The raw palette of the P14 redesign (`UI-UX/README.md`, Design tokens).
///
/// Widgets don't read these directly: they read the per-theme set from
/// [AppTokens] (`app_tokens.dart`), which picks the dark or light value of
/// every token below. What lives here is the measured palette and the
/// mappings from Jenkins' own vocabularies (build `result`, job ball
/// `color`, pipeline stage `status`) to a [StatusTone].
///
/// Every pairing that carries meaning is measured in
/// `test/core/theme/app_colors_test.dart`: 4.5:1 for text (WCAG 1.4.3),
/// 3:1 for dots and icons (WCAG 1.4.11). A status is never conveyed by
/// colour alone — it always has a text label too (NFR-A11Y-03).
class AppColors {
  const AppColors._();

  /// The one app-wide accent (P14 decision 4): primary buttons, the
  /// selected tab, switches. White text on it is 5.2:1. A CI tool's brand
  /// colour no longer re-tints the app — it appears only on that tool's
  /// own logo tile — so Jenkins red can't be mistaken for "failed".
  static const accent = Color(0xFF2563EB);

  // The logo (Phase 16, Concept B; UI-UX/brand/mark.svg). Fixed in both
  // themes and never used for UI: the theme accent stays [accent].
  static const logoTile = Color(0xFF0F172A);
  static const logoStage = Color(0xFF93C5FD);
  static const logoConnector = Color(0xFF60A5FA);
  static const logoRun = Color(0xFF4ADE80);

  // Dark surfaces, back to front.
  static const backgroundDark = Color(0xFF0B1120);
  static const chromeDark = Color(0xFF0F172A); // nav bar, sheets' backdrop
  static const cardDark = Color(0xFF111A2B);
  static const cardBorderDark = Color(0xFF1F2A3D);
  static const raisedDark = Color(0xFF1E293B); // secondary buttons, chips
  static const consoleDark = Color(0xFF060A14);

  // The build log is drawn on [consoleDark] in both themes (AUD-30: kept
  // here, not as literals in the widgets, so their contrast is tested).
  static const consoleText = textSecondaryDark;

  /// Line numbers: 5.6:1 on [consoleDark].
  static const consoleGutter = Color(0xFF8291A8);

  /// Behind a line that reads as an error.
  static const consoleErrorLine = Color(0xFF2A1216);

  /// The log screen's banners and bars.
  static const consoleBar = raisedDark;

  /// The current search match, and the other matches.
  static const consoleMatch = Color(0xFFFFB300);
  static const consoleOtherMatch = Color(0x66FFB300);

  /// The 16 standard terminal colours, tuned for legibility on black.
  /// Jenkins output picks them, so a few (black on black) can't be legible.
  static const consoleAnsi = [
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

  /// The light theme's card shadow: slate 900 at 6%.
  static const shadowLight = Color(0x0F0F172A);

  static const textDark = Color(0xFFF1F5F9);
  static const textSecondaryDark = Color(0xFFCBD5E1);

  /// The lowest text shade in dark mode: 6.6:1 on [cardDark].
  static const textMutedDark = Color(0xFF94A3B8);

  // Light surfaces.
  static const backgroundLight = Color(0xFFF8FAFC);
  static const chromeLight = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardBorderLight = Color(0xFFE2E8F0);
  static const raisedLight = Color(0xFFF1F5F9);

  static const textLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF334155);

  /// The lowest text shade in light mode: 7.6:1 on [cardLight].
  static const textMutedLight = Color(0xFF475569);

  /// Each status as text, tint and dot, per theme. Dark mode draws pale
  /// text on a deep tint; light mode draws 700/800 text on a pale tint.
  static const successDark = StatusColors(
    foreground: Color(0xFF86EFAC),
    background: Color(0xFF0F2E1F),
    dot: Color(0xFF4ADE80),
  );
  static const failureDark = StatusColors(
    foreground: Color(0xFFFCA5A5),
    background: Color(0xFF3A1418),
    dot: Color(0xFFF87171),
  );
  static const unstableDark = StatusColors(
    foreground: Color(0xFFFDBA74),
    background: Color(0xFF3A2210),
    dot: Color(0xFFFB923C),
  );
  static const runningDark = StatusColors(
    foreground: Color(0xFF93C5FD),
    background: Color(0xFF10284A),
    dot: Color(0xFF60A5FA),
  );
  static const pausedDark = StatusColors(
    foreground: Color(0xFFFCD34D),
    background: Color(0xFF3A2E0B),
    dot: Color(0xFFFBBF24),
  );
  static const neutralDark = StatusColors(
    foreground: Color(0xFFCBD5E1),
    background: Color(0xFF1E293B),
    dot: Color(0xFF94A3B8),
  );

  static const successLight = StatusColors(
    foreground: Color(0xFF15803D),
    background: Color(0xFFDCFCE7),
    dot: Color(0xFF16A34A),
  );
  static const failureLight = StatusColors(
    foreground: Color(0xFFB91C1C),
    background: Color(0xFFFEE2E2),
    dot: Color(0xFFDC2626),
  );
  static const unstableLight = StatusColors(
    foreground: Color(0xFFC2410C),
    background: Color(0xFFFFEDD5),
    dot: Color(0xFFEA580C),
  );
  static const runningLight = StatusColors(
    foreground: Color(0xFF1D4ED8),
    background: Color(0xFFDBEAFE),
    dot: Color(0xFF2563EB),
  );
  static const pausedLight = StatusColors(
    foreground: Color(0xFF92400E),
    background: Color(0xFFFEF3C7),
    dot: Color(0xFFD97706),
  );
  static const neutralLight = StatusColors(
    foreground: Color(0xFF334155),
    background: Color(0xFFF1F5F9),
    dot: Color(0xFF64748B),
  );

  /// Jenkins build `result` → tone. `null` means still building.
  static StatusTone toneForBuildResult(String? result) =>
      switch (result?.toUpperCase()) {
        'SUCCESS' => StatusTone.success,
        'FAILURE' => StatusTone.failure,
        'UNSTABLE' => StatusTone.unstable,
        null => StatusTone.running,
        _ => StatusTone.neutral, // ABORTED, NOT_BUILT, anything unrecognised.
      };

  /// Pipeline stage/step `status` → tone. Jenkins uses a different
  /// vocabulary here (`FAILED`, `IN_PROGRESS`, …) than for a build result.
  static StatusTone toneForStageStatus(String status) =>
      switch (status.toUpperCase()) {
        'SUCCESS' => StatusTone.success,
        'FAILED' => StatusTone.failure,
        'UNSTABLE' => StatusTone.unstable,
        'IN_PROGRESS' => StatusTone.running,
        'PAUSED_PENDING_INPUT' => StatusTone.paused,
        _ => StatusTone.neutral, // NOT_EXECUTED, ABORTED, unrecognised.
      };

  /// From `StatusIndicator.swift` — Jenkins' job "ball color" (`color`
  /// field: `blue`/`red`/`yellow`/`notbuilt`/`disabled`/`aborted`, each
  /// optionally suffixed `_anime` while building) → tone. Jenkins' "blue"
  /// means *success* (a historical quirk), so it maps to the success tone.
  static StatusTone toneForJobColor(String? jenkinsColor) {
    final clean = jenkinsColor?.toLowerCase().replaceAll('_anime', '') ?? '';
    return switch (clean) {
      'blue' => StatusTone.success,
      'red' => StatusTone.failure,
      'yellow' => StatusTone.unstable,
      _ => StatusTone.neutral,
    };
  }

  /// The `_anime` suffix (e.g. `blue_anime`) means the job is currently
  /// building — `StatusIndicator` pulses while true.
  static bool isJobColorAnimating(String? jenkinsColor) =>
      jenkinsColor?.toLowerCase().contains('_anime') ?? false;

  /// P6-05: screen-reader label for [StatusIndicator] — the ball color
  /// alone conveys nothing to a non-visual user. Mirrors [toneForJobColor],
  /// plus the `_anime` "building" state.
  static String describeJobColor(String? jenkinsColor) {
    final clean = jenkinsColor?.toLowerCase().replaceAll('_anime', '') ?? '';
    final base = switch (clean) {
      'blue' => 'Success',
      'red' => 'Failed',
      'yellow' => 'Unstable',
      'disabled' => 'Disabled',
      'notbuilt' => 'Not built',
      'aborted' => 'Aborted',
      _ => 'Unknown status',
    };
    return isJobColorAnimating(jenkinsColor) ? '$base, building' : base;
  }

  /// From `Tools/ToolSelection/CITool.swift`'s per-tool `accentColor`.
  /// Drawn only on the tool's own logo tile (P14 decision 4).
  static const ciToolJenkins = Color(0xFFD12E2E);
  static const ciToolGithubActions = Color(0xFF212121);
  static const ciToolGitlab = Color(0xFFE65929);
  static const ciToolSonarqube = Color(0xFF4F99ED);
  static const ciToolCircleci = Color(0xFF17A694);
}

/// The kinds of status the app shows. Each has a text label wherever it
/// appears; the colour is the second signal.
enum StatusTone { success, failure, unstable, running, paused, neutral }

/// One status's three colours in one theme: [foreground] for its text and
/// icons, [background] for its tinted pill or tile, [dot] for a bare
/// status dot or bar on a card.
@immutable
class StatusColors {
  const StatusColors({
    required this.foreground,
    required this.background,
    required this.dot,
  });

  final Color foreground;
  final Color background;
  final Color dot;

  static StatusColors lerp(StatusColors a, StatusColors b, double t) =>
      StatusColors(
        foreground: Color.lerp(a.foreground, b.foreground, t)!,
        background: Color.lerp(a.background, b.background, t)!,
        dot: Color.lerp(a.dot, b.dot, t)!,
      );
}
