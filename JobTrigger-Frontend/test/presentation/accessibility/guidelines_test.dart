import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/features/auth/login_screen.dart';
import 'package:job_trigger/presentation/features/auth/signup_screen.dart';
import 'package:job_trigger/presentation/features/tool_selection/tool_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NFR-A11Y-01/02, AUD-62: Flutter's own accessibility guidelines on the
/// screens every user passes through, in both themes.
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final screens = <String, Widget Function()>{
    'login': () => const LoginScreen(),
    'signup': () => const SignupScreen(),
    'tool selection': () => const ToolSelectionScreen(),
  };

  for (final MapEntry(key: name, value: build) in screens.entries) {
    for (final dark in [false, true]) {
      testWidgets('$name (${dark ? 'dark' : 'light'}) meets the guidelines', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: build(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
