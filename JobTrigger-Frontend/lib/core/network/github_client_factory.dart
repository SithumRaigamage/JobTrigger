import 'package:dio/dio.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

/// GitHub's REST API base — every `GitHubRepository` call is relative to
/// this. Unlike Jenkins (a different base URL per server), every GitHub
/// credential talks to the same `api.github.com`; what varies per
/// credential is only the Bearer token.
const gitHubApiBaseUrl = 'https://api.github.com';

/// Builds a per-credential `Dio` instance with a Bearer-token
/// `Authorization` header set once at construction — see
/// `docs/user-stories/12-github-actions.md`'s epic intro for why this is
/// structurally simpler than `buildJenkinsDio`: no CSRF crumb interceptor
/// (`NFR-SEC-06` is a Jenkins-only mechanism, GitHub's API doesn't use
/// one), and the base URL is fixed rather than per-credential.
Dio buildGitHubDio({required String token}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: gitHubApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/vnd.github+json'},
    ),
  );

  dio.options.headers['Authorization'] = 'Bearer $token';

  return dio;
}

/// "Test connection" (`US-GH-CRED-04`): `GET /user` against a throwaway
/// `Dio` instance — never the active credential's client, matching
/// `testJenkinsConnection()`'s reasoning exactly. Returns the
/// authenticated username on success.
Future<Result<String, AppFailure>> testGitHubConnection({
  required String token,
}) async {
  final dio = buildGitHubDio(token: token);
  try {
    final response = await dio.get<Map<String, dynamic>>('/user');
    final login = response.data?['login'] as String?;
    return Ok(login ?? 'unknown');
  } on DioException catch (exception) {
    return Err(AppFailure.fromGitHubException(exception));
  } finally {
    dio.close();
  }
}
