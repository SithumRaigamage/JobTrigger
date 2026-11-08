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
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';

/// NFR-SEC-03 / P8-26: the backend, Jenkins and GitHub are three
/// independent auth failure domains. Only the backend's session can be
/// ended by a 401 (its interceptor clears the stored tokens and signals
/// the app); a 401 from Jenkins or GitHub is just that tool's credential
/// being wrong, and must not log the user out of JobTrigger. These tests
/// run the real client factories against scripted adapters. The task also
/// asks for a live check against a real GitHub account, which stays open.
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

  test('a GitHub 401 is only an AuthFailure: no logout, backend session '
      'untouched', () async {
    final github = buildGitHubDio(token: 'ghp_bad')
      ..httpClientAdapter = _StatusAdapter(401);

    final result = await GitHubRepositoryImpl(github).fetchRepos();

    expect((result as Err).error, isA<AuthFailure>());
    expect(container.read(sessionSignalProvider), 0);
    expect(unauthorizedCalls, 0);
    expect(await storage.readToken(), 'backend-access');
  });

  test('a Jenkins 401 is only an AuthFailure: no logout, backend session '
      'untouched', () async {
    final jenkins = buildJenkinsDio(
      baseUrl: 'https://jenkins.test',
      username: 'u',
      password: 'wrong',
    )..httpClientAdapter = _StatusAdapter(401);

    final result = await JenkinsRepositoryImpl(jenkins).fetchJobTree();

    expect((result as Err).error, isA<AuthFailure>());
    expect(container.read(sessionSignalProvider), 0);
    expect(unauthorizedCalls, 0);
    expect(await storage.readToken(), 'backend-access');
  });

  test('a GitHub rate limit is not an auth failure at all', () async {
    final adapter = _RateLimited();
    final github = buildGitHubDio(token: 'ghp_ok')..httpClientAdapter = adapter;

    final result = await GitHubRepositoryImpl(github).fetchRepos();

    expect((result as Err).error, isA<RateLimitFailure>());
    expect(container.read(sessionSignalProvider), 0);
  });

  test('the backend losing its session does not disturb the GitHub or '
      'Jenkins clients', () async {
    final githubAdapter = _StatusAdapter(200, body: '[]');
    final github = buildGitHubDio(token: 'ghp_ok')
      ..httpClientAdapter = githubAdapter;
    final jenkinsAdapter = _StatusAdapter(200, body: '{"jobs":[]}');
    final jenkins = buildJenkinsDio(
      baseUrl: 'https://jenkins.test',
      username: 'u',
      password: 'secret',
    )..httpClientAdapter = jenkinsAdapter;

    // The backend refuses both the token and the refresh: session over.
    await backend(
      _StatusAdapter(401),
    ).get<void>('/api/credentials').then((_) {}, onError: (_) {});
    expect(unauthorizedCalls, 1);
    expect(container.read(sessionSignalProvider), 1);
    expect(await storage.readToken(), isNull);

    // Both tool clients still carry their own credentials and still work.
    expect(
      (await GitHubRepositoryImpl(github).fetchRepos()),
      isA<Ok<dynamic, AppFailure>>(),
    );
    expect(
      githubAdapter.requests.single.headers['Authorization'],
      'Bearer ghp_ok',
    );
    expect(
      (await JenkinsRepositoryImpl(jenkins).fetchJobTree()),
      isA<Ok<dynamic, AppFailure>>(),
    );
    expect(
      jenkinsAdapter.requests.first.headers['Authorization'],
      startsWith('Basic '),
    );
  });

  test('the GitHub client never carries the backend token, and the backend '
      'client never carries the GitHub token', () async {
    final githubAdapter = _StatusAdapter(200, body: '[]');
    final github = buildGitHubDio(token: 'ghp_ok')
      ..httpClientAdapter = githubAdapter;
    await GitHubRepositoryImpl(github).fetchRepos();
    expect(githubAdapter.requests.single.headers['x-auth-token'], isNull);

    final backendAdapter = _StatusAdapter(200);
    await backend(backendAdapter).get<void>('/api/credentials');
    expect(
      backendAdapter.requests.single.headers['x-auth-token'],
      'backend-access',
    );
    expect(backendAdapter.requests.single.headers['Authorization'], isNull);
  });
}

/// GitHub's rate-limit response: 403 with `x-ratelimit-remaining: 0`.
class _RateLimited implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"message":"API rate limit exceeded"}',
    403,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      'x-ratelimit-remaining': ['0'],
    },
  );

  @override
  void close({bool force = false}) {}
}
