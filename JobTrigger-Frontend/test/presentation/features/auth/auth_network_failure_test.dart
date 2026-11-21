import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/auth_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_repository.dart';
import 'package:job_trigger/presentation/common_widgets/inline_alert.dart';
import 'package:job_trigger/presentation/features/auth/login_screen.dart';
import 'package:job_trigger/presentation/features/auth/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// US-AUTH-01 and US-AUTH-02, "network/server failure": the NetworkFailure
// copy is shown, the typed password survives, and submitting again works.

class _Unreachable implements AuthRepository {
  int calls = 0;

  @override
  Future<Result<AuthSession, AppFailure>> login({
    required String email,
    required String password,
  }) async {
    calls++;
    return const Err(NetworkFailure());
  }

  @override
  Future<Result<AuthSession, AppFailure>> signup({
    required String email,
    required String password,
  }) async {
    calls++;
    return const Err(NetworkFailure());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<_Unreachable> _pump(WidgetTester tester, Widget screen) async {
  final repo = _Unreachable();
  tester.view
    ..physicalSize = const Size(800, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: AppTheme.dark(), home: screen),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

String _text(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('login: network copy, password kept, Log in tries again', (
    tester,
  ) async {
    final repo = await _pump(tester, const LoginScreen());
    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'a@b.dev',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'hunter22',
    );
    final submit = find.byKey(const Key('login_submit_button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byType(InlineAlert), findsOneWidget);
    expect(find.textContaining(const NetworkFailure().message), findsOneWidget);
    expect(_text(tester, 'login_password_field'), 'hunter22');

    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
  });

  testWidgets('signup: network copy, passwords kept, submit tries again', (
    tester,
  ) async {
    final repo = await _pump(tester, const SignupScreen());
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'a@b.dev',
    );
    await tester.enterText(
      find.byKey(const Key('signup_password_field')),
      'hunter2222',
    );
    await tester.enterText(
      find.byKey(const Key('signup_confirm_field')),
      'hunter2222',
    );
    final submit = find.byKey(const Key('signup_submit_button'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.byType(InlineAlert), findsOneWidget);
    expect(find.textContaining(const NetworkFailure().message), findsOneWidget);
    expect(_text(tester, 'signup_password_field'), 'hunter2222');
    expect(_text(tester, 'signup_confirm_field'), 'hunter2222');

    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repo.calls, 2);
  });
}
