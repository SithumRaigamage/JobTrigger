import 'user.dart';

/// Held by `authNotifierProvider` — see `docs/state-management.md`'s
/// "Global providers" table.
sealed class AuthState {
  const AuthState();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;
}
