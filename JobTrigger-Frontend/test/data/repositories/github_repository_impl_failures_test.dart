import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';

/// PE-40 (P8-20): how every GH-RUN call maps GitHub's failures. A 403 with
/// `X-RateLimit-Remaining: 0` is the rate limit, not a refused token; the
/// dispatch's 422 keeps GitHub's own detail when there is one.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body, {this.headers = const {}, this.error});

  final int status;
  final Object? body;
  final Map<String, List<String>> headers;
  final DioException? error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (error != null) throw error!.copyWith(requestOptions: options);
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

GitHubRepositoryImpl _repo(_Adapter adapter) => GitHubRepositoryImpl(
  Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = adapter,
);

typedef _Call =
    Future<Result<Object?, AppFailure>> Function(GitHubRepositoryImpl repo);

/// Every GH-RUN call, each returning its result.
final _calls = <String, _Call>{
  'fetchRuns': (r) => r.fetchRuns('o', 'r', 1),
  'fetchRun': (r) => r.fetchRun('o', 'r', 2),
  'triggerRun': (r) => r.triggerRun('o', 'r', 1, ref: 'main'),
  'cancelRun': (r) => r.cancelRun('o', 'r', 2),
  'fetchJobs': (r) => r.fetchJobs('o', 'r', 2),
};

AppFailure _failure(Result<Object?, AppFailure> result) =>
    (result as Err<Object?, AppFailure>).error;

void main() {
  for (final MapEntry(key: name, value: call) in _calls.entries) {
    group('$name failures', () {
      test('403 with the rate limit exhausted is a RateLimitFailure', () async {
        final result = await call(
          _repo(
            _Adapter(
              403,
              {'message': 'API rate limit exceeded'},
              headers: {
                'x-ratelimit-remaining': ['0'],
              },
            ),
          ),
        );
        expect(_failure(result), isA<RateLimitFailure>());
      });

      test('403 with quota left is a PermissionFailure', () async {
        final result = await call(
          _repo(
            _Adapter(
              403,
              {'message': 'Resource not accessible'},
              headers: {
                'x-ratelimit-remaining': ['4999'],
              },
            ),
          ),
        );
        expect(_failure(result), isA<PermissionFailure>());
      });

      test('401 is an AuthFailure', () async {
        final result = await call(_repo(_Adapter(401, {'message': 'Bad'})));
        expect(_failure(result), isA<AuthFailure>());
      });

      test('404 is a NotFoundFailure', () async {
        final result = await call(_repo(_Adapter(404, {'message': 'Nope'})));
        expect(_failure(result), isA<NotFoundFailure>());
      });

      test('a 5xx is a ServerFailure carrying the status', () async {
        final result = await call(_repo(_Adapter(502, {'message': 'Bad'})));
        expect(_failure(result), isA<ServerFailure>());
        expect((_failure(result) as ServerFailure).statusCode, 502);
      });

      test('no connection is a NetworkFailure', () async {
        final result = await call(
          _repo(
            _Adapter(
              0,
              null,
              error: DioException(
                requestOptions: RequestOptions(),
                type: DioExceptionType.connectionError,
              ),
            ),
          ),
        );
        expect(_failure(result), isA<NetworkFailure>());
      });
    });
  }

  group('triggerRun 422 (US-GH-RUN-02)', () {
    Future<AppFailure> trigger(Object? body) async => _failure(
      await _repo(_Adapter(422, body)).triggerRun('o', 'r', 1, ref: 'x'),
    );

    test('with no detail from GitHub uses the general copy only', () async {
      final failure = await trigger(<String, dynamic>{});
      expect(failure, isA<DispatchRejectedFailure>());
      expect(failure.message, contains('workflow_dispatch'));
      expect(failure.message, isNot(contains('GitHub said')));
    });

    test('with a body that is not an object does not crash', () async {
      final failure = await trigger('Unprocessable');
      expect(failure, isA<DispatchRejectedFailure>());
      expect((failure as DispatchRejectedFailure).detail, isNull);
    });
  });

  group('cancelRun', () {
    test('a run that already finished (409) is reported', () async {
      final result = await _repo(
        _Adapter(409, {
          'message': 'Cannot cancel a workflow run that is completed.',
        }),
      ).cancelRun('o', 'r', 2);
      final failure = _failure(result);
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 409);
    });
  });

  group('rate limit and the token', () {
    test('a rate-limited failure never repeats the token', () async {
      final result = await _repo(
        _Adapter(
          403,
          {'message': 'rate limit for token ghp_secret'},
          headers: {
            'x-ratelimit-remaining': ['0'],
          },
        ),
      ).fetchRun('o', 'r', 2);
      expect(_failure(result).message, isNot(contains('ghp_')));
    });
  });
}
