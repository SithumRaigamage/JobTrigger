import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_branch_ref.dart';

void main() {
  _refInterceptor();
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

// US-SQ-QUALITY-10: the chosen branch rides on project-scoped calls only.
void _refInterceptor() {
  group('branch ref interceptor (US-SQ-QUALITY-10)', () {
    test('adds branch to project calls, not to the branch list', () async {
      final seen = <Uri>[];
      final dio = buildSonarQubeDio(
        baseUrl: 'https://sonar.test',
        token: 't',
        refFor: (_) => const SonarQubeBranchRef.branch('release/2.0'),
      );
      // Appended, so the branch interceptor has already run.
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen.add(options.uri);
            handler.reject(
              DioException(requestOptions: options, error: 'stop'),
            );
          },
        ),
      );

      for (final path in [
        '/api/qualitygates/project_status',
        '/api/measures/component',
        '/api/project_branches/list',
      ]) {
        try {
          await dio.get<Map<String, dynamic>>(path);
        } on DioException {
          // Expected: the spy stops the request before the network.
        }
      }

      expect(seen[0].queryParameters['branch'], 'release/2.0');
      expect(seen[1].queryParameters['branch'], 'release/2.0');
      expect(seen[2].queryParameters.containsKey('branch'), isFalse);
    });

    test('a file key finds its project, with or without : in its key', () async {
      final seen = <Uri>[];
      final chosen = {
        'web': const SonarQubeBranchRef.branch('feature/login'),
        'acme:api': const SonarQubeBranchRef.pullRequest('42'),
      };
      final dio = buildSonarQubeDio(
        baseUrl: 'https://sonar.test',
        token: 't',
        refFor: (key) => chosen[key] ?? const SonarQubeBranchRef.main(),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen.add(options.uri);
            handler.reject(
              DioException(requestOptions: options, error: 'stop'),
            );
          },
        ),
      );

      for (final file in [
        'web:src/app.ts',
        'acme:api:src/x.ts',
        'other:a.ts',
      ]) {
        try {
          await dio.get<Map<String, dynamic>>(
            '/api/issues/search',
            queryParameters: {'componentKeys': file},
          );
        } on DioException {
          // Expected: the spy stops the request before the network.
        }
      }

      expect(seen[0].queryParameters['branch'], 'feature/login');
      expect(seen[1].queryParameters['pullRequest'], '42');
      expect(seen[1].queryParameters.containsKey('branch'), isFalse);
      expect(seen[2].queryParameters.containsKey('branch'), isFalse);
      expect(seen[2].queryParameters.containsKey('pullRequest'), isFalse);
    });

    test('the main branch adds nothing', () async {
      final seen = <Uri>[];
      final dio = buildSonarQubeDio(baseUrl: 'https://sonar.test', token: 't');
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen.add(options.uri);
            handler.reject(
              DioException(requestOptions: options, error: 'stop'),
            );
          },
        ),
      );

      try {
        await dio.get<Map<String, dynamic>>('/api/measures/component');
      } on DioException {
        // Expected.
      }

      expect(seen.single.queryParameters.containsKey('branch'), isFalse);
    });
  });
}
