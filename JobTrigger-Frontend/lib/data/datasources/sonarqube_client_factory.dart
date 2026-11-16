import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../credentials/active_sonarqube_credential_notifier.dart';
import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/host_pinning.dart';
import '../../domain/sonarqube/sonarqube_branch_ref.dart';

part 'sonarqube_client_factory.g.dart';

/// Builds a per-credential `Dio` instance with a Bearer-token
/// `Authorization` header set once at construction, against the
/// credential's own `baseUrl` — unlike `buildGitHubDio` (a fixed
/// `api.github.com` base, only the token varies), SonarQube supports
/// self-hosted instances, so the base URL is per-credential, matching
/// `buildJenkinsDio`'s shape instead.
Dio buildSonarQubeDio({
  required String baseUrl,
  required String? token,
  SonarQubeBranchRef Function(String projectKey)? refFor,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // AUD-63: a credential whose token the backend could not decrypt has no
  // usable token. Send the request unauthenticated rather than inventing
  // one — SonarQube answers 401, which is the honest result for a
  // credential the user still has to re-enter.
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  // AUD-45: the token only ever goes to the credential's own server.
  dio.interceptors.add(hostPinningInterceptor());
  // US-SQ-QUALITY-10: every project-scoped call carries the chosen branch or
  // pull request. Only the endpoints that accept it are touched, so listing
  // branches (and anything server-wide) is never given a branch parameter.
  if (refFor != null) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_refAwarePaths.any(options.path.startsWith)) {
            final ref = refFor(_projectKeyOf(options.queryParameters));
            final queryKey = ref.queryKey;
            if (queryKey != null) options.queryParameters[queryKey] = ref.name;
          }
          handler.next(options);
        },
      ),
    );
  }

  return dio;
}

/// "Test connection" (`US-SQ-CRED-04`): `GET /api/authentication/validate`
/// against a throwaway `Dio` instance — never the active credential's
/// client, matching `testGitHubConnection()`'s reasoning exactly. Unlike
/// GitHub/Jenkins, SonarQube's validate endpoint always answers `200` with
/// a `{valid: bool}` body, even for a bad token — an invalid token is not
/// a `DioException` at all, so it has to be mapped to a failure explicitly
/// here rather than inferred from HTTP status.
Future<Result<void, AppFailure>> testSonarQubeConnection({
  required String baseUrl,
  required String token,
}) async {
  final dio = buildSonarQubeDio(baseUrl: baseUrl, token: token);
  try {
    final result = await guardRequest(() async {
      final response = await dio.get<Map<String, dynamic>>(
        '/api/authentication/validate',
      );
      return response.data?['valid'] == true;
    });
    return switch (result) {
      Ok(value: true) => const Ok(null),
      Ok() => const Err(AuthFailure()),
      Err(:final error) => Err(error),
    };
  } finally {
    dio.close();
  }
}

/// Rebuilt whenever the active SonarQube credential changes — mirrors
/// `gitHubClientProvider` exactly. Throws if there's no active credential
/// yet; screens that depend on this are expected to already gate on a
/// credential being configured before reaching that point.
@riverpod
Dio sonarQubeClient(Ref ref) {
  final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
  if (credential == null) {
    throw StateError('No active SonarQube credential is configured.');
  }
  return buildSonarQubeDio(
    baseUrl: credential.baseUrl,
    token: credential.secret,
    refFor: (projectKey) =>
        ref.watch(sonarQubeBranchSelectionsNotifierProvider)[projectKey] ??
        const SonarQubeBranchRef.main(),
  );
}

/// The endpoints that take `branch` / `pullRequest` (`US-SQ-QUALITY-10`).
/// The project a request is about, from whichever parameter it uses. A
/// component key is `project:path`, so the project is its first two parts.
String _projectKeyOf(Map<String, dynamic> query) {
  for (final name in ['project', 'projectKey', 'component', 'componentKeys']) {
    final value = query[name];
    if (value is! String || value.isEmpty) continue;
    final parts = value.split(':');
    return parts.length > 2 ? '${parts[0]}:${parts[1]}' : value;
  }
  return '';
}

const _refAwarePaths = [
  '/api/qualitygates/project_status',
  '/api/measures/component_tree',
  '/api/measures/component',
  '/api/measures/search_history',
  '/api/issues/search',
  '/api/hotspots/search',
  '/api/project_analyses/search',
  '/api/ce/component',
];

/// The branch or pull request each project's views read (`US-SQ-QUALITY-10`),
/// per project: switching one project's ref leaves the others on main. The
/// SonarQube client watches this map, so a change rebuilds it and every
/// notifier on that project reloads through its own provider.
@riverpod
class SonarQubeBranchSelectionsNotifier
    extends _$SonarQubeBranchSelectionsNotifier {
  @override
  Map<String, SonarQubeBranchRef> build() => const {};

  SonarQubeBranchRef refFor(String projectKey) =>
      state[projectKey] ?? const SonarQubeBranchRef.main();

  void set(String projectKey, SonarQubeBranchRef ref) =>
      state = {...state, projectKey: ref};
}
