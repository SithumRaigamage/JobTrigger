import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/auth/auth_validation.dart';
import 'auth_notifier.dart';

part 'signup_notifier.g.dart';

/// Same shape as `LoginNotifier`, plus the signup-specific
/// password-length/confirm-match rules — ported from `SignupViewModel.swift`.
@riverpod
class SignupNotifier extends _$SignupNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> signup({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!AuthValidation.isValidEmail(email)) {
      state = AsyncError(
        const FormValidationError('Please enter a valid email address.'),
        StackTrace.current,
      );
      return;
    }
    if (!AuthValidation.isValidPassword(password)) {
      state = AsyncError(
        const FormValidationError('Password must be at least 6 characters.'),
        StackTrace.current,
      );
      return;
    }
    if (!AuthValidation.passwordsMatch(password, confirmPassword) ||
        confirmPassword.isEmpty) {
      state = AsyncError(
        const FormValidationError('Passwords do not match.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signup(email: email, password: password);
    switch (result) {
      case Ok(:final value):
        await ref
            .read(authNotifierProvider.notifier)
            .setSession(value.user, value.token);
        state = const AsyncData(null);
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}
