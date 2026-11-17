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

  group('PI-09 token pages', () {
    test('GitHub pre-fills the classic scopes JobTrigger needs', () {
      final url = gitHubTokenPageUrl();
      expect(url.host, 'github.com');
      expect(url.path, '/settings/tokens/new');
      expect(url.queryParameters['scopes'], 'repo,workflow');
      expect(url.queryParameters['description'], 'JobTrigger');
    });

    test('SonarQube uses the user account security page', () {
      expect(
        sonarQubeTokenPageUrl('https://sonar.example.com/').toString(),
        'https://sonar.example.com/user/account/security',
      );
    });

    test('SonarCloud uses its own account security page', () {
      expect(
        sonarQubeTokenPageUrl('https://sonarcloud.io').toString(),
        'https://sonarcloud.io/account/security',
      );
    });
  });
}
