import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/common_widgets/inline_alert.dart';
import 'package:job_trigger/presentation/features/auth/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P14-04: the signup screen as redesigned (`UI-UX/screens/02-signup`).
void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSignup(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark(), home: const SignupScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the redesigned copy', (tester) async {
    await pumpSignup(tester);

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('At least 8 characters'), findsOneWidget);
  });

  testWidgets('the meter follows the password as it is typed', (tester) async {
    await pumpSignup(tester);
    final password = find.byKey(const Key('signup_password_field'));

    await tester.enterText(password, 'short');
    await tester.pump();
    expect(find.text('Too short — at least 8 characters'), findsOneWidget);

    await tester.enterText(password, 'abcdEF12');
    await tester.pump();
    expect(find.text('Good'), findsOneWidget);
  });

  testWidgets('a confirmation that differs is flagged on the field', (
    tester,
  ) async {
    await pumpSignup(tester);
    await tester.enterText(
      find.byKey(const Key('signup_password_field')),
      'abcdEF12',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm_field')),
      'abcdEF1',
    );
    await tester.pump();

    expect(find.text('Passwords don’t match.'), findsOneWidget);
  });

  testWidgets('a refused form is reported inline', (tester) async {
    await pumpSignup(tester);
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'not-an-email',
    );
    final submit = find.byKey(const Key('signup_submit_button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.byType(InlineAlert), findsOneWidget);
    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });
}
