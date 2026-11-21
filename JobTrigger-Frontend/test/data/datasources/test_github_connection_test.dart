import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/datasources/github_client_factory.dart';

/// US-GH-CRED-04: "Test connection" for a GitHub token.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body, {this.headers = const {}});

  final int status;
  final Object body;
  final Map<String, List<String>> headers;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<(Result<String, AppFailure>, _Adapter)> _test(_Adapter adapter) async {
  final dio = buildGitHubDio(token: 'fixture-token')
    ..httpClientAdapter = adapter;
  final result = await testGitHubConnection(token: 'fixture-token', dio: dio);
  return (result, adapter);
}

void main() {
  test('a live token names its user, via GET /user with Bearer auth', () async {
    final (result, adapter) = await _test(_Adapter(200, {'login': 'octocat'}));

    expect((result as Ok<String, AppFailure>).value, 'octocat');
    expect(adapter.last?.path, '/user');
    expect(adapter.last?.headers['Authorization'], 'Bearer fixture-token');
  });

  test('a rejected token is an AuthFailure, not a network failure', () async {
    final (result, _) = await _test(
      _Adapter(401, {'message': 'Bad credentials'}),
    );

    final failure = (result as Err<String, AppFailure>).error;
    expect(failure, isA<AuthFailure>());
    expect(failure.message, isNot(const NetworkFailure().message));
  });

  test('a rate limit says so, not a generic server error', () async {
    final (result, _) = await _test(
      _Adapter(
        403,
        {'message': 'API rate limit exceeded'},
        headers: {
          'x-ratelimit-remaining': ['0'],
        },
      ),
    );

    expect((result as Err<String, AppFailure>).error, isA<RateLimitFailure>());
  });
}
