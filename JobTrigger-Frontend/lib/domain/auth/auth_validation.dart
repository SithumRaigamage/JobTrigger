/// A client-side form validation failure — never reached the network, so
/// it's deliberately not an `AppFailure` (those are for repository/network
/// outcomes only, per `docs/architecture.md#6-error-handling`).
class FormValidationError implements Exception {
  const FormValidationError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Field-validation rules ported 1:1 from `LoginViewModel.swift` /
/// `SignupViewModel.swift` — same substring-based email check and 6-char
/// password minimum as the backend itself enforces
/// (`JobTrigger-Backend/controllers/authController.js`).
class AuthValidation {
  const AuthValidation._();

  static bool isValidEmail(String email) =>
      email.contains('@') && email.contains('.');

  static bool isValidPassword(String password) => password.length >= 6;

  static bool passwordsMatch(String password, String confirmPassword) =>
      password == confirmPassword || confirmPassword.isEmpty;
}
