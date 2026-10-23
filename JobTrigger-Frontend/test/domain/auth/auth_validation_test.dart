import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/auth/auth_validation.dart';

void main() {
  group('AuthValidation.isValidEmail', () {
    test('accepts an address with an @ and a .', () {
      expect(AuthValidation.isValidEmail('a@b.com'), isTrue);
    });

    test('rejects an address with no @', () {
      expect(AuthValidation.isValidEmail('ab.com'), isFalse);
    });

    test('rejects an address with no .', () {
      expect(AuthValidation.isValidEmail('a@bcom'), isFalse);
    });

    test('rejects an empty string', () {
      expect(AuthValidation.isValidEmail(''), isFalse);
    });

    test('matches the backend: no spaces, text on each side (AUD-26)', () {
      expect(AuthValidation.isValidEmail('a b@c.com'), isFalse);
      expect(AuthValidation.isValidEmail('@b.com'), isFalse);
      expect(AuthValidation.isValidEmail('a@.com'), isFalse);
      expect(AuthValidation.isValidEmail(' a@b.com '), isTrue); // Trimmed.
    });
  });

  group('AuthValidation.isValidPassword', () {
    test('accepts an 8-character password (AUD-26)', () {
      expect(AuthValidation.isValidPassword('abcdefgh'), isTrue);
    });

    test('rejects a 7-character password', () {
      expect(AuthValidation.isValidPassword('abcdefg'), isFalse);
    });

    test('rejects an empty password', () {
      expect(AuthValidation.isValidPassword(''), isFalse);
    });
  });

  group('AuthValidation.passwordsMatch', () {
    test('true when both are equal and non-empty', () {
      expect(AuthValidation.passwordsMatch('secret', 'secret'), isTrue);
    });

    test('false when they differ and confirm is non-empty', () {
      expect(AuthValidation.passwordsMatch('secret', 'other'), isFalse);
    });

    test('true when confirm is empty, regardless of password', () {
      expect(AuthValidation.passwordsMatch('secret', ''), isTrue);
    });
  });

  group('AuthValidation.passwordStrength', () {
    test('0 below the minimum length', () {
      expect(AuthValidation.passwordStrength(''), 0);
      expect(AuthValidation.passwordStrength('Ab1!xyz'), 0);
    });

    test('1 at the minimum with one kind of character', () {
      expect(AuthValidation.passwordStrength('abcdefgh'), 1);
    });

    test('a point for 12+ characters', () {
      expect(AuthValidation.passwordStrength('abcdefghijkl'), 2);
    });

    test('a point for three kinds of character', () {
      expect(AuthValidation.passwordStrength('abcdEF12'), 2);
    });

    test('tops out with length and all four kinds', () {
      expect(
        AuthValidation.passwordStrength('correct-Horse-9'),
        AuthValidation.maxPasswordStrength,
      );
      expect(AuthValidation.passwordStrength('abcdefghijklmnop'), 3);
    });
  });
}
