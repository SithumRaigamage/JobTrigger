import 'package:flutter/material.dart';

/// Colors ported 1:1 from the SwiftUI app. Note there was no custom brand
/// palette to port wholesale — `Shared/Navigation/AppTheme.swift` only held
/// the light/system/dark mode enum, and `AccentColor.colorset` was never
/// filled in; the app relied on iOS system semantic colors everywhere
/// (`.blue`, `.secondary`, `UIColor.systemBackground`, etc.), which Material
/// 3's `ColorScheme.fromSeed` covers in `app_theme.dart`. The two things
/// that *were* consistently color-coded and worth preserving exactly are
/// below.
class AppColors {
  const AppColors._();

  /// From `JobDetailView.statusColor`/`HistoryView` — Jenkins build result
  /// → color. `building`/unrecognized results fall back to `aborted`'s gray,
  /// matching the old app's `default: return .gray` (there was no distinct
  /// "in progress" color).
  static const buildSuccess = Colors.green;
  static const buildFailure = Colors.red;
  static const buildAborted = Colors.grey;
  static const buildUnstable = Colors.orange;

  static Color forBuildResult(String? result) => switch (result
      ?.toUpperCase()) {
    'SUCCESS' => buildSuccess,
    'FAILURE' => buildFailure,
    'UNSTABLE' => buildUnstable,
    _ => buildAborted, // ABORTED, building (null), and anything unrecognized.
  };

  /// From `StatusIndicator.swift` — Jenkins' job "ball color" (`color`
  /// field: `blue`/`red`/`yellow`/`notbuilt`/`disabled`/`aborted`, each
  /// optionally suffixed `_anime` while building) → color. Distinct from
  /// [forBuildResult] above: this maps the job-tree list's `color` field,
  /// not a build's `result` string. Note Jenkins' "blue" ball color means
  /// *success* (a historical quirk) — the old app deliberately remaps it to
  /// green so it reads as success to users, not literally blue.
  static const jobColorBlue = Colors.green;
  static const jobColorRed = Colors.red;
  static const jobColorYellow = Colors.orange;
  static const jobColorGray =
      Colors.grey; // aborted, disabled, notbuilt, unrecognized

  /// The `_anime` suffix (e.g. `blue_anime`) means the job is currently
  /// building — `StatusIndicator` pulses while true.
  static bool isJobColorAnimating(String? jenkinsColor) =>
      jenkinsColor?.toLowerCase().contains('_anime') ?? false;

  static Color forJobColor(String? jenkinsColor) {
    final clean = jenkinsColor?.toLowerCase().replaceAll('_anime', '') ?? '';
    return switch (clean) {
      'blue' => jobColorBlue,
      'red' => jobColorRed,
      'yellow' => jobColorYellow,
      _ => jobColorGray,
    };
  }

  /// P6-05: screen-reader label for [StatusIndicator] — the ball color
  /// alone conveys nothing to a non-visual user. Mirrors [forJobColor]'s
  /// mapping, plus the `_anime` "building" state.
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
  static const ciToolJenkins = Color(0xFFD12E2E);
  static const ciToolGithubActions = Color(0xFF212121);
  static const ciToolGitlab = Color(0xFFE65929);
  static const ciToolSonarqube = Color(0xFF4F99ED);
  static const ciToolCircleci = Color(0xFF17A694);

  /// iOS system blue — what the SwiftUI app actually rendered as its accent,
  /// since `AccentColor.colorset` was left empty and every screen tinted off
  /// the platform default. Used as `AppTheme`'s default `accentColor` (i.e.
  /// before any tool is selected) and passed straight through to
  /// `ColorScheme.fromSeed` in `app_theme.dart`.
  ///
  /// History: a full per-tool reseed (`ColorScheme.fromSeed(seedColor:
  /// CiToolX.accentColor)`) was tried early on and reverted — from
  /// [ciToolJenkins] red it produced a muddy, desaturated brown/terracotta
  /// tonal palette across light-mode surfaces and containers, back when
  /// those surfaces (cards, tiles, rows) read `colorScheme.surface`/
  /// `surfaceContainerHigh` directly. `AppTheme` briefly swapped only
  /// `primary`/`onPrimary` to work around that — but that left anything
  /// defaulting to `secondary`/`secondaryContainer` (the bottom
  /// `NavigationBar`'s selected indicator/icon chief among them) stuck on
  /// this blue regardless of the active tool. Now that big surfaces read
  /// the app's own independent glass tokens (`glassFillLight`/`Dark`)
  /// instead, `AppTheme` reseeds the full scheme from `accentColor` again
  /// — see its doc comment.
  static const brandSeed = Color(0xFF007AFF);

  /// Light-mode surface tokens (ui-ux-pro-max `color --domain` "B2B Service"
  /// palette), used directly rather than through `fromSeed` — M3's generated
  /// light surface is only *near*-white and still carries a faint hue tint
  /// from the seed, which reads as "not really white" against pure-white
  /// cards elsewhere in the OS chrome.
  static const surfaceLight = Colors.white;
  static const backgroundLight = Color(0xFFF8FAFC);
  static const onSurfaceLight = Color(0xFF0F172A);
  static const secondaryLight = Color(0xFF334155);
  static const outlineLight = Color(0xFFE2E8F0);

  /// Dark-mode counterparts, pinned in `app_theme.dart` for the same reason
  /// as the light-mode set above: `AppTheme` now seeds its *entire*
  /// `ColorScheme` (including `surface`) from the active tool's accent
  /// color, and without pinning these, the scaffold background would drift
  /// toward that accent hue while `GlassSurface`'s cards — which use the
  /// fixed [glassFillDark] below, not `colorScheme.surface` — would not,
  /// producing a visible mismatch between card fill and page background.
  /// `backgroundDark` is deliberately one step darker than [glassFillDark]
  /// (slate-900 vs. slate-800), matching light mode's own card-lighter-
  /// than-background relationship.
  static const backgroundDark = Color(0xFF0F172A);
  static const onSurfaceDark = Color(0xFFF1F5F9);
  static const outlineDark = Color(0x33FFFFFF);

  /// Glassmorphism surface tokens (`docs/user-stories/00-design-system-
  /// glassmorphism.md`, US-DESIGN-01/02) — a "subtle frost": high fill
  /// opacity so body/status text stays legible per the WCAG AA floor
  /// US-DESIGN-02 requires, a hairline border, and a soft low-spread
  /// shadow for depth.
  static const glassFillLight = Color(0xCCFFFFFF); // white @ ~80%
  static const glassBorderLight = Color(0x1F0F172A); // onSurfaceLight @ ~12%
  static const glassShadowLight = Color(0x1A0F172A); // onSurfaceLight @ ~10%

  static const glassFillDark = Color(0xCC1E293B); // slate-800 @ ~80%
  static const glassBorderDark = Color(0x33FFFFFF); // white @ ~20%
  static const glassShadowDark = Color(0x40000000); // black @ ~25%

  /// Opaque fallback fill for the reduce-transparency accessibility mode
  /// (US-DESIGN-03) — same surface role as the glass fill tokens above, but
  /// fully opaque; used instead of them (with blur skipped entirely) when
  /// `ReduceTransparencyNotifier` is on.
  static const glassFallbackFillLight = Color(0xFFF1F5F9);
  static const glassFallbackFillDark = Color(0xFF1E293B);
}
