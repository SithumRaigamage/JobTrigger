import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/guard.dart';
import 'package:job_trigger/core/error/result.dart';

DioException _badResponse(int statusCode) {
  final options = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response<void>(requestOptions: options, statusCode: statusCode),
  );
}

AppFailure _errorOf<T>(Result<T, AppFailure> result) => switch (result) {
  Err(:final error) => error,
  Ok() => fail('expected Err, got Ok'),
};

void main() {
  group('guardRequest (AUD-11)', () {
    test('wraps a successful value in Ok', () async {
      final result = await guardRequest(() async => 42);
      expect(result, isA<Ok<int, AppFailure>>());
      expect((result as Ok<int, AppFailure>).value, 42);
    });

    test(
      'maps a DioException with AppFailure.fromDioException by default',
      () async {
        final result = await guardRequest<int>(() => throw _badResponse(500));
        expect(_errorOf(result), isA<ServerFailure>());
      },
    );

    test('uses a custom mapper when given', () async {
      final result = await guardRequest<int>(
        () => throw _badResponse(500),
        mapDioException: (_) => const NotFoundFailure(),
      );
      expect(_errorOf(result), isA<NotFoundFailure>());
    });

    test('recover can turn a DioException into a successful result', () async {
      final result = await guardRequest<int?>(
        () => throw _badResponse(404),
        recover: (exception) =>
            exception.response?.statusCode == 404 ? const Ok(null) : null,
      );
      expect(result, isA<Ok<int?, AppFailure>>());
    });

    test('recover returning null falls through to the mapper', () async {
      final result = await guardRequest<int?>(
        () => throw _badResponse(500),
        recover: (_) => null,
      );
      expect(_errorOf(result), isA<ServerFailure>());
    });

    test(
      'an undecodable body wrapped by Dio is an unexpected response',
      () async {
        final result = await guardRequest<int>(
          () => throw DioException(
            requestOptions: RequestOptions(path: '/x'),
            error: const FormatException('Unexpected character'),
          ),
        );
        expect(_errorOf(result), isA<UnexpectedResponseFailure>());
      },
    );

    test(
      'a TypeError from parsing never escapes -- it becomes a failure',
      () async {
        final result = await guardRequest<Map<String, dynamic>>(() async {
          const Object htmlBody = '<html>Sign in</html>';
          return htmlBody as Map<String, dynamic>;
        });
        final error = _errorOf(result);
        expect(error, isA<UnexpectedResponseFailure>());
        // User-facing copy never includes the raw exception text.
        expect(error.message, isNot(contains('TypeError')));
        expect(error.message, isNot(contains('_String')));
      },
    );

    test('a FormatException (e.g. malformed URL) becomes a failure', () async {
      final result = await guardRequest<Uri>(
        () async => Uri.parse('http://[not a host'),
      );
      expect(_errorOf(result), isA<UnexpectedResponseFailure>());
    });
  });
}
