// P6-08: sends the app's own "Send test crash report" to the crash-reporting
// host named by SENTRY_DSN, from a simulator/device, through demo mode (no
// backend needed). The event must then appear in GlitchTip with the made-up
// credentials redacted (docs/error-reporting.md, "Verifying").
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sends a test crash report', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    final demo = find.byKey(const Key('login_demo_button'));
    // A device that is already signed in has no login screen.
    if (demo.evaluate().isNotEmpty) {
      await tester.ensureVisible(demo);
      await tester.tap(demo);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    final cont = find.byKey(const Key('tool_continue_button'));
    if (cont.evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('tool_card_jenkins')));
      await tester.pumpAndSettle();
      await tester.tap(cont);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    final send = find.text('Send test crash report');
    await tester.scrollUntilVisible(send, 300);
    await tester.tap(send);
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });
}
