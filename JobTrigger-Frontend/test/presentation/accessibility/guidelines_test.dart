import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_colors.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/common_widgets/status_mark.dart';
import 'package:job_trigger/presentation/features/auth/login_screen.dart';
import 'package:job_trigger/presentation/features/auth/signup_screen.dart';
import 'package:job_trigger/presentation/features/tool_selection/tool_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PI-06: every tone rendered as shape + words, so adding a tone without a
/// visible label shows up here as a contrast/label failure.
class _StatusMarks extends StatelessWidget {
  const _StatusMarks();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tone in StatusTone.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: StatusMark(
                    tone: tone,
                    label: '${tone.name} status',
                    iconSize: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    'tool selection': () => const ToolSelectionScreen(choosing: true),
    'status marks': () => const _StatusMarks(),
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

  testWidgets('tool selection stays usable at 320pt and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const ToolSelectionScreen(choosing: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tool_continue_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
