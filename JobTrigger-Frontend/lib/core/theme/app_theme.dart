import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light/dark `ThemeData`, fully seeded from [accentColor] (the active
/// tool's `CiToolX.accentColor` — see `ActiveToolNotifier` and `main.dart`).
///
/// This used to swap only `primary`/`onPrimary`, leaving every other
/// `ColorScheme` slot derived from a fixed blue seed — which meant anything
/// defaulting to `secondary`/`secondaryContainer` (Material 3's
/// `NavigationBar` selected indicator/icon, `Chip`, `SegmentedButton`,
/// `FilledButton.tonal`) stayed off-brand no matter which tool was active.
/// Now the whole scheme is seeded from [accentColor] via
/// `ColorScheme.fromSeed`, and only the handful of neutral slots that must
/// stay pinned for the app's clean white/near-black identity are restored
/// afterward — everything else (including those secondary/tertiary/
/// container slots) follows the active tool's color.
///
/// A *full* reseed was tried once before and reverted — see
/// [AppColors.brandSeed]'s doc comment — because it dragged large
/// surface/container fills toward a muddy, desaturated brown/terracotta
/// when seeded from Jenkins red. That's no longer a risk: the big visible
/// surfaces (cards, tool tiles, job rows, the bottom sheet) now read the
/// app's own independent glass tokens (`AppColors.glassFillLight/Dark`),
/// not `colorScheme.surface`/`surfaceContainerHigh` — so only small,
/// genuinely brand-relevant elements (nav bar, chips, tonal buttons,
/// dialogs) pick up the tint.
class AppTheme {
  const AppTheme._();

  /// [onPrimary] is deliberately *not* pinned to white (it used to be).
  /// M3 derives `primary`/`onPrimary` into a contrast-safe pair on its own:
  /// a dark, saturated `primary` with white text in light mode, and a light
  /// `primary` with dark text in dark mode. Forcing `onPrimary: Colors.white`
  /// broke that pairing in dark mode, where `primary` is a pale tint — white
  /// text on it measured 1.71:1 (WCAG AA needs 4.5:1), which failed
  /// `textContrastGuideline` on the auth screens' primary buttons.
  ///
  /// The rule this restores: `primary` is a *surface* color, `onPrimary` is
  /// its foreground. Anything that paints text or an icon on a `primary`
  /// background must use `onPrimary`, never `Colors.white`.
  static ThemeData light({Color accentColor = AppColors.brandSeed}) =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: Brightness.light,
            ).copyWith(
              surface: AppColors.surfaceLight,
              onSurface: AppColors.onSurfaceLight,
              outline: AppColors.outlineLight,
            ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
      );

  static ThemeData dark({Color accentColor = AppColors.brandSeed}) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ).copyWith(
          surface: AppColors.backgroundDark,
          onSurface: AppColors.onSurfaceDark,
          outline: AppColors.outlineDark,
        ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
  );
}
