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
  });

  group('AuthValidation.isValidPassword', () {
    test('accepts a 6-character password', () {
      expect(AuthValidation.isValidPassword('abcdef'), isTrue);
    });

    test('rejects a 5-character password', () {
      expect(AuthValidation.isValidPassword('abcde'), isFalse);
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
}
