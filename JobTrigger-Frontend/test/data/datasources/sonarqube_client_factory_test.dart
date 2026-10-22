import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/sonarqube_client_factory.dart';

void main() {
  group('buildSonarQubeDio', () {
    test("sets a Bearer Authorization header and the credential's baseUrl", () {
      final dio = buildSonarQubeDio(
        baseUrl: 'https://sonarcloud.io',
        token: 'squ_faketoken',
      );

      expect(dio.options.headers['Authorization'], 'Bearer squ_faketoken');
      expect(dio.options.baseUrl, 'https://sonarcloud.io');
    });

    test('a fresh instance per call carries its own baseUrl and token', () {
      final dioA = buildSonarQubeDio(
        baseUrl: 'https://sonarcloud.io',
        token: 'token-a',
      );
      final dioB = buildSonarQubeDio(
        baseUrl: 'https://sonar.example.com',
        token: 'token-b',
      );

      expect(dioA.options.baseUrl, 'https://sonarcloud.io');
      expect(dioB.options.baseUrl, 'https://sonar.example.com');
      expect(dioA.options.headers['Authorization'], 'Bearer token-a');
      expect(dioB.options.headers['Authorization'], 'Bearer token-b');
      expect(identical(dioA, dioB), isFalse);
    });
  });

  // testSonarQubeConnection itself has no test -- it always builds its own
  // internal Dio (a throwaway client, deliberately never the active
  // credential's, matching testGitHubConnection's reasoning) with no
  // injection seam for a fake adapter. Same untested-for-the-same-reason
  // shape already accepted in this codebase for testJenkinsConnection/
  // testGitHubConnection.
}
