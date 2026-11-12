import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/password_reset_repository_impl.dart';
import '../../../domain/auth/auth_validation.dart';

part 'forgot_password_notifier.g.dart';

/// US-AUTH-08: the "Forgot password?" form. `true` once the request went
/// through — the screen then says to check the inbox, worded so it never
/// confirms that the email has an account (the backend doesn't either).
@riverpod
class ForgotPasswordNotifier extends _$ForgotPasswordNotifier {
  @override
  FutureOr<bool> build() => false;

  Future<void> requestReset(String email) async {
    if (!AuthValidation.isValidEmail(email)) {
      state = AsyncError(
        const FormValidationError('Please enter a valid email address.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    final result = await ref
        .read(passwordResetRepositoryProvider)
        .requestReset(email: email);
    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final error) => AsyncError(error, StackTrace.current),
    };
  }

  /// "Use a different email": back to the empty form.
  void reset() => state = const AsyncData(false);
}
