import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/auth/auth_validation.dart';
import 'auth_notifier.dart';
import 'remembered_email_notifier.dart';

part 'login_notifier.g.dart';

/// Form-submit state (loading/error) for the login screen — see
/// `docs/state-management.md`'s "Feature: auth" section. Owns nothing about
/// the session itself; on success it delegates to `authNotifierProvider`.
@riverpod
class LoginNotifier extends _$LoginNotifier {
  @override
  FutureOr<void> build() {}

  /// [rememberMe] is applied only after a successful login — a failed
  /// attempt never changes what's remembered.
  Future<void> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      state = AsyncError(
        const FormValidationError('Please fill in all fields.'),
        StackTrace.current,
      );
      return;
    }
    if (!AuthValidation.isValidEmail(email)) {
      state = AsyncError(
        const FormValidationError('Please enter a valid email address.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    switch (result) {
      case Ok(:final value):
        await ref
            .read(authNotifierProvider.notifier)
            .setSession(
              value.user,
              value.token,
              refreshToken: value.refreshToken,
            );
        final rememberedEmail = ref.read(
          rememberedEmailNotifierProvider.notifier,
        );
        await (rememberMe
            ? rememberedEmail.remember(email)
            : rememberedEmail.forget());
        state = const AsyncData(null);
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}
