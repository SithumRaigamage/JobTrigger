import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/password_reset_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_validation.dart';
import 'package:job_trigger/domain/auth/password_reset_repository.dart';
import 'package:job_trigger/presentation/features/auth/forgot_password_notifier.dart';
import 'package:job_trigger/presentation/features/auth/reset_password_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _FakePasswordResetRepository implements PasswordResetRepository {
  Result<void, AppFailure> requestResult = const Ok(null);
  Result<void, AppFailure> confirmResult = const Ok(null);
  final requestedEmails = <String>[];
  final confirmed = <(String, String)>[];

  @override
  Future<Result<void, AppFailure>> requestReset({required String email}) async {
    requestedEmails.add(email);
    return requestResult;
  }

  @override
  Future<Result<void, AppFailure>> confirmReset({
    required String token,
    required String newPassword,
  }) async {
    confirmed.add((token, newPassword));
    return confirmResult;
  }
}

final _token = 'a' * 64;

void main() {
  late _FakePasswordResetRepository repo;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
    repo = _FakePasswordResetRepository();
    container = ProviderContainer(
      overrides: [passwordResetRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  group('ForgotPasswordNotifier', () {
    test('rejects a malformed email without calling the backend', () async {
      await container
          .read(forgotPasswordNotifierProvider.notifier)
          .requestReset('not-an-email');

      expect(
        container.read(forgotPasswordNotifierProvider).error,
        isA<FormValidationError>(),
      );
      expect(repo.requestedEmails, isEmpty);
    });

    test('marks the request sent on success', () async {
      await container
          .read(forgotPasswordNotifierProvider.notifier)
          .requestReset('a@b.com');

      expect(container.read(forgotPasswordNotifierProvider).value, isTrue);
      expect(repo.requestedEmails, ['a@b.com']);
    });

    test('shows the failure, and can go back to the form', () async {
      repo.requestResult = const Err(NetworkFailure());
      final notifier = container.read(forgotPasswordNotifierProvider.notifier);
      await notifier.requestReset('a@b.com');
      expect(
        container.read(forgotPasswordNotifierProvider).error,
        isA<NetworkFailure>(),
      );

      notifier.reset();
      expect(container.read(forgotPasswordNotifierProvider).value, isFalse);
    });
  });

  group('ResetPasswordNotifier', () {
    test('accepts only a 64-character hex token', () {
      expect(ResetPasswordNotifier.isWellFormedToken(_token), isTrue);
      expect(ResetPasswordNotifier.isWellFormedToken(''), isFalse);
      expect(ResetPasswordNotifier.isWellFormedToken('A' * 64), isFalse);
      expect(ResetPasswordNotifier.isWellFormedToken('a' * 63), isFalse);
    });

    test('checks the password rules before calling the backend', () async {
      final notifier = container.read(resetPasswordNotifierProvider.notifier);

      await notifier.resetPassword(
        token: _token,
        password: 'short',
        confirmPassword: 'short',
      );
      expect(
        container.read(resetPasswordNotifierProvider).error,
        isA<FormValidationError>(),
      );

      await notifier.resetPassword(
        token: _token,
        password: 'long-enough-1',
        confirmPassword: 'different-one',
      );
      expect(
        container.read(resetPasswordNotifierProvider).error,
        isA<FormValidationError>(),
      );
      expect(repo.confirmed, isEmpty);
    });

    test('resets with the token and reports done', () async {
      await container
          .read(resetPasswordNotifierProvider.notifier)
          .resetPassword(
            token: _token,
            password: 'long-enough-1',
            confirmPassword: 'long-enough-1',
          );

      expect(container.read(resetPasswordNotifierProvider).value, isTrue);
      expect(repo.confirmed, [(_token, 'long-enough-1')]);
    });

    test('shows the backend\'s reason for an expired link', () async {
      repo.confirmResult = const Err(
        RejectedRequestFailure('This reset link is invalid or has expired.'),
      );
      await container
          .read(resetPasswordNotifierProvider.notifier)
          .resetPassword(
            token: _token,
            password: 'long-enough-1',
            confirmPassword: 'long-enough-1',
          );

      expect(
        container.read(resetPasswordNotifierProvider).error,
        isA<RejectedRequestFailure>(),
      );
    });
  });
}
