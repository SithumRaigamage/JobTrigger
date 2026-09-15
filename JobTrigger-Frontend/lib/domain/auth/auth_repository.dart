import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'user.dart';

typedef AuthSession = ({User user, String token});

abstract class AuthRepository {
  Future<Result<AuthSession, AppFailure>> signup({
    required String email,
    required String password,
  });

  Future<Result<AuthSession, AppFailure>> login({
    required String email,
    required String password,
  });
}
