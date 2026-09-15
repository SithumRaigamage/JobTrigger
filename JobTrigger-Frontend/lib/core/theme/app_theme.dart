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

  static ThemeData light({Color accentColor = AppColors.brandSeed}) =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: Brightness.light,
            ).copyWith(
              onPrimary: Colors.white,
              surface: AppColors.surfaceLight,
              onSurface: AppColors.onSurfaceLight,
              outline: AppColors.outlineLight,
            ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
      );

  static ThemeData dark({Color accentColor = AppColors.brandSeed}) =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: accentColor,
              brightness: Brightness.dark,
            ).copyWith(
              onPrimary: Colors.white,
              surface: AppColors.backgroundDark,
              onSurface: AppColors.onSurfaceDark,
              outline: AppColors.outlineDark,
            ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
      );
}
