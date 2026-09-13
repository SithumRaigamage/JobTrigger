import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../presentation/features/settings/active_server_notifier.dart';
import '../error/app_failure.dart';
import '../error/result.dart';

part 'jenkins_client_factory.g.dart';

/// Builds a per-server `Dio` instance with HTTP Basic Auth set once at
/// construction — Jenkins credentials aren't JWTs and don't rotate
/// mid-session (see `docs/api-reference.md#2-jenkins-api-direct-per-server-basic-auth`).
Dio buildJenkinsDio({
  required String baseUrl,
  required String username,
  required String password,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final basicAuth = base64Encode(utf8.encode('$username:$password'));
  dio.options.headers['Authorization'] = 'Basic $basicAuth';

  return dio;
}

/// Rebuilt whenever the active server changes (`docs/state-management.md`).
/// Throws if there's no active server yet — screens that depend on this
/// (via `jenkinsRepositoryProvider`, Phase 4) are expected to already gate
/// on a server being configured before reaching that point.
@riverpod
Dio jenkinsClient(Ref ref) {
  final server = ref.watch(activeServerNotifierProvider);
  if (server == null) {
    throw StateError('No active Jenkins server is configured.');
  }
  return buildJenkinsDio(
    baseUrl: server.jenkinsURL,
    username: server.username,
    password: server.secret,
  );
}

/// "Test connection" (P3-08): `GET {url}/api/json` against a throwaway
/// `Dio` instance — never the active one, so testing a new/edited server
/// doesn't disturb the active session. Returns the job count on success.
///
/// This calls Jenkins directly rather than through a `JenkinsRepository`
/// because that repository (with job-tree fetching, URL rewriting, etc.) is
/// Phase 4 scope (`tasks/phase-4-jenkins-job-tree.md`) — building it now
/// would preempt that phase's actual design. `docs/state-management.md`'s
/// mention of `jenkinsRepositoryProvider.testConnection(...)` describes the
/// eventual full picture once Phase 4 lands.
Future<Result<int, AppFailure>> testJenkinsConnection({
  required String jenkinsURL,
  required String username,
  required String password,
}) async {
  final dio = buildJenkinsDio(
    baseUrl: jenkinsURL,
    username: username,
    password: password,
  );
  try {
    final response = await dio.get<Map<String, dynamic>>('/api/json');
    final jobs = response.data?['jobs'] as List<dynamic>?;
    return Ok(jobs?.length ?? 0);
  } on DioException catch (exception) {
    return Err(AppFailure.fromDioException(exception));
  } finally {
    dio.close();
  }
}
