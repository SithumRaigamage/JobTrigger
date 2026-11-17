// P2-11: signs in on a simulator and leaves the app installed.
//
// Needs a backend with the account below (see docs/integration-testing.md).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/main.dart' as app;

const _email = String.fromEnvironment('RELAUNCH_EMAIL');
const _password = String.fromEnvironment('RELAUNCH_PASSWORD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signs in and reaches tool selection', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('login_email_field')), _email);
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      _password,
    );
    // "Remember my email" is also what keeps the session across a relaunch
    // (P19-01): without it the session ends with the app, by design.
    final remember = find.widgetWithText(SwitchListTile, 'Remember my email');
    await tester.ensureVisible(remember);
    await tester.tap(remember);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(find.byKey(const Key('tool_card_jenkins')), findsOneWidget);
  });
}
