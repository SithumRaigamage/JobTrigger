import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/password_reset_repository_impl.dart';
import '../../../domain/auth/auth_state.dart';
import '../../../domain/auth/auth_validation.dart';
import 'auth_notifier.dart';

part 'reset_password_notifier.g.dart';

/// Matches the backend's link token: 32 random bytes in hex.
final _tokenPattern = RegExp(r'^[a-f0-9]{64}$');

/// US-AUTH-08: choosing a new password from the emailed link
/// (`jobtrigger://app/reset-password?token=…`). `true` once it's reset.
@riverpod
class ResetPasswordNotifier extends _$ResetPasswordNotifier {
  @override
  FutureOr<bool> build() => false;

  /// Whether [token] can be a reset token at all. A malformed link is
  /// shown as expired straight away, without a round trip.
  static bool isWellFormedToken(String token) => _tokenPattern.hasMatch(token);

  Future<void> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    if (!AuthValidation.isValidPassword(password)) {
      state = AsyncError(
        const FormValidationError(
          'Password must be at least '
          '${AuthValidation.minPasswordLength} characters.',
        ),
        StackTrace.current,
      );
      return;
    }
    if (confirmPassword.isEmpty ||
        !AuthValidation.passwordsMatch(password, confirmPassword)) {
      state = AsyncError(
        const FormValidationError('Passwords do not match.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final result = await ref
        .read(passwordResetRepositoryProvider)
        .confirmReset(token: token, newPassword: password);
    switch (result) {
      case Ok():
        // The reset signed out every session. If this device had one,
        // drop it now rather than at the next request's 401.
        if (ref.read(authNotifierProvider).value is Authenticated) {
          await ref.read(authNotifierProvider.notifier).logout();
        }
        if (ref.mounted) state = const AsyncData(true);
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}
