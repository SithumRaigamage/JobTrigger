import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';

DioException _exception({
  required DioExceptionType type,
  int? statusCode,
  String? message,
  Map<String, List<String>>? headers,
}) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    message: message,
    response: statusCode == null
        ? null
        : Response(
            requestOptions: requestOptions,
            statusCode: statusCode,
            headers: Headers.fromMap(headers ?? {}),
          ),
  );
}

void main() {
  group('AppFailure.fromDioException', () {
    // Representative DioException shapes, per
    // docs/api-reference.md#error-shapes-to-handle-explicitly.
    test('connection timeout maps to NetworkFailure', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.connectionTimeout),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('connection refused (connectionError) maps to NetworkFailure', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.connectionError),
      );

      expect(failure, isA<NetworkFailure>());
    });

    test('401 bad response maps to AuthFailure', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.badResponse, statusCode: 401),
      );

      expect(failure, isA<AuthFailure>());
    });

    test('403 bad response maps to AuthFailure', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.badResponse, statusCode: 403),
      );

      expect(failure, isA<AuthFailure>());
    });

    test('404 bad response maps to NotFoundFailure', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.badResponse, statusCode: 404),
      );

      expect(failure, isA<NotFoundFailure>());
    });

    test('500 bad response maps to ServerFailure with the status code', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.badResponse, statusCode: 500),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });

    test('unknown type maps to UnknownFailure', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.unknown, message: 'boom'),
      );

      expect(failure, isA<UnknownFailure>());
      expect((failure as UnknownFailure).debugMessage, 'boom');
    });
  });

  group('AppFailure.fromGithubException', () {
    test(
      'a 403 with X-RateLimit-Remaining: 0 maps to RateLimitFailure',
      () {
        final failure = AppFailure.fromGithubException(
          _exception(
            type: DioExceptionType.badResponse,
            statusCode: 403,
            headers: {
              'x-ratelimit-remaining': ['0'],
            },
          ),
        );

        expect(failure, isA<RateLimitFailure>());
      },
    );

    test(
      'a 403 with a non-zero X-RateLimit-Remaining is a plain AuthFailure',
      () {
        final failure = AppFailure.fromGithubException(
          _exception(
            type: DioExceptionType.badResponse,
            statusCode: 403,
            headers: {
              'x-ratelimit-remaining': ['42'],
            },
          ),
        );

        expect(failure, isA<AuthFailure>());
      },
    );

    test('a 403 with no rate-limit header at all is a plain AuthFailure', () {
      final failure = AppFailure.fromGithubException(
        _exception(type: DioExceptionType.badResponse, statusCode: 403),
      );

      expect(failure, isA<AuthFailure>());
    });

    test('delegates to fromDioException for everything else (401)', () {
      final failure = AppFailure.fromGithubException(
        _exception(type: DioExceptionType.badResponse, statusCode: 401),
      );

      expect(failure, isA<AuthFailure>());
    });

    test(
      'delegates to fromDioException for everything else (connection error)',
      () {
        final failure = AppFailure.fromGithubException(
          _exception(type: DioExceptionType.connectionError),
        );

        expect(failure, isA<NetworkFailure>());
      },
    );
  });
}
