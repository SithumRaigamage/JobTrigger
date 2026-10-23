import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The redesign's tokens for the current theme (P14-02). `AppTheme`
/// registers [dark] or [light] on its `ThemeData`; widgets read them with
/// `AppTokens.of(context)` so a status pill or a muted label picks the
/// right shade for the theme without asking for the brightness itself.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.background,
    required this.chrome,
    required this.card,
    required this.cardBorder,
    required this.raised,
    required this.console,
    required this.text,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.failure,
    required this.unstable,
    required this.running,
    required this.paused,
    required this.neutral,
  });

  static const dark = AppTokens(
    background: AppColors.backgroundDark,
    chrome: AppColors.chromeDark,
    card: AppColors.cardDark,
    cardBorder: AppColors.cardBorderDark,
    raised: AppColors.raisedDark,
    console: AppColors.consoleDark,
    text: AppColors.textDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    success: AppColors.successDark,
    failure: AppColors.failureDark,
    unstable: AppColors.unstableDark,
    running: AppColors.runningDark,
    paused: AppColors.pausedDark,
    neutral: AppColors.neutralDark,
  );

  static const light = AppTokens(
    background: AppColors.backgroundLight,
    chrome: AppColors.chromeLight,
    card: AppColors.cardLight,
    cardBorder: AppColors.cardBorderLight,
    raised: AppColors.raisedLight,
    // The console stays dark in both themes: build output is read like a
    // terminal, and its syntax colours are measured against this ground.
    console: AppColors.consoleDark,
    text: AppColors.textLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    success: AppColors.successLight,
    failure: AppColors.failureLight,
    unstable: AppColors.unstableLight,
    running: AppColors.runningLight,
    paused: AppColors.pausedLight,
    neutral: AppColors.neutralLight,
  );

  /// The tokens of the nearest theme. Falls back to the set matching the
  /// theme's brightness when a test builds a bare `ThemeData` without them.
  static AppTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppTokens>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  final Color background;
  final Color chrome;
  final Color card;
  final Color cardBorder;
  final Color raised;
  final Color console;
  final Color text;
  final Color textSecondary;
  final Color textMuted;
  final StatusColors success;
  final StatusColors failure;
  final StatusColors unstable;
  final StatusColors running;
  final StatusColors paused;
  final StatusColors neutral;

  StatusColors status(StatusTone tone) => switch (tone) {
    StatusTone.success => success,
    StatusTone.failure => failure,
    StatusTone.unstable => unstable,
    StatusTone.running => running,
    StatusTone.paused => paused,
    StatusTone.neutral => neutral,
  };

  @override
  AppTokens copyWith({
    Color? background,
    Color? chrome,
    Color? card,
    Color? cardBorder,
    Color? raised,
    Color? console,
    Color? text,
    Color? textSecondary,
    Color? textMuted,
    StatusColors? success,
    StatusColors? failure,
    StatusColors? unstable,
    StatusColors? running,
    StatusColors? paused,
    StatusColors? neutral,
  }) => AppTokens(
    background: background ?? this.background,
    chrome: chrome ?? this.chrome,
    card: card ?? this.card,
    cardBorder: cardBorder ?? this.cardBorder,
    raised: raised ?? this.raised,
    console: console ?? this.console,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    success: success ?? this.success,
    failure: failure ?? this.failure,
    unstable: unstable ?? this.unstable,
    running: running ?? this.running,
    paused: paused ?? this.paused,
    neutral: neutral ?? this.neutral,
  );

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    StatusColors s(StatusColors a, StatusColors b) =>
        StatusColors.lerp(a, b, t);
    return AppTokens(
      background: c(background, other.background),
      chrome: c(chrome, other.chrome),
      card: c(card, other.card),
      cardBorder: c(cardBorder, other.cardBorder),
      raised: c(raised, other.raised),
      console: c(console, other.console),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      success: s(success, other.success),
      failure: s(failure, other.failure),
      unstable: s(unstable, other.unstable),
      running: s(running, other.running),
      paused: s(paused, other.paused),
      neutral: s(neutral, other.neutral),
    );
  }
}
