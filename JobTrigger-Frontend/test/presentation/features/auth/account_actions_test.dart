import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';
import 'package:job_trigger/data/repositories/auth_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_repository.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/auth_validation.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_home_widget_bridge.dart';
import 'package:job_trigger/core/platform/home_widget_bridge.dart';

const _user = User(id: 'u1', email: 'a@b.com');

class _Repo implements AuthRepository {
  Result<AuthSession, AppFailure> changeResult = const Ok((
    user: _user,
    token: 'access-2',
    refreshToken: 'refresh-2',
  ));
  Result<void, AppFailure> deleteResult = const Ok(null);
  int calls = 0;

  @override
  Future<Result<AuthSession, AppFailure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    calls++;
    return changeResult;
  }

  @override
  Future<Result<void, AppFailure>> deleteAccount({
    required String password,
  }) async {
    calls++;
    return deleteResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  final storage = SecureStorageService(const FlutterSecureStorage());

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> signedIn(_Repo repo) async {
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        homeWidgetBridgeProvider.overrideWithValue(FakeHomeWidgetBridge()),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authNotifierProvider.future);
    await c
        .read(authNotifierProvider.notifier)
        .setSession(_user, 'access-1', refreshToken: 'refresh-1');
    return c;
  }

  group('change password (AUD-48)', () {
    test('checks the form before asking the server', () async {
      final repo = _Repo();
      final notifier = (await signedIn(
        repo,
      )).read(authNotifierProvider.notifier);
      for (final (current, next, confirm) in [
        ('', 'new-password', 'new-password'),
        ('old-password', 'short', 'short'),
        ('old-password', 'new-password', 'different'),
      ]) {
        final problem = await notifier.changePassword(
          currentPassword: current,
          newPassword: next,
          confirmPassword: confirm,
        );
        expect(problem, isA<FormValidationError>());
      }
      expect(repo.calls, 0);
    });

    test('keeps this device signed in with the new session', () async {
      final c = await signedIn(_Repo());
      final problem = await c
          .read(authNotifierProvider.notifier)
          .changePassword(
            currentPassword: 'old-password',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );
      expect(problem, isNull);
      expect(await storage.readToken(), 'access-2');
      expect(await storage.readRefreshToken(), 'refresh-2');
      expect(c.read(authNotifierProvider).value, isA<Authenticated>());
    });

    test('a wrong current password changes nothing', () async {
      final repo = _Repo()
        ..changeResult = const Err(
          RejectedRequestFailure('Current password is incorrect'),
        );
      final c = await signedIn(repo);
      final problem = await c
          .read(authNotifierProvider.notifier)
          .changePassword(
            currentPassword: 'wrong-password',
            newPassword: 'new-password',
            confirmPassword: 'new-password',
          );
      expect(problem, isA<RejectedRequestFailure>());
      expect(await storage.readToken(), 'access-1');
    });
  });

  group('delete account (AUD-48)', () {
    test('signs out and clears this device', () async {
      final c = await signedIn(_Repo());
      final problem = await c
          .read(authNotifierProvider.notifier)
          .deleteAccount('password');
      expect(problem, isNull);
      expect(await storage.readToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(c.read(authNotifierProvider).value, isA<Unauthenticated>());
    });

    test('a failure keeps the session and every local value', () async {
      final repo = _Repo()..deleteResult = const Err(NetworkFailure());
      final c = await signedIn(repo);
      final problem = await c
          .read(authNotifierProvider.notifier)
          .deleteAccount('password');
      expect(problem, isA<NetworkFailure>());
      expect(await storage.readToken(), 'access-1');
      expect(c.read(authNotifierProvider).value, isA<Authenticated>());
    });

    test('needs the password', () async {
      final repo = _Repo();
      final c = await signedIn(repo);
      final problem = await c
          .read(authNotifierProvider.notifier)
          .deleteAccount('');
      expect(problem, isA<FormValidationError>());
      expect(repo.calls, 0);
    });
  });
}
