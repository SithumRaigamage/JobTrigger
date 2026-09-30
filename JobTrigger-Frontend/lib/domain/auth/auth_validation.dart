/// A client-side form validation failure — never reached the network, so
/// it's deliberately not an `AppFailure` (those are for repository/network
/// outcomes only, per `docs/architecture.md#6-error-handling`).
class FormValidationError implements Exception {
  const FormValidationError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Field-validation rules, kept in step with what the backend enforces
/// (`JobTrigger-Backend/controllers/authController.js`, AUD-26): the same
/// email pattern and an 8-character password minimum. Originally ported
/// from `LoginViewModel.swift`/`SignupViewModel.swift` (a substring email
/// check and 6 characters).
class AuthValidation {
  const AuthValidation._();

  /// Something, `@`, something, `.`, something, with no spaces.
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static const minPasswordLength = 8;

  static bool isValidEmail(String email) => _email.hasMatch(email.trim());

  static bool isValidPassword(String password) =>
      password.length >= minPasswordLength;

  static bool passwordsMatch(String password, String confirmPassword) =>
      password == confirmPassword || confirmPassword.isEmpty;
}
