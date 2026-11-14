import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/datasources/github_client_factory.dart';

void main() {
  group('buildGitHubDio', () {
    test('sets a Bearer Authorization header and the fixed base URL', () {
      final dio = buildGitHubDio(token: 'ghp_faketoken');

      expect(dio.options.headers['Authorization'], 'Bearer ghp_faketoken');
      expect(dio.options.baseUrl, gitHubApiBaseUrl);
    });

    test('a fresh instance per call carries its own token', () {
      final dioA = buildGitHubDio(token: 'token-a');
      final dioB = buildGitHubDio(token: 'token-b');

      expect(dioA.options.headers['Authorization'], 'Bearer token-a');
      expect(dioB.options.headers['Authorization'], 'Bearer token-b');
      expect(identical(dioA, dioB), isFalse);
    });
  });

  group('testGitHubConnection (US-GH-CRED-04)', () {
    Dio dioReturning(int status, Object? body, {Map<String, List<String>>? h}) {
      return Dio(BaseOptions(baseUrl: gitHubApiBaseUrl))
        ..httpClientAdapter = _Adapter(status, body, h);
    }

    test('returns the authenticated login', () async {
      final result = await testGitHubConnection(
        token: 't',
        dio: dioReturning(200, {'login': 'octocat'}),
      );
      expect((result as Ok<String, AppFailure>).value, 'octocat');
    });

    test('falls back to "unknown" when GitHub sends no login', () async {
      final result = await testGitHubConnection(
        token: 't',
        dio: dioReturning(200, <String, dynamic>{}),
      );
      expect((result as Ok<String, AppFailure>).value, 'unknown');
    });

    test('a rejected token is an AuthFailure', () async {
      final result = await testGitHubConnection(
        token: 't',
        dio: dioReturning(401, {'message': 'Bad credentials'}),
      );
      expect((result as Err<String, AppFailure>).error, isA<AuthFailure>());
    });

    test('an exhausted rate limit is not mistaken for a bad token', () async {
      final result = await testGitHubConnection(
        token: 't',
        dio: dioReturning(
          403,
          {'message': 'rate limit'},
          h: {
            'x-ratelimit-remaining': ['0'],
          },
        ),
      );
      expect(
        (result as Err<String, AppFailure>).error,
        isA<RateLimitFailure>(),
      );
    });
  });

  group('gitHubClientProvider', () {
    test('throws a clear error with no active credential', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(gitHubClientProvider),
        throwsA(isA<Object>()),
      );
    });
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body, this.headers);

  final int status;
  final Object? body;
  final Map<String, List<String>>? headers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...?headers,
    },
  );

  @override
  void close({bool force = false}) {}
}
