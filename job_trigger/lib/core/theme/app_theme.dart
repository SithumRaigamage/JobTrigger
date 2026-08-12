import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light/dark `ThemeData`. Dark mode is seeded from `AppColors.brandSeed`
/// (iOS system blue) to match the accent the SwiftUI app actually rendered —
/// see that constant's doc comment for why a Jenkins-red seed was dropped.
/// Light mode uses explicit white/near-white surface tokens instead of
/// `fromSeed` so backgrounds read as genuinely white, not M3's hue-tinted
/// "near white".
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.brandSeed,
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

  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandSeed,
      brightness: brightness,
    ),
  );
}
