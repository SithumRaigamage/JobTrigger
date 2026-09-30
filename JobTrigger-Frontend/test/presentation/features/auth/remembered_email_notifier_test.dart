import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/auth_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_repository.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/auth/login_notifier.dart';
import 'package:job_trigger/presentation/features/auth/remembered_email_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.loginResult);

  final Result<AuthSession, AppFailure> loginResult;

  @override
  Future<Result<AuthSession, AppFailure>> login({
    required String email,
    required String password,
  }) async => loginResult;

  @override
  Future<Result<AuthSession, AppFailure>> signup({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> logoutEverywhere() =>
      throw UnimplementedError();
}

const _success = Ok<AuthSession, AppFailure>((
  user: User(id: 'u1', email: 'a@b.com'),
  token: 'jwt-abc',
  refreshToken: null,
));

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer containerWith(Result<AuthSession, AppFailure> result) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(result)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(authNotifierProvider, (_, _) {});
    return container;
  }

  group('RememberedEmailNotifier (AUD-01)', () {
    test('deletes a legacy plaintext password left by older builds', () async {
      SharedPreferences.setMockInitialValues({
        'login_saved_email': 'a@b.com',
        'login_saved_password': 'hunter2',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final email = await container.read(
        rememberedEmailNotifierProvider.future,
      );

      expect(email, 'a@b.com');
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(prefs.getString('login_saved_password'), isNull);
    });

    test('resolves to null when nothing is remembered', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(rememberedEmailNotifierProvider.future),
        isNull,
      );
    });
  });

  group('LoginNotifier remember-me', () {
    test('remembers only the email after a successful login', () async {
      final container = containerWith(_success);

      await container
          .read(loginNotifierProvider.notifier)
          .login(email: 'a@b.com', password: 'secret', rememberMe: true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('login_saved_email'), 'a@b.com');
      expect(prefs.getKeys().any((key) => key.contains('password')), isFalse);
      expect(
        prefs.getKeys().map(prefs.get).contains('secret'),
        isFalse,
        reason: 'the password must never reach shared_preferences',
      );
    });

    test('forgets a previously remembered email when unchecked', () async {
      SharedPreferences.setMockInitialValues({'login_saved_email': 'a@b.com'});
      final container = containerWith(_success);

      await container
          .read(loginNotifierProvider.notifier)
          .login(email: 'a@b.com', password: 'secret');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('login_saved_email'), isNull);
    });

    test('a failed login does not change what is remembered', () async {
      SharedPreferences.setMockInitialValues({
        'login_saved_email': 'old@b.com',
      });
      final container = containerWith(const Err(ServerFailure(400)));

      await container
          .read(loginNotifierProvider.notifier)
          .login(email: 'new@b.com', password: 'wrong', rememberMe: true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('login_saved_email'), 'old@b.com');
    });
  });
}
