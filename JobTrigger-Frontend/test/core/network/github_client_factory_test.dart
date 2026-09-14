import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/network/github_client_factory.dart';

void main() {
  group('buildGithubDio', () {
    test('sets a Bearer Authorization header and the fixed base URL', () {
      final dio = buildGithubDio(token: 'ghp_faketoken');

      expect(dio.options.headers['Authorization'], 'Bearer ghp_faketoken');
      expect(dio.options.baseUrl, githubApiBaseUrl);
    });

    test('a fresh instance per call carries its own token', () {
      final dioA = buildGithubDio(token: 'token-a');
      final dioB = buildGithubDio(token: 'token-b');

      expect(dioA.options.headers['Authorization'], 'Bearer token-a');
      expect(dioB.options.headers['Authorization'], 'Bearer token-b');
      expect(identical(dioA, dioB), isFalse);
    });
  });

  // testGithubConnection itself has no test — it always builds its own
  // internal Dio (a throwaway client, deliberately never the active
  // credential's, matching testJenkinsConnection's reasoning) with no
  // injection seam for a fake adapter. Same untested-for-the-same-reason
  // shape as testJenkinsConnection already has in this codebase; the
  // logic worth testing (rate-limit vs. plain-403 detection) lives in
  // AppFailure.fromGithubException and is covered directly in
  // test/core/error/app_failure_test.dart instead.
}
