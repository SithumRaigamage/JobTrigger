import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light/dark `ThemeData`, seeded from the Jenkins brand red the old app
/// used as its one consistent accent color (`AppColors.ciToolJenkins`) —
/// there's no other custom palette to match since the SwiftUI app leaned on
/// iOS system colors throughout (see `app_colors.dart`'s doc comment).
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _themeFor(Brightness.light);

  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.ciToolJenkins,
      brightness: brightness,
    ),
  );
}
