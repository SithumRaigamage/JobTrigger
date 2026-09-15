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

  testWidgets(
    'Login screen renders with the original blue theme, not tool-tinted',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final emailField = find.byKey(const Key('login_email_field'));
      expect(emailField, findsOneWidget);
      expect(
        primaryColorAt(tester, emailField),
        AppColors.brandSeed,
        reason:
            'Before any tool is selected, primary should be the original '
            'blue (AppColors.brandSeed), not a tool accent color.',
      );
    },
  );

  testWidgets(
    'Login -> Tool Selection stays blue -> selecting Jenkins turns Home red',
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
        AppColors.brandSeed,
        reason: 'ToolSelectionScreen itself is still pre-selection: blue.',
      );

      await tester.tap(jenkinsCard);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        find.text('Jobs'),
        findsOneWidget,
        reason: 'Tapping Jenkins should navigate to HomeScreen ("Jobs").',
      );
      expect(
        Theme.of(tester.element(find.text('Jobs'))).colorScheme.primary,
        AppColors.ciToolJenkins,
        reason: 'Once Jenkins is selected, primary should be Jenkins red.',
      );
    },
  );
}
