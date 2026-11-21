import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/presentation/common_widgets/inline_alert.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P14-03: the login screen as redesigned (`UI-UX/screens/01-login`).
/// A session read that hasn't finished yet (a cold start).
class _Rehydrating extends AuthNotifier {
  final gate = Completer<AuthState>();

  @override
  Future<AuthState> build() => gate.future;
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
      ),
    );
    // US-AUTH-03: the stored session is read first (a spinner), then the form.
    await tester.pumpAndSettle();
  }

  testWidgets('shows the redesigned copy and actions', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Log in to trigger and watch your builds.'), findsOne);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Remember my email'), findsOneWidget);
  });

  testWidgets('a failed attempt is reported inline, above the form', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(find.byType(InlineAlert), findsNothing);

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pump();

    expect(find.byType(InlineAlert), findsOneWidget);
    expect(find.text('Please fill in all fields.'), findsOneWidget);
  });

  testWidgets('each field is named by its visible label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpLogin(tester);

    expect(find.bySemanticsLabel(RegExp('^Email')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Password')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('no form flashes while the stored session is read (US-AUTH-03)', (
    tester,
  ) async {
    final auth = _Rehydrating();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => auth)],
        child: MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('session_check')), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);

    auth.gate.complete(const Unauthenticated());
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
