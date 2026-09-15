import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/auth_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_repository.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/auth/signup_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FakeAuthRepository implements AuthRepository {
  Result<AuthSession, AppFailure>? signupResult;
  int signupCallCount = 0;

  @override
  Future<Result<AuthSession, AppFailure>> signup({
    required String email,
    required String password,
  }) async {
    signupCallCount++;
    return signupResult!;
  }

  @override
  Future<Result<AuthSession, AppFailure>> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test('rejects a malformed email without calling the repository', () async {
    final repo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(signupNotifierProvider.notifier).signup(
      email: 'not-an-email',
      password: 'password',
      confirmPassword: 'password',
    );

    expect(container.read(signupNotifierProvider).hasError, isTrue);
    expect(repo.signupCallCount, 0);
  });

  test('rejects a password shorter than 6 characters', () async {
    final repo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(signupNotifierProvider.notifier).signup(
      email: 'a@b.com',
      password: 'short',
      confirmPassword: 'short',
    );

    expect(container.read(signupNotifierProvider).hasError, isTrue);
    expect(repo.signupCallCount, 0);
  });

  test('rejects mismatched password/confirmPassword', () async {
    final repo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(signupNotifierProvider.notifier).signup(
      email: 'a@b.com',
      password: 'password',
      confirmPassword: 'different',
    );

    expect(container.read(signupNotifierProvider).hasError, isTrue);
    expect(repo.signupCallCount, 0);
  });

  test('rejects an empty confirmPassword', () async {
    final repo = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(signupNotifierProvider.notifier).signup(
      email: 'a@b.com',
      password: 'password',
      confirmPassword: '',
    );

    expect(container.read(signupNotifierProvider).hasError, isTrue);
    expect(repo.signupCallCount, 0);
  });

  test('a successful signup sets AuthNotifier to Authenticated', () async {
    final repo = _FakeAuthRepository()
      ..signupResult = const Ok((
        user: User(id: 'u1', email: 'a@b.com'),
        token: 'jwt-abc',
      ));
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(authNotifierProvider, (_, _) {});

    await container.read(signupNotifierProvider.notifier).signup(
      email: 'a@b.com',
      password: 'password',
      confirmPassword: 'password',
    );

    expect(container.read(signupNotifierProvider).hasError, isFalse);
    expect(container.read(authNotifierProvider).value, isA<Authenticated>());
  });

  test('a repository failure surfaces as SignupNotifier state error', () async {
    final repo = _FakeAuthRepository()
      ..signupResult = const Err(ServerFailure(400));
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(signupNotifierProvider.notifier).signup(
      email: 'a@b.com',
      password: 'password',
      confirmPassword: 'password',
    );

    expect(container.read(signupNotifierProvider).error, isA<AppFailure>());
  });
}
