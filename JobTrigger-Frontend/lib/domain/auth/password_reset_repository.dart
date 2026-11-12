import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';

/// US-AUTH-08 / P20-74: resetting a forgotten password by email. Kept
/// apart from [AuthRepository]: neither call needs or returns a session.
abstract class PasswordResetRepository {
  /// Asks the backend to email a reset link. Succeeds the same way whether
  /// or not an account has [email] (the backend never says which).
  Future<Result<void, AppFailure>> requestReset({required String email});

  /// Sets [newPassword] using the [token] from the emailed link. Every
  /// session on every device is signed out by it.
  Future<Result<void, AppFailure>> confirmReset({
    required String token,
    required String newPassword,
  });
}
