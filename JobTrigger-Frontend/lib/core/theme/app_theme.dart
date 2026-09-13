import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light/dark `ThemeData`. [accentColor] (the active tool's `CiToolX.accentColor`
/// — see `ActiveToolNotifier` and `main.dart`) drives only `primary`/`onPrimary`
/// (AppBars, buttons, selected nav state, highlights). Everything else —
/// surfaces, backgrounds, containers, outlines — comes from the same fixed
/// tokens as before, regardless of which tool is active.
///
/// This is deliberately *not* a full `ColorScheme.fromSeed(seedColor:
/// accentColor, ...)` reseed: that was tried first and reseeding from
/// Jenkins red produced a muddy, desaturated brown/terracotta tonal palette
/// across light-mode surfaces and containers — see [AppColors.brandSeed]'s
/// doc comment for the history. Swapping just the primary swatch gets the
/// "this is Jenkins" branding on the elements that matter without dragging
/// every surface tone red-brown.
class AppTheme {
  const AppTheme._();

  static ThemeData light({Color accentColor = AppColors.brandSeed}) =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: accentColor,
          onPrimary: Colors.white,
          secondary: AppColors.secondaryLight,
          onSecondary: Colors.white,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.onSurfaceLight,
          outline: AppColors.outlineLight,
          error: AppColors.buildFailure,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
      );

  static ThemeData dark({Color accentColor = AppColors.brandSeed}) =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: AppColors.brandSeed,
              brightness: Brightness.dark,
            ).copyWith(
              primary: accentColor,
              onPrimary: Colors.white,
            ),
      );
}
