import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// The redesign's two typefaces (P14-02, `UI-UX/README.md`): Inter for
/// interface text and JetBrains Mono for anything a CI tool printed or
/// counted — build numbers, durations, branches, URLs, file and parameter
/// names, console output. Both are bundled (`assets/fonts/`).
///
/// Screens still reach for `Theme.of(context).textTheme.*`; [textTheme]
/// sets its sizes and weights once. Use [mono] to switch any of those
/// styles to the monospaced face.
class AppTypography {
  const AppTypography._();

  static const sans = 'Inter';
  static const monoFamily = 'JetBrains Mono';

  /// The same style in the monospaced face.
  static TextStyle mono(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(fontFamily: monoFamily);

  /// Console output, column-aligned (`BuildLogView.swift` set the log
  /// monospaced too).
  static const buildLog = TextStyle(
    fontFamily: monoFamily,
    fontSize: 12,
    height: 1.7,
  );

  /// Inter is set on every style here, not only through
  /// `ThemeData.fontFamily`: the component themes (`FilledButton`,
  /// `ListTile`, inputs …) take their styles from this text theme directly,
  /// and a style without a family would fall back to the platform font.
  static TextTheme textTheme(AppTokens t) =>
      _textTheme(t).apply(fontFamily: sans);

  static TextTheme _textTheme(AppTokens t) => TextTheme(
    // Screen titles.
    headlineLarge: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.15,
      color: t.text,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.56,
      height: 1.15,
      color: t.text,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.24,
      height: 1.2,
      color: t.text,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: t.text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: t.text,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: t.text,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: t.text),
    bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: t.text),
    bodySmall: TextStyle(fontSize: 13, height: 1.4, color: t.textMuted),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: t.text,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: t.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: t.textMuted,
    ),
  );
}
