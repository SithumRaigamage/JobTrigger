import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/password_reset_repository_impl.dart';

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

PasswordResetRepositoryImpl _repo(_JsonAdapter adapter) =>
    PasswordResetRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = adapter,
    );

void main() {
  test('requestReset posts the email and succeeds on 202', () async {
    final adapter = _JsonAdapter(202, {'message': 'sent if it exists'});
    final result = await _repo(adapter).requestReset(email: 'a@b.com');

    expect(result, isA<Ok<void, AppFailure>>());
    expect(adapter.requests.single.path, '/api/auth/password-reset/request');
    expect(adapter.requests.single.data, {'email': 'a@b.com'});
  });

  test('confirmReset posts the token and the new password', () async {
    final adapter = _JsonAdapter(200, {'message': 'reset'});
    final result = await _repo(
      adapter,
    ).confirmReset(token: 'a' * 64, newPassword: 'new-password');

    expect(result, isA<Ok<void, AppFailure>>());
    expect(adapter.requests.single.path, '/api/auth/password-reset/confirm');
    expect(adapter.requests.single.data, {
      'token': 'a' * 64,
      'newPassword': 'new-password',
    });
  });

  test('an expired link surfaces the backend\'s own words', () async {
    final adapter = _JsonAdapter(400, {
      'message': 'This reset link is invalid or has expired. Ask for a new one.',
    });
    final result = await _repo(
      adapter,
    ).confirmReset(token: 'a' * 64, newPassword: 'new-password');

    final failure = (result as Err<void, AppFailure>).error;
    expect(failure, isA<RejectedRequestFailure>());
    expect(
      (failure as RejectedRequestFailure).serverMessage,
      contains('invalid or has expired'),
    );
  });

  test('a rate limit is not mistaken for a rejected request', () async {
    final adapter = _JsonAdapter(429, {
      'message': 'Too many attempts. Please wait a few minutes and try again.',
    });
    final result = await _repo(adapter).requestReset(email: 'a@b.com');
    expect((result as Err<void, AppFailure>).error, isNot(isA<RejectedRequestFailure>()));
  });
}
