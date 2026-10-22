import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../credentials/active_sonarqube_credential_notifier.dart';
import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/host_pinning.dart';

part 'sonarqube_client_factory.g.dart';

/// Builds a per-credential `Dio` instance with a Bearer-token
/// `Authorization` header set once at construction, against the
/// credential's own `baseUrl` — unlike `buildGitHubDio` (a fixed
/// `api.github.com` base, only the token varies), SonarQube supports
/// self-hosted instances, so the base URL is per-credential, matching
/// `buildJenkinsDio`'s shape instead.
Dio buildSonarQubeDio({required String baseUrl, required String? token}) {
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
  );
}
