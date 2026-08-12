// TEMPORARY manual P2-11 real-device verification, step 1 of 2.
// Runs the REAL app on a REAL simulator against the REAL local backend,
// signs up a fresh user through the real UI, and confirms landing on
// ToolSelectionScreen. Run step 2 as a SEPARATE `flutter test
// integration_test/...` invocation on the SAME device -- a fresh process
// reusing the simulator's real Keychain/shared_preferences is the closest
// available equivalent to "kill and relaunch the app" without a fully
// scripted OS-level app-kill. Not part of the permanent suite -- delete
// both files after use.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign up a fresh user and land on ToolSelectionScreen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsWidgets);

    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pumpAndSettle();

    final email =
        'p2-11-relaunch-${DateTime.now().millisecondsSinceEpoch}@example.com';
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm Password'),
      'password123',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Account'));
    // Real network round-trip to the real local backend.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Choose Your Tool'), findsOneWidget);
    // ignore: avoid_print
    print('P2-11 step 1: signed up $email, landed on ToolSelectionScreen.');
  });
}
