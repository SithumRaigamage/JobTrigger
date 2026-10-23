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

  /// The highest [passwordStrength].
  static const maxPasswordStrength = 4;

  /// P14-04: how far a new password goes past the minimum, for the signup
  /// screen's meter — 0 below [minPasswordLength], 1 at it, then a point
  /// each for 12+ characters, for mixing three kinds of character (lower,
  /// upper, digit, symbol), and for 16+ characters or all four kinds.
  /// Advisory only: the backend enforces just the length.
  static int passwordStrength(String password) {
    if (!isValidPassword(password)) return 0;
    final kinds = [
      RegExp('[a-z]'),
      RegExp('[A-Z]'),
      RegExp('[0-9]'),
      RegExp('[^a-zA-Z0-9]'),
    ].where((kind) => kind.hasMatch(password)).length;
    var strength = 1;
    if (password.length >= 12) strength++;
    if (kinds >= 3) strength++;
    if (password.length >= 16 || kinds == 4) strength++;
    return strength;
  }
}
