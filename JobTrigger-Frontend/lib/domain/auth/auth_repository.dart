import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'user.dart';

/// [refreshToken] renews the short-lived [token] (AUD-26); null from a
/// backend that predates refresh.
typedef AuthSession = ({User user, String token, String? refreshToken});

abstract class AuthRepository {
  Future<Result<AuthSession, AppFailure>> signup({
    required String email,
    required String password,
  });

  Future<Result<AuthSession, AppFailure>> login({
    required String email,
    required String password,
  });

  /// AUD-26: revokes every session this account has, on every device.
  Future<Result<void, AppFailure>> logoutEverywhere();

  /// AUD-48: changes the password, which revokes every session on every
  /// device; returns a fresh session for this one.
  Future<Result<AuthSession, AppFailure>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// AUD-48: deletes the account and every credential stored for it.
  Future<Result<void, AppFailure>> deleteAccount({required String password});
}
