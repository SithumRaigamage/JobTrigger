import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/core/theme/app_tokens.dart';

/// US-PROF-02: the app is built as `main.dart` builds it (light theme,
/// dark theme, the chosen mode). "System" follows the OS while the app is
/// open, and an explicit mode uses that mode's tokens whatever the OS says.
Future<AppTokens> _tokens(WidgetTester tester, ThemeMode mode) async {
  late AppTokens tokens;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: Builder(
        builder: (context) {
          tokens = AppTokens.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tokens;
}

void main() {
  testWidgets('System follows the OS appearance while the app is open', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    expect(await _tokens(tester, ThemeMode.system), AppTokens.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    expect(await _tokens(tester, ThemeMode.system), AppTokens.dark);
  });

  testWidgets('an explicit mode uses only its own tokens', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    expect(await _tokens(tester, ThemeMode.dark), AppTokens.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    expect(await _tokens(tester, ThemeMode.light), AppTokens.light);
  });
}
