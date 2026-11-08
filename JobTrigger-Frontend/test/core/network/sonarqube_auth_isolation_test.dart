import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/network/backend_api_client.dart';
import 'package:job_trigger/core/network/session_signal.dart';
import 'package:job_trigger/core/storage/secure_storage_service.dart';
import 'package:job_trigger/data/datasources/github_client_factory.dart';
import 'package:job_trigger/data/datasources/jenkins_client_factory.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';

/// NFR-SEC-03 / P10-14: SonarQube is the fourth independent auth failure
/// domain, next to the backend, Jenkins and GitHub. Only the backend's
/// session can be ended by a 401. These run the real client factories
/// against scripted adapters; the live check against a real SonarQube
/// stays open (P10-15).
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status, {this.body = '{}'});

  final int status;
  final String body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late SecureStorageService storage;
  late ProviderContainer container;
  late int unauthorizedCalls;

  Dio backend(HttpClientAdapter adapter) => buildBackendDio(
    baseUrl: 'https://backend.test',
    secureStorage: storage,
    debugLogging: false,
    onUnauthorized: () {
      unauthorizedCalls++;
      container.read(sessionSignalProvider.notifier).markUnauthorized();
    },
  )..httpClientAdapter = adapter;

  Dio sonar(HttpClientAdapter adapter) =>
      buildSonarQubeDio(baseUrl: 'https://sonar.test', token: 'sq_token')
        ..httpClientAdapter = adapter;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureStorageService(const FlutterSecureStorage());
    await storage.saveToken('backend-access');
    await storage.saveRefreshToken('backend-refresh');
    container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(sessionSignalProvider, (_, _) {});
    unauthorizedCalls = 0;
  });

  test('a SonarQube 401 is only an AuthFailure: no logout, backend session '
      'untouched', () async {
    final result = await SonarQubeRepositoryImpl(
      sonar(_StatusAdapter(401)),
    ).fetchProjects();

    expect((result as Err).error, isA<AuthFailure>());
    expect(container.read(sessionSignalProvider), 0);
    expect(unauthorizedCalls, 0);
    expect(await storage.readToken(), 'backend-access');
  });

  test('a SonarQube 403 (no permission) is not an auth failure', () async {
    final result = await SonarQubeRepositoryImpl(
      sonar(_StatusAdapter(403)),
    ).fetchProjects();

    expect((result as Err).error, isA<PermissionFailure>());
    expect(container.read(sessionSignalProvider), 0);
  });

  test('the backend losing its session does not disturb the SonarQube, '
      'GitHub or Jenkins clients', () async {
    final sonarAdapter = _StatusAdapter(200, body: '{"components":[]}');
    final githubAdapter = _StatusAdapter(200, body: '[]');
    final jenkinsAdapter = _StatusAdapter(200, body: '{"jobs":[]}');
    final sonarDio = sonar(sonarAdapter);
    final github = buildGitHubDio(token: 'ghp_ok')
      ..httpClientAdapter = githubAdapter;
    final jenkins = buildJenkinsDio(
      baseUrl: 'https://jenkins.test',
      username: 'u',
      password: 'secret',
    )..httpClientAdapter = jenkinsAdapter;

    await backend(
      _StatusAdapter(401),
    ).get<void>('/api/credentials').then((_) {}, onError: (_) {});
    expect(unauthorizedCalls, 1);
    expect(container.read(sessionSignalProvider), 1);
    expect(await storage.readToken(), isNull);

    expect(
      await SonarQubeRepositoryImpl(sonarDio).fetchProjects(),
      isA<Ok<dynamic, AppFailure>>(),
    );
    expect(
      sonarAdapter.requests.single.headers['Authorization'],
      'Bearer sq_token',
    );
    expect(
      await GitHubRepositoryImpl(github).fetchRepos(),
      isA<Ok<dynamic, AppFailure>>(),
    );
    expect(
      await JenkinsRepositoryImpl(jenkins).fetchJobTree(),
      isA<Ok<dynamic, AppFailure>>(),
    );
  });

  test('the SonarQube client carries neither the backend token nor another '
      "tool's credentials, and its token goes nowhere else", () async {
    final sonarAdapter = _StatusAdapter(200, body: '{"components":[]}');
    await SonarQubeRepositoryImpl(sonar(sonarAdapter)).fetchProjects();
    final sent = sonarAdapter.requests.single;
    expect(sent.headers['x-auth-token'], isNull);
    expect(sent.headers['Authorization'], 'Bearer sq_token');

    final backendAdapter = _StatusAdapter(200);
    await backend(backendAdapter).get<void>('/api/credentials');
    expect(backendAdapter.requests.single.headers['Authorization'], isNull);

    final githubAdapter = _StatusAdapter(200, body: '[]');
    await GitHubRepositoryImpl(
      buildGitHubDio(token: 'ghp_ok')..httpClientAdapter = githubAdapter,
    ).fetchRepos();
    expect(
      githubAdapter.requests.single.headers['Authorization'],
      'Bearer ghp_ok',
    );
  });
}
