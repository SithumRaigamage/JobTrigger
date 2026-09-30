import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/credential/token_hygiene.dart';

void main() {
  test('recognises current and legacy Jenkins API tokens', () {
    // A real token from the fixture Jenkins (2.568.3): `11` + 32 hex.
    expect(
      looksLikeJenkinsApiToken('118addfcc60b8573398ead1f701cb565a1'),
      isTrue,
    );
    // Legacy format: 32 hex.
    expect(
      looksLikeJenkinsApiToken('0123456789abcdef0123456789abcdef'),
      isTrue,
    );
    // Surrounding whitespace from a paste doesn't matter.
    expect(
      looksLikeJenkinsApiToken(' 0123456789abcdef0123456789abcdef\n'),
      isTrue,
    );
  });

  test('flags anything else as a probable password', () {
    expect(looksLikeJenkinsApiToken('hunter2'), isFalse);
    expect(
      looksLikeJenkinsApiToken('0123456789ABCDEF0123456789ABCDEF'),
      isFalse,
    );
    expect(
      looksLikeJenkinsApiToken('0123456789abcdef0123456789abcde'),
      isFalse,
    );
    expect(
      looksLikeJenkinsApiToken('990123456789abcdef0123456789abcdef'),
      isFalse,
    );
  });

  test('token page URL', () {
    expect(
      jenkinsTokenPageUrl('https://ci.test/jenkins/').toString(),
      'https://ci.test/jenkins/me/configure',
    );
  });
}
