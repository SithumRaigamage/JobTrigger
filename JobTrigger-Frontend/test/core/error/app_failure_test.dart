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

    test('403 bad response maps to PermissionFailure, not AuthFailure', () {
      final failure = AppFailure.fromDioException(
        _exception(type: DioExceptionType.badResponse, statusCode: 403),
      );

      expect(failure, isA<PermissionFailure>());
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

  group('AppFailure.fromGitHubException', () {
    test('a 403 with X-RateLimit-Remaining: 0 maps to RateLimitFailure', () {
      final failure = AppFailure.fromGitHubException(
        _exception(
          type: DioExceptionType.badResponse,
          statusCode: 403,
          headers: {
            'x-ratelimit-remaining': ['0'],
          },
        ),
      );

      expect(failure, isA<RateLimitFailure>());
    });

    test(
      'a 403 with a non-zero X-RateLimit-Remaining is a plain PermissionFailure',
      () {
        final failure = AppFailure.fromGitHubException(
          _exception(
            type: DioExceptionType.badResponse,
            statusCode: 403,
            headers: {
              'x-ratelimit-remaining': ['42'],
            },
          ),
        );

        expect(failure, isA<PermissionFailure>());
      },
    );

    test(
      'a 403 with no rate-limit header at all is a plain PermissionFailure',
      () {
        final failure = AppFailure.fromGitHubException(
          _exception(type: DioExceptionType.badResponse, statusCode: 403),
        );

        expect(failure, isA<PermissionFailure>());
      },
    );

    test('delegates to fromDioException for everything else (401)', () {
      final failure = AppFailure.fromGitHubException(
        _exception(type: DioExceptionType.badResponse, statusCode: 401),
      );

      expect(failure, isA<AuthFailure>());
    });

    test(
      'delegates to fromDioException for everything else (connection error)',
      () {
        final failure = AppFailure.fromGitHubException(
          _exception(type: DioExceptionType.connectionError),
        );

        expect(failure, isA<NetworkFailure>());
      },
    );
  });

  group('AppFailure.message', () {
    test('a backend 429 asks the user to wait (AUD-05)', () {
      expect(
        const ServerFailure(429).message,
        'Too many attempts. Please wait a few minutes and try again.',
      );
    });

    test('other server errors keep the status code', () {
      expect(const ServerFailure(502).message, contains('HTTP 502'));
    });

    test('a server error quotes the backend request id (P13-26)', () {
      expect(
        const ServerFailure(500, requestId: 'a1b2c3d4e5f60718').message,
        'Something went wrong on the server (HTTP 500). '
        'Reference: a1b2c3d4e5f60718',
      );
    });
  });

  group('request id from a response (P13-26)', () {
    ServerFailure fromHeader(String value) =>
        AppFailure.fromDioException(
              _exception(
                type: DioExceptionType.badResponse,
                statusCode: 500,
                headers: {
                  'x-request-id': [value],
                },
              ),
            )
            as ServerFailure;

    test('an id-shaped header is kept', () {
      expect(fromHeader('a1b2c3d4e5f60718').requestId, 'a1b2c3d4e5f60718');
    });

    test('anything else is dropped, so it never reaches the copy', () {
      expect(fromHeader('call support <now>').requestId, isNull);
    });

    test('no header, no id', () {
      final failure =
          AppFailure.fromDioException(
                _exception(type: DioExceptionType.badResponse, statusCode: 500),
              )
              as ServerFailure;
      expect(failure.requestId, isNull);
    });
  });

  group('isUnreachable', () {
    test('is true for connection failures and gateway errors', () {
      expect(const NetworkFailure().isUnreachable, isTrue);
      for (final code in [502, 503, 504]) {
        expect(ServerFailure(code).isUnreachable, isTrue, reason: '$code');
      }
    });

    test('is false for everything else', () {
      expect(const ServerFailure(500).isUnreachable, isFalse);
      expect(const AuthFailure().isUnreachable, isFalse);
      expect(const PermissionFailure().isUnreachable, isFalse);
      expect(const NotFoundFailure().isUnreachable, isFalse);
      expect(const UnknownFailure().isUnreachable, isFalse);
    });
  });
}
