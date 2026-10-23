// End-to-end tests driving the real app (real network calls, real
// navigation) on a connected simulator/device — see docs/dev-setup.md for
// prerequisites and docs/integration-testing.md for how to run these.
//
// Requires JobTrigger-Backend running (./setup-dev.sh) with the dev account
// seeded by scripts/setup-migrations.js: developer@jobtrigger.app /
// SecurePassword123!.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:job_trigger/core/theme/app_colors.dart';
import 'package:job_trigger/main.dart' as app;

const _devEmail = 'developer@jobtrigger.app';
const _devPassword = 'SecurePassword123!';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Color primaryColorAt(WidgetTester tester, Finder finder) =>
      Theme.of(tester.element(finder)).colorScheme.primary;

  testWidgets('Login screen renders with the app accent', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    final emailField = find.byKey(const Key('login_email_field'));
    expect(emailField, findsOneWidget);
    expect(
      primaryColorAt(tester, emailField),
      AppColors.accent,
      reason: 'Before any tool is selected, primary is the app accent.',
    );
  });

  testWidgets(
    'Login -> Tool Selection -> Jenkins Home all keep the one app accent',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('login_email_field')),
        _devEmail,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        _devPassword,
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // Network round-trip to the backend + AuthNotifier + router redirect.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final jenkinsCard = find.byKey(const Key('tool_card_jenkins'));
      expect(
        jenkinsCard,
        findsOneWidget,
        reason: 'Should have landed on ToolSelectionScreen after login.',
      );
      expect(
        primaryColorAt(tester, jenkinsCard),
        AppColors.accent,
        reason: 'ToolSelectionScreen uses the app accent too.',
      );

      await tester.tap(jenkinsCard);
      await tester.pumpAndSettle();
      // P14-05: choosing a tool highlights it; Continue commits it.
      await tester.tap(find.byKey(const Key('tool_continue_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('Jobs'),
        findsOneWidget,
        reason: 'Choosing Jenkins and continuing should land on Home ("Jobs").',
      );
      expect(
        Theme.of(tester.element(find.text('Jobs'))).colorScheme.primary,
        AppColors.accent,
        reason:
            'P14 decision 4: selecting Jenkins no longer re-tints the app — '
            'Jenkins red would compete with the "failed" red.',
      );
    },
  );
}
